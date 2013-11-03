#### NEED TO FIGURE OUT HOW WE'RE KEEPING KEYS AND RESULTS TOGETHER IN MULTI FETCHES
#### ZIP?
module Cacheable
	module CacheFetcher

		class Fetcher

			attr_accessor :object, :klass

			def initialize(options = {})
				@object ||= options[:object]
				@klass = options[:klass] || object.class
			end

			def act_on(*key_blobs, options={} &block)
				if keys.size == 1
					single_fetch(key_blobs.first, options) { yield if block_given? }
				else
					multiple_fetch(key_blobs) { yield if block_given? }
				end
			end

			def single_fetch(key_blob, &block, options)
				result = read_from_cache(key_blob)
				method_args = Formatter.symbolize_args(options[:args]) unless options.empty?
				write? = false

				if result.nil? && block_given?
					result = yield
					write? = true
				elsif method_args && result[method_args].nil? && block_given?
					result[method_args] = yield
					write? = true
				end

				write_to_cache(key_blob, result) if write?
			end

			def multiple_fetch(key_blobs, &block)
				results = read_multi_from_cache(key_blobs)
				key_result_join = key_blobs.zip(results).to_hash
				if results.any(&:nil?)
					if block_given?
						results = yield
						write_multi_to_cache(key_result_join)
					end
				end
			end

			private

			##
			## READING FROM THE CACHE
			##

			def read_from_cache(key_blob)
				result = Rails.cache.read key_blob[:key]
				return result if result.nil?
				inter = Interpreter.new(result, key_blob[:type])
				inter.interpret
			end

			def read_multi_from_cache(key_blobs)
				keys = key_blobs.map { |blob| blob[:key] }
				results = Rails.cache.read_multi(keys)
				return results if results.all?(&:nil?)
				
				types = key_blobs.map { |blob| blob[:type] }
				results.each do |result|
					unless result.nil?
						type = types.pop
						inter = Interpreter.new(result, type)
						inter.interpret
					end
				end
			end

			###
			### WRITING TO THE CACHE
			###

			def write_multi_to_cache(keys_and_results)
				keys_and_results.each do |key, result|
					write_to_cache(key, result)
				end
			end

			def write_to_cache(key_blob, result)
				formatter = Formatter.new(result, key_blob[:type])
				formatted_result = formatter.format
				Rails.cache.write key_blob[:key], formatted_result
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
