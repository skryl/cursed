require_relative 'pdendrite'
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
    @pdendrite = PDendrite.new(inputs.sample(INPUT_SIZE))
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
    ensure_learning_cell
  end

# learning cell selection

  def learning_cell
    @cells.find(&:learning?)
  end

  def ensure_learning_cell
    learning_cell || choose_best_cell.learn!
  end

  def choose_best_cell
    @cells.select  { |c| c.best_matching_segment }.
           sort_by { |c| c.best_matching_segment.overlap}.
           last || 
    @cells.sort_by {|c| c.num_segments }.first
  end

end
