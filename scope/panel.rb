require_relative 'instrument'

class Panel < Window

  def initialize(config, **opts)
    super(opts)
    @instruments = \
      config[:instruments].map { |config| Instrument.new(config, parent: self) }
    @instruments.first.select unless active_child
  end

end
