# Copyright (c) 2018 Christian Huxtable <chris@huxtable.ca>.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


class Config::Token

	@string_value : String?
	@raw_value : Int64|Float64|Nil

	# Initialization

	def initialize()
		@type = :eof
		@location = Location.new()

		@string_value = nil
		@raw_value = nil
	end


	# Properties

	def string_value() : String
		value = @string_value
		return value if ( value )
		return @type.to_s
	end

	property raw_value : Int64|Float64|Nil

	def reset_as(type : Symbol, string_value : String? = nil, raw_value : Int64|Float64|Nil = nil) : Nil
		@type = type
		@string_value = string_value
		@raw_value = raw_value

		if ( string_value )
			location.size = string_value.size.to_u32
		elsif ( type != :eof )
			location.size = type.to_s.size.to_u32
		else
			location.size = 0_u32
		end
	end


	{% for key, value in {int: Int64, float: Float64} %}
		def {{key.id}}_value=(other : {{value.id}}) : Nil
			@raw_value = other
		end

		def {{key.id}}_value() : {{value.id}}
			raise("Invalid raw type; was nil, expected {{ value.id }}.") if ( @raw_value.nil? )
			return @raw_value.as({{value.id}})
		end
	{% end %}


	# Type

	property type : Symbol

	def type?(*types)
		types.each() { |a_type| return true if ( @type == a_type ) }
		return false
	end

	{% for name, index in ["int", "float", "string", "eof"] %}
		def {{name.id}}?()
			return ( @type == :{{name.id}} )
		end
	{% end %}


	# Location

	property location : Location

	delegate(line, to: @location)
	delegate(column, to: @location)


	# Stringification

	def to_s(io)
		case ( @type )
			when :int			then int_value.to_s(io)
			when :float			then float_value.to_s(io)
			when :string		then @string_value.to_s(io)
			else @type.to_s(io)
		end
	end

	def type_string() : String
		return self.class.type_string(type)
	end

	def self.type_string(type : Symbol) : String
		return "\\t" if ( type == :"\t" )
		return "\\n" if ( type == :"\n" )
		return type.to_s
	end

end
