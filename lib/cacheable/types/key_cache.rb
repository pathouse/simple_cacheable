module Cacheable
  module KeyCache
    def with_key
      self.cached_key = true

      define_singleton_method("find_cached") do |id|
        cache_key = Cacheable.instance_key(self, id)
        Cacheable.fetch(cache_key) do
          self.find(id)
        end
      end
    end
  end
end