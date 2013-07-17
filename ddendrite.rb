require_relative 'synapse'
require_relative 'dendrite'

class DDendrite < Dendrite
  attr_reader :synapses

  MIN_THRESHOLD = 1
  ACTIVATION_THRESHOLD = 5
  MAX_NEW_SYNAPSES = 3

  def raw_overlap(state = :active)
    active_synapses(aggressive: true, state: state).count
  end

  def overlap
    overlap = raw_overlap
    overlap < MIN_THRESHOLD ? 0 : overlap
  end

  def active?
    raw_overlap(:active) >= ACTIVATION_THRESHOLD
  end

  def learning?
    raw_overlap(:learning) >= ACTIVATION_THRESHOLD
  end

  def add_new_synapses(cells)
    inputs = cells.sample(MAX_NEW_SYNAPSES - active_synapses.count)
    @synapses += inputs.map { |inp| Synapse.new(inp) }
  end

end
