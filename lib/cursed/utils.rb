module Cursed::Utils
  def deep_transform_all(obj, &block)
    case obj
    when Hash
      Hash[ obj.map { |k,v| [deep_transform_all(k, &block),
                             deep_transform_all(v, &block)] }]
    when Array
      obj.map { |i| deep_transform_all(i, &block) }
    else block[obj]
    end
  end

  def deep_stringify_all(obj)
    deep_transform_all(obj) { |obj| obj.is_a?(Symbol) ? obj.to_s : obj }
  end

  def deep_symbolize_all(obj)
    deep_transform_all(obj) { |obj| obj.is_a?(String) ? obj.to_sym : obj }
  end
end
