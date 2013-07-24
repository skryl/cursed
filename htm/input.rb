class Input
  attr_reader :index

  def initialize(index)
    @index = index
    @value = false
  end

  def active?
    @value
  end

  def value=(val)
    @value = (!val || val == 0) ? false : true
  end
end
