class Synapse
  include TemporalAttributes

  PERM_CONNECTED = 0.5
  PERM_DELTA = 0.1
  INIT_PERM_MIN = PERM_CONNECTED - PERM_DELTA
  INIT_PERM_MAX = PERM_CONNECTED + PERM_DELTA

  PERM_INC = 0.01
  PERM_DEC = 0.01

  attr_reader :input, :permanence
  temporal_attr :active, type: :snapshot, history: 2

  def initialize(input, **opts)
    @input = input
    @permanence = opts[:active] ? PERM_CONNECTED : rand(INIT_PERM_MIN..INIT_PERM_MAX).round(2)
  end

  def active?(**opts)
    @input.send((state = opts[:state]) ? "#{state}?": :active?) && (opts[:aggressive] || @permanence >= PERM_CONNECTED)
  end

  def strengthen!
    @permanence = [@permanence + PERM_INC, 1.0].min
  end

  def boost!
    @permanence = [@permanence + (0.1 * PERM_CONNECTED), 1.0].min
  end

  def weaken!
    @permanence = [@permanence - PERM_DEC, 0.0].max
  end

end