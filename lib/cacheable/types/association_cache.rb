module Cacheable
  module AssocationCache

    def with_association(*association_names)
      self.cached_associations ||= []
      self.cached_associations += association_names

      association_names.each do |assoc_name|
        cached_assoc_methods(assoc_name)
      end
    end

    def cached_assoc_methods(name)
      method_name = "cached_#{name}"
      define_method(method_name) do
        cache_key = Cacheable::KeyMaker.new(object: self).association_key(name)
        fetcher = Cacheable::Fetcher.new(object: self)
        if instance_variable_get("@#{method_name}").nil?
          instance_keys = fetcher.act_on(cache_key) do
            self.send(name).map { |obj| Cacheable::KeyMaker.new(object: obj).instance_key }
          end
          association = fetcher.act_on(*instance_keys) do |keys_results|
            keys_results.each do |key,result|
              if result.nil?
                key_parts = key.scan(/(^.*)\/(.*)\/(.*$)/).last
                keys_results[key] = key_parts.first.constantize.send(:find, key_parts.last.to_i)
              end
            end
          end
          instance_variable_set("@#{method_name}", association)
        end
        instance_variable_get("@#{method_name}")
      end
    end
  end
end