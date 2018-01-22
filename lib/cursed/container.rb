class Cursed::Container
  include Cursed
  extend  Forwardable

  ATTRIBUTES    = [:height, :width, :top, :left            ].freeze
  DEFAULT_SIZE  = { height: 3, width: 3, top: 0, left: 0   }.freeze
  BORDER_OFFSET = { height: -2, width: -2, top: 1, left: 1 }.freeze
  FLOW_OFFSETS  = { vertical: :top, horizontal: :left      }.freeze
  FLOW_DIMS     = { vertical: :height, horizontal: :width  }.freeze
  FLOW_ATTRS    = [:size, :offset                          ].freeze

  attr_reader   :id, :parent, :children, :flow, :buffer
  attr_reader   :variable_scope, :keybinding_scope
  protected     :variable_scope, :keybinding_scope

  attr_accessor :fixed_height, :fixed_width, :fixed_top, :fixed_left
  attr_accessor :auto_height, :auto_width, :auto_top, :auto_left

  def_predicates :visible, :exclusive, :selected, :focused, :bordered

  def_delegators :@window, :write, :colorize
  def_delegators :@buffer, :puts, :<<

  class NilParent
    def nil?; true end
    def method_missing(method, *args, &blk); nil end
  end

  def initialize(parent, params)
    params ||= {}
    @parent = parent || NilParent.new
    @class  = params[:class]

    # TODO: garbage collect
    tmp_scope = Scope.new(self, @parent.try(:variable_scope), params[:variables])
    @styles   = tmp_scope.deep_eval((tmp_scope.styles || {})[@class] || {}, ignore: [:keybindings])
    opts      = defaults.deep_merge(@styles).deep_merge(params)

    @children    = []
    @focused     = false
    @selected    = false
    @buffer      = Buffer.new(self)
    @content     = opts[:content]
    @window      = opts[:window]
    @layout      = opts[:layout]      || []
    @variables   = opts[:variables]   || []
    @keybindings = opts[:keybindings] || []
    @exclusive   = opts[:exclusive]   || false
    @flow        = opts[:flow]        || :vertical
    @id          = opts[:id]          || :container
    @fg          = opts[:fg]          || :white
    @bg          = opts[:bg]          || :black
    @bc          = opts[:bc]          || :blue
    @sc          = opts[:sc]          || :red
    @fc          = opts[:fc]          || :green
    @bordered    = opts[:border].nil?  ? true : opts[:border]
    @visible     = opts[:visible].nil? ? true : opts[:visible]

    @variable_scope   = Scope.new(self, @parent.try(:variable_scope),   @variables)
    @keybinding_scope = Scope.new(nil,  @parent.try(:keybinding_scope), @keybindings)

    unless @window
      @fixed_height, @fixed_width, @fixed_top, @fixed_left = \
        opts.values_at(:height, :width, :top, :left)
      @window = Curses::Window.new(height, width, top, left)
    end

    @layout.map { |child| Container.build(self, child) }
    @parent.add_child!(self)
    @children.first.selected!
  end

  # support for different container types (ie. grid)
  #
  def self.build(parent, params)
    params ||= {}
    klass = Cursed.constantize(params[:type]) || self
    klass.new(parent, params)
  end

# collection helpers

  def visible_children
    @children.select(&:visible?)
  end

  def hidden_children
    @children.select(&:not_visible?)
  end

  def selected_child
    @children.find(&:selected?)
  end

# primitive ops
#
# visible?, exclusive?, selected?, focused?, bordered?
# visible!, exclusive!, selected!, focused!, bordered!
#

  def focusable?
    @children.any?
  end

  def add_child!(child)
    @children << child
    adjust_children!
  end

  def remove_child!(child)
    @children.delete(child)
    adjust_children!
  end

  def select_child!(child)
    selected_child.not_selected!
    child.selected!
  end

  def swap_child!(child1, child2)
    child1.not_visible!
    child1.not_selected!
    child2.visible!
    child2.selected!
  end

# ops
  
  def select_child!(direction)
    return false if children.empty?

    idx = @children.index(selected_child)
    dir = (direction == :next ? 1 : -1)
    select_child!(@children.rotate(dir)[idx])
  end

  def hide_selected!
    selected_child.not_visible!
    select_child(:next)
  end

  def swap_selected!(new_child)
    swap_child(selected_child, new_child)
  end

  def focus_in!
    return false unless selected_child.focusable?

    not_focused!
    selected_child.focused!
    selected_child
  end

  def focus_out!
    return false if @parent.nil?

    not_focused!
    @parent.focused!
    @parent
  end

  def focus!(direction)
    if @parent.select_child!(direction)
      focus_out!
      @parent.focus_in!
    end
  end

  # def show_child!(idx)
  #   hidden_children[idx].visible!
  #   hidden_children[idx].select!
  # end

