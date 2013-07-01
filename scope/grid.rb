require_relative 'grid_primitives'

class Grid
  extend Forwardable
  include GridPrimitives

  ALTERNATE_COLOR = :red
  Infinity = 1.0/0.0

  def_delegators :@window, :write, :colorize
  attr_reader :rows, :cols
  
  def initialize(window, **opts)
    @window = window
    @fg, @bg = opts.values_at(:fg, :bg)
    @alt_fg = ALTERNATE_COLOR

    @rratio, @cratio = 1, 1
    @cell_size = 1
    @cells = []
  end

  def height; @window.effective_height end
  def width;  @window.effective_width  end
  def rows; [height / @rratio, max_rows].min end 
  def cols; width  / @cratio end

  def max_rows
    @data_size && (@data_size / cols).ceil || Infinity
  end

  def display(streams)
    stream1, stream2 = streams
    @data_size = stream1.length
    update_coords(draw)
    @cells.each.with_index do |(r,c),i| 
      val = format_val(stream1[i])
      clr = (stream2 && !stream2[i].empty?) ? @alt_fg : @fg

      if !val.empty? 
        colorize(clr, style: :underline) { write(r, c, val) }
      else
        colorize(@bg, style: :normal) { write(r,c, format_val(i)) }
      end
    end
  end

private

  def update_coords(grid)
    @rows, @cols, @cells = grid
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
