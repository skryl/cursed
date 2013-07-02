require_relative 'grid_primitives'

class Grid
  extend Forwardable
  include GridPrimitives

  SCROLL_AMT = 5
  ALTERNATE_COLOR = :red
  Infinity = 1.0/0.0

  def_delegator  :@window, :effective_height, :height
  def_delegator  :@window, :effective_width,  :width
  def_delegators :@window, :write, :colorize
  attr_reader    :rows, :cols, :vscroll, :hscroll, 
                 :rratio, :cratio, :cell_size, :cells
  
  def initialize(window, **opts)
    @window = window
    @fg, @bg = opts.values_at(:fg, :bg)
    @alt_fg = ALTERNATE_COLOR

    @vscroll, @hscroll = 0, 0
    @rratio, @cratio = 1, 1
    @cell_size = 1
  end

  def display(streams)
    @data_rows, @data_cols = calc_dimensions(streams.first)
    @rows = [@data_rows, max_rows].min
    @cols = [@data_cols, max_cols].min
    @cells = draw
    fill(streams.map { |s| window_data(s) })
  end

  def scroll(direction)
    case direction
    when :down
      return if @data_rows < @rows
      @vscroll = [@vscroll + SCROLL_AMT, @data_rows-@rows].min
    when :up
      @vscroll = [@vscroll - SCROLL_AMT, 0].max 
    when :right
      return if @data_cols < @cols
      @hscroll = [@hscroll + SCROLL_AMT, @data_cols-@cols].min
    when :left
      @hscroll = [@hscroll - SCROLL_AMT, 0].max 
    end
  end

private

  def max_rows; height / @rratio - 1 end 
  def max_cols; width  / @cratio - 1 end

  def calc_dimensions(stream)
    if stream.first.is_a? Array
      [stream.size, stream.first.size]
    else
      if stream.size > max_cols
        [(stream.size.to_f / max_cols).ceil, max_cols]
      else
        [1, stream.size]
      end
    end
  end

  def window_data(stream)
    vscroll_end = @vscroll + @rows
    hscroll_end = @hscroll + @cols

    stream = stream.first.is_a?(Array) ?
      stream : stream.each_slice(@cols).to_a

    stream[@vscroll..vscroll_end].flat_map do |r| 
      r[@hscroll..hscroll_end]
    end
  end

  def fill(streams)
    stream1, stream2 = streams
    @cells.each.with_index do |(r,c),i| 
      val = format_val(stream1[i])
      clr = (stream2 && !stream2[i].empty?) ? @alt_fg : @fg

      if !val.empty? 
        colorize(clr, style: :underline) { write(r, c, val) }
      else
        colorize(@bg, style: :normal) { write(r, c, format_val(i)) }
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
