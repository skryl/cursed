require_relative 'window'
require_relative 'panel'

class Cursed::Screen < Cursed::Window
  include Cursed

  def initialize(config, **opts)
    super(config.merge(opts))
    @panels = config[:panels].map { |config| Panel.new(config, parent: self, border: false) }
    visible_children.first.select
  end

end
