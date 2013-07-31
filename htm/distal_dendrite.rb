require_relative 'cell_synapse'
require_relative 'dendrite'

class DistalDendrite < Dendrite
  include Inspector

  MIN_THRESHOLD = 1
  ACTIVATION_THRESHOLD = 3
  NEW_SYNAPSE_COUNT = 20

  hide_vars!
  hash_fields :synapses

  def initialize(sequence: false)
    @sequence = sequence
    @synapses = []
  end

  def sequence?; @sequence end
  def sequence!; @sequence = true end

  def active?
    raw_overlap(:active) >= ACTIVATION_THRESHOLD
  end

  def learning?
    raw_overlap(:learning) >= ACTIVATION_THRESHOLD
  end

  def overlap
    overlap = raw_overlap(:active)
    overlap >= ACTIVATION_THRESHOLD ? overlap : 0
  end

  def aggressive_overlap
    overlap = raw_overlap(:active, true)
    overlap < MIN_THRESHOLD ? 0 : overlap
  end

  def strengthen!
    active_synapses.each { |syn| syn.strengthen! }
    # inactive_synapses.each { |syn| syn.weaken! }
  end

  def weaken!
    active_synapses.each { |syn| syn.weaken! }
  end

  def add_new_synapses(cells)
    own_cells = @synapses.map { |s| s.input }
    active_cells = active_synapses.map { |s| s.input }
    new_synapse_count = NEW_SYNAPSE_COUNT - active_cells.count

    if new_synapse_count > 0
      cells = cells.reject { |c| own_cells.include?(c) }.sample(new_synapse_count)
      @synapses += cells.map { |c| CellSynapse.new(c, active: true) }
    end
  end

private

  def raw_overlap(state = active, aggressive = false)
    active_synapses(state: state, aggressive: aggressive).count
  end

end
