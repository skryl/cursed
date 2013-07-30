require_relative '../common/inspector'
require_relative 'input_synapse'
require_relative 'dendrite'

class ProximalDendrite < Dendrite
  include Inspector

  MIN_OVERLAP = 10
  hide_vars!

  def initialize(inputs = [])
    @synapses = inputs.map { |inp| InputSynapse.new(inp) }
  end

  def raw_overlap
    active_synapses.count
  end

  def overlap
    overlap = raw_overlap
    overlap < MIN_OVERLAP ? 0 : overlap
  end

  def tune_synapses
    active_synapses.each { |syn| syn.strengthen! }
    inactive_synapses.each { |syn| syn.weaken! }
  end

  def boost_all!
    @synapses.each { |syn| syn.boost! }
  end

end
