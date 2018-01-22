class Scope
  include Cursed::Utils
  extend  Forwardable

  def_delegator :@parent, :has_var?, :parent_has_var?
  def_delegator :@parent, :get_proc, :parent_get_proc

  class NilParent
    def has_var?(name); false end
    def get_proc(name); nil end
  end

  class NilObject
    def respond_to?(name); false end
  end

  def initialize(obj, parent, vars)
    @obj    = obj    || NilObject.new
    @parent = parent || NilParent.new
    @vars   = {}
    @cache  = {}
    add_variables(deep_symbolize_all(vars || []))
  end

  def method_missing(method, *args, &blk)
    has_var?(method) ? instance_exec(*args, &get_proc(method)) : super
  end

  def respond_to_missing?(method, include_private=false)
    has_var?(method) || super
  end

  # TODO: kill this
  #
  def deep_eval(obj, opts={})
    ignored = opts[:ignore] || []

    case obj
    when Proc
      instance_exec &obj
    when Hash
      Hash[obj.map { |k,v|
        ignored.include?(k) ? [k,v] : [k, deep_eval(v, opts)]
      }]
    when Array
      obj.map { |o| deep_eval(o, opts) }
    else obj
    end
  end

protected

  def has_var?(name)
    !!@vars[name] || !!@cache[name] || @obj.respond_to?(name) || parent_has_var?(name)
  end

  def get_proc(name)
    @vars[name] || @cache[name] || pull_obj_method(name) || cache_parent_proc(name)
  end

private

  def pull_obj_method(name)
    @obj.method(name) rescue nil
  end

  def cache_parent_proc(name)
    prc = parent_get_proc(name)
    @cache[name] = prc if prc
  end

  def add_variables(vars)
    vars.each { |name, val| add_variable(name, val) }
  end

  def add_variable(name, val)
    @vars[name.to_sym] = val.is_a?(Proc) ? val : lambda { val }
  end

end
