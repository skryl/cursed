require_relative 'synapse'

class InputSynapse < Synapse

  def active?(**opts)
    @input.active? && @permanence >= PERM_CONNECTED
  end

end
