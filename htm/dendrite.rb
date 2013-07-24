require_relative 'synapse'

class Dendrite

  attr_reader :synapses

  def initialize(inputs = [])
    @synapses = inputs.map { |inp| Synapse.new(inp) }
  end

  def active_synapses(**opts)
    @synapses.select { |syn| syn.active?(opts)}
  end

  def inactive_synapses(**opts)
    @synapses.reject { |syn| syn.active?(opts)}
  end

end
