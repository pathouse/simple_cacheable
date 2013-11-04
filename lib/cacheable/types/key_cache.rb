module Cacheable
  module KeyCache
    def with_key
      self.cached_key = true

      define_singleton_method("find_cached") do |id|
        cache_key = Cacheable::KeyMaker.new(klass: self).instance_key(id)
        fetcher = Cacheable::Fetcher.new(klass: self)
        fetcher.act_on(cache_key) do
          self.find(id)
        end
      end
    end
  end
end