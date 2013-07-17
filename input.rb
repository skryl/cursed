require_relative 'common/temporal_attributes'

# TODO: performance
# temporal_attributes are 2x slower
#
class Input
  include TemporalAttributes
  
  attr_reader :index
  temporal_attr :value, history: 2

  def initialize(index)
    set(:value, false)
    @index = index
  end

  def active?
    get(:value)
  end

  def value=(val)
    set(:value, (!val || val == 0) ? false : true)
  end

end
