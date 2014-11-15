class Class

  def def_predicates(*names)
    names.reject! { |n| n.to_s.empty? }
    names.each do |name|
      ivar = "@#{name}"
      name = name.to_s

      define_method("#{name}?") do
        instance_variable_get(ivar)
      end

      define_method("not_#{name}?") do
        !instance_variable_get(ivar)
      end

      define_method("#{name}!") do
        instance_variable_set(ivar, true)
      end

      define_method("not_#{name}!") do
        instance_variable_set(ivar, false)
      end
    end
  end

end
