class Cursed::Grid
  extend Forwardable

  BAR = "|"
  PLS = "+"
  MNS = "-"

  ALTERNATE_COLOR = :red
  Infinity = 1.0/0.0

  def_delegator  :@window, :effective_height, :height
  def_delegator  :@window, :effective_width,  :width
  def_delegators :@window, :write, :colorize
  attr_reader    :rows, :cols, :rratio, :cratio, :cell_size, :box_size,
                 :vscroll, :hscroll, :cells
  
  def initialize(window, **opts)
    @window = window
    @alt_fg = ALTERNATE_COLOR
    # colors (foreground, background, grid)
    @fg, @bg, @gc = opts.values_at(:fg, :bg, :gc)

    @scroll_amt = 1
    @vscroll, @hscroll = 0, 0
    @rratio, @cratio = 1, 1
    @cell_size, @box_size = 1, 1
  end

  # TODO: refactor to seperate nested vs non nested stream processing
  #
  def display(streams)
    @data_rows, @data_cols = calc_dimensions(streams.first)
    @rows = [@data_rows, max_rows].min
    @cols = [@data_cols, max_cols].min
    @cells = colorize(@gc) { draw }
    streams = normalize_dimensions(streams)
    fill(streams.map { |s| window_data(s) })
  end

  def scroll(direction, amt: @scroll_amt)
    case direction
    when :down
      return if @data_rows < @rows
      @vscroll = [@vscroll + amt, @data_rows-@rows].min
    when :up
      @vscroll = [@vscroll - amt, 0].max 
    when :right
      return if @data_cols < @cols
      @hscroll = [@hscroll + amt, @data_cols-@cols].min
    when :left
      @hscroll = [@hscroll - amt, 0].max 
    end
  end

private

  def max_rows; height / @rratio - 1 end 
  def max_cols; width  / @cratio - 1 end

  def calc_dimensions(stream)
    if stream.first.is_a? Array
      max_size = stream.map(&:length).max
      [stream.size, max_size]
    else
      if stream.size > max_cols
        [(stream.size.to_f / max_cols).ceil, max_cols]
      else
        [1, stream.size]
      end
    end
  end

  # pads a 2d stream to max col size, otherwise fill_data will fail
  #
  def normalize_dimensions(streams)
    return streams unless streams[0][0].is_a?(Array)

    streams.map do |stream|
      stream.map do |vals|
        binding.pry if vals.is_a? String
        vals[@cols-1] = nil if vals.length < @cols; vals
      end
    end
  end

  def window_data(stream)
    vscroll_end = @vscroll + @rows
    hscroll_end = @hscroll + @cols

    stream = stream.first.is_a?(Array) ?
      stream : stream.each_slice(@cols).to_a

    stream[@vscroll...vscroll_end].flat_map do |r| 
      r[@hscroll...hscroll_end]
    end
  end

  def fill(streams)
    stream1, stream2 = streams
    idx_start = @vscroll * @cols + @hscroll
    @cells.each.with_index do |(r,c),i| 
      val = format_val(stream1[i])
      clr = (stream2 && stream2[i] && !stream2[i].empty?) ? @alt_fg : @fg

      if !val.empty? 
        colorize(clr, style: :underline) { write(r, c, val) }
      else
        colorize(@bg, style: :normal) { write(r, c, format_val(idx_start+i)) }
      end
    end
  end

  def format_val(val)
    case val
    when Integer
      "%##{cell_size}d" % val
    when Float
      "%#1.#{cell_size/2}f" % val
    when String
      return val if val.empty?
      val * cell_size
    else ''
    end
  end

# TODO: refactor me

  def rect(row1,col1,row2,col2)
    width = col2 - col1 + 1
    height = (row2 - row1)/2

    write(row1, col1, PLS )
    write(row1, col2, PLS )
    write(row1, col1+1, (MNS * (width-2)) )
    (1..height).each do |i| 
      write(row1 + i, col1, BAR)
      write(row1 + i, col2, BAR)
    end
    write(row1 + height, col1, PLS )
    write(row1 + height, col2, PLS )
    write(row1 + height, col1+1, (MNS * (width-2)) )
  end

  def print_indices(row, col, horz_cell_size, vert_cell_size)
    row_idx_fmt = "%2d "
    row_idx_sz  = 3
    col_idx_fmt = "%2d" + (' ' * (horz_cell_size-1))
    col_idx_pad = ' ' * (horz_cell_size+1)

    # print top indices
    col_indices = (hscroll...hscroll+cols).map{|i| col_idx_fmt % i}
    write(row, col, col_idx_pad + col_indices.join)

    # print side indices
    row_indices = (vscroll...vscroll+rows).map{|i| row_idx_fmt % i}
    row_indices.each.with_index { |ridx, i| write(row+1+(i*vert_cell_size)+(vert_cell_size-1), col, ridx) }
  end

end
