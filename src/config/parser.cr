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

require "./lexer"


class Config::Parser

	property max_nesting : UInt16 = 32_u16
	property macros : Hash(String, Any) = Hash(String, Any).new()


	# Initialization

	def initialize(serial : String|IO)
		@lexer = Config::Lexer.new(serial)
		@nest = 0
	end


	# Parsing

	def parse() : Hash(String, Type)
		next_token(true)
		config = Hash(String, Type).new()

		nest(:eof) {
			expect_type(:string, :macro)

			key = token.string_value()
			is_macro = token.type?(:macro)

			next_token()
			expect_type(:":", :"=")

			is_assignment = token.type?(:"=")
			next_token()

			if ( is_macro )
				if ( is_assignment )
					@macros[key] = Any.new(parse_value())
					next
				end

				key = @macros[key].as_s?()
				parse_exception("expected token 'string'") if ( !key )
			end

			config[key] = parse_value()
		}

		expect_type(:eof)
		return config
	end

	private def parse_value() : Type
		return case ( token.type )
			when :macro			then parse_macro()
			when :int			then next_token_passthrough(token.int_value)
			when :float			then next_token_passthrough(token.float_value)
			when :string		then next_token_passthrough(token.string_value)
			when :null			then next_token_passthrough(nil)
			when :true			then next_token_passthrough(true)
			when :false			then next_token_passthrough(false)
			when :"["			then parse_array()
			when :"{"			then parse_object()
			else unexpected_type()
		end
	end

	private def parse_array() : Array(Type)
		next_token()
		array = Array(Type).new()

		nest(:"]") {
			array << parse_value()
			expect_type(:",", :"\n", :"]")
		}

		next_token()
		return array
	end

	private def parse_object() : Hash(String, Type)
		next_token(true)
		object = Hash(String, Type).new()

		nest(:"}") {
			expect_type(:string)
			key = token.string_value()

			next_token()
			expect_type(:":")
			next_token()

			object[key] = parse_value()
			expect_type(:",", :"\n", :"}")
		}

		next_token()
		return object
	end

	private def parse_macro() : Type
		value = @macros[token.string_value]?
		parse_exception("macro '#{token.string_value}' not previously defined.") if ( !value )

		next_token()
		return value.raw
	end

	private def skip_seporators()
		while ( !token.eof? && token.type?(:",", :"\n") )
			next_token(true)
		end
	end


	# Tokens

	private delegate(token, to: @lexer)
	private delegate(next_token, to: @lexer)

	private def next_token_passthrough(value) : Type
		next_token()
		return value
	end


	# Nesting

	private def nest(close : Symbol) : Nil
		@nest += 1
		parse_exception("Nesting too deep. Current depth: #{@nest}") if ( @nest > @max_nesting )
		while ( !token.type?(close) )
			skip_seporators()
			break if ( token.type?(close) )

			yield()
		end
		@nest -= 1
	end


	# Errors

	private def expect_type(*expected : Symbol) : Nil
		return if ( token.type?(*expected) )
		expected_type(*expected)
	end

	private def expected_type(*expected : Symbol) : Nil
		expected = expected.to_a.map(){ |e| "'#{Token.type_string(e)}'" }.join(", ")
		parse_exception("expected token: #{expected}, was: '#{token().type_string}'")
	end

	private def unexpected_type() : Nil
		parse_exception("unexpected token '#{token().type_string}'")
	end

	private def parse_exception(msg : String) : Nil
		raise(ParseException.new(msg, token.location))
	end

end
