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
        def_delegators 'self.class', :temporal_attributes, :temporal_attribute_settings

        @temporal_attributes = []
        @temporal_attribute_settings = {}
      end
    end
  end

  module TemporalAttributesClassMethods
    attr_reader :temporal_attributes, :temporal_attribute_settings

    def temporal_attr(*attrs, type: :historical, history: 2)
      attrs.each do |attr|
        @temporal_attributes << attr
        @temporal_attribute_settings[attr] = [type, history]
      end
    end
  end

  def get(key, time = default_time)
    key = key.to_sym
    # db[key][time] if valid_temporal_attribute?(key)
    db[key][time]
  end

  def set(key, val)
    key = key.to_sym
    # if valid_temporal_attribute?(key)
    historical?(key) ? shift_value(key, val) : set_value(key, val)
    # else nil
    # end
  end

  def snap
    snapshot_attributes.each do |attr|
      shift_value(attr, get(attr))
    end
  end

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

private

  def default_time
    global_time || 0
  end

  def init
    @temporal_mod = TemporalAttributes
    @temporal_db = Hash.new { |h,k| h[k] = [] } 
  end

  def db
    init_proc = method(:init)
    body_proc = lambda { @temporal_db }
    run_once(:db, init_proc, body_proc)
  end

  def shift_value(key, val)
    db[key].unshift(val)
    db[key] = db[key][0...history(key)]
    val
  end

  def set_value(key, val)
    db[key][default_time] = val
  end

  def valid_temporal_attribute?(attr)
    temporal_attributes.include?(attr)
  end

  def snapshot_attributes
    temporal_attributes.select { |attr| !historical?(attr) }
  end

  def historical?(key)
    temporal_attribute_settings[key.to_sym].first == :historical
  end

  def history(key)
    temporal_attribute_settings[key.to_sym].last
  end

  def run_once(name, init, body)
    init.call.tap { define_singleton_method(name, &body) }
  end

end
