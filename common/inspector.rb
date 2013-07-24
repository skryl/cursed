require 'forwardable'

module Inspector

  def self.included(klass)
    klass.class_eval do
      extend Forwardable
      extend InspectorClassMethods

      @visible_vars   = []
      @hidden_vars    = [:@inspected_vars]
      @visible_fields = []
      @hashed_fields  = []
      @hide_vars = false

      def_delegators 'self.class', 
        :visible_vars, :hidden_vars, :visible_fields, :hashed_fields, :hide_vars?
    end
  end

  module InspectorClassMethods
    attr_reader :visible_vars, :hidden_vars, :visible_fields, :hashed_fields

    def show_vars(*vars)
      vars.each { |var| @visible_vars << to_ivar(var) }
    end

    def hide_vars(*vars)
      vars.each { |var| @hidden_vars << to_ivar(var) }
    end

    def show_fields(*attrs)
      attrs.each { |attr| @visible_fields << attr.to_sym }
    end

    def hash_fields(*attrs)
      attrs.each { |attr| @hashed_fields << attr.to_sym }
    end

    def hide_vars!; @hide_vars = true end
    def hide_vars?; @hide_vars end

  private

    def to_ivar(field)
      ('@' + field.to_s).to_sym
    end
  end

  def inspect
    obj    = "#{self.class.name}:#{self.object_id}"
    vars   = inspected_vars.map { |iv| "#{iv}: #{self.instance_variable_get(iv).inspect}" }
    fields = visible_fields.map { |f| "#{f}: #{self.send(f).inspect}" }
    "#<#{obj} #{(vars + fields).join(', ')}>"
  end

  def to_h
    hashed_fields.reduce({}) { |h, f| h[f] = self.send(f); h }
  end

  def inspected_vars
    @inspected_vars ||= 
      if hide_vars?
        []
      elsif (visible_vars + visible_fields).empty?
        instance_variables - hidden_vars
      else
        (instance_variables & visible_vars) - hidden_vars
      end
  end

end
