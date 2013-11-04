module Cacheable
	module DataFormatter

		class Formatter

			attr_accessor :result, :key_type

			def self.symbolize_args(args)
				return if args.nil?
				args.map do |arg|
					if arg.is_a?(Hash)
						arg.map {|k,v| "#{k}:#{v}"}.join(",")
					elsif arg.is_a?(Array)
						arg.join(",")
					else
						arg.to_s.split(" ").join("_")
					end
				end.join("+").to_sym
			end

			def self.escape_punctuation(string)
    		string.sub(/\?\Z/, '_query').sub(/!\Z/, '_bang')
 			end
			
			def initialize(result, key_type)
				@result = result
				@key_type = key_type
			end

			def format
				if key_type == :object || key_type == :association || key_type == :attribute
					formatted_result = format_object(result)
				else
					formatted_result = format_method(result)
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

			def format_method(result)
				unless result.is_a?(Hash)
					format_data(result)
				else
					result.each do |arg_key, value|
						result[arg_key] = format_data(value)
					end
				end
			end

			def format_data(result)
				unless result.is_a?(ActiveRecord::Base) || result.is_a?(Array)
					return result
				end

				if result.is_a?(ActiveRecord::Base)
					result = format_object(result)
				elsif result[0].is_a?(ActiveRecord::Base)
					result.map { |r| format_object(r) }
				end
				result
			end
		end
	end
end


