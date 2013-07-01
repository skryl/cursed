require_relative 'curses_window'
require_relative 'buffer'
require 'forwardable'

class Window
  extend Forwardable
  def_delegators :@cwindow, :write, :colorize

  ATTRIBUTES    = [:height, :width, :top, :left].freeze
  DEFAULT_SIZE  = { height: 3, width: 3, top: 0, left: 0 }.freeze
  BORDER_OFFSET = { height: -2, width: -2, top: 1, left: 1 }.freeze
  FLOW_OFFSETS  = { vertical: :top, horizontal: :left}.freeze
  FLOW_DIMS     = { vertical: :height, horizontal: :width }.freeze
  FLOW_ATTRS    = [:size, :offset].freeze
  DEFAULT_FLOW  = :vertical

  attr_reader   :children, :title, :flow
  attr_accessor :fixed_height, :fixed_width, :fixed_top, :fixed_left
  attr_accessor :auto_height, :auto_width, :auto_top, :auto_left
  def_delegators :@buffer, :puts, :<<

  def initialize(**params)
    @children = []
    @buffer   = Buffer.new(self)
    @parent = params[:parent]
    @cwindow = params[:window]
    @border = params[:border].nil? ? true : params[:border]
    @flow   = params[:flow] || DEFAULT_FLOW
    @title  = params[:title] || 'window'
    @visible = params[:visible].nil? ? true : params[:visible]
    @selected = params[:selected].nil? ? false : params[:selected]

    unless @cwindow
      @fixed_height, @fixed_width, @fixed_top, @fixed_left = \
        params.values_at(:height, :width, :top, :left)
      @cwindow = Curses::Window.new(height, width, top, left)
    end

    @parent.add_child(self) if @parent
  end

  # TODO: need better way to globalize data generator
  #
  def htm
    @htm ||= @parent.htm
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
    @cwindow && @cwindow.send(attr) || DEFAULT_SIZE[attr]
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

  # performs a quick refresh, must call refresh! to eventually draw to the
  # screen
  #
  def refresh
    @cwindow.resize(height, width)
    @cwindow.move(top, left)
    @cwindow.clear
    print_buffer
    draw_border
    @cwindow.noutrefresh
    visible_children.each(&:refresh)
  end

  # actually draws to the screen
  #
  def refresh!
    refresh
    @cwindow.refresh
  end

  def draw_border
    @cwindow.colorize(selected? && parent_selected? ? :red : :white) do 
      @border ? (@cwindow.box(?|, ?-); draw_title) : @cwindow.marker(?+)
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
    visible_children.reduce(0) { |a,c| a + (c.send("fixed_#{flow_dimension}")|| 0) }
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

  def print_buffer
    @border ? print_buffer_in_border : print_buffer_no_border
  end

  def print_buffer_in_border
    @cwindow.setpos(1,1)
    @buffer.slices.each do |line|
      @cwindow << line
      @cwindow.setpos(@cwindow.cury+1,1)
    end
    @buffer.clear!
  end

  def print_buffer_no_border
    @cwindow.setpos(0,0)
    @cwindow << @buffer.flush
  end

private

  def decode_flow_attr(attr)
    attr == :size ? flow_dimension : flow_axis
  end

end
