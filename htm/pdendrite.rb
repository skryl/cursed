require_relative 'synapse'
require_relative 'dendrite'

class PDendrite < Dendrite
  include Inspector

  MIN_OVERLAP = 10
  hide_vars!

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
