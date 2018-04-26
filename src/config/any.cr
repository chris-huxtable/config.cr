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


struct Config::Any

	include Enumerable(self)

	# Returns the raw underlying value, a `Config::Type`.
	getter raw : Config::Type

	# Creates a `Config::Any` that wraps the given `Config::Type`.
	def initialize(@raw : Config::Type)
	end

	# Assumes the underlying value is an `Array` or `Hash` and returns its size.
	# Raises if the underlying value is not an `Array` or `Hash`.
	def size() : Int
		object = @raw
		return object.size if ( object.is_a?(Array) || object.is_a?(Hash) )
		raise "Expected Array or Hash for #size, not #{object.class}"
	end

	# Assumes the underlying value is an `Array` or `Hash` and returns its size.
	# Raises if the underlying value is not an `Array` or `Hash`.
	def size?() : Int?
		object = @raw
		return object.size if ( object.is_a?(Array) || object.is_a?(Hash) )
		return nil
	end

	# Assumes the underlying value is an `Array` and returns the element
	# at the given index.
	# Raises if the underlying value is not an `Array`.
	def [](index : Int) : Any
		case ( object = @raw )
			when Array then Any.new(object[index])
			else raise "Expected Array for #[](index : Int), not #{object.class}"
		end
	end

	# Assumes the underlying value is an `Array` and returns the element
	# at the given index, or `nil` if out of bounds.
	# Raises if the underlying value is not an `Array`.
	def []?(index : Int) : Any?
		case ( object = @raw )
			when Array
				value = object[index]?
				value.nil? ? nil : Any.new(value)
			else
				raise "Expected Array for #[]?(index : Int), not #{object.class}"
		end
	end

	# Assumes the underlying value is a `Hash` and returns the element
	# with the given key.
	# Raises if the underlying value is not a `Hash`.
	def [](key : String) : Any
		case ( object = @raw )
			when Hash then Any.new(object[key])
			else raise "Expected Hash for #[](key : String), not #{object.class}"
		end
	end

	# Assumes the underlying value is a `Hash` and returns the element
	# with the given key, or `nil` if the key is not present.
	# Raises if the underlying value is not a `Hash`.
	def []?(key : String) : Any?
		case ( object = @raw )
			when Hash
				value = object[key]?
				value.nil? ? nil : Any.new(value)
			else
				raise "Expected Hash for #[]?(key : String), not #{object.class}"
		end
	end

	# Assumes the underlying value is an `Array` or `Hash` and yields each
	# of the elements or key/values, always as `Config::Any`.
	# Raises if the underlying value is not an `Array` or `Hash`.
	def each()
		case ( object = @raw )
			when Array then object.each { |elem| yield Any.new(elem), Any.new(nil) }
			when Hash then object.each { |key, value| yield Any.new(key), Any.new(value) }
			else raise "Expected Array or Hash for #each, not #{object.class}"
		end
	end

	{% for name, kind in {s: String, h: "Hash(String, Any)", a: "Array(Any)",
						  i: Int32, i64: Int64, i128: Int128,
						  f: Float64, f32: Float32,
						  bool: Bool} %}
		# Checks that the underlying value is `{{ kind.id }}`, and returns its value.
		# Raises otherwise.
		def as_{{ name.id }} : {{ kind.id }}
			{% if name == :i %}\
				return @raw.as(Int).to_i
			{% elsif name == :i64 %}\
				return @raw.as(Int).to_i64
			{% elsif name == :f %}\
				return @raw.as(Float).to_f
			{% elsif name == :f32 %}\
				return @raw.as(Float).to_f32
			{% elsif name == :a %}\
				return @raw.as(Array).map() { |elm| Any.new(elm) }
			{% elsif name == :h %}\
				hash = @raw.as(Hash)
				hash_new = Hash(String, Any).new(nil, hash.size)
				hash.each() { |k,v| hash_new[k] = Any.new(v) }
				return hash_new
			{% else %}\
				return @raw.as({{ kind.id }})
			{% end %}\
		end

		# Checks that the underlying value is `{{ kind.id }}`, and returns its value.
		# Returns `nil` otherwise.
		def as_{{ name.id }}? : {{ kind.id }}?
			return as_{{ name.id }} if @raw.is_a?\
			{% if name == :i || name == :i64 %}\
				(Int)
			{% elsif name == :f ||  name == :f32 %}\
				(Float)
			{% elsif name == :a %}\
				(Array)
			{% elsif name == :h %}\
				(Hash)
			{% else %}\
				({{ kind.id }})
			{% end %}\
			{% if name == :f32 %}\
				return as_{{ name.id }} if @raw.is_a?(Float64)
			{% end %}\
			return nil
		end

		# Assumes the underlying value is a `Hash` and returns the element
		# with the given key as a `{{ kind.id }}`.
		# Raises otherwise.
		def as_{{ name.id }}(key : String) : {{ kind.id }}
			return self[key].as_{{ name.id }}()
		end

		# Assumes the underlying value is a `Hash` and returns the element
		# with the given key as a `{{ kind.id }}`.
		# Returns `nil` otherwise.
		def as_{{ name.id }}?(key : String) : {{ kind.id }}?
			value = self[key]?
			return nil if ( !value )
			return value.as_{{ name.id }}?()
		end

		# Assumes the underlying value is an `Array` and returns the element
		# with the given key as a `{{ kind.id }}`.
		# Raises otherwise.
		def as_{{ name.id }}(index : Int)
			return self[index].as_{{ name.id }}()
		end

		# Assumes the underlying value is an `Array` and returns the element
		# with the given key as a `{{ kind.id }}`.
		# Returns `nil` otherwise.
		def as_{{ name.id }}?(index : Int)
			value = self[index]?
			return nil if ( !value )
			return value.as_{{ name.id }}?()
		end

	{% end %}

	# Checks that the underlying value is `Nil`, and returns `nil`.
	# Raises otherwise.
	def as_nil : Nil
		return @raw.as(Nil)
	end

	# Assumes the underlying value is an `Hash` and checks that the
	# elements underlying value is `Nil`, and returns `nil`.
	# Raises otherwise.
	def as_nil(key : String) : Nil
		return self[key].as_nil()
	end


	# :nodoc:
	def inspect(io)
		return @raw.inspect(io)
	end

	# :nodoc:
	def to_s(io)
		return @raw.to_s(io)
	end

	# :nodoc:
	def pretty_print(pp)
		return @raw.pretty_print(pp)
	end

	# Returns `true` if both `self` and *other*'s raw object are equal.
	def ==(other : Config::Any)
		return ( raw == other.raw )
	end

	# Returns `true` if the raw object is equal to *other*.
	def ==(other)
		return ( raw == other )
	end

	# See `Object#hash(hasher)`
	def_hash raw

	# :nodoc:
	def to_json(json : JSON::Builder)
		return raw.to_json(json)
	end
end

class Object
	def ===(other : Config::Any)
		return ( self === other.raw )
	end
end

class Regex
	def ===(other : Config::Any)
		value = ( self === other.raw )
		$~ = $~
		value
	end
end