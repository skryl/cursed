require_relative '../common/inspector'
require_relative 'column'
require_relative 'input'

class HTM
  include Inspector

  COLUMNS = 80
  INPUTS = 80
  INIT_INHIBITION_RADIUS = 10

  PUBLIC_VARS = %i(cycles learning num_columns num_inputs inhibition_radius columns inputs)
  HASH_ATTRS  = PUBLIC_VARS
  SHOW_ATTRS  = HASH_ATTRS - %i(columns inputs)

  attr_reader *PUBLIC_VARS
  show_fields *SHOW_ATTRS
  hash_fields *HASH_ATTRS

  def initialize(**params)
    @pattern = params[:pattern]
    @learning = false
    @cycles = 1
    @num_columns, @num_inputs = COLUMNS, INPUTS
    @inhibition_radius = INIT_INHIBITION_RADIUS
    @inputs = Array.new(@num_inputs) { |i| Input.new(i) } 
    @columns = Array.new(@num_columns) { Column.new(self, @inputs) }
    @active_columns = []
  end

  def cells
    @cells ||= @columns.flat_map(&:cells)
  end

  def step(new_input=nil)
    new_input ||=  @pattern[@cycles % 2]

    raise "bad input: #{new_input.size} > #{@inputs.size}" if new_input.size != @inputs.size
    while_learning {
      @cycles += 1
      @inputs.each.with_index { |inp, i| inp.value = new_input[i] }
      @active_columns = @columns.select { |c| c.active? }

      # temporal pooling
      # 1. reinforce all segments (that caused prediction) for the learning cells
      # 2. generate new predictive cells (save segments that caused prediction)
      #
      # @columns.each { |c| c.reinforce_cells }
      # @columns.each { |c| c.generate_predictions }

      # spatial pooling
      # 1. reinforce the dendrites of active columns
      # 2. tune boost and permanence for inactive columns
      # 3. adjust inhibition radius based on average overlap
      #
      @active_columns.each { |c| c.tune_proximal_dendrite }
      @columns.each { |c| c.tune_boost }
      adjust_inhibition_radius
    }
  end

  def while_learning
    @learning = true
    yield
    @learning = false
  end

  def activity_ratio
    (@active_columns.count / num_columns.to_f).round(2)
  end

  def adjust_inhibition_radius
    @inhibition_radius = average_receptive_field_size
  end

  def average_receptive_field_size
    @columns.reduce(0) { |a,c| a + c.raw_overlap} / @columns.count
  end

end
