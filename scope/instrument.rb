require_relative 'full_grid'
require_relative 'minimal_grid'

class Instrument < Window

  SCROLL_AMT = 5

  attr_reader :title, :rows, :cols

  def initialize(config, **opts)
    super(config.merge(opts))
    @type = config[:type]
    @view = config[:dataf]
    @maps = config[:streamfs]
    @grid = minimal? ? 
      MinimalGrid.new(self, config) : 
      FullGrid.new(self, config)

    @vscroll = 0
    @hscroll = 0

    @data = @view[htm]
    @nested = @data.first.is_a?(Array)
    @data_rows, @data_cols = data_dimensions
  end

  def minimal?; @type == :minimal end
  def nested?;  @nested end

  def scrollable?
    @nested && (@data_rows > @grid.rows || @data_cols > @grid.cols )
  end

  def refresh
    super
    @grid.display(streams, vscroll: @vscroll, hscroll: @hscroll)
    @cwindow.noutrefresh
  end

  def streams
    @maps.map { |streamf| data_window.map(&streamf) }
  end
                     
  def data_window
    if nested? && scrollable?
      vscroll_end = @vscroll + @grid.rows
      hscroll_end = @hscroll + @grid.cols
      @data[@vscroll..vscroll_end].map do |r| 
        r[@hscroll..hscroll_end]
      end.flatten
    else @data.flatten
    end
  end

  def scroll(direction)
    case direction
    when :down
      return if @data_rows < @grid.rows
      @vscroll = [@vscroll + SCROLL_AMT, @data_rows-@grid.rows].min
    when :up
      @vscroll = [@vscroll - SCROLL_AMT, 0].max 
    when :right
      return if @data_cols < @grid.cols
      @hscroll = [@hscroll + SCROLL_AMT, @data_cols-@grid.cols].min
    when :left
      @hscroll = [@hscroll - SCROLL_AMT, 0].max 
    end
  end

private

  def data_dimensions
    if @nested
      [@data.size, @data.first.size]
    else
      if @data.size > @grid.cols
        [(@data.size.to_f / @grid.cols).ceil, @grid.cols]
      else
        [1, @data.size]
      end
    end
  end

end
