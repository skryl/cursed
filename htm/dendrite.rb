require_relative 'synapse'

class Dendrite

  attr_reader :synapses

  def active_synapses(**opts)
    @synapses.select { |syn| syn.active?(opts)}
  end

  def inactive_synapses(**opts)
    @synapses.reject { |syn| syn.active?(opts)}
  end

  def snapshot!
    @synapses.each { |syn| syn.snap }
  end

end
