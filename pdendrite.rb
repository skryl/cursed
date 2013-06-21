require_relative 'synapse'

class PDendrite
  attr_reader :synapses

  def initialize(inputs)
    @synapses = inputs.map { |inp| Synapse.new(inp) }
  end

  def overlap
    active_synapses.size
  end

  def tune_synapses
    active_synapses.each { |syn| syn.strengthen! }
    inactive_synapses.each { |syn| syn.weaken! }
  end

  def strengthen_all!
    @synapses.each { |syn| syn.strengthen! }
  end

  def active_synapses
    @synapses.select { |syn| syn.active?}
  end

  def inactive_synapses
    @synapses.reject { |syn| syn.active?}
  end

  def to_h
    { synapses: @synapses.map { |syn| syn.to_h }}
  end

end
