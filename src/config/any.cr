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

	alias KeyTypes = String|Int::Primitive

	# Returns the raw underlying value, a `Config::Type`.
	getter raw : Config::Type

	# Creates a `Config::Any` that wraps the given `Config::Type`.
	def initialize(@raw : Config::Type)
	end

	# Assumes the underlying value is an `Array`, `Hash`, or `String` and returns
	# its size.
	#
	# Raises if the underlying value is not an `Array`, `Hash`, or `String`.
	def size() : Int
		raw = @raw
		return raw.size if ( raw.is_a?(Array(Config::Type)|Hash(String, Config::Type)|String) )
		raise "Expected Array, Hash, or String for #size, not #{raw.class}"
	end

	# Assumes the underlying value is an `Array`, `Hash`, or `String` and returns
	# its size.
	#
	# Raises if the underlying value is not an `Array`, `Hash`, or `String`.
	def size?() : Int32?
		raw = @raw
		return raw.size if ( raw.is_a?(Array(Config::Type)|Hash(String, Config::Type)|String) )
		return nil
	end

	# Assumes the underlying value is an `Array` and returns the element at the
	# given index.
	#
	# Raises if the underlying value is not an `Array`.
	def [](index : Int::Primitive) : Any
		object = @raw
		return Any.new(object[index]) if ( object.is_a?(Array) )
		raise "Expected Array for #[](index : Int), not #{object.class}"
	end

	# Assumes the underlying value is an `Array` and returns the element at the
	# given index, or `nil` if out of bounds.
	#
	# Raises if the underlying value is not an `Array`.
	def []?(index : Int::Primitive) : Any?
		object = @raw
		raise "Expected Array for #[]?(index : Int), not #{object.class}" if ( !object.is_a?(Array) )
		value = object[index]?
		return ( value.nil? ) ? nil : Any.new(value)
	end

	# Assumes the underlying value is a `Hash` and returns the element with the
	# given key.
	#
	# Raises if the underlying value is not a `Hash`.
	def [](key : String) : Any
		object = @raw
		return Any.new(object[key]) if ( object.is_a?(Hash) )
		raise "Expected Hash for #[](key : String), not #{object.class}"
	end

	# Assumes the underlying value is a `Hash` and returns the element with the
	# given key, or `nil` if the key is not present.
	#
	# Raises if the underlying value is not a `Hash`.
	def []?(key : String) : Any?
		object = @raw
		raise "Expected Hash for #[]?(key : String), not #{object.class}" if ( !object.is_a?(Hash) )
		value = object[key]?
		return ( value.nil? ) ? nil : Any.new(value)
	end

	# Extracts the nested value specified by the sequence of path keys by calling
	# dig at each step, raising if any intermediate step fails.
	def dig(*path : KeyTypes) : Any
		return self[path[0]] if ( path.size == 1 )

		current = self
		idx = 0
		last = path.size - 1
		while ( idx <= last )
			current = current[path[idx]]
			return current if idx >= last
			idx += 1
		end

		raise "Not Found"
	end

	# Extracts the nested value specified by the sequence of path keys by calling
	# dig at each step, returning `nil` if any intermediate step is `nil`.
	def dig?(*path : KeyTypes) : Any?
		return self[path[0]]? if ( path.size == 1 )

		current = self
		idx = 0
		last = path.size - 1
		while ( idx <= last )
			current = current[path[idx]]?
			return nil if !current
			return current if idx >= last
			idx += 1
		end

		return nil
	end

	# Assumes the underlying value is an `Array` or `Hash` and yields each
	# of the elements or key/values, always as `Config::Any`.
	# Raises if the underlying value is not an `Array` or `Hash`.
	def each(&block : Any, Any? -> _)
		case ( object = @raw )
			when Array then object.each { |elem| yield Any.new(elem), Any.new(nil) }
			when Hash then object.each { |key, value| yield Any.new(key), Any.new(value) }
			else raise "Expected Array or Hash for #each, not #{object.class}"
		end
	end

	def each(&block : Any -> _)
		case ( object = @raw )
			when Array then object.each { |elem| yield Any.new(elem) }
				#when Hash then object.each { |key, value| yield Any.new(key), Any.new(value) }
			else raise "Expected Array or Hash for #each, not #{object.class}"
		end
	end

	# Returns a `Bool` indicating if the value at the key is `nil`.
	def is_nil? : Bool
		return @raw.is_a?(Nil)
	end

	# Assumes the underlying value is indexable and returns a `Bool` that indicates
	# if the element at the given paths underlying value is `Nil`.
	#
	# Raises if nothing exists at path.
	def is_nil?(*path : KeyTypes) : Bool
		return dig(*path).is_nil?()
	end

	{% for name, kind in {s: String, bool: Bool,
						  i: Int32, i64: Int64, i128: Int128,
						  f: Float64, f32: Float32 } %}
		# Returns the underlying value as an `{{ kind.id }}` if it can.
		#
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
			{% else %}\
				return @raw.as({{ kind.id }})
			{% end %}\
		end

		# Returns the underlying value as an `{{ kind.id }}` if it can.
		#
		# Returns `nil` otherwise.
		def as_{{ name.id }}? : {{ kind.id }}?
			return as_{{ name.id }} if @raw.is_a?\
			{% if name == :i || name == :i64 %}\
				(Int)
			{% elsif name == :f || name == :f32 %}\
				(Float)
			{% else %}\
				({{ kind.id }})
			{% end %}\
			{% if name == :f32 %}\
				return as_{{ name.id }} if @raw.is_a?(Float64)
			{% end %}\
			return nil
		end

		# Assumes the underlying value is indexable and returns the element with the
		# given key as a `{{ kind.id }}`.
		#
		# Raises otherwise.
		def as_{{ name.id }}(*path : KeyTypes) : {{ kind.id }}
			return dig(*path).as_{{ name.id }}()
		end

		# Assumes the underlying value is indexable and returns the element with the
		# given key as a `{{ kind.id }}`.
		#
		# Returns `nil` otherwise.
		def as_{{ name.id }}?(*path : KeyTypes) : {{ kind.id }}?
			value = dig?(*path)
			return nil if ( value.nil? )
			return value.as_{{ name.id }}?()
		end

	{% end %}


	# MARK: - Arrays

	# Returns the underlying value as an `Array(Any)` if it can.
	#
	# Raises otherwise.
	def as_a() : Array(Any)
		return @raw.as(Array).map() { |elm| Any.new(elm) }
	end

	# Returns the underlying value as an `Array(Any)` if it can.
	#
	# Returns `nil` otherwise.
	def as_a?() : Array(Any)?
		value = @raw.as?(Array)
		return if value.nil?
		return value.map() { |elm| Any.new(elm) }
	end

	# Assumes the underlying value is indexable and returns the specified element
	# at the given key path as an `Array(Any)`.
	#
	# Raises if it is not an `Array` or not found.
	def as_a(*path : KeyTypes) : Array(Any)
		return dig(*path).as_a()
	end

	# Assumes the underlying value is indexable and returns the specified element
	# at the given key path as an `Array(Any)`.
	#
	# Returns `nil` if it is not an `Array` or not found.
	def as_a?(*path : KeyTypes) : Array(Any)?
		value = dig?(*path)
		return nil if ( value.nil? )
		return value.as_a?()
	end

	# Assumes the underlying value is indexable and returns the specified element
	# at the given key path as an `Array` of type `U`.
	#
	# Raises if it is not an `Array`, not found, or an entry is not able to be
	# cast to type `U`.
	def as_a(*path : KeyTypes, each_as : U.class) : Array(U) forall U
		return dig(*path).raw.as(Array).map() { |elm| elm.as(U) }
	end

	# Assumes the underlying value is indexable and returns the specified element
	# at the given key path as an `Array` of type `U`.
	#
	# Returns `nil` if it is not an `Array` or not found.
	#
	# Note: If an entry is not able to be cast to type `U` and `skip` is not
	# false (the default) it is skipped.
	def as_a?(*path : KeyTypes, each_as : U.class, skip : Bool = true) : Array(U)? forall U
		array = dig?(*path)
		return nil if ( array.nil? )

		array = array.raw.as?(Array)
		return nil if ( array.nil? )

		return array.compact_map() { |elm|
			elm = elm.as?(U)
			if ( elm.nil? )
				next if skip
				return nil
			end

			next elm
		}
	end

	# Assumes the underlying value is indexable and yields each element at the
	# given key path as type `U`.
	#
	# Raises if it is not an `Array`, not found, or an entry is not able to be
	# cast to type `U`.
	def as_a(*path : KeyTypes, each_as : U.class, &block : U -> Nil) : Nil forall U
		return dig(*path).raw.as(Array).map() { |elm| yield(elm.as(U)) }
	end

	# Assumes the underlying value is indexable and yields each element at the
	# given key path as type `U`.
	#
	# Returns a `Bool` indicating if the `Array` was found.
	#
	# Note: If an entry is not able to be cast to type `U` it is skipped.
	def as_a?(*path : KeyTypes, each_as : U.class|Nil = nil, &block : U -> Nil) : Bool forall U
		array = dig?(*path)
		return false if ( array.nil? )

		array = array.raw.as?(Array)
		return false if ( array.nil? )

		array.each() { |elm|
			elm = elm.as?(U)
			next if elm.nil?
			yield(elm)
		}
		return true
	end


	# MARK: - Hash

	# Returns the underlying value as an `Hash(String, Any)` if it can.
	#
	# Raises otherwise.
	def as_h() : Hash(String, Any)
		hash = @raw.as(Hash)
		hash_new = Hash(String, Any).new()
		hash.each() { |k,v| hash_new[k] = Any.new(v) }
		return hash_new
	end

	# Returns the underlying value as an `Hash(String, Any)` if it can.
	#
	# Returns `nil` otherwise.
	def as_h?() : Hash(String, Any)?
		return as_h if @raw.is_a?(Hash)
	end

	# Assumes the underlying value is indexable and returns the specified element
	# at the given key path as an `Hash(String, Any)`.
	#
	# Raises if it is not an `Hash` or not found.
	def as_h(*path : KeyTypes) : Hash(String, Any)
		return dig(*path).as_h()
	end

	# Assumes the underlying value is indexable and returns the specified element
	# at the given key path as an `Hash(String, Any)`.
	#
	# Returns `nil` if it is not an `Hash` or not found.
	def as_h?(*path : KeyTypes) : Hash(String, Any)?
		value = dig?(*path)
		return nil if ( value.nil? )
		return value.as_h?()
	end

	# Assumes the underlying value is indexable and returns the specified element
	# at the given key path as a `Hash` of type `U`.
	#
	# Raises if it is not an `Hash`, not found, or an entry is not able to be
	# cast to type `U`.
	def as_h(*path : KeyTypes, each_as : U.class) : Hash(String, U) forall U
		hash = dig(*path).raw.as(Hash)
		hash_new = Hash(String, U).new()
		hash.each() { |k,v| hash_new[k] = v.as(U) }
		return hash_new
	end

	# Assumes the underlying value is indexable and returns the specified element
	# at the given key path as a `Hash` of type `U`.
	#
	# Returns `nil` if it is not a `Hash` or not found.
	#
	# Note: If an entry is not able to be cast to type `U` and `skip` is not
	# false (the default) it is skipped.
	def as_h?(*path : KeyTypes, each_as : U.class, skip : Bool = true) : Hash(String, U)? forall U
		hash = dig?(*path)
		return nil if ( hash.nil? )

		hash = hash.raw.as?(Hash)
		return nil if ( hash.nil? )

		hash_new = Hash(String, U).new()
		hash.each() do |key, value|
			value = value.as?(U)
			if ( value.nil? )
				next if skip
				return nil
			end

			hash_new[key] = value
		end

		return hash_new
	end

	# Assumes the underlying value is indexable and yields each element at the
	# given key path as type `U`.
	#
	# Raises if it is not a `Hash`, not found, or an entry is not able to be
	# cast to type `U`.
	def as_h(*path : KeyTypes, each_as : U.class, &block : String, U -> Nil) : Nil forall U
		return dig(*path).raw.as(Hash).map() { |key, value| yield(key, value.as(U)) }
	end

	# Assumes the underlying value is indexable and yields each element at the
	# given key path as type `U`.
	#
	# Returns a `Bool` indicating if the `Hash` was found.
	#
	# Note: If an entry is not able to be cast to type `U` it is skipped.
	def as_h?(*path : KeyTypes, each_as : U.class|Nil = nil, &block : String, U -> Nil) : Bool forall U
		hash = dig?(*path)
		return false if ( hash.nil? )

		hash = hash.raw.as?(Hash)
		return false if ( hash.nil? )

		hash.each() { |key, value|
			value = value.as?(U)
			next if value.nil?
			yield(key, value)
		}
		return true
	end



	# MARK: - Printing

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
