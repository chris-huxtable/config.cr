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

require "string_pool"


class Config::Lexer

	# Initializer

	def initialize(input : String|IO, macros : Macros = Macros.new())
		@token			= Token.new()
		@string_pool	= StringPool.new()

		@cursor			= Cursor.new(input)
		@buffer			= Buffer.new(@cursor)
		@tokenize		= Tokenizer.new(@cursor, @buffer, @token, @string_pool, macros)

		@reserved		= {"true" => :true, "false" => :false, "null" => :null}
	end


	# Properties

	getter token : Token


	# Next Token

	def next_token(expects_key : Bool = false, comment : Bool = false, whitespace : Bool = false) : Token
		skip_whitespace()

		@token.location = @cursor.location

		case
			when try_comment?(expects_key)
			when try_macro?()
			when try_special?()
			when try_string?(expects_key)
			else @tokenize.number()
		end

		if ( @token.type?(:comment) && !comment )
			next_token(expects_key, comment)
		end

		return @token
	end


	# Try's

	private def try_special?() : Bool
		case ( @cursor.char() )
			when '\0'	then @token.reset_as(:eof)
			when '{'	then @token.reset_as(:"{")
			when '}'	then @token.reset_as(:"}")
			when '['	then @token.reset_as(:"[")
			when ']'	then @token.reset_as(:"]")
			when '\n'	then @token.reset_as(:"\n")
			when ','	then @token.reset_as(:",")
			when ':'	then @token.reset_as(:":")
			when '='	then @token.reset_as(:"=")
			else return false
		end

		@cursor.next()
		return true
	end

	private def try_string?(expects_key : Bool) : Bool
		if ( @cursor.char?('"') )
			@tokenize.string(expects_key)
			return true
		elsif ( Test.symbol_start?(@cursor) )
			@tokenize.symbol(expects_key)
			try_reserved?()
			return true
		end
		return false
	end

	private def try_macro?() : Bool
		return false if ( !@cursor.char?('$') )
		@tokenize.macro()
		return true
	end

	private def try_reserved?() : Bool
		unexpected_char() if ( !@token.string?() )
		key = @reserved[@token.string_value]?
		return false if ( key.nil? )
		@token.type = key
		return true
	end

	private def try_comment?(expects_key : Bool) : Bool
		return false if ( !Test.comment_start?(@cursor) )
		@tokenize.comment(expects_key)
		return true
	end


	# Mark: - Skipping

	private def skip_whitespace() : Nil
		while ( Test.whitespace?(@cursor) )
			next @cursor.next()
		end
	end


	# MARK: - Errors

	private def unexpected_char(char : Char = @cursor.char, location = @cursor.location)
		char = "\\n" if ( char == '\n' )
		char = "\\t" if ( char == '\t' )
		raise ParseException.new("Unexpected char '#{char}'", location)
	end


	# MARK: - Tests

	private module Test

		private macro cursor_char(name)
			# ditto
			def self.{{ name }}(cursor : Cursor) : Bool
				return {{ name }}(cursor.char)
			end
		end

		# Tests if the character is valid whitespace
		def self.whitespace?(char : Char) : Bool
			return false if ( char == '\n' )
			return ( char.whitespace?() )
		end
		cursor_char(whitespace?)

		# Tests if the character is a valid seperator
		def self.seperator?(char : Char) : Bool
			return true if ( char == '\n' )
			return true if ( char == ':' )
			return true if ( char == ';' )
			return true if ( char == ',' )
			return false
		end
		cursor_char(seperator?)

		# Tests if the character is valid at the start of a symbol
		def self.symbol_start?(char : Char) : Bool
			return false if ( char.number? )
			return false if ( char == '\\' )
			return true
		end
		cursor_char(symbol_start?)

		# Tests if the character is valid in a symbol
		def self.symbol?(char : Char, is_key : Bool = false) : Bool
			return false if ( is_key && ( char == ':' || char == '=' ) )
			return false if ( char == '\n' )
			return false if ( char == ',' )
			return false if ( char == ']' )
			return false if ( char == '}' )
			return false if ( char == '[' )
			return false if ( char == '{' )
			return false if ( char == '"' )
			return false if ( char == Char::ZERO )
			return true
		end

		# ditto
		def self.symbol?(cursor : Cursor, is_key : Bool = false) : Bool
			return symbol?(cursor.char, is_key)
		end

		# Tests if the character is valid at the start of a comment
		def self.comment_start?(char : Char) : Bool
			return true if ( char == '#' )
			return true if ( char == '/' )
			return false
		end
		cursor_char(comment_start?)

	end


	private class Buffer

		def self.new(cursor : Cursor, &block : Buffer -> Nil) : String
			buffer = new(cursor)
			yield(buffer)
			return buffer.to_s
		end


		# MARK: - Initalization

		def initialize(@cursor : Cursor)
			@buffer = IO::Memory.new()
		end


		# MARK: - Mutators

		def clear() : Nil
			@buffer.clear
		end

		def next() : Char
			@buffer << @cursor.char()
			return @cursor.next()
		end

		def next?() : Char?
			@buffer << @cursor.char()
			return @cursor.next?()
		end

		def <<(value : Char|String) : self
			@buffer << value
			return self
		end


		# MARK: - Utilities

		def digits(&block : Char -> Nil) : Nil
			char = @cursor.char?()
			while ( char && char.number? )
				yield(char)
				char = self.next()
			end
		end

		def hex_digits(&block : Char -> Nil) : Nil
			char = @cursor.char?()
			while ( char && char.hex? )
				yield(char)
				char = self.next()
			end
		end

		# Buffers until a newline character is found
		def line() : Nil
			return self.until('\n')
		end

		# Buffers the characters while block yields `true`
		def while(&block : Char -> Bool) : Nil
			while ( !@cursor.eof?() )
				break if ( !yield(@cursor.char) )
				next self.next()
			end
		end

		# Buffers until one of the provided characters is met
		def until(*chars : Char) : Nil
			while ( !@cursor.eof?() )
				break if ( @cursor.char?(*chars) )
				next self.next()
			end
		end

		# Buffers upto, but not including, where the block yields `true`
		def upto(&block : Char -> Bool) : Nil
			while ( @cursor.has_more?() )
				if ( yield(@cursor.peek()) )
					self << @cursor.char
					break
				end
				next self.next()
			end
		end

		# Buffers upto, but not including, one of the provided characters
		def upto(*chars : Char) : Nil
			while ( @cursor.has_more?() )
				if ( yield(@cursor.peek?(chars)) )
					self << @cursor.char
					break
				end
				next self.next()
			end
		end


		# MARK: - Complex Entries

		def symbol(is_key : Bool = false, limit : UInt32? = nil) : Nil
			return self.while() { |char| next Test.symbol?(char, is_key) }
		end

		def escape_sequence() : Nil
			case ( char = @cursor.next() )
				when '\\', '"', '/', '$', '#'	then @buffer << char
				when 'b'						then @buffer << '\b'
				when 'f'						then @buffer << '\f'
				when 'n'						then @buffer << '\n'
				when 'r'						then @buffer << '\r'
				when 't'						then @buffer << '\t'
				when 'u'						then @buffer << read_hex_number().chr
				else							raise("Unknown escape char: #{char}")
			end
		end

		private def read_hex_number()
			hexnum = 0
			4.times() {
				char = @cursor.next()
				hexnum = (hexnum << 4) | (char.to_i?(16) || unexpected_char())
			}
			return hexnum
		end


		# MARK: - Stringification

		def to_s(io : IO)
			@buffer.to_s(io)
		end


		# MARK: - Errors

		private def unexpected_char(char : Char = @cursor.char, location = @cursor.location) : Nil
			raise ParseException.new("Unexpected char #{char.inspect}", location)
		end

		private def limit_reached(char : Char = @cursor.char, location = @cursor.location) : Nil
			raise ParseException.new("Limit reached #{char.inspect}", location)
		end

		private def raise(msg)
			::raise(ParseException.new(msg, @cursor.location))
		end

	end


	private class Tokenizer

		# MARK: - Initalization

		def initialize(@cursor : Cursor, @buffer : Buffer, @token : Token, @pool : StringPool, @macros :  Macros)
		end

		protected def reset_token(key : Symbol, *, raw = nil, strip : Bool = false, pool : Bool = false) : Nil
			string = @buffer.to_s
			string = string.strip if ( strip )
			string = @pool.get(string) if ( pool )

			@token.reset_as(key, string, raw)
			@buffer.clear
		end


		# MARK: - Tokenizers

		def macro() : Nil
			unexpected_char() if ( !@cursor.char?('$') )
			@buffer.clear()
			@buffer.next()

			@buffer.symbol(true)
			reset_token(:macro, strip: true, pool: true)
		end

		def symbol(expects_key : Bool = false) : Nil
			@buffer.clear()
			@buffer.next()

			@buffer.symbol(expects_key)
			reset_token(:string, strip: true, pool: true)
		end

		def string(expects_key : Bool = false) : Nil
			@buffer.clear()

			loop do
				case char = @cursor.next?
					when nil	then raise("Unterminated string #{char}")
					when '\\'	then @buffer.escape_sequence()
					when '$'	then string_macro()
					when '"'
						@cursor.next
						break

					else
						if ( (char.ord == 127) || (char.ord >= 32) || (9 <= char.ord <= 10) )
							@buffer << char
						else
							unexpected_char()
						end
				end
			end

			reset_token(:string, pool: expects_key)
		end

		def string_macro()
			name = Buffer.new(@cursor) { |buffer|
				buffer.next()

				if ( @cursor.char?('{') )
					@cursor.next
					buffer.while() { |char|
						next true if Test.symbol?(char)
						next false if char == '}'
						unexpected_char()
					}
				else
					buffer.upto() { |char|
						next false if Test.symbol?(char)
						next true
					}
				end
			}

			macro_value = @macros[name]?
			raise("missing macro #{name.inspect}") if ( !macro_value )
			string = macro_value.as_s?()
			raise("expected macro, #{name.inspect}, to be a string") if ( !string )

			@buffer << string
		end

		def comment(expects_key : Bool = false) : Nil
			case ( @cursor.char() )
				when '#'
					@buffer.clear()
					@buffer.next()
					comment_line()

				when '/'
					@buffer.clear()
					@buffer.next()

					case ( @cursor.char() )
						when '/'
							@buffer.next()
							comment_line()

						when '*'
							@buffer.next()
							comment_block()

						else
							@buffer.symbol(expects_key)
							reset_token(:symbol, pool: expects_key)
							return
					end

				else
					symbol(expects_key)
			end
		end

		protected def comment_line() : Nil
			@buffer.line()
			reset_token(:comment, strip: true)
		end

		protected def comment_block() : Nil
			while ( !@cursor.char?('/') )
				@buffer.until('*')
				@buffer.next() if ( !@cursor.eof?() )
			end

			@buffer.next()
			reset_token(:comment, strip: true)
		end

		def number() : Nil
			@buffer.clear()

			negative = false

			if ( @cursor.char?('-') )
				negative = true
				@buffer.next()
			end

			case ( char = @cursor.char )
				when '0'
					@buffer.next()
					case ( @cursor.char() )
						when '.'		then number_float(negative: negative)
						when 'e', 'E'	then number_exponent(negative: negative)
						when 'x', 'X'	then number_integer(base: 16, skip_first: 1)
						when 'o', 'O'	then number_integer(base: 8, skip_first: 1)
						when 'b', 'B'	then number_integer(base: 2, skip_first: 1)
						else			number_integer(base: 10)
					end
					return

				when '1'..'9'
					value = char.to_i64()
					@buffer.next()

					@buffer.digits() { |char|
						value *= 10
						value += char - '0'
					}

					case ( @cursor.char() )
						when '.'		then number_float(value: value, negative: negative)
						when 'e', 'E'	then number_exponent(value: value, negative: negative)
						else			number_integer(value: value, base: 10, negative: negative )
					end
					return

				else
					unexpected_char()
			end
		end


		# MARK: - Utilities

		protected def number_integer(*, value : Int64 = 0_i64, base : Int = 10, negative : Bool = false, skip_first : Int = 0) : Nil
			raise Exception.new("Invalid Base, #{base}...") if ( base != 2 && base != 8 && base != 10 && base != 16 )

			skip_first.times() { @buffer.next() }

			if ( base != 16 )
				@buffer.digits() { |char|
					value *= base
					value += char - '0'
				}
			else
				@buffer.hex_digits() { |char|
					value = value << 4
					value += char.to_i(16)
				}
			end

			reset_token(:int, raw: value)
		end

		protected def number_float(*, value : Int|Float = 0_f64, negative : Bool = false) : Nil
			divisor = 1_u64
			@buffer.next()

			unexpected_char() if ( !@cursor.char.number? )

			decimal = 0_u64
			@buffer.digits() { |char|
				decimal *= 10
				decimal += char - '0'
				divisor *= 10
			}

			float = value.to_f64 + (decimal.to_f64 / divisor)

			case ( @cursor.char )
				when 'e', 'E' then number_exponent(value: float, negative: negative)
				else
					# If there's a chance of overflow, we parse the raw string
					# TODO: Check Overflow
					#value = ( float >= 18 ) ? @buffer.to_s.to_f64 : (negative ? -float : float)
					float = (negative ? -float : float)
					reset_token(:float, raw: float)
					return
			end
		end

		protected def number_exponent(*, value : Int|Float = 0_f64, negative : Bool = false) : Nil
			value = value.to_f64

			exponent = 0
			negative_exponent = false
			char = @buffer.next()

			if ( char == '+' )
				char = @buffer.next()
			elsif ( char == '-' )
				char = @buffer.next()
				negative_exponent = true
			end

			unexpected_char() if ( !char.number? )

			@buffer.digits() { |char|
				exponent *= 10
				exponent += char - '0'
			}

			exponent = -exponent if ( negative_exponent )
			value *= (10_f64 ** exponent)

			# If there's a chance of overflow, we parse the raw string
			# TODO: Check overflow
			#value = ( digits >= 18 ) ? @buffer.to_s.to_f64 : (negative ? -float : float)
			reset_token(:float, raw: (negative ? -value : value))
		end


		# MARK: - Errors

		private def unexpected_char(char : Char = @cursor.char, location = @cursor.location) : Nil
			raise ParseException.new("Unexpected char #{char.inspect}", location)
		end

		private def raise(msg)
			::raise(ParseException.new(msg, @cursor.location))
		end

	end

end
