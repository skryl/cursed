require 'forwardable'

module TemporalAttributes

  @global_time = 0

  class << self
    def global_time
      @global_time
    end

    def set_global_time(time)
      @global_time = time
    end
    private :set_global_time

    def use_global_time(time)
      old_time = global_time
      set_global_time(time)
      ret = yield
      set_global_time(old_time)
      ret
    end

    def included(klass)
      klass.extend(Forwardable)
      klass.def_delegators  self, :global_time, :use_global_time
      klass.def_delegators 'self.class', :temporal_attributes, :temporal_attribute_settings
      klass.instance_variable_set("@temporal_attribute_settings", {})
      klass.extend(TemporalAttributesClassMethods)
    end
  end

  module TemporalAttributesClassMethods
    attr_reader :temporal_attribute_settings

    def temporal_attr(*attrs, history: 2)
      attrs.each do |attr|
        @temporal_attribute_settings[attr] = history 
      end
    end

    def temporal_attributes
      @temporal_attribute_settings.keys
    end
  end

  def get(key, time= global_time || 0)
    key = key.to_sym
    # db[key][time] if valid_temporal_attribute?(key)
    db[key][time]
  end

  def set(key, val)
    key = key.to_sym
    # if valid_temporal_attribute?(key)
      db[key].unshift(val)
      db[key] = db[key][0...history(key)]
      val
    # else nil
    # end
  end

  def respond_to_missing?(method, priv)
    valid_temporal_attribute?(method) || super
  end

  def method_missing(method, *args, &block)
    method, setter = /^(.*?)(=?)$/.match(method).values_at(1,2)
    if valid_temporal_attribute?(method.to_sym) 
      setter.empty? ? get(method, *args) : set(method, *args)
    else super
    end
  end

private

  def init
    @temporal_mod = TemporalAttributes
    @temporal_db = Hash.new { |h,k| h[k] = [] } 
  end

  def db
    init_proc = method(:init)
    body_proc = lambda { @temporal_db }
    run_once(:db, init_proc, body_proc)
  end

  def valid_temporal_attribute?(attr)
    temporal_attributes.include?(attr)
  end

  def history(key)
    temporal_attribute_settings[key.to_sym]
  end

  def run_once(name, init, body)
    init.call.tap { define_singleton_method(name, &body) }
  end

end
