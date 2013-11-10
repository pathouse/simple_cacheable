module Cacheable

  def expire_all
    Cacheable.expire(self)
  end

  def self.expire(object)
    expire_instance_key(object)
    expire_class_method_keys(object)
    expire_attribute_keys(object)
  end

  def self.expire_instance_key(object)
    key = Cacheable.instance_key(object.class, object.id)
    Rails.cache.delete(key[:key])
  end

  def self.expire_class_method_keys(object)
    object.class.cached_class_methods.map do |class_method|
      key = Cacheable.class_method_key(object.class, class_method)
    end.each do |method_key|
      Rails.cache.delete(method_key[:key])
    end
  end

  def self.expire_attribute_keys(object)
    object.class.cached_indices.map do |index, values|
      values.map { |v| Cacheable.attribute_key(object.class, index, v) }
    end.flatten.each do |attribute_key|
      Rails.cache.delete(attribute_key[:key])
    end
  end
end