require 'uri'
require "cacheable/caches"
require "cacheable/keys"
require "cacheable/expiry"
require "cacheable/cache_io/fetching"
require "cacheable/cache_io/formatting"
require "cacheable/cache_io/parsing"
require 'cityhash'

module Cacheable

  def self.included(base)
    base.extend(Cacheable::Caches)
    base.extend(Cacheable::ClassMethods)

    base.class_eval do
      class_attribute   :cached_key,
                        :cached_indices,
                        :cached_methods,
                        :cached_class_methods,
                        :cached_associations
      after_commit :expire_all
    end
  end

  module ClassMethods
    def model_cache(&block)
      instance_exec &block
    end
  end

end