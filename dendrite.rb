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

  def to_h
    { synapses: @synapses.map { |syn| syn.to_h }}
  end

end
