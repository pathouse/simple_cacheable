module Cacheable
  module ClassMethodCache
    # Cached class method
    # Should expire on any instance save
    def with_class_method(*methods)
      self.cached_class_methods ||= []
      self.cached_class_methods += methods

      methods.each do |meth|
        define_singleton_method("cached_#{meth}") do |*args|
          cache_key = Cacheable.class_method_key(self, meth)
          fetcher = Cacheable::Fetcher.new(klass: self)
          fetcher.act_on(cache_key, args: args) do
            unless args.empty?
              self.send(meth, *args)
            else
              self.send(meth)
            end
          end
        end
      end
    end
  end
end