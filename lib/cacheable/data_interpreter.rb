module Cacheable
	module DataInterpreter

		class Interpreter

			attr_accessor :result, :key_type

			def self.hash_inspect(hash)
				hash.has_key?(:class) && hash.has_key?('attributes')
			end

			def initialize(result, key_type)
				@result = result
				@key_type = key_type
			end

			def interpret
				if key_type == :object || key_type == :attribute || key_type == :association
					object_parse(result)
				else
					method_parse(result)
				end
			end

			## OBJECT PARSING ##

			def object_parse(result)
				coder = result.dup
				if coder.is_a?(Array)
					coder.map {|obj| record_from_coder(obj)}
				else
					record_from_coder(coder)
				end
			end

			def record_from_coder(coder)
				record = coder[:class].allocate
				record.init_with(coder)
			end

			## METHOD PARSING ## 
			#
			## METHOD STORE FORMATTING
			#
			# { args.to_string.to_symbol => answer } 

			def method_parse(result)
				if result.is_a?(Hash)
					result.each do |k,v|
						result[k] = data_parse(v)
					end
				end
				result
			end

			## DATA PARSING ##

			def data_parse(result)
				unless result.is_a?(Hash) || result.is_a?(Array)
					result
				end
				
				if result.is_a?(Hash) && Interpreter.hash_inspect(result)
					object_parse(result)
				elsif result[0].is_a?(Hash) && Interpreter.hash_inspect(result[0]) 
					result.map { |r| object_parse(r) }
				else
					result
				end
			end
		end
	end
end