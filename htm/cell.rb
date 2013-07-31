require_relative '../common/temporal_attributes'
require_relative 'distal_dendrite'

class Cell
  include TemporalAttributes
  include Inspector
  extend  Forwardable

  def_delegators  :@column, :htm, :columns
  def_delegators  :htm, :cells, :learning_cells

  PUBLIC_VARS = %i(column segments)
  HASH_ATTRS  = PUBLIC_VARS + %i(index active? learning?) - %i(column)
  SHOW_ATTRS  = HASH_ATTRS  - %i(segments)

  attr_reader *PUBLIC_VARS
  show_fields *SHOW_ATTRS
  hash_fields *HASH_ATTRS

  temporal_attr :predicted, :predicted_next, history: 3

  LEARNING_RADIUS = 30

  def initialize(column)
    @active = false
    @learning = false
    @column = column
    @segments = []
    @active_segments = []
    @learning_segment = nil
  end

  def index
    @index ||= cells.index { |c| c == self }
  end

  def active?; @active end
  def activate!; @active = true end
  def deactivate!; @active = false end

  def learning?; @learning end
  def learn!;  @learning = true end

  def predicted?; predicted end
  def prev_predicted?; predicted(1) end

  def predicted_next?; predicted_next end
  def prev_predicted_next?; predicted_next(1) end

# reset cell state
  
  def reset!
    @active = false
    @learning = false
    @active_segment = nil
    @learning_segment = nil
    self.predicted_next = false
  end

# segments

  def active_segments
    @segments.select(&:active?)
  end

  def set_learning_segment(seg)
    learn!
    @learning_segment = seg
  end

  def add_learning_segment
    learn!
    @learning_segment = DistalDendrite.new(sequence: true)
  end

# predictions

  def predict_next_state
    @active_segments = active_segments
    self.predicted = @active_segments.any?
  end

# activation
  
  def activate_and_check_learning
    if predicted?
      @active = true
      @active_segment = \
        use_global_time(1) { get_active_segment }

      self.predicted_next = @active_segment.sequence?
      @learning = predicted_next? && @active_segment.learning?
    end
  end

  def get_active_segment
    @active_segments.sort { |s1,s2| 
      if s1.sequence? ^ s2.sequence?
        s1.sequence? ? -1 : 1
      else
        s1.overlap <=> s2.overlap
      end
    }.first
  end

# reinforcement

  def reinforce
    if learning?
      reinforce_learning_segment if @learning_segment
      use_global_time(1) { @active_segments.each(&:strengthen!) }
    elsif (prev_predicted? && !predicted?)
      use_global_time(1) { @active_segments.each(&:weaken!) }
    end
  end

  def reinforce_learning_segment
    @learning_segment.sequence!
    use_global_time(1) { @learning_segment.add_new_synapses(learning_cells) }
    @segments << @learning_segment unless @segments.include?(@learning_segment)
  end


  # take a temporal snapshot of all teh things
  #
  def snapshot!
    @segments.each { |s| s.snapshot! }
  end

  def best_matching_segment
    seg = \
      @segments.
        map { |s| [s, s.aggressive_overlap] }.
        select  { |(segment, aoverlap)| aoverlap > 0 }.
        sort_by { |(segment, aoverlap)| aoverlap }.
        last
    seg && seg.first
  end


  # def learning_neighbors
    # column.neighbors(LEARNING_RADIUS).flat_map(&:cells).select(&:learning?)
  # end

end
