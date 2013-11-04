module Cacheable
  module Expiry

    def expire_all(object)
      Reaper.new(self).expire
    end

    class Reaper

      attr_accessor :klass, :object

      def initialize(object)
        @object = object
        @klass = object.class
      end

      def expire
        expire_instance
        expire_methods
        expire_attributes
      end

      def expire_instance
        key = KeyMaker.new(object: object).instance_key
        Rails.cache.delete(key)
      end

      def expire_methods
        klass.cached_class_methods.map do |m| 
          KeyMaker.new(klass: klass).class_method_key(m)
        end.each do |mkey|
          Rails.cache.delete(mkey)
        end
      end

      def expire_attributes
        klass.cached_indices.map do |index, values|
          values.map { |v| KeyMaker.new(klass: klass).attribute_key(index, v) }
        end.flatten.each do |akey|
          Rails.cache.delete(akey)
        end
      end
    end
  end
end