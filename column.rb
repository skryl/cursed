require_relative 'pdendrite'
require 'forwardable'

class Column
  extend Forwardable

  INPUT_SIZE = 30
  MIN_OVERLAP = 5
  DESIRED_LOCAL_ACTIVITY = 1

  def_delegators :@htm, :inhibition_radius, :columns, :num_columns, :cycles, :learning
  def_delegators :@pdendrite, :synapses
  attr_reader    :boost, :input_indices, :active_count, :overlap_count

  def initialize(htm, inputs)
    @htm = htm
    @boost = 1.0
    @active_count = 0
    @overlap_count = 0
    @pdendrite = PDendrite.new(inputs.sample(INPUT_SIZE))
  end

  def active?
    overlap >= min_local_activity
  end

# learning

  def tune_proximal_dendrite
    @pdendrite.tune_synapses
  end

# overlap

  def raw_overlap
    @pdendrite.overlap
  end

  def overlap
    overlap = raw_overlap
    overlap < MIN_OVERLAP ? 0 : overlap * @boost
  end

# boost
  
  def tune_boost
    update_duty_cycle_counters
    tune_overlap_boost
    tune_permanence
  end

# boost overlap

  def tune_overlap_boost
    boost_delta = active_duty_cycle - min_duty_cycle
    @boost = (boost_delta > 0) ? 1.0 : (@boost + boost_delta.abs)
  end

  def active_duty_cycle
    @active_count.to_f / cycles
  end

  def update_duty_cycle_counters
    @overlap_count += 1 if learning && overlap > 0
    @active_count += 1 if learning && active?
  end

  def min_duty_cycle
    0.01 * max_duty_cycle
  end

  def max_duty_cycle
    neighbors.map { |n| n.active_duty_cycle }.max
  end

# boost permanence

  def tune_permanence
    if overlap_duty_cycle < min_duty_cycle
      @pdendrite.boost_all!
    end
  end

  def overlap_duty_cycle
    @overlap_count.to_f / cycles
  end
  
# local activity

  def min_local_activity
    kth_score(neighbors, DESIRED_LOCAL_ACTIVITY)
  end

  def kth_score(neighbors, dla)
    neighbors.map { |n| n.overlap }.sort.reverse[dla-1]
  end

  def index
    @index ||= columns.index { |c| c == self }
  end

  def neighbors
    idx_min = index - inhibition_radius
    idx_min = (idx_min < 0) ? num_columns + idx_min : idx_min
    columns.rotate(idx_min).take(inhibition_radius*2+1) - [self]
  end

  def to_h
    { raw_overlap: raw_overlap, 
      overlap: overlap, 
      boost: @boost,
      num_neighbors: neighbors.size,
      active_duty_cycle: active_duty_cycle,
      overlap_duty_cycle: overlap_duty_cycle,
      min_local_activity: min_local_activity
    }.merge @pdendrite.to_h
  end

end
