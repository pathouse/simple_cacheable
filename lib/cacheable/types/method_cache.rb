module Cacheable
  module MethodCache
    def with_method(*methods)
      self.cached_methods ||= []
      self.cached_methods += methods

      methods.each do |meth|
        method_name = "cached_#{meth}"
        define_method("cached_#{meth}") do |*args|
          args ||= []
          cache_key = Cacheable.method_key(self, meth)
          fetcher = Cacheable::Fetcher.new(object: self)
          memoized_name = Cacheable::Formatter.escape_punctuation("@#{method_name}")
          if instance_variable_get(memoized_name).nil?
            result = fetcher.act_on(cache_key, args: args) do
              unless args.empty? 
                self.send(meth, *args)
              else
                self.send(meth)
              end
            end
            instance_variable_set(memoized_name, result)
          end
          instance_variable_get(memoized_name)
        end
      end
    end
  end
end