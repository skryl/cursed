require_relative '../common/temporal_attributes'
require_relative '../common/inspector'
require_relative 'synapse'

class CellSynapse < Synapse
  include Inspector
  include TemporalAttributes

  temporal_caller :active_aggressive?,       :_active_aggressive?,       history: 3
  temporal_caller :active_non_aggressive?,   :_active_non_aggressive?,   history: 3
  temporal_caller :learning_non_aggressive?, :_learning_non_aggressive?, history: 3

  show_fields 
  hash_fields :input

  HASH_ATTRS  = PUBLIC_VARS + %i(active_aggressive? active_non_aggressive? learning_non_aggressive?)
  SHOW_ATTRS  = HASH_ATTRS  - %i(input)

  attr_reader *PUBLIC_VARS
  show_fields *SHOW_ATTRS
  hash_fields *HASH_ATTRS

  def active?(**opts)
    if opts[:aggressive]
      active_aggressive?
    elsif opts[:state] == :learning
      learning_non_aggressive?
    else
      active_non_aggressive?
    end
  end

private

  def _active_aggressive?
    @input.active?
  end

  def _active_non_aggressive?
    @input.active? && @permanence >= PERM_CONNECTED
  end

  def _learning_non_aggressive?
    @input.learning? && @permanence >= PERM_CONNECTED
  end

end
