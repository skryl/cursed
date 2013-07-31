require_relative 'full_grid'
require_relative 'minimal_grid'

class Cursed::Instrument < Cursed::Window
  include Cursed
  extend  Forwardable

  def_delegators :@grid, :scroll
  attr_reader :title

  def initialize(config, **opts)
    super(config.merge(opts))
    @type = config[:type]
    @view = config[:dataf]
    @maps = config[:streamfs]
    @grid = minimal? ? 
      MinimalGrid.new(self, config) : 
      FullGrid.new(self, config)
  end

  def minimal?; @type == :minimal end

  def streams
    @data = @view[data_obj]
    if @data.first.is_a? Array
      @maps.map { |streamf| @data.map { |r| r.map(&streamf) } }
    else
      @maps.map { |streamf| @data.map(&streamf) }
    end
  end

  def refresh
    super
    @grid.display(streams)
    @cwindow.noutrefresh
  end

end
