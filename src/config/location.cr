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


struct Config::Location

	# Initializer

	def initialize()
		@line	= 1_u32
		@column	= 0_u32
		@size	= 1_u32
	end


	# Properties

	property(line : UInt32)
	property(column : UInt32)
	property(size : UInt32)


	# Utilities

	def newline()
		@line	+= 1_u32
		@column	 = 0_u32
	end

	def to_s(io : IO)
		io << @line.to_s << ":"
		io << @column.to_s << '(' << @size.to_s << ')'
	end

end
