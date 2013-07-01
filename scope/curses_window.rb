require 'curses'

class Curses::Window
  alias_method :height, :maxy
  alias_method :width,  :maxx
  alias_method :top,    :begy
  alias_method :left,   :begx

  COLOR  = 
    { red:     Curses::COLOR_RED,
      green:   Curses::COLOR_GREEN,
      blue:    Curses::COLOR_BLUE,
      white:   Curses::COLOR_WHITE,
      yellow:  Curses::COLOR_YELLOW,
      black:   Curses::COLOR_BLACK  }

  STYLE = 
    { reverse:    Curses::A_REVERSE,
      standout:   Curses::A_STANDOUT,
      bold:       Curses::A_BOLD,
      underline:  Curses::A_UNDERLINE,
      blink:      Curses::A_BLINK,
      normal:     Curses::A_NORMAL }

  def init_display
    Curses.noecho
    Curses.init_screen
    Curses.stdscr.keypad(true)
    Curses.start_color
    Curses.curs_set(0)

    Curses.init_pair(COLOR[:red], COLOR[:red], COLOR[:black])
    Curses.init_pair(COLOR[:blue], COLOR[:blue], COLOR[:black])
    Curses.init_pair(COLOR[:green], COLOR[:green], COLOR[:black])
    Curses.init_pair(COLOR[:yellow], COLOR[:yellow], COLOR[:black])
    Curses.init_pair(COLOR[:white], COLOR[:white], COLOR[:black])
    Curses.init_pair(COLOR[:black], COLOR[:black], COLOR[:black])

    begin
      yield
    ensure
      Curses.close_screen
    end
  end

# print primitives

  def write(row, col, text)
    setpos(row, col)
    addstr(text)
    setpos(row, col)
  end

# print helpers

  def curpos
    [top, left]
  end

  def newline(n=1)
    setpos(curpos[0] + n, curpos[1])
  end

  def w(text)
    addstr(text)
  end

  def wnl(text)
    addstr(text)
    newline
  end

  def save_pos
    oldpos = curpos
    yield
    setpos(*oldpos)
  end

# border

  def marker(ch)
    save_pos do
      write(0,0,ch)
    end
  end

# color

  def colorize(color, style: :normal)
    color = COLOR[color] || COLOR[:white]
    style = STYLE[style] || STYLE[:normal]
    attron(Curses.color_pair(color|style))
    ret = yield
    attroff(Curses.color_pair(color|style))
    ret
  end

end
