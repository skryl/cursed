require_relative 'full_grid'
require_relative 'minimal_grid'

class Instrument < Window

  WIDTH = 20

  attr_reader :title, :vscroll, :hscroll, :rows, :cols, :coords, :grid

  def initialize(config, **opts)
    super(opts)
    @type = config[:type]
    @view = config[:dataf]
    @maps = config[:mapfs]
    @grid = minimal? ? 
      MinimalGrid.new(self, config) : 
      FullGrid.new(self, config)

    sync
    @nested = @data.first.is_a?(Array)
    @vscroll = 0
    @hscroll = 0
    @data_rows, @data_cols = data_dimensions
    @scrollable = @nested &&
                 (@data_rows > @grid.rows || 
                  @data_cols > @grid.cols )
    @rows, @cols = scroll_window_dimensions
  end

  def minimal?; @type == :minimal end

  def sync
    @data = @view[htm]
    @flat_data = @data.flatten
  end

  def refresh
    super
    @grid.display(streams)
    @cwindow.refresh
  end

  def streams
    @maps.map { |mapf| data_window.map(&mapf) }
  end
                     
  def data_window
    if @nested && @scrollable
      vscroll_end = @vscroll + @grid.rows
      hscroll_end = @hscroll + @grid.cols
      @data[@vscroll..vscroll_end].map do |r| 
        r[@hscroll..hscroll_end]
      end.flatten
    else @flat_data
    end
  end

  def scroll(direction)
    case direction
    when :down
      return if @data_rows < @grid.rows
      @vscroll = [@vscroll + 1, @data_rows-@grid.rows].min
    when :up
      @vscroll = [@vscroll - 1, 0].max 
    when :right
      return if @data_cols < @grid.cols
      @hscroll = [@hscroll + 1, @data_cols-@grid.cols].min
    when :left
      @hscroll = [@hscroll - 1, 0].max 
    end
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
      [[@data_rows, @grid.rows].min, 
       [@data_cols, @grid.cols].min]
    else [@data_rows, @data_cols]
    end
  end

end
