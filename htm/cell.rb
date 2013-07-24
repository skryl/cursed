require_relative '../common/temporal_attributes'
require_relative 'ddendrite'

class Cell
  include Inspector
  include TemporalAttributes
  extend  Forwardable

  def_delegators  :@column, :htm, :columns
  def_delegators  :htm, :cells
  temporal_attr   :predicted, :predictive_segment, history: 2

  PUBLIC_VARS = %i(learning column segments)
  HASH_ATTRS  = PUBLIC_VARS + %i(index) - %i(column)
  SHOW_ATTRS  = HASH_ATTRS  - %i(segments)

  attr_reader *PUBLIC_VARS
  show_fields *SHOW_ATTRS
  hash_fields *HASH_ATTRS

  LEARNING_RADIUS = 30

  def initialize(column)
    @column = column
    @learning = false
    self.predicted = false
    @segments = []
  end

  def predicted?; predicted end
  def prev_predicted?; predicted(1) end
  def num_segments; @segments.count end

  def index
    @index ||= cells.index { |c| c == self }
  end

  def active?
    @column.active_without_predictions? || (@column.active? && predicted?)
  end

  def learning?
    active? && @learning
  end

  def learn!
    @learning_segment = best_matching_segment || DDendrite.new
    @learning = true 
  end

# segments

  def active_segments
    @segments.select(&:active?)
  end

# reinforcement

  def reinforce
    if learning?
      reinforce_learning_segment 
      # use_global_time(1) { active_segments.each(&:strengthen!) }
      # use_global_time(2) { predictive_segment.strengthen! }
    elsif (prev_predicted? && !predicted?)
      # use_global_time(1) { active_segments.each(&:weaken!) }
      # use_global_time(2) { predictive_segment.weaken! }
    end
  end

  def reinforce_learning_segment
    @segments << @learning_segment unless @segments.include?(@learning_segment)
    @learning_segment.add_new_synapses(learning_neighbors)
  end

# predictions

  def predict_next_state
    @active_segments = active_segments
    self.predicted = @active_segments.any?
    @learning = @active_segments.any?(&:learning?)
    @learning_segment = @active_segments.find(&:learning?) 
    # self.predictive_segment = use_global_time(1) { best_matching_segment }
  end

  def learning_neighbors
    column.neighbors(LEARNING_RADIUS).flat_map(&:cells).select(&:learning?)
  end

  def best_matching_segment
    @segments.
      select  { |s| s.overlap > 0 }.
      sort_by { |s| s.overlap }.
      last
  end

end
