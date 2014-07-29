class Cursed::Screen < Cursed::Container

  def initialize(parent, params)
    super
    @panels = params[:panels].map { |config| Panel.new(self, config) }
    visible_children.first.select
  end

  def defaults
    { visible: false, border: false, flow: :horizontal }
  end

end
