module Cacheable
	module CacheFetcher

		class Fetcher

			attr_accessor :object, :klass

			def initialize(options = {})
				@object ||= options[:object]
				@klass = options[:klass] || object.class
			end

			def act_on(*keys)
				if keys.size == 1
					single_fetch(keys.first)
				else
					multiple_fetch(keys)
				end
			end

			
			protected

			def single_fetch(key)
				
			end

			def multiple_fetch(*keys)
			end


		end
	end
end
