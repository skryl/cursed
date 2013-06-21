class Instrument < Window

  WIDTH = 20
  VERT_SCROLL_SIZE = 40
  HORZ_SCROLL_SIZE = 15
  ALTERNATE_COLOR = :red

  attr_reader :title, :fg, :alt_fg, :bg, :vscroll, 
              :hscroll, :rows, :cols, :coords, :grid

  def initialize(config, **opts)
    super(opts)
    # @htm = htm
    @fg, @bg, @type, @side, @visible = \
      config.values_at(:fg, :bg, :type, :side, :visible)

    @drawn = false
    @alt_fg = ALTERNATE_COLOR
    @selected = false
    @view = config[:dataf]
    @maps = config[:mapfs]

    # refresh!
    # @nested = @data.first.is_a?(Array)
    # @vscroll = 0
    # @hscroll = 0
    # @data_rows, @data_cols = data_dimensions
    # @scrollable = @nested &&
    #              (@data_rows > VERT_SCROLL_SIZE || 
    #               @data_cols > HORZ_SCROLL_SIZE)
    # @rows, @cols = scroll_window_dimensions
  end

  def minimal?; @type == :minimal end

  def refresh!
    @data = @view[@htm]
    @flat_data = @data.flatten
  end

  def scroll_window
    if @nested && @scrollable
      vscroll_end = @vscroll + VERT_SCROLL_SIZE
      hscroll_end = @hscroll + HORZ_SCROLL_SIZE
      @data[@vscroll..vscroll_end].map do |r| 
        r[@hscroll..hscroll_end]
      end.flatten
    else @flat_data
    end
  end

  def streams
    @maps.map { |mapf| scroll_window.map(&mapf) }
  end
                     
  def scroll(direction)

    case direction
    when :down
      return if @data_rows < VERT_SCROLL_SIZE
      @vscroll = [@vscroll + 1, @data_rows-VERT_SCROLL_SIZE].min
    when :up
      @vscroll = [@vscroll - 1, 0].max 
    when :right
      return if @data_cols < HORZ_SCROLL_SIZE
      @hscroll = [@hscroll + 1, @data_cols-HORZ_SCROLL_SIZE].min
    when :left
      @hscroll = [@hscroll - 1, 0].max 
    end
  end

  def update_coords(data)
    @grid   = data[:grid]
  end

private

  def data_dimensions
    if @nested
      [@data.size, @data.first.size]
    else
      if @data.size > WIDTH
        [(@data.size.to_f / WIDTH).ceil, WIDTH]
      else
        [1, @data.size]
      end
    end
  end

  def scroll_window_dimensions
    if @nested && @scrollable
      [[@data_rows, VERT_SCROLL_SIZE].min, 
       [@data_cols, HORZ_SCROLL_SIZE].min]
    else [@data_rows, @data_cols]
    end
  end

end
