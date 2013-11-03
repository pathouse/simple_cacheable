module Cacheable
	module Formatter

		class Formatter

			attr_accessor :result, :key_type

			def self.symbolize_args(args)
				args.each do |arg|
					if arg.is_a?(Hash)
						arg.map {|k,v| "#{k}:#{v}"}
					elsif arg.is_a?(Array)
						arg.map {|k,v| "#{k},#{v}"}
					else
						arg.to_s
					end
				end.join("+").to_sym
			end
			

			def initialize(result, key_type)
				@result = result
				@key_type = key_type
			end

			def format(options={})
				if key_blob[:type] == :object || key_blob[:type] == :association
					formatted_result = format_object(result)
				elsif key_blob[:type] == :method || key_blob[:type] == :class_method
					formatted_result = format_method(result, options)
				else
					formatted_result = format_data(result)
				end
			end

			## OBJECT FORMATTING ##

			def format_object(object)
				unless object.nil?
					if object.is_a?(Array)
						object.map { |obj| coder_from_record(obj) }
					else
						coder_from_record(object)
					end
				end
			end

			def coder_from_record(record)
				unless record.nil?
					coder = { :class => record.class }
					record.encode_with(coder)
					coder
				end
			end

			## METHOD FORMATTING ##

			def format_method(result, options)
				if options[:args].nil?
					format_data(result)
				else
					result.each do |arg_key, value|
						result[arg_key] = format_data(value)
					end
				end
			end

			def format_data(result)
				unless result.is_a?(Hash) || result.is_a?(Array)
					return result
				end

				if result.is_a?(Hash) && Interpreter.hash_inspect(result)
					result = format_object(result)
				elsif result[0].is_a?(Hash) && Interpreter.hash_inspect(result[0])
					result.map { |r| format_object(r) }
				end
				result
			end
		end
	end
end


