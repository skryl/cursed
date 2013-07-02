require_relative 'column'
require_relative 'input'

class HTM
  COLUMNS = 80
  INPUTS = 80
  INIT_INHIBITION_RADIUS = 10

  attr_reader :learning, :cycles, :num_columns, :num_inputs, :inputs, :columns, :inhibition_radius

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

  def step(new_input=nil)
    new_input ||=  @pattern[@cycles % 2]

    raise "bad input: #{new_input.size} > #{@inputs.size}" if new_input.size != @inputs.size
    while_learning {
      @cycles += 1
      @inputs.each.with_index { |inp, i| inp.value = new_input[i] }
      @active_columns = @columns.select { |c| c.active? }
      @active_columns.each { |c| c.tune_proximal_dendrite }
      @columns.each { |c| c.tune_boost }
      tune_inhibition_radius
    }
  end

  def while_learning
    learning = true
    yield
    learning = false
  end

  def activity_ratio
    (@active_columns.count / num_columns.to_f).round(2)
  end

  def tune_inhibition_radius
    @inhibition_radius = average_receptive_field_size
  end

  def average_receptive_field_size
    @columns.reduce(0) { |a,c| a + c.raw_overlap} / @columns.count
  end

  def to_h
    { inhibition_radius: @inhibition_radius,
      columns: @columns.map { |c| c.to_h } }
  end
end
