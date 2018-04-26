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

	def initialize(input : String|IO)
		@token			= Token.new()
		@cursor			= Cursor.new(input)
		@string_pool	= StringPool.new()
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
				#when try_symbol?(expects_key)
			else tokenize_number()
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
			tokenize_string(expects_key)
			return true
		elsif ( test_symbol_start?() )
			tokenize_symbol(expects_key)
			try_reserved?()
			return true
		end
		return false
	end

	private def try_macro?() : Bool
		return false if ( !@cursor.char?('$') )
		tokenize_macro()
		return true
	end

	private def try_reserved?() : Bool
		unexpected_char() if ( !@token.string?() )
		key = @reserved[@token.string_value]?
		return false if ( key.nil? )
		@token.type = key
		return true
	end

	private def try_whitespace?() : Bool
		return false if ( !test_whitespace?() )
		consume_whitespace()
		return true
	end

	private def try_comment?(expects_key : Bool) : Bool
		return false if ( !test_comment_start?() )
		tokenize_comment(expects_key)
		return true
	end


	# Tests

	private def test_whitespace?(cursor : Cursor = @cursor) : Bool
		return false if ( cursor.char?('\n') )
		return ( cursor.char().whitespace?() )
	end

	private def test_seperator?(cursor : Cursor = @cursor) : Bool
		return ( cursor.char?('\n', ':', ';', ',') )
	end

	private def test_symbol_start?(cursor : Cursor = @cursor) : Bool
		return false if cursor.char().number?
		return false if cursor.char?('\\')
		return true
	end

	private def test_symbol?(cursor : Cursor = @cursor, is_key : Bool = false) : Bool
		return false if ( is_key && cursor.char?(':', '=') )
		return ( !cursor.char?('\n', ',', ']', '}', '[', '{') )
		#return ( cursor.char().alphanumeric? || cursor.char?('_', '.', '/', '-') )
	end

	private def test_comment_start?(cursor : Cursor = @cursor) : Bool
		return true if ( cursor.char?('#') )
		return true if ( cursor.char?('/') )
		return false
	end


	# Skipping

	private def skip_whitespace() : Nil
		while ( test_whitespace?() )
			next @cursor.next()
		end
	end


	# Consumption

	private def tokenize_comment(expects_key : Bool = false) : Nil
		case ( @cursor.char() )
			when '#'
				@cursor.buffer_first()
				buffer_line()
				consume_buffer_as_comment()

			when '/'
				@cursor.buffer_first()
				case ( @cursor.char() )
					when '/'
						@cursor.buffer_and_next()
						buffer_line()
						consume_buffer_as_comment()

					when '*'
						@cursor.buffer_and_next()
						while ( !@cursor.char?('/') )
							buffer_until('*')
						end
						@cursor.buffer_and_next()
						consume_buffer_as_comment()

					else
						buffer_symbol(expects_key)
						consume_buffer_as_symbol(expects_key)
				end

			else
				tokenize_symbol()
		end
	end

	private def tokenize_symbol(expects_key : Bool = false) : Nil
		@cursor.buffer_first()
		buffer_symbol(expects_key)
		consume_buffer_as_symbol(expects_key)
	end

	private def tokenize_macro() : Nil
		@cursor.buffer_first()
		buffer_symbol(true)
		consume_buffer_as_macro()
	end

	private def tokenize_string(expects_key : Bool = false) : Nil
		@cursor.buffer.clear()

		while ( char = @cursor.next )
			case char
				when '\0' then raise("Unterminated string")
				when '\\' then @cursor.buffer << consume_string_escape_sequence()
				when '"'
					@cursor.next
					break
				else
					if ( (char.ord == 127) || (char.ord >= 32) || (9 <= char.ord <= 10) )
						@cursor.buffer << char
					else
						unexpected_char()
					end
			end
		end

		@token.reset_as(:string, ( expects_key ) ? @string_pool.get(@cursor.buffer) : @cursor.buffer.to_s())
	end

	private def consume_buffer_as_comment()
		@token.reset_as(:comment, @cursor.buffer.to_s().strip())
	end

	private def consume_buffer_as_string(is_key : Bool = false)
		@token.reset_as(:string, @cursor.buffer.to_s())
	end

	private def consume_buffer_as_symbol(is_key : Bool = false)
		string = @cursor.buffer.to_s().strip
		@token.reset_as(:string, ( is_key ) ? @string_pool.get(string) : string)
	end

	private def consume_buffer_as_macro()
		string = @cursor.buffer.to_s().strip
		@token.reset_as(:macro, @string_pool.get(string))
	end

	private def consume_string_escape_sequence() : Char
		case ( char = @cursor.next() )
			when '\\', '"', '/'	then char
			when 'b'			then '\b'
			when 'f'			then '\f'
			when 'n'			then '\n'
			when 'r'			then '\r'
			when 't'			then '\t'
			when 'u'
				hexnum1 = read_hex_number()
				if ( hexnum1 > 0xD800 && hexnum1 < 0xDBFF )
					raise("Unterminated UTF-16 sequence") if ( @cursor.next != '\\' || @cursor.next != 'u' )
					hexnum2 = read_hex_number()
					(0x10000 | (hexnum1 & 0x3FF) << 10 | (hexnum2 & 0x3FF)).chr
				else
					hexnum1.chr
				end
			else
				raise("Unknown escape char: #{char}")
		end
	end

	private def tokenize_number() : Nil
		@cursor.buffer.clear

		integer = 0_i64
		negative = false
		digits = 0

		if ( @cursor.char?('-') )
			negative = true
			@cursor.buffer_and_next()
		end

		case ( char = @cursor.char )
			when '0'
				@cursor.buffer_and_next()
				case ( @cursor.char() )
					when '.'		then consume_float(negative, integer, digits)
					when 'e', 'E'	then consume_exponent(negative, integer.to_f64, digits)
					when 'x', 'X'	then consume_base(16)
					when 'o', 'O'	then consume_base(8)
					when 'b', 'B'	then consume_base(2)
					else 			@token.reset_as(:int, @cursor.buffer.to_s, 0_i64)
				end
				return
			when '1'..'9'
				digits = 1
				integer = (@cursor.char - '0').to_i64()
				char = @cursor.buffer_and_next()

				buffer_digits() { |char|
					integer *= 10
					integer += char - '0'
					digits += 1
				}

				case ( @cursor.char )
					when '.'		then consume_float(negative, integer, digits)
					when 'e', 'E'	then consume_exponent(negative, integer.to_f64, digits)
					else 			@token.reset_as(:int, @cursor.buffer.to_s, (negative ? -integer : integer))
				end
				return
			else
				unexpected_char()
		end
	end

	private def consume_float(negative, integer, digits)
		divisor = 1_u64
		@cursor.buffer_and_next()

		unexpected_char() if ( !@cursor.char.number? )

		decimal = 0_u64
		buffer_digits() { |char|
			decimal *= 10
			decimal += char - '0'
			divisor *= 10
		}

		float = integer.to_f64 + (decimal.to_f64 / divisor)

		case ( @cursor.char )
			when 'e', 'E' then consume_exponent(negative, float, digits)
			else
				@token.type = :float
				# If there's a chance of overflow, we parse the raw string
				value = ( digits >= 18 ) ? @cursor.buffer.to_s.to_f64 : (negative ? -float : float)
				@token.reset_as(:float, @cursor.buffer.to_s, value)
				return
		end
	end

	private def consume_exponent(negative : Bool, float : Float, digits)
		exponent = 0
		negative_exponent = false
		char = @cursor.buffer_and_next()

		if ( char == '+' )
			char = @cursor.buffer_and_next()
		elsif ( char == '-' )
			char = @cursor.buffer_and_next()
			negative_exponent = true
		end

		unexpected_char() if ( !char.number? )

		buffer_digits() { |char|
			exponent *= 10
			exponent += char - '0'
		}

		exponent = -exponent if ( negative_exponent )
		float *= (10_f64 ** exponent)

		# If there's a chance of overflow, we parse the raw string
		value = ( digits >= 18 ) ? @cursor.buffer.to_s.to_f64 : (negative ? -float : float)
		@token.reset_as(:float, @cursor.buffer.to_s, value)
	end

	private def consume_base(base : Int = 10)
		raise Exception.new("Invalid Base, #{base}...") if ( base != 2 && base != 8 && base != 10 && base != 16 )

		value = 0_i64
		char = @cursor.buffer_and_next()

		if ( base != 16 )
			buffer_digits() { |char|
				value *= base
				value += char - '0'
			}
		else
			buffer_hex() { |char|
				value *= base
				value += char.to_i(16)
			}
		end

		@token.reset_as(:int, @cursor.buffer.to_s, value)
	end

	private def read_hex_number()
		hexnum = 0
		4.times() {
			char = @cursor.next()
			hexnum = (hexnum << 4) | (char.to_i?(16) || raise("Unexpected char in hex number: #{char.inspect}"))
		}
		return hexnum
	end


	# Buffering

	private def buffer_digits(&block)
		char = @cursor.char()
		while ( char.number? )
			yield(char)
			char = @cursor.buffer_and_next()
		end
	end

	private def buffer_hex(&block)
		char = @cursor.char()
		while ( char.hex? )
			yield(char)
			char = @cursor.buffer_and_next()
		end
	end

	private def buffer_upto(&block : Cursor -> Bool) : Nil
		while ( !@cursor.eof?() && !yield(@cursor) )
			next @cursor.buffer_and_next()
		end
	end

	private def buffer_until(&block : Cursor -> Bool) : Nil
		buffer_upto() { |cursor| yield(cursor) }
		@cursor.buffer_and_next() if ( !@cursor.eof?() )
	end

	private def buffer_upto(*chars : Char) : Nil
		return buffer_upto() { |cursor| @cursor.char?(*chars) }
	end

	private def buffer_until(*chars : Char) : Nil
		return buffer_until() { |cursor| @cursor.char?(*chars) }
	end

	private def buffer_line() : Nil
		return buffer_upto('\n')
	end

	private def buffer_symbol(is_key : Bool = false) : Nil
		return buffer_upto() { |cursor| next !test_symbol?(cursor, is_key) }
	end


	# Errors

	private def unexpected_char(char : Char = @cursor.char)
		char = "\\n" if ( char == '\n' )
		char = "\\t" if ( char == '\t' )
		raise("Unexpected char '#{char}'")
	end

	private def raise(msg)
		::raise(ParseException.new(msg, @cursor.location))
	end

end
