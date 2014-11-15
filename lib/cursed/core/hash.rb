class Hash

  def deep_merge(other_hash)
    dup.deep_merge!(other_hash)
  end

  def deep_merge!(other_hash)
    other_hash.each_pair do |k,v|
      tv = self[k]
      self[k] = \
        if tv.is_a?(Hash) && v.is_a?(Hash)
          tv.deep_merge(v)
        elsif tv.is_a?(Array) && v.is_a?(Array)
          tv + v
        else v
        end
    end
    self
  end

end
