class Cursed::WM < Cursed::Container

  def defaults
    super.merge( window: Curses.stdscr, border: false, selected: true, focusable: false )
  end

  def initialize(config)
    super(nil, config)
    find_container(:body).focused!
    adjust_children!
  end

  def run
    @window.init_display do
      refresh!
      catch(:exit) {
        loop {
          process_input
          adjust_children!
          refresh!
      }}
    end
  end

  def process_input
    input = Curses.getch.chr.to_sym
    in_focus.react_to_input(input)
  end

# screens / panels / instruments

  # def scroll_instrument(direction, opts)
  #   active_instrument.scroll(direction, opts)
  # end
  #
private

  # def check_default_bindings(input)
  #   case @mode
  #   when :normal
  #     case input
  #     when ?X then hide_active_panel
  #     when ?K then scroll_instrument(:up)
  #     when ?J then scroll_instrument(:down)
  #     when ?U then scroll_instrument(:up, amt: 10)
  #     when ?D then scroll_instrument(:down, amt: 10)
  #     when ?L then scroll_instrument(:right)
  #     when ?H then scroll_instrument(:left)
  # end

end
