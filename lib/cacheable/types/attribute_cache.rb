module Cacheable
  module AttributeCache
    def with_attribute(*attributes)
      self.cached_indices ||= {}
      self.cached_indices = self.cached_indices.merge(attributes.each_with_object({}) {
        |attribute, indices| indices[attribute] = {}
      })

      attributes.each do |attribute|
        define_singleton_method("find_cached_by_#{attribute}") do |value|
          self.cached_indices["#{attribute}"] ||= []
          self.cached_indices["#{attribute}"] << value
          cache_key = KeyMaker.new(klass: self).attribute_key(attribute, value)
          fetcher = Fetcher.new(klass: self)
          fetcher.act_on(cache_key) do
            self.send("find_by_#{attribute}", value)
          end
        end

        define_singleton_method("find_cached_all_by_#{attribute}") do |value|
          self.cached_indices["#{attribute}"] ||= []
          self.cached_indices["#{attribute}"] << value
          cache_key = KeyMaker.new(klass: self).all_with_attribute_key(attribute, value)
          fetcher = Fetcher.new(klass: self)
          fetcher.act_on(cache_key) do
            self.send("find_all_by_#{attribute}", value)
          end
        end
      end
    end
  end
end