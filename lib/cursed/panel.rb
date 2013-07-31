require_relative 'instrument'

class Panel < Cursed::Window
  include Cursed

  def initialize(config, **opts)
    super(config.merge(opts))
    @instruments = config[:instruments].map { |config| Instrument.new(config, parent: self) }
    visible_children.first.select
  end

end
