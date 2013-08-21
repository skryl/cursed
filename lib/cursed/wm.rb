require 'benchmark'
require_relative 'screen'
require_relative 'window'

class Cursed::WM < Cursed::Window
  include Cursed

  HEADER_HEIGHT = 5
  FOOTER_HEIGHT = 4

  attr_reader :data, :binding_mode, :step_time

  def initialize(data, config)
    super(window: Curses.stdscr, border: false)
    @data = data
    @step_time = 0.0
    @binding_mode = :normal

    @header_content = config[:header] || {}
    @keybindings    = config[:keybindings] || {}
    @functions      = config[:functions] || []

    @header  = Window.new(parent: self, title: 'Cortex v0.1', border: true, bc: :blue, fg: :yellow, height: HEADER_HEIGHT)
    @body    = Window.new(parent: self, title: :body, border: false, exclusive: true,
                 top: @header.top + @header.height, height: self.effective_height - @header.height)
    @screens = config[:screens].map { |config| 
                 Screen.new(config, parent: @body, visible: false, border: false, flow: :horizontal)} 
    @menu    = Window.new(parent: self, title: :menu, border: true, visible: false, bc: :blue, fg: :yellow,
                 height: FOOTER_HEIGHT, top: self.top + self.height - FOOTER_HEIGHT)

    import_user_defined_functions
    @screens.first.show
    @screens.first.select
  end

  def start
    @cwindow.init_display do
      refresh!
      catch(:exit) do
        loop do 
          Curses.getch.tap do |input| 
            check_user_defined_bindings(input)
            check_default_bindings(input)
            refresh!
          end
        end
      end
    end
  end

# modes

  def set_binding_mode!(mode)
    case mode
    when :menu
      @menu.show
    when :normal
      @menu.hide
    end
    @binding_mode = mode 
  end

  def normal_mode?; @binding_mode == :normal end
  def menu_mode?; @binding_mode == :menu end

# screens / panels / instruments
  
  def show_screen(direction)
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

  def select_instrument(direction)
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

  def hide_active_panel
    active_screen.hide_selected
  end

  def hide_active_instrument
    active_panel.hide_selected
  end

  def show_panel(num)
    panel = active_screen.hidden_children[num]
    panel && panel.show
    set_binding_mode!(:normal)
  end

  def show_instrument(num)
    ins = active_panel.hidden_children[num]
    ins && ins.show
    set_binding_mode!(:normal)
  end

  def scroll_instrument(direction, **opts)
    active_instrument.scroll(direction, opts)
  end

# header / menu

  def menu_content
    case @binding_mode
    when :normal
      ''
    when :menu
      "PANELS: #{hidden_children(active_screen)}\nINSTRUMENTS: #{hidden_children(active_panel)}" 
    end
  end

private

  def refresh
    @header.buffer.format_fields(header_attributes)
    @menu << menu_content
    super
  end

# user defined functions / bindings

  def import_user_defined_functions
    @functions.each do |fun, body|
      define_singleton_method(fun, &body)
    end
  end

  def check_user_defined_bindings(input)
    @keybindings[input] && instance_exec(&@keybindings[input])
  end

# default bindings

  def check_default_bindings(input)
    case @binding_mode
    when :normal
      case input
      when ?k then select_instrument(:up)
      when ?j then select_instrument(:down)
      when ?l then select_instrument(:right)
      when ?h then select_instrument(:left)
      when ?x then hide_active_instrument
      when ?X then hide_active_panel
      when ?m then set_binding_mode!(:menu)
      when ?K then scroll_instrument(:up)
      when ?J then scroll_instrument(:down)
      when ?U then scroll_instrument(:up, amt: 10)
      when ?D then scroll_instrument(:down, amt: 10)
      when ?L then scroll_instrument(:right)
      when ?H then scroll_instrument(:left)
      when ?n then show_screen(:right)
      when ?p then show_screen(:left) 
      when ?q then throw(:exit)
      when ?b then binding.pry
      end
    when :menu
      case input
      when ?m then set_binding_mode!(:normal)
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
  end

# header formatting

  # convert nested hash to [[Row, [[Field, Val], ...]] ... ]
  # and evaluate any procs.
  # 
  def header_attributes
    @header_content.map { |row, fields| 
      [row, fields.map{ |field, val| [field, call_or_val(val)] }] }
  end

# helpers

  def hidden_children(window)
    window.hidden_children.map.with_index{ |c,i| "[#{i}](#{c.title})" }.join(' ')
  end

  def call_or_val(val)
    val.is_a?(Proc) ? instance_exec(&val).to_s : val.to_s
  end

end
