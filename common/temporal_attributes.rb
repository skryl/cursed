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
      klass.class_eval do
        extend Forwardable
        extend TemporalAttributesClassMethods

        def_delegators  TemporalAttributes, :global_time, :use_global_time

        @temporal_attributes = []
        @temporal_attribute_settings = {}
      end
    end
  end

  module TemporalAttributesClassMethods
    attr_reader :temporal_attributes, :temporal_attribute_settings

    def temporal_attr(*attrs, type: :historical, history: 2, **opts)
      attrs.each do |attr|
        @temporal_attributes << attr
        @temporal_attribute_settings[attr] = [type, history]
      end
    end

    def temporal_caller(attr, method, history: 2)
      @temporal_attributes << attr
      @temporal_attribute_settings[attr] = [:caller, history, method]
    end
  end

  def get(key, time = default_time)
    key = key.to_sym
    return unless valid_temporal_attribute?(key)

    case [attr_type(key), time]
    when [:caller, 0] 
      set_value(key, self.send(callee(key)))
    else
      db[key][time]
    end
  end

  def set(key, val)
    key = key.to_sym
    return unless valid_temporal_attribute?(key)

    case attr_type(key)
    when :historical; shift_value(key, val)
    when :snapshot;   set_value(key, val)
    when :caller      # do nothing
    end
  end

  def snap
    snapshot_attributes.each do |attr|
      shift_value(attr, get(attr))
    end
  end

# magix

  def respond_to_missing?(method, priv)
    valid_temporal_attribute?(method) || super
  end

  #TODO: define accessors dynamically vs method_missing
  #
  def method_missing(method, *args, &block)
    meth, setter = /^(.*?)(=?)$/.match(method).values_at(1,2)
    if valid_temporal_attribute?(meth.to_sym) 
      setter.empty? ? get(meth, *args) : set(meth, *args)
    else super
    end
  end

# class property readers

  def temporal_settings
    @temporal_settings ||= self.class.temporal_attribute_settings
  end

  def temporal_attributes
    @temporal_attributes ||= self.class.temporal_attributes
  end

private

  def default_time
    global_time || 0
  end

# initialization

  def init
    @temporal_mod = TemporalAttributes
    @temporal_db  = Hash.new { |h,k| h[k] = [nil] } 
  end

  def db
    init_proc = method(:init)
    body_proc = lambda { @temporal_db }
    run_once(:db, init_proc, body_proc)
  end

  def run_once(name, init, body)
    init.call.tap { define_singleton_method(name, &body) }
  end

# saving values

  def shift_value(key, val)
    db[key].unshift(val)
    db[key] = db[key][0...history(key)]
    val
  end

  def set_value(key, val)
    db[key][default_time] = val
  end

# helpers

  def valid_temporal_attribute?(attr)
    temporal_attributes.include?(attr)
  end

  def snapshot_attributes
    temporal_attributes.select { |attr| !historical?(attr) }
  end

  def historical?(key); attr_type(key) == :historical end
  def snapshot?(key);   attr_type(key) == :snapshot   end
  def caller?(key);     attr_type(key) == :caller     end

  def attr_type(key); temporal_settings[key][0] end
  def history(key);   temporal_settings[key][1] end
  def callee(key);    temporal_settings[key][2] end

end
