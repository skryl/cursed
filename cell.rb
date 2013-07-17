require_relative 'common/temporal_attributes'
require_relative 'ddendrite'

class Cell
  include TemporalAttributes

  attr_reader :column, :sequence_segments
  temporal_attr :predicted, :predictive_segment, history: 2

  LEARNING_RADIUS = 5

  def initialize(column)
    @column = column
    @learning = false
    predicted = false
    @segments = []
  end

  def predicted?; predicted end
  def prev_predicted?; predicted(1) end
  def predictive_segment; predictive_segment end
  def num_segments; @segments.count end

  def active?
    @column.active_without_predictions? || (@column.active? && predicted?)
  end

  def learning?
    active? && @learning
  end

  def learn!
    @learning = true 
    @learning_segment = best_matching_segment || DDendrite.new
  end

# segments

  def active_segments
    @segments.select(&:active?)
  end

# reinforcement

  def reinforce
    if learning?
      use_global_time(1) { reinforce_learning_segment }
      use_global_time(1) { @active_segments.each(&:strengthen!) }
      use_global_time(2) { predictive_segment.strengthen! }
    elsif (prev_predicted? && !predicted?)
      use_global_time(1) { @active_segments.each(&:weaken!) }
      use_global_time(2) { predictive_segment.weaken! }
    end
  end

  def reinforce_learning_segment
    @segments << @learning_segment unless 
      @segments.include?(@learning_segment)

    @learning_segment.add_new_synapses(active_neighbors)
  end

  def active_neighbors
    column.neighbors(LEARNING_RADIUS).flat_map(&:cells).select(&:active?)
  end

# predictions

  def predict_next_state
    @active_segments = active_segments
    predicted =  @active_segments.any?
    @learning = predicted && @active_segments.first.learning?
    predictive_segment = best_matching_segment
  end

  def best_matching_segment
    @segments.
      select  { |s| s.overlap > 0 }.
      sort_by { |s| s.overlap }.
      last
  end

end
