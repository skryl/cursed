class Cursed::Container
  include Cursed
  extend  Forwardable
  def_delegators :@window, :write, :colorize

  ATTRIBUTES    = [:height, :width, :top, :left].freeze
  DEFAULT_SIZE  = { height: 3, width: 3, top: 0, left: 0 }.freeze
  BORDER_OFFSET = { height: -2, width: -2, top: 1, left: 1 }.freeze
  FLOW_OFFSETS  = { vertical: :top, horizontal: :left}.freeze
  FLOW_DIMS     = { vertical: :height, horizontal: :width }.freeze
  FLOW_ATTRS    = [:size, :offset].freeze

  attr_reader   :parent, :buffer, :children, :title, :flow, :keybindings
  attr_accessor :fixed_height, :fixed_width, :fixed_top, :fixed_left
  attr_accessor :auto_height, :auto_width, :auto_top, :auto_left
  def_delegators :@buffer, :puts, :<<

  def defaults; {} end

  def initialize(parent, params)
    @parent      = parent
    params       = defaults.merge(params || {})

    @children    = []
    @buffer      = Buffer.new(self)
    @buffer_proc = params[:buffer]
    @window     = params[:window]
    @exclusive   = params[:exclusive].nil? ? false : params[:exclusive]
    @border      = params[:border].nil? ? true : params[:border]
    @flow        = params[:flow] || :vertical
    @title       = params[:title] || :container
    @visible     = params[:visible].nil? ? true : params[:visible]
    @selected    = params[:selected].nil? ? false : params[:selected]
    @keybindings = params[:keybindings] || []

    # colors (foreground, background, border)
    @fg  = params[:fg] || :white
    @bg  = params[:bg] || :black
    @bc  = params[:bc] || :blue

    # bring variables into object scope
    import_user_variables params[:variables] || []

    unless @window
      @fixed_height, @fixed_width, @fixed_top, @fixed_left = \
        params.values_at(:height, :width, :top, :left)
      @window = Curses::Window.new(height, width, top, left)
    end

    @parent.add_child(self) if @parent
  end

  def show
    @visible = true
    @parent.adjust_children
  end

  def hide
    @visible = false
    @parent.adjust_children
  end

  def visible?; @visible end
  def hidden?; !@visible end
  def exclusive?; @exclusive end
  def border?; @border end
  def select; @selected = true end
  def unselect; @selected = false end
  def selected?; @selected end
  def parent_selected?; @parent && @parent.selected? end

# children

  def add_child(child)
    @children << child
    adjust_children
  end

  def visible_children
    @children.select(&:visible?)
  end

  def hidden_children
    @children.select(&:hidden?)
  end

  def active_child
    visible_children.find(&:selected?)
  end

  def hide_selected
    active = active_child
    select_child(:next)
    active.hide
  end

  def select_child(direction)
    active = active_child
    valid_children = exclusive? ? children : visible_children
    new_child = next_child(valid_children, active, direction)
    active.hide    if exclusive?
    active.unselect
    new_child.show if exclusive?
    new_child.select
  end

  def next_child(children, active, direction)
    new_idx = \
      ((children.index(active) +
       (direction == :next ? 1 : -1)) %
      children.size)
    children[new_idx]
  end

# container attributes ie. height, width, top, left

  def get_attribute(attr)
    instance_variable_get("@fixed_#{attr}") ||
    instance_variable_get("@auto_#{attr}")  ||
    @parent && @parent.send("effective_#{attr}") ||
    @window && @window.send(attr) || DEFAULT_SIZE[attr]
  end

  def get_effective_attribute(attr)
    get_attribute(attr) + (@border ? BORDER_OFFSET[attr] : 0)
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

# movement

  def resize(params)
    update_attributes(params)
  end

  def move(params)
    update_attributes(params)
  end

  # performs a quick refresh, must call refresh! to eventually draw to the
  # screen
  #
  def refresh
    @window.resize(height, width)
    @window.move(top, left)
    @window.clear
    @window.bkgd(1) # even background hack
    fill_buffer if @buffer_proc
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

  def draw_border
    @window.colorize(selected? && parent_selected? ? :red : @bc) do
      @border ? (@window.box(?|, ?-); draw_title) : @window.marker(?+)
    end
  end

  def draw_title
    title = "[#{@title}]"
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

  def adjust_children
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

  def fill_buffer
    @buffer << variable_scope.instance_exec(&@buffer_proc)
  end

  def print_buffer
    colorize(@fg) { @border ? print_buffer_in_border : print_buffer_no_border }
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

  def variable_scope
    @variable_scope ||= @parent && @parent.variable_scope
  end

private

  def decode_flow_attr(attr)
    attr == :size ? flow_dimension : flow_axis
  end

  def import_user_variables(variables)
    variables.each do |name, val|
      case val
      when Proc
        define_singleton_method(name, &val)
      else
        define_singleton_method(name) { val }
      end
    end
  end

end
