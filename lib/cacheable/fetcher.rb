module Cacheable
	module CacheFetcher

		class Fetcher

			attr_accessor :object, :klass

			def initialize(options = {})
				@object ||= options[:object]
				@klass = options[:klass] || object.class
			end

			def act_on(*keys, &block)
				if keys.size == 1
					single_fetch(keys.first) { yield if block_given? }
				else
					multiple_fetch(keys) { yield if block_given? }
				end
			end

			
			protected

			def single_fetch(key, &block)
				result = read_from_cache(key)
				if result.nil?
					if block_given?
						yield
						write_to_cache(key, result)
					end
				end
			end

			def multiple_fetch(keys, &block)
				results = read_multi_from_cache(keys)
				if results.any(&:nil?)
					if block_given?
						yield
						write_multi_to_cache(keys, results)
					end
				end
			end
		end
	end
end

# OLD STUFF

module Cacheable
	module ModelFetch

		def fetch(key, &block)
			
			result = read_from_cache(key)

			if result.nil?
				if block_given?
					result = yield
					write_to_cache(key, result)
				end
			end
			result
		end

		def coder_from_record(record)
			unless record.nil?
				coder = { :class => record.class }
				record.encode_with(coder)
				coder
			end
		end

		def record_from_coder(coder)
			record = coder[:class].allocate
			record.init_with(coder)
		end

		def write_to_cache(key, value)
			if value.respond_to?(:to_a)
				value = value.to_a
				coder = value.map {|obj| coder_from_record(obj) }
			else
				coder = coder_from_record(value)
			end

			Rails.cache.write(key, coder)
			coder
		end

		def read_from_cache(key)
			coder = Rails.cache.read(key)
			return nil if coder.nil?
			
			unless coder.is_a?(Array)
				record_from_coder(coder)
			else
				coder.map { |obj| record_from_coder(obj) }
			end
		end
	end
end
