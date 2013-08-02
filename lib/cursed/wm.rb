require 'benchmark'
require_relative 'screen'
require_relative 'window'

class Cursed::WM < Cursed::Window
  include Cursed

  HEADER_HEIGHT = 5
  FOOTER_HEIGHT = 4

  attr_reader :data_obj, :mode, :step_time

  def initialize(data_obj, config)
    @mode = :normal
    super(window: Curses.stdscr, border: false)
    @data_obj = data_obj
    @step_time = 0.0

    @header_content = config[:header]
    @keybindings = config[:keybindings] || {}

    @header = Window.new(parent: self, title: 'Cortex v0.1', border: true, bc: :blue, fg: :yellow, height: HEADER_HEIGHT)
    @body   = Window.new(parent: self, title: :body, border: false, exclusive: true,
      top: @header.top + @header.height, height: self.effective_height - @header.height)
    @screens = config[:screens].map { |config| 
      Screen.new(config, parent: @body, visible: false, border: false, flow: :horizontal)} 
    @menu = Window.new(parent: self, title: :menu, border: true, visible: false, bc: :blue, fg: :yellow,
      height: FOOTER_HEIGHT, top: self.top + self.height - FOOTER_HEIGHT)

    @screens.first.show
    @screens.first.select
  end

  def start
    @cwindow.init_display do
      refresh!
      loop do 
        break if @exit
        Curses.getch.tap do |input| 
          react_to_input(input) if input 
        end
      end
    end
  end

  def react_to_input(input)
    check_custom_bindings(input)

    case @mode
    when :normal
      case input
      when ?k then change_selected(:up)
      when ?j then change_selected(:down)
      when ?l then change_selected(:right)
      when ?h then change_selected(:left)
      when ?x then hide_selected_instrument
      when ?X then hide_selected_panel
      when ?m then switch_mode(:menu)
      when ?K then scroll_instrument(:up)
      when ?J then scroll_instrument(:down)
      when ?U then scroll_instrument(:up, amt: 10)
      when ?D then scroll_instrument(:down, amt: 10)
      when ?L then scroll_instrument(:right)
      when ?H then scroll_instrument(:left)
      when ?n then change_screen(:right)
      when ?p then change_screen(:left) 
      when ?q then @exit = true
      when ?b then binding.pry
      end
    when :menu
      case input
      when ?m then switch_mode(:normal)
      when ?0 then show_instrument(0)
      when ?1 then show_instrument(1)
      when ?2 then show_instrument(2)
      when ?3 then show_instrument(3)
      when ?4 then show_instrument(4)
      when ?5 then show_instrument(5)
      when ?6 then show_instrument(6)
      when ?7 then show_instrument(7)
      when ?8 then show_instrument(8)
      when ?9 then show_instrument(9)
      when ?) then show_panel(0)
      when ?! then show_panel(1)
      when ?@ then show_panel(2)
      when ?# then show_panel(3)
      when ?$ then show_panel(4)
      when ?% then show_panel(5)
      when ?^ then show_panel(6)
      when ?& then show_panel(7)
      when ?* then show_panel(8)
      when ?( then show_panel(9)
      when ?q then exit
      end
    end
    refresh!
  end

  def check_custom_bindings(input)
    @keybindings[input] && instance_exec(&@keybindings[input])
  end

  def refresh
    @header << header_content
    @menu << menu_content
    super
  end

# modes

  def switch_mode(mode)
    case mode
    when :menu
      @menu.show
    when :normal
      @menu.hide
    end
    @mode = mode 
  end

  def normal_mode?; @mode == :normal end
  def menu_mode?; @mode == :menu end

# screens
  
  def change_screen(direction)
    case direction
    when :right
      @body.select_child(:next)
    when :left
      @body.select_child(:prev)
    end
  end

  def active_screen
    @body.active_child
  end

# panels

  def change_selected(direction)
    case direction
    when :up
      active_panel.select_child(:prev)
    when :down
      active_panel.select_child(:next)
    when :right
      active_screen.select_child(:next)
    when :left
      active_screen.select_child(:prev)
    end
  end

  def active_panel
    active_screen.active_child
  end

  def active_instrument
    active_panel.active_child
  end

  def hide_selected_panel
    active_screen.hide_selected
  end

  def hide_selected_instrument
    active_panel.hide_selected
  end

  def show_panel(num)
    panel = active_screen.hidden_children[num]
    panel && panel.show
    switch_mode(:normal)
  end

  def show_instrument(num)
    ins = active_panel.hidden_children[num]
    ins && ins.show
    switch_mode(:normal)
  end

  def scroll_instrument(direction, **opts)
    active_instrument.scroll(direction, opts)
  end


# header / footer
  
  def header_content
    len = @header_content.values.
      map(&:to_a).
      flatten(1).
      map{ |(k,v)| [k, call_or_ret(v)] }.
      map(&:join).
      map(&:length).max + 2

    @header_content.inject('') do |str, (title, fields)|
      str << "#{title.to_s.upcase}:".ljust(10)
      fields.each { |name, val| str << "#{name}: #{call_or_ret(val)}".ljust(len) << ' ' } 
      str << "\n"
    end
  end

  def menu_content
    case @mode
    when :normal
      ''
    when :menu
      str = ''
      str << "PANELS: #{hidden_child_index(active_screen)}\n"
      str << "INSTRUMENTS: #{hidden_child_index(active_panel)}" 
    end
  end

  def hidden_child_index(window)
    window.hidden_children.map.with_index{ |c,i| "[#{i}](#{c.title})" }.join(' ')
  end

# simulation

  def step(n=1)
    time = \
      Benchmark.realtime do
        n.times { @data_obj.step }
      end
    @step_time = time/n
  end

private

  def call_or_ret(val)
    val.is_a?(Proc) ? instance_exec(&val).to_s : val.to_s
  end

end
