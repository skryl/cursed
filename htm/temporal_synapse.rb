class TemporalSynapse
  include TemporalAttributes

  PERM_CONNECTED = 0.5
  PERM_DELTA = 0.1
  INIT_PERM_MIN = PERM_CONNECTED - PERM_DELTA
  INIT_PERM_MAX = PERM_CONNECTED + PERM_DELTA

  PERM_INC = 0.01
  PERM_DEC = 0.01

  temporal_attr :input, :permanence, history: 3

  def initialize(input, **opts)
    self.input = input
    self.permanence = opts[:active] ? PERM_CONNECTED : rand(INIT_PERM_MIN..INIT_PERM_MAX).round(2)
  end

  def active?(**opts)
    input.send((state = opts[:state]) ? "#{state}?": :active?) && (opts[:aggressive] || @permanence >= PERM_CONNECTED)
  end

  def strengthen!
    self.permanence = [@permanence + PERM_INC, 1.0].min
  end

  def boost!
    self.permanence = [@permanence + (0.1 * PERM_CONNECTED), 1.0].min
  end

  def weaken!
    self.permanence = [@permanence - PERM_DEC, 0.0].max
  end

end
