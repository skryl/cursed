class Input
  
  attr_reader :index

  def initialize(index)
    @active = false
    @index = index
  end

  def active?
    @active
  end

  def value=(val)
    @active = (!val || val == 0) ? false : true
  end

end
