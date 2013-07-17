require_relative 'common/temporal_attributes'

class Input
  include TemporalAttributes
  
  attr_reader :index
  temporal_attr :value, history: 2

  def initialize(index)
    set(:value, false)
    # @value = false
    @index = index
  end

  def active?
    # @value
    get(:value)
  end

  def value=(val)
    set(:value, (!val || val == 0) ? false : true)
    # @value = (!val || val == 0) ? false : true
  end

end
