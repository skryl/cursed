require 'curses'

class Curses::Window
  alias_method :height, :maxy
  alias_method :width,  :maxx
  alias_method :top,    :begy
  alias_method :left,   :begx
end

class Canvas

  BAR = "|"
  PLS = "+"
  MNS = "-"

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
    Curses.setpos(row, col)
    Curses.addstr(text)
    Curses.setpos(row, col)
  end

  def rect(r1,c1,r2,c2)
    width = c2 - c1 + 1
    height = (r2 - r1)/2

    write(r1, c1, PLS )
    write(r1, c2, PLS )
    write(r1, c1+1, (MNS * (width-2)) )
    (1..height).each do |i| 
      write(r1 + i, c1, BAR)
      write(r1 + i, c2, BAR)
    end
    write(r1 + height, c1, PLS )
    write(r1 + height, c2, PLS )
    write(r1 + height, c1+1, (MNS * (width-2)) )
  end

  def sqr(r,c,side)
    rect(r,c,r+side,c+side)
  end

  def grid(row,column,rows,cols,size)
    grid = []
    rows.times do |r|
      rshift = (size/2 - 1) * r
      cols.times do |c|
        cshift = (size-1) * c
        rstart, cstart = row+r+rshift, column+c+cshift
        grid[r * cols + c] = [rstart+1,cstart+size/2]
        sqr(rstart,cstart,size)
      end
    end

    { coords: [row, column], 
      height: curpos[0] - row, 
      width:  curpos[1] - column, 
      grid:   grid }
  end

  def grid_minimal(row,column,rows,cols,vscroll,hscroll,size)
    grid = []

    # print top indices
    indices = (0...cols).map{|i| format_val(hscroll+i)}.join(' ' * size)
    wnl(' ' * 5 + indices)

    rows.times do |r|
      # print side indices
      w(format_val(vscroll+r) + ' ')
      cols.times do |c|
        w('+ ')
        grid << curpos
        w(' ' * size)
      end
      w('+')
      newline
    end

    { coords: [row, column], 
      height: curpos[0] - row, 
      width:  curpos[1] - column, 
      grid:   grid }
  end

# print helpers

  def curpos
    [Curses.stdscr.cury, Curses.stdscr.curx]
  end

  def newline(n=1)
    Curses.setpos(curpos[0] + n, curpos[1])
  end

  def w(text)
    Curses.addstr(text)
  end

  def wnl(text)
    Curses.addstr(text)
    newline
  end

  def wgrid(rows,cols,size)
    grid(*curpos,rows,cols,size).tap { newline }
  end

  def wgrid_minimal(rows,cols,vscroll,hscroll,size)
    grid_minimal(*curpos,rows,cols,vscroll,hscroll,size).tap { newline }
  end

  def save_pos
    oldpos = Curses.curpos
    yield
    Curses.setpos(*oldpos)
  end

  def print_panel(panel)
    title = panel.title.to_s.upcase + ':'
    panel.selected? ? color(:red) { wnl(title) } : wnl(title)
    data = panel.minimal? ? 
      color(panel.bg) { wgrid_minimal(panel.rows, panel.cols, panel.vscroll, panel.hscroll, 3) } :
      color(panel.bg) { wgrid(panel.rows, panel.cols, 4) }
    panel.update_coords(data)
    fill_grid(panel)
    newline
  end

  def fill_grid(panel)
    stream1, stream2 = panel.streams
    save_pos do
      panel.grid.each.with_index do |(r,c),i| 
        val = format_val(stream1[i])
        clr = (stream2 && !stream2[i].empty?) ? panel.alt_fg : panel.fg

        if !val.empty? 
          color(clr) { write(r, c, val) }
        else
          color(panel.bg) { write(r,c, format_val(i)) }
        end
      end
    end
  end

  def format_val(val)
    case val
    when Integer
      "%2d" % val
    when Float
      "%.1f" % val
    when String
      return val if val.empty?
      val * (2/val.length)
    else ''
    end
  end

end
