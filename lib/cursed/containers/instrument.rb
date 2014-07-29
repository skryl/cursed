class Cursed::Instrument < Cursed::Container
  extend  Forwardable

  def_delegators :@grid, :scroll
  attr_reader :title

  def initialize(parent, params)
    super
    @type    = params[:type]
    @streams = params[:streams]
    @grid    = minimal? ?
        MinimalGrid.new(self, params) :
        FullGrid.new(self, params)
  end

  def minimal?; @type == :minimal end

  def streams
    @streams.map { |stream| variable_scope.instance_exec(&stream) }
  end

  def refresh
    super
    @grid.display(streams)
    @window.noutrefresh
  end

end
