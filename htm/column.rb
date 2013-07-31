require_relative '../common/temporal_attributes'
require_relative 'proximal_dendrite'
require_relative 'cell'
require 'forwardable'

class Column
  include Inspector
  include TemporalAttributes
  extend  Forwardable

  CELL_COUNT = 4
  INPUT_SIZE = 30
  DESIRED_LOCAL_ACTIVITY = 3

  def_delegators :@htm, :inhibition_radius, :columns, :num_columns, :cycles, :learning
  def_delegators :@pdendrite, :synapses, :raw_overlap

  PUBLIC_VARS = %i(boost active_count overlap_count pdendrite cells htm)
  HASH_ATTRS  = PUBLIC_VARS + %i(index active? raw_overlap overlap active_duty_cycle overlap_duty_cycle min_local_activity) - %i(htm)
  SHOW_ATTRS  = HASH_ATTRS  - %i(pdendrite cells)

  attr_reader *PUBLIC_VARS
  show_fields *SHOW_ATTRS
  hash_fields *HASH_ATTRS

  def initialize(htm, inputs)
    @num_cells = CELL_COUNT
    @htm = htm
    @boost = 1.0
    @active_count = 0
    @overlap_count = 0
    @pdendrite = ProximalDendrite.new(inputs.sample(INPUT_SIZE))
    @cells = Array.new(@num_cells) { Cell.new(self) }
  end

  def active?
    overlap >= min_local_activity
  end

  def active_without_predictions?
    active? && !@cells.any?(&:predicted?)
  end

# learning

  def tune_proximal_dendrite
    @pdendrite.tune_synapses
  end

# overlap

  def overlap
    @pdendrite.overlap * @boost
  end

# boost
  
  def tune_boost
    update_duty_cycles
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

  def update_duty_cycles
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

  def kth_score(neighbors, k)
    neighbors.map(&:overlap).sort.reverse[k-1]
  end

  def index
    @index ||= columns.index { |c| c == self }
  end

  def neighbors(radius=inhibition_radius)
    idx_min = index - radius
    idx_min = (idx_min < 0) ? num_columns + idx_min : idx_min
    columns.rotate(idx_min).take(radius*2+1) - [self]
  end

# reinforcement

  def reinforce_cells
    @cells.each(&:reinforce)
  end

# predictions

  def generate_predictions
    @cells.each(&:predict_next_state)
  end

# learning cell selection

  def ensure_active_and_learning
    @cells.each(&:activate_and_check_learning)
    sequence_cells = @cells.select(&:predicted_next?)

    if sequence_cells.empty?
      @cells.each(&:activate!)
    else
      sequence_cells.each(&:activate!)
    end

    unless @cells.any?(&:learning?)
      best_cell, best_segment = use_global_time(1) { best_matching_cell }
      if (best_cell)
        best_cell.set_learning_segment(best_segment)
      else
        fewest_segment_cell.add_learning_segment
      end
    end
  end

  def best_matching_cell
    cell = \
      @cells.map {|c| 
          seg = c.best_matching_segment
          [c, seg, seg && seg.aggressive_overlap] }.
        select  { |(c, bms, aoverlap)| bms }.
        sort_by { |(c, bms, aoverlap)| aoverlap }.
        last
    cell && cell[0..1]
  end

  def fewest_segment_cell
    @cells.sort_by {|c| c.segments.count }.first
  end

end
