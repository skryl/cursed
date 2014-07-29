class Cursed::WM < Cursed::Window

  attr_reader :mode, :header, :menu, :body, :screens

  def defaults
    { window: Curses.stdscr, border: false }
  end

  def initialize(config)
    super(nil, config)
    initialize_window_layout(config)
    set_mode!(:normal)
  end

  def run
    @cwindow.init_display do
      refresh!
      catch(:exit) {
        loop {
          react_to_input
          refresh!
      }}
    end
  end

# modes

  def set_mode!(mode)
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
    set_mode!(:normal)
  end

  def show_instrument(num)
    ins = active_panel.hidden_children[num]
    ins && ins.show
    set_mode!(:normal)
  end

  def scroll_instrument(direction, **opts)
    active_instrument.scroll(direction, opts)
  end

  def variable_scope
    self
  end

private

# initialization

  def initialize_window_layout(config)
    # object creation order matters here (dont change!)
    @header = Header.new(self, config[:header])
    @body   = Body.new(self, config[:body])
    @menu   = Menu.new(self, config[:menu])
    @screens = config[:screens].map { |config| Screen.new(@body, config) }

    @screens.first.show
    @screens.first.select
  end

# screen refresh

  def refresh
    update_menu
    super
  end

  def update_menu
    @menu << (menu_mode? ?
      "PANELS: #{hidden_children(active_screen)}\nINSTRUMENTS: #{hidden_children(active_panel)}" : '')
  end

# windows

  def hidden_children(window)
    window.hidden_children.map.with_index{ |c,i| "[#{i}](#{c.title})" }.join(' ')
  end

# keyboard input

  def react_to_input
    Curses.getch.tap do |input|
      check_user_defined_bindings(input)
      check_default_bindings(input)
    end
  end

  def check_user_defined_bindings(input)
    @keybindings[input] && instance_exec(&@keybindings[input])
  end

  def check_default_bindings(input)
    case @mode
    when :normal
      case input
      when ?k then select_instrument(:up)
      when ?j then select_instrument(:down)
      when ?l then select_instrument(:right)
      when ?h then select_instrument(:left)
      when ?x then hide_active_instrument
      when ?X then hide_active_panel
      when ?m then set_mode!(:menu)
      when ?K then scroll_instrument(:up)
      when ?J then scroll_instrument(:down)
      when ?U then scroll_instrument(:up, amt: 10)
      when ?D then scroll_instrument(:down, amt: 10)
      when ?L then scroll_instrument(:right)
      when ?H then scroll_instrument(:left)
      when ?n then show_screen(:right)
      when ?p then show_screen(:left)
      when ?q then throw(:exit)
      when ?b
        Curses.close_screen
        binding.pry
      end
    when :menu
      case input
      when ?m then set_mode!(:normal)
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

end
