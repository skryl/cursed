class Cursed::Instrument < Cursed::Container
  extend  Forwardable

  def_delegators :@grid, :scroll

  def initialize(parent, params)
    super
    @type    = params[:type] || :full
    @streams = params[:streams]
    @grid    = minimal? ?
        MinimalGrid.new(self, params) :
        FullGrid.new(self, params)
  end

  def minimal?; @type == :minimal end

  def streams
    @streams.map { |stream| @variable_scope.deep_eval(stream) }
  end

  def refresh
    super
    @grid.display(streams)
    @window.noutrefresh
  end

end
