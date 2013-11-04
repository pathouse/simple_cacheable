module Cacheable
  module ClassMethodCache
    # Cached class method
    # Should expire on any instance save
    def with_class_method(*methods)
      self.cached_class_methods ||= []
      self.cached_class_methods += methods

      methods.each do |meth|
        define_singleton_method("cached_#{meth}") do |*args|
          cache_key = KeyMaker.new(klass: self).class_method_key(meth)
          fetcher = Fetcher.new(klass: self)
          fetcher.act_on(cache_key, args: args) do
            self.send(meth, args)
          end
        end
      end
    end
  end
end