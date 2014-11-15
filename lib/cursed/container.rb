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

  def_predicates :visible, :selected, :focused, :focusable, :exclusive, :border

  def_delegators :@window, :write, :colorize
  def_delegators :@buffer, :puts, :<<

  class NilParent
    def nil?; true end
    def not_focusable?; true end
    def method_missing(method, *args, &blk); nil end
  end

  def initialize(parent, params)
    params ||= {}
    @parent = parent || NilParent.new
    @class  = params[:class]

    # TODO: is this bootstrapping necessary?
    tmp_scope = Scope.new(self, @parent.variable_scope, params[:variables])
    @styles   = tmp_scope.deep_eval((tmp_scope.styles || {})[@class] || {}, ignore: [:keybindings])
    opts      = defaults.deep_merge(@styles).deep_merge(params)

    @children    = []
    @focused     = false
    @selected    = false
    @buffer      = Buffer.new(self)
    @id          = opts[:id]
    @name        = opts[:name]
    @content     = opts[:content]
    @window      = opts[:window]
    @layout      = opts[:layout]      || []
    @variables   = opts[:variables]   || []
    @keybindings = opts[:keybindings] || []
    @exclusive   = opts[:exclusive]   || false
    @flow        = opts[:flow]        || :vertical
    @fg          = opts[:fg]          || :white
    @bg          = opts[:bg]          || :black
    @bc          = opts[:bc]          || :blue
    @sc          = opts[:sc]          || :red
    @fc          = opts[:fc]          || :green
    @border      = opts[:border].nil?    ? true : opts[:border]
    @visible     = opts[:visible].nil?   ? true : opts[:visible]
    @focusable   = opts[:focusable].nil? ? true : opts[:focusable]

    @variable_scope   = Scope.new(self, @parent.variable_scope,   @variables)
    @keybinding_scope = Scope.new(nil,  @parent.keybinding_scope, @keybindings)

    unless @window
      @fixed_height, @fixed_width, @fixed_top, @fixed_left = \
        opts.values_at(:height, :width, :top, :left)
      @window = Curses::Window.new(height, width, top, left)
    end

    @layout.map { |child| Container.build(self, child) }
    @parent.add_child!(self)
    @children.first.selected! if @children.any?
  end

  # support for different container types (ie. grid)
  #
  def self.build(parent, params)
    params ||= {}
    klass = Cursed.constantize(params[:class]) || self
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

  def focusable?;     @focusable && @children.any? end
  def not_focusable?; !focusable? end

# unsafe ops

  def add_child!(child)
    @children << child
  end

  def remove_child!(child)
    @children.delete(child)
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

# safe ops

  def select_adjacent_child!(direction)
    return false if visible_children.size < 2

    idx = visible_children.index(selected_child)
    dir = (direction == :next ? 1 : -1)
    select_child!(visible_children.rotate(dir)[idx])
  end

  def smart_select_child!(direction, depth = 0)
    required_flow, adjacent_direction = \
      case direction
      when :up    then [:vertical,   :prev]
      when :down  then [:vertical,   :next]
      when :left  then [:horizontal, :prev]
      when :right then [:horizontal, :next]
      end

    if flow == required_flow && visible_children.size > 1
      select_adjacent_child!(adjacent_direction)
      depth.times { focus_in! }
    else
      focus_out!
      parent.smart_select_child!(direction, depth + 1)
    end
  end

  def hide_selected!
    old_child = selected_child
    select_adjacent_child!(:next)
    old_child.not_visible!
  end

  def focus_in!
    return false if selected_child.not_focusable?

    not_focused!
    selected_child.focused!
  end

  def focus_out!
    return false if @parent.not_focusable?

    not_focused!
    @parent.focused!
  end

  def show_child!(container)
    parent = container.parent
    if parent.exclusive?
      swap_child!(parent.selected_child, container)
    else
      container.visible!
    end
  end

  def show_hidden_child(idx)
    show_child!(hidden_children[idx])
  end

# container attributes ie. height, width, top, left

  def get_attribute(attr)
    instance_variable_get("@fixed_#{attr}") ||
    instance_variable_get("@auto_#{attr}")  ||
    @parent.send("effective_#{attr}") ||
    @window.send(attr) || DEFAULT_SIZE[attr]
  end

  def get_effective_attribute(attr)
    get_attribute(attr) + (border? ? BORDER_OFFSET[attr] : 0)
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
      border? ? (@window.box(?|, ?-); draw_title) : @window.marker(?+)
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
    title = "[#{@name || @id}]"
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
    (autoplaceable_children - autosizable_children).reduce(0) do |sum, c|
      sum + (c.send("fixed_#{flow_dimension}") || 0)
    end
  end

  def autosizable_children
    autoplaceable_children.reject { |c| c.send("fixed_#{flow_dimension}")}
  end

  def autoplaceable_children
    visible_children.reject { |c| c.send("fixed_#{flow_axis}") }
  end

# flow autosizing

  def adjust_children!
    autosize_children unless autosizable_children.empty?
    autoposition_children
    children.each { |c| c.adjust_children! }
  end

  def autosize_children
    autosizable_count = autosizable_children.count
    new_size = flow_space.to_f / autosizable_count
    autosizable_children.each { |c| c.resize(flow_dimension => new_size.to_i) }
    # fix for odd flow space size
    size_fix = ((new_size % 1) * autosizable_count).round
    autosizable_children.last.resize(
      flow_dimension => size_fix, offset: true) if new_size != new_size.to_i
  end

  def autoposition_children
    autoplaceable_children.reduce(effective_flow_offset) do |offset, c|
      c.move(flow_axis => offset)
      offset + c.send(flow_dimension)
    end
  end

# printing

  def buffer_content
    @buffer << @variable_scope.deep_eval(@content)
  end

  def print_buffer
    colorize(@fg) { border? ? print_buffer_in_border : print_buffer_no_border }
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

  def find_container(id)
    all_containers.find { |c| c.id.to_s == id.to_s }
  end

  def root
    @parent.root || self
  end

  def first_leaf
    if visible_children.any?
      visible_children.first.first_leaf
    else self
    end
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
    { visible: true,
      keybindings: {
        'k' => -> { select_adjacent_child!(:prev) if flow == :vertical   },
        'j' => -> { select_adjacent_child!(:next) if flow == :vertical   },
        'l' => -> { select_adjacent_child!(:prev) if flow == :horizontal },
        'h' => -> { select_adjacent_child!(:next) if flow == :horizontal },
        'K' => -> { smart_select_child!(:up)    },
        'J' => -> { smart_select_child!(:down)  },
        'L' => -> { smart_select_child!(:right) },
        'H' => -> { smart_select_child!(:left)  },
        'i' => -> { focus_in!  },
        'o' => -> { focus_out! },
        'x' => -> { hide_selected!},
        'q' => -> { throw(:exit)  },
        'b' => -> { Curses.close_screen; binding.pry }
    }}
  end

end
