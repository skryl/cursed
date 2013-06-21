require_relative 'instrument'

class Panel < Window

  def initialize(config, **opts)
    super(opts)
    @instruments = \
      config[:instruments].map { |config| Instrument.new(config, title: config[:title], parent: self) }
    @instruments.first.select unless active_child
  end

end
