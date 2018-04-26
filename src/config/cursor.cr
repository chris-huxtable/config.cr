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


abstract class Config::Cursor

	# Constructors

	def self.new(string : String)
		return StringCursor.new(string)
	end

	def self.new(io : IO)
		return IOCursor.new(io)
	end


	# Initalization

	def initialize()
		super()
		@location	= Location.new()
		#@lookahead	= Queue(Char).new()
		@buffer		= IO::Memory.new()
		@newline	= false
	end


	# Properties

	@lookahead : Char? = nil

	getter location : Location
	getter buffer : IO::Memory

	abstract def char() : Char

	def char?(*chars : Char) : Bool
		cur = char()
		chars.each() { |a_char| return true if ( cur == a_char ) }
		return false
	end

	def peek?(*chars : Char) : Bool
		cur = peek()
		chars.each() { |a_char| return true if ( cur == a_char ) }
		return false
	end

	def eof?() : Bool
		return char?('\0')
	end


	# Movement

	abstract def peek() : Char
	abstract def next() : Char

	def buffer_and_next() : Char
		@buffer << char()
		return self.next()
	end

	def buffer_first() : Char
		@buffer.clear()
		return buffer_and_next()
	end


	# Errors

	private def unexpected_char() : Nil
		raise("Unexpected char '#{self.char()}'")
	end

	private def unexpected_char(char : Char) : Nil
		raise("Unexpected char '#{char}'")
	end

	private def raise(msg) : Nil
		::raise(ParseException.new(msg, @location))
	end

end


class Config::IOCursor < Config::Cursor

	# Initalization

	def initialize(@io : IO)
		super()
		@char = (@io.read_char() || '\0')
	end


	# Properties

	def char() : Char
		return @char
	end


	# Movement

	def peek() : Char
		lookahead = @lookahead
		return lookahead if ( lookahead )
		peek = (@io.read_char() || '\0')
		@lookahead = peek
		return peek
	end

	def next() : Char
		if ( @newline )
			@location.newline()
			@newline = false
		end

		@location.column += 1

		if ( peek = @lookahead )
			@char = peek
			@lookahead = nil
		else
			@char = (@io.read_char() || '\0')
		end

		@newline = true if ( char?('\n') )
		return @char
	end

end


class Config::StringCursor < Config::Cursor

	# Initalization

	def initialize(string : String)
		super()
		@reader = Char::Reader.new(string)
	end


	# Properties

	def char() : Char
		return @reader.current_char
	end


	# Movement

	def peek() : Char
		return '\0' if ( !@reader.has_next? )
		return @reader.peek_next_char()
	end

	def next() : Char
		if ( @newline )
			@location.newline()
			@newline = false
		end

		@location.column += 1

		return '\0' if ( !@reader.has_next? )

		char = @reader.next_char()
		@newline = true if ( char?('\n') )
		return char
	end

end
