module Cacheable
  module Keys

    # THE KEY MAKER
    #
    # Handles creation of keys for all objects and classes.
    # 
    # CLASS KEYS
    # A class is responsible for expiring instance caches and class method caches
    # class expiry only happens naturally when a model's schema is changed
    # 
    # INSTANCE KEYS
    # Instance object caches (aside from the main key cache) no longer require expiry
    # since this now happens automatically w/ attribute-dependent generations
    #
    # METHOD KEYS
    # Method keys no longer include arguments. Instead, the cache itself 
    # will contain hashes of arg:value pairs


    class KeyMaker
      attr_accessor :object, :klass

      # INITIATILIZED with OBJECT or CLASS
      def initialize(options = {})
        @object ||= options[:object]
        @klass = options[:class] || object.class
      end

      # HASH generated from SCHEMA to indicate MODEL GENERATIONS
      def model_generation
        columns = klass.columns
        schema_string = columns.sort_by(&:name).map{|c| "#{c.name}:#{c.type}"}.join(',')
        CityHash.hash64(schema_string)
      end

      # HASH generated from ATTRIBUTES to indicate INSTANCE GENERATIONS
      def instance_generation
        atts = object.all_attributes
        att_string = atts.sort.map { |k, v| [k,v].join(":") }.join(",")
        CityHash.hash64(att_string)
      end

      # => "users/model_generation"
      def key_prefix
        [klass.name.tabelize, model_generation].join("/")

      # EXPIRE ON WRITE OR OVERWRITE ON UPDATE
      # => "users/model_generation/user.id/"
      def instance_key(id=nil)
        id ||= object.id unless object.nil?
        [key_prefix, id.to_s].join("/")
      end

      # => "users/model_generation/user.id/instance_generation/attribute"
      def attribute_key(att)
        [instance_key, instance_generation, att].join("/")
      end

      # => "users/model_generation/user.id/instance_generation/method
      def method_key(method)
        [instance_key(object.id), instance_generation, method].join("/")
      end

      # EXPIRE MODEL UPDATE, NEW MODEL, MODEL DELETE, ETC. 
      # ANY CHANGE TO CLASS
      # => "users/model_generation/method
      def class_method_key(method)
        [key_prefix, method, args].join("/")
      end

      # USED FOR MASS EXPIRY
      def all_class_method_keys
        self.cached_class_methods.map { |c_method| class_method_key(c_method) }
      end

      # => "users/model_generation/user.id/instance_generation/association_name"
      def association_key(association_name)
        [instance_key, association_name].join("/")
      end
    end 
  end
end