class Synapse
  CONNECTED_PERM = 0.5
  PERM_D = 0.1
  INIT_PERM_MIN = CONNECTED_PERM - PERM_D
  INIT_PERM_MAX = CONNECTED_PERM + PERM_D

  PERMANENCE_INC = 0.01
  PERMANENCE_DEC = 0.01

  attr_reader :input

  def initialize(input)
    @input = input
    @permanence = rand(INIT_PERM_MIN..INIT_PERM_MAX).round(2)
  end

  def active?
    @input.active? && @permanence >= CONNECTED_PERM
  end

  def strengthen!
    @permanence = [@permanence + PERMANENCE_INC, 1.0].min
  end

  def weaken!
    @permanence = [@permanence - PERMANENCE_DEC, 0.0].max
  end

  def to_h
    { input: @input.active?, permanence: @permanence }
  end

end