# container attributes ie. height, width, top, left

  def get_attribute(attr)
    instance_variable_get("@fixed_#{attr}") ||
    instance_variable_get("@auto_#{attr}")  ||
    @parent.send("effective_#{attr}") ||
    @window.send(attr) || DEFAULT_SIZE[attr]
  end

  def get_effective_attribute(attr)
    get_attribute(attr) + (bordered? ? BORDER_OFFSET[attr] : 0)
  end

  # creates :height, :width, :top, :left and effective_* readers
  #
  ATTRIBUTES.each do |attr|
    define_method(attr) do
      get_attribute(attr)
    end

    define_method("effective_#{attr}") do
      get_effective_attribute(attr)
    end
  end

  # creates :flow_size, :flow_offset and effective_* readers
  #
  FLOW_ATTRS.each do |attr|
    define_method("flow_#{attr}") do
      get_attribute(decode_flow_attr(attr))
    end

    define_method("effective_flow_#{attr}") do
      get_effective_attribute(decode_flow_attr(attr))
    end
  end

  def update_attributes(attrs)
    offset = attrs.delete(:offset) || false
    attrs.each do |attr, val|
      val = offset ? send(attr) + val.to_i : val
      instance_variable_set("@auto_#{attr}", val)
    end
  end

  # performs a quick refresh, must call refresh! to eventually draw to the
  # screen
  #
  def refresh
    @window.resize(height, width)
    @window.move(top, left)
    @window.clear
    @window.bkgd(1) # even background hack
    buffer_content if @content.is_a?(Proc)
    print_buffer
    draw_border
    @window.noutrefresh
    visible_children.each(&:refresh)
  end

  # actually draws to the screen
  #
  def refresh!
    refresh
    @window.refresh
  end

  def resize(params)
    update_attributes(params)
  end

  def move(params)
    update_attributes(params)
  end

  def draw_border
    @window.colorize(border_color) do
      bordered? ? (@window.box(?|, ?-); draw_title) : @window.marker(?+)
    end
  end

  def border_color
    if selected? && @parent.focused?
      @sc
    elsif focused?
      @fc
    else @bc
    end
  end

  def draw_title
    title = "[#{@id}]"
    left = (width - title.length)/2
    write(0, left, title)
  end

# flow

  def flow_dimension
    @flow_dimension ||= FLOW_DIMS[@flow]
  end

  def flow_axis
    @flow_axis||= FLOW_OFFSETS[@flow]
  end

  def flow_space
    effective_flow_size - reserved_space
  end

  def reserved_space
    visible_children.reduce(0) { |a,c| a + (c.send("fixed_#{flow_dimension}") || 0) }
  end

  def autosizable_children
    visible_children.reject { |c| c.send("fixed_#{flow_dimension}")}
  end

# flow autosizing

  def adjust_children!
    autosize_children unless autosizable_children.empty?
    autoposition_children
  end

  def autosize_children
    autosizable_count = autosizable_children.count
    new_size = flow_space.to_f / autosizable_count
    size_fix = ((new_size % 1) * autosizable_count).to_i
    autosizable_children.each { |c| c.resize(flow_dimension => new_size.to_i) }
    # fix for odd flow space size
    autosizable_children.last.resize(
      flow_dimension => size_fix, offset: true) if new_size != new_size.to_i
  end

  def autoposition_children
    visible_children.reduce(effective_flow_offset) do |offset, c|
      c.move(flow_axis => offset)
      offset + c.send(flow_dimension)
    end
  end

# printing

  def buffer_content
    @buffer << @variable_scope.deep_eval(@content)
  end

  def print_buffer
    colorize(@fg) { bordered? ? print_buffer_in_border : print_buffer_no_border }
  end

  def print_buffer_in_border
    @window.setpos(1,1)
    @buffer.slices.each do |line|
      @window << line
      @window.setpos(@window.cury+1,1)
    end
    @buffer.clear!
  end

  def print_buffer_no_border
    @window.setpos(0,0)
    @window << @buffer.flush
  end

# keybindings

  def react_to_input(input)
    if @keybinding_scope.respond_to?(input)
      @variable_scope.deep_eval(@keybinding_scope.send(:get_proc, input))
    end
  end

# global state

  def in_focus
    all_containers.find { |c| c.focused? }
  end

  def root
    @parent.nil? ? @parent.root : self
  end

  def find_container(id)
    all_containers.find { |c| c.id.to_s == id.to_s }
  end

  def flatten_tree
    if children.any?
      children.flat_map(&:flatten_tree).unshift(self)
    else self
    end
  end

private

  def all_containers
    @all ||= root.flatten_tree
  end

  def decode_flow_attr(attr)
    attr == :size ? flow_dimension : flow_axis
  end

  def defaults
    { keybindings: {
        'k' => -> { select_child!(:prev) },
        'j' => -> { select_child!(:next) },
        'l' => -> { focus!(:prev) },
        'h' => -> { focus!(:next) },
        'i' => -> { focus_in! },
        'o' => -> { focus_out! },
        'x' => -> { hide_selected!},
        'q' => -> { throw(:exit) },
        'b' => -> { Curses.close_screen; binding.pry },
        '0' => -> { show_child!(0) },
        '1' => -> { show_child!(1) },
        '2' => -> { show_child!(2) },
        '3' => -> { show_child!(3) },
        '4' => -> { show_child!(4) },
        '5' => -> { show_child!(5) },
        '6' => -> { show_child!(6) },
        '7' => -> { show_child!(7) },
        '8' => -> { show_child!(8) },
        '9' => -> { show_child!(9) }
    }}
  end

end
