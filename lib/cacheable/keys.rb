module Cacheable
  module Keys

    # THE KEY MAKER
    #
    # Handles creation of keys for all objects and classes.
    # Keys generated in hashes called Key blobs => { type: :key_type, key: 'key' }
    # The type is used by the fetcher so it doesn't have to parse
    # the key to figure out what kind it is and how to handle its contents.
    # 
    # CLASS KEYS
    # A class is responsible for expiring instance object caches and class method caches
    # class expiry only happens naturally when a model's schema is changed
    # 
    # INSTANCE KEYS
    # Instance object caches (aside from the main key cache) no longer require expiry
    # since this now happens automatically w/ attribute-dependent generations
    #
    # METHOD KEYS
    # Method keys no longer include arguments. Instead, the cache itself 
    # will contain hashes of arg:value pairs.
    # This is to keep class and instance method handling similar. 
    # Instance methods are trivial to expire, class methods are not, if you
    # include arguments in their keys. 


    class KeyMaker
      attr_accessor :object, :klass

      # INITIATILIZED with OBJECT or CLASS
      def initialize(options = {})
        @object ||= options[:object]
        @klass = options[:klass] || object.class
      end

      # HASH generated from SCHEMA to indicate MODEL GENERATIONS
      def model_generation
        columns = klass.try(:columns)
        return if columns.nil?
        schema_string = columns.sort_by(&:name).map{|c| "#{c.name}:#{c.type}"}.join(',')
        CityHash.hash64(schema_string)
      end

      # HASH generated from ATTRIBUTES to indicate INSTANCE GENERATIONS
      def instance_generation
        atts = object.attributes
        att_string = atts.sort.map { |k, v| [k,v].join(":") }.join(",")
        CityHash.hash64(att_string)
      end

      # => "users/model_generation"
      def key_prefix
        [klass.name.tableize, model_generation].join("/")
      end

      # EXPIRE ON WRITE OR OVERWRITE ON UPDATE
      # => "users/model_generation/user.id/"
      def instance_key(id=nil)
        id ||= object.try(:id)
        { type: :object, key: [key_prefix, id.to_s].join("/") }
      end

      # => "users/model_generation/attribute:args"
      def attribute_key(att, *val)
        att_val = [att, Cacheable::Formatter.symbolize_args(val)].join(":")
        { type: :attribute, 
          key: [key_prefix, att_val].join("/") }
      end

      # => "users/model_generation/all/attribute:args"
      def all_with_attribute_key(att, *val)
        att_val = [att, Cacheable::Formatter.symbolize_args(val)].join(":")
        { type: :attribute,
          key: [key_prefix, "all", att_val].join("/") }
      end

      # => "users/model_generation/user.id/instance_generation/method
      def method_key(method)
        { type: :method, 
          key: [key_prefix, object.id, instance_generation, method].join("/") }
      end

      # EXPIRE MODEL UPDATE, NEW MODEL, MODEL DELETE, ETC. 
      # ANY CHANGE TO CLASS
      # => "users/model_generation/method
      def class_method_key(method)
        { type: :class_method,
          key: [key_prefix, method].join("/") }
      end

      # USED FOR MASS EXPIRY
      def all_class_method_keys
        klass.cached_class_methods.map { |c_method| class_method_key(c_method) }
      end

      # => "users/model_generation/user.id/instance_generation/association_name"
      def association_key(association_name)
        { type: :association,
          key: [key_prefix, object.id, instance_generation, association_name].join("/") }
      end
    end 
  end
end