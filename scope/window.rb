require_relative 'canvas'

class Window < Canvas

  ATTRIBUTES    = [:height, :width, :top, :left].freeze
  DEFAULT_SIZE  = { height: 3, width: 3, top: 0, left: 0 }.freeze
  BORDER_OFFSET = { height: -2, width: -2, top: 1, left: 1 }.freeze
  FLOW_OFFSETS  = { vertical: :top, horizontal: :left}.freeze
  FLOW_DIMS     = { vertical: :height, horizontal: :width }.freeze
  FLOW_ATTRS    = [:size, :offset].freeze
  DEFAULT_FLOW  = :vertical

  attr_reader   :children, :title
  attr_accessor :fixed_height, :fixed_width, :fixed_top, :fixed_left
  attr_accessor :auto_height, :auto_width, :auto_top, :auto_left

  def initialize(**params)
    @buffer = ''
    @children = []
    @parent = params[:parent]
    @window = params[:window]
    @border = params[:border].nil? ? true : params[:border]
    @flow   = params[:flow] || DEFAULT_FLOW
    @title  = params[:title] || 'window'
    @visible = true
    @selected = false

    unless @window
      @fixed_height, @fixed_width, @fixed_top, @fixed_left = \
        params.values_at(:height, :width, :top, :left)
      @window = Curses::Window.new(height, width, top, left)
    end

    @parent.add_child(self) if @parent
    _refresh
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
  def select; @selected = true end
  def unselect; @selected = false end
  def selected?; @selected end
  def parent_selected?; @parent && @parent.selected? end
  def drawn?; @drawn end

# children

  def add_child(child)
    @children << child
    adjust_children
    _refresh
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
    select_adjacent_child(:next)
    active.hide
  end

  def select_adjacent_child(order)
    children = visible_children
    active = active_child
    active.unselect
    new_idx = \
      ((children.index(active) + 
       (order == :next ? 1 : -1)) % 
      children.size)
    children[new_idx].select
  end

  def find_child(title)
    visible_children.find { |p| p.title == title }
  end

# window attributes ie. height, width, top, left

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

  def update_attributes(offset: false, **attrs)
    attrs.each do |attr, val|
      val = offset ? send(attr) + val.to_i : val
      instance_variable_set("@auto_#{attr}", val) 
    end
  end

# movement

  def resize(**params)
    update_attributes(params)
  end

  def move(**params)
    update_attributes(params)
  end

  def _refresh(**opts)
    @window.resize(height, width)
    @window.move(top, left)
    @window.clear
    draw_border if @border
    print_buffer
    @window.refresh
    visible_children.each(&:_refresh)
  end

  def print_buffer
    if @border
      @window.setpos(1,1)
      width = effective_width
      sliced_buffer = @buffer.scan(/.{1,#{width}}/)
      num_lines = [(@buffer.length/width.to_f).ceil, effective_height].min

      num_lines.times do |n|
        @window << sliced_buffer[n]
        @window.setpos(@window.cury+1,1)
      end
    else
      @window.setpos(0,0)
      @window << @buffer
    end
  end

  def draw_border
    colorize(selected? && parent_selected? ? :red : :white) { @window.box(?|, ?-) }
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
    visible_children.reduce(0) { |a,c| a + (c.send("fixed_#{flow_dimension}")|| 0) }
  end

  def autosizable_children
    visible_children.reject { |c| c.send("fixed_#{flow_dimension}")}
  end

# flow autosizing

  def adjust_children
    autosize_children unless autosizable_children.empty?
    autoposition_children
    _refresh
  end

  def autosize_children
    autosizable_count = autosizable_children.size
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

# some magic

  def colorize(color, style: :normal)
    @window.attron(Curses.color_pair(COLOR[color]|STYLE[style]))
    ret = yield
    @window.attroff(Curses.color_pair(COLOR[color]|STYLE[style]))
    ret
  end

# printing

  def left_print(content)
    @buffer = content.to_s
  end

  def center_print(content)
  end

  def right_print(content)
  end

  def hidden_child_index
    hidden_children.map.with_index{ |c,i| "#{i}: #{c.title}" }.join(' ')
  end

private

  def decode_flow_attr(attr)
    attr == :size ? flow_dimension : flow_axis
  end

end
