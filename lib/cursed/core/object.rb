class Object

  def constantize(name)
    self.const_get(name.to_s.capitalize) rescue nil
  end

end
