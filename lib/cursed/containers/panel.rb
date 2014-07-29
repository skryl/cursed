class Panel < Cursed::Container

  def initialize(parent, params)
    super
    @instruments = params[:instruments].map { |config| Instrument.new(self, config) }
    visible_children.first.select
  end

  def defaults
    { border: false }
  end

end
