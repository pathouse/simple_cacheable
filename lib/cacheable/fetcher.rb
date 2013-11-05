module Cacheable
	module CacheFetcher

		class Fetcher

			attr_accessor :object, :klass

			def initialize(options = {})
				@object ||= options[:object]
				@klass = options[:klass] || object.class
			end

			def act_on(key_blob, options={}, &block)
				unless key_blob.is_a?(Array)
					single_fetch(key_blob, options) { yield if block_given? }
				else
					multiple_fetch(key_blob) { yield if block_given? }
				end
			end

			def single_fetch(key_blob, options, &block)
				result = read_from_cache(key_blob)
				method_args = Cacheable::Formatter.symbolize_args(options[:args])
				should_write = false

				if block_given?
					if method_args != :no_args && (result.nil? || result[method_args].nil?)
						result ||= {}
						result[method_args] = yield
						should_write = true
					elsif method_args == :no_args && result.nil?
						result = yield
						should_write = true
					end
				end

				write_to_cache(key_blob, result) if should_write
				
				result = (method_args == :no_args) ? result : result[method_args]
			end

			def multiple_fetch(key_blobs, &block)
				results = read_multi_from_cache(key_blobs)
				key_result_join = key_blobs.zip(results).to_hash
				if results.any(&:nil?)
					if block_given?
						key_result_join = yield(key_result_join)
						write_multi_to_cache(key_result_join)
					end
				end
				results
			end

			##
			## READING FROM THE CACHE
			##

			def read_from_cache(key_blob)
				result = Rails.cache.read key_blob[:key]
				return result if result.nil?
				inter = Cacheable::Interpreter.new(result, key_blob[:type])
				inter.interpret
			end

			def read_multi_from_cache(key_blobs)
				keys = key_blobs.map { |blob| blob[:key] }
				results = Rails.cache.read_multi(*keys)
				return results if results.all?(&:nil?)

				results.map do |key, result|
					type = key_blobs.select {|kb| kb.has_value?(key) }.first[:type]
					Cacheable::Interpreter.new(result, type).interpret
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
				formatter = Cacheable::Formatter.new(result, key_blob[:type])
				formatted_result = formatter.format
				Rails.cache.write key_blob[:key], formatted_result
			end
		end
	end
end