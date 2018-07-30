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

require "./spec_helper"


describe Config::Any do

	describe "determines if entry is" do

		it "nil" do
			Config.parse("foo: nil").is_nil?("foo").should be_true
			Config.parse("foo: null").is_nil?("foo").should be_true

			Config.parse("foo: { bar: nil }").is_nil?("foo", "bar").should be_true
			Config.parse("foo: { bar: null }").is_nil?("foo", "bar").should be_true

			Config.parse("foo: string").is_nil?("foo").should be_false
			Config.parse("foo: { bar: string }").is_nil?("foo", "bar").should be_false
		end

	end

	describe "entry casts to" do

		it "bool" do
			# Base
			Config.parse("foo: true").as_bool("foo").should be_true
			Config.parse("foo: false").as_bool("foo").should be_false
			Config.parse("foo: true").as_bool?("foo").should be_true
			Config.parse("foo: false").as_bool?("foo").should be_false

			# Nested
			Config.parse("foo: { bar: true }").as_bool("foo", "bar").should be_true
			Config.parse("foo: { bar: false }").as_bool("foo", "bar").should be_false
			Config.parse("foo: { bar: true }").as_bool?("foo", "bar").should be_true
			Config.parse("foo: { bar: false }").as_bool?("foo", "bar").should be_false

			# Not Found
			Config.parse("foo: 2").as_bool?("foo").should be_nil
			Config.parse("foo: { bar: 2 }").as_bool?("foo", "bar").should be_nil
		end

		it "int" do
			# Base
			Config.parse("foo: 123").as_i("foo").should eq(123)
			Config.parse("foo: 123").as_i?("foo").should eq(123)
			Config.parse("foo: 123456789123456").as_i64("foo").should eq(123456789123456)
			Config.parse("foo: 123456789123456").as_i64?("foo").should eq(123456789123456)

			# Nested
			Config.parse("foo: { bar: 123 }").as_i("foo", "bar").should eq(123)
			Config.parse("foo: { bar: 123 }").as_i?("foo", "bar").should eq(123)
			Config.parse("foo: { bar: 123456789123456 }").as_i64("foo", "bar").should eq(123456789123456)
			Config.parse("foo: { bar: 123456789123456 }").as_i64?("foo", "bar").should eq(123456789123456)

			# Not Found
			Config.parse("foo: true").as_i?("foo").should be_nil
			Config.parse("foo: true").as_i64?("foo").should be_nil
			Config.parse("foo: { bar: true }").as_i?("foo", "bar").should be_nil
			Config.parse("foo: { bar: true }").as_i64?("foo", "bar").should be_nil
		end

		it "float" do
			# Base
			Config.parse("foo: 123.45").as_f("foo").should eq(123.45)
			Config.parse("foo: 123.45").as_f?("foo").should eq(123.45)
			Config.parse("foo: 123.45").as_f32("foo").should eq(123.45_f32)
			Config.parse("foo: 123.45").as_f32?("foo").should eq(123.45_f32)

			# Nested
			Config.parse("foo: { bar: 123.45 }").as_f("foo", "bar").should eq(123.45)
			Config.parse("foo: { bar: 123.45 }").as_f?("foo", "bar").should eq(123.45)
			Config.parse("foo: { bar: 123.45 }").as_f32("foo", "bar").should eq(123.45_f32)
			Config.parse("foo: { bar: 123.45 }").as_f32?("foo", "bar").should eq(123.45_f32)

			# Not Found
			Config.parse("foo: true").as_f?("foo").should be_nil
			Config.parse("foo: true").as_f32?("foo").should be_nil
			Config.parse("foo: { bar: true }").as_f?("foo", "bar").should be_nil
			Config.parse("foo: { bar: true }").as_f32?("foo", "bar").should be_nil
		end

		it "string" do
			expected = "hello"

			# Base
			Config.parse("foo: \"hello\"").as_s("foo").should eq(expected)
			Config.parse("foo: hello").as_s("foo").should eq(expected)
			Config.parse("foo: \"hello\"").as_s?("foo").should eq(expected)
			Config.parse("foo: hello").as_s?("foo").should eq(expected)

			# Nested
			Config.parse("foo: { bar: \"hello\" }").as_s("foo", "bar").should eq(expected)
			Config.parse("foo: { bar: hello }").as_s("foo", "bar").should eq(expected)
			Config.parse("foo: { bar: \"hello\" }").as_s?("foo", "bar").should eq(expected)
			Config.parse("foo: { bar: hello }").as_s?("foo", "bar").should eq(expected)

			# Not Found
			Config.parse("foo: true").as_s?("foo").should be_nil
			Config.parse("foo: { bar: true }").as_s?("foo", "bar").should be_nil
			expect_raises(Exception) { Config.parse("foo: true").as_s("foo") }
			expect_raises(Exception) { Config.parse("foo: { bar: true }").as_s("foo", "bar") }
		end

		it "array" do
			expected = [1, 2, 3]

			# Base
			Config.parse("foo: [1, 2, 3]").as_a("foo").should eq(expected)
			Config.parse("foo: [1, 2, 3]").as_a?("foo").should eq(expected)

			# Nested
			Config.parse("foo: { bar: [1, 2, 3] }").as_a("foo", "bar").should eq(expected)
			Config.parse("foo: { bar: [1, 2, 3] }").as_a?("foo", "bar").should eq(expected)

			# Not Found
			Config.parse("foo: true").as_a?("foo").should be_nil
			expect_raises(Exception) { Config.parse("foo: true").as_a("foo") }
		end

		it "hash" do
			expected = {"this" => Config::Any.new("test")}

			# Base
			Config.parse("foo: {this: test}").as_h("foo").should eq(expected)
			Config.parse("foo: {this: test}").as_h?("foo").should eq(expected)

			# Nested
			Config.parse("foo: {bar: {this: test}}").as_h("foo", "bar").should eq(expected)
			Config.parse("foo: {bar: {this: test}}").as_h?("foo", "bar").should eq(expected)

			# Not Found
			Config.parse("foo: true").as_h?("foo").should be_nil
			expect_raises(Exception) { Config.parse("foo: true").as_h("foo") }
		end

		it "array of type" do
			expected = ["this", "is", "a", "test"]

			# Base
			Config.parse("foo: [this, is, a, test]").as_a("foo", each_as: String).should eq(expected)
			Config.parse("foo: [this, is, a, test]").as_a?("foo", each_as: String).should eq(expected)

			# Nested
			Config.parse("foo: {bar: [this, is, a, test]}").as_a("foo", "bar", each_as: String).should eq(expected)
			Config.parse("foo: {bar: [this, is, a, test]}").as_a?("foo", "bar", each_as: String).should eq(expected)

			# Mixed and Bad Types
			Config.parse("foo: [0, 1, 2, 3]").as_a?("foo", each_as: String).should eq(Array(String).new())
			Config.parse("foo: [this, test, 2, 3]").as_a?("foo", each_as: String).should eq(["this", "test"])

			Config.parse("foo: [0, 1, 2, 3]").as_a?("foo", each_as: String, skip: false).should be_nil
			Config.parse("foo: [this, test, 2, 3]").as_a?("foo", each_as: String, skip: false).should be_nil

			expect_raises(Exception) { Config.parse("foo: [0, 1, 2, 3]").as_a("foo", each_as: String) }
			expect_raises(Exception) { Config.parse("foo: [this, test, 2, 3]").as_a("foo", each_as: String) }
		end

		it "hash of type" do
			expected = {"this" => "is", "a" => "test"}

			# Base
			Config.parse("foo: {this: is, a: test}").as_h("foo", each_as: String).should eq(expected)
			Config.parse("foo: {this: is, a: test}").as_h?("foo", each_as: String).should eq(expected)

			# Nested
			Config.parse("foo: {bar: {this: is, a: test}}").as_h("foo", "bar", each_as: String).should eq(expected)
			Config.parse("foo: {bar: {this: is, a: test}}").as_h?("foo", "bar", each_as: String).should eq(expected)

			# Mixed and Bad Types
			Config.parse("foo: {this: 1, a: 3}").as_h?("foo", each_as: String).should eq(Hash(String, String).new())
			Config.parse("foo: {this: test, a: 3}").as_h?("foo", each_as: String).should eq({"this" => "test"})

			Config.parse("foo: {this: 1, a: 3}").as_h?("foo", each_as: String, skip: false).should be_nil
			Config.parse("foo: {this: test, a: 3}").as_h?("foo", each_as: String, skip: false).should be_nil

			expect_raises(Exception) { Config.parse("foo: {this: 1, a: 3}").as_h("foo", each_as: String) }
			expect_raises(Exception) { Config.parse("foo: {this: test, a: 3}").as_h("foo", each_as: String) }
		end

		it "array yields" do
			expected = ["this", "is", "a", "test"]

			# Base
			array = Array(String).new()
			Config.parse("foo: [this, is, a, test]").as_a("foo", each_as: String) { |elm| array << elm }
			array.should eq(expected)

			array = Array(String).new()
			Config.parse("foo: [this, is, a, test]").as_a?("foo", each_as: String) { |elm| array << elm }
			array.should eq(expected)

			# Nested
			array = Array(String).new()
			Config.parse("foo: {bar: [this, is, a, test]}").as_a("foo", "bar", each_as: String) { |elm| array << elm }
			array.should eq(expected)

			array = Array(String).new()
			Config.parse("foo: {bar: [this, is, a, test]}").as_a?("foo", "bar", each_as: String) { |elm| array << elm }
			array.should eq(expected)

			# Mixed and Bad Types
			array = Array(String).new()
			Config.parse("foo: [0, 1, 2, 3]").as_a?("foo", each_as: String) { |elm| array << elm }
			array.should eq(Array(String).new())

			array = Array(String).new()
			Config.parse("foo: [this, test, 2, 3]").as_a?("foo", each_as: String) { |elm| array << elm }
			array.should eq(["this", "test"])

			expect_raises(Exception) do
				array = Array(String).new()
				Config.parse("foo: [0, 1, 2, 3]").as_a("foo", each_as: String) { |elm| array << elm }
			end

			expect_raises(Exception) do
				array = Array(String).new()
				Config.parse("foo: [this, test, 2, 3]").as_a("foo", each_as: String) { |elm| array << elm }
			end
		end

		it "hash yield" do
			expected = {"this" => "is", "a" => "test"}

			# Base
			hash = Hash(String, String).new()
			Config.parse("foo: {this: is, a: test}").as_h("foo", each_as: String) { |key, value| hash[key] = value }
			hash.should eq(expected)

			hash = Hash(String, String).new()
			Config.parse("foo: {this: is, a: test}").as_h?("foo", each_as: String) { |key, value| hash[key] = value }
			hash.should eq(expected)

			# Nested
			hash = Hash(String, String).new()
			Config.parse("foo: {bar: {this: is, a: test}}").as_h("foo", "bar", each_as: String) { |key, value| hash[key] = value }
			hash.should eq(expected)

			hash = Hash(String, String).new()
			Config.parse("foo: {bar: {this: is, a: test}}").as_h?("foo", "bar", each_as: String) { |key, value| hash[key] = value }
			hash.should eq(expected)

			# Mixed and Bad Types
			hash = Hash(String, String).new()
			Config.parse("foo: {this: 1, a: 3}").as_h?("foo", each_as: String) { |key, value| hash[key] = value }
			hash.should eq(Hash(String, String).new())

			hash = Hash(String, String).new()
			Config.parse("foo: {this: test, a: 3}").as_h?("foo", each_as: String) { |key, value| hash[key] = value }
			hash.should eq({"this" => "test"})

			expect_raises(Exception) do
				array = Hash(String, String).new()
				Config.parse("foo: {this: 1, a: 3}").as_h("foo", each_as: String) { |key, value| hash[key] = value }
			end

			expect_raises(Exception) do
				array = Hash(String, String).new()
				Config.parse("foo: {this: test, a: 3}").as_h("foo", each_as: String) { |key, value| hash[key] = value }
			end
		end
	end

	describe "#size of" do
		it "array" do
			Config.parse("foo: [1, 2, 3]")["foo"].size.should eq(3)
			Config.parse("foo: [1, 2, 3]")["foo"].size?.should eq(3)
		end

		it "hash" do
			Config.parse("foo: {foo: bar, bar: foo}")["foo"].size.should eq(2)
			Config.parse("foo: {foo: bar, bar: foo}")["foo"].size?.should eq(2)
		end

		it "string" do
			Config.parse("foo: \"bar\"")["foo"].size.should eq(3)
			Config.parse("foo: \"bar\"")["foo"].size?.should eq(3)
		end
	end

	describe "#[] of" do
		it "array" do
			Config.parse("foo: [1, 2, 3]")["foo"][1].raw.should eq(2)
		end

		it "hash" do
			Config.parse("foo: {bar: foo}")["foo"]["bar"].raw.should eq("foo")
		end
	end

	describe "#[]? of" do
		it "array" do
			Config.parse("foo: [1, 2, 3]")["foo"][1]?.not_nil!.raw.should eq(2)
			Config.parse("foo: [1, 2, 3]")["foo"][3]?.should be_nil
			Config.parse("foo: [true, false]")["foo"][1]?.should eq false
		end

		it "hash" do
			Config.parse("foo: {foo: bar}")["foo"]["foo"]?.not_nil!.raw.should eq("bar")
			Config.parse("foo: {foo: bar}")["foo"]["fox"]?.should be_nil
			Config.parse("foo: {foo: false}")["foo"]["foo"]?.should eq false
		end
	end

	describe "#dig?" do
		it "is not nil" do
			Config.parse("foo: { bar: string }").dig?("foo", "bar").should_not be_nil
		end

		it "is nil" do
			Config.parse("foo: { }").dig?("foo", "bar").should be_nil
		end

		describe "with hash" do
			Config.parse("foo: { bar: string }").dig?("foo", "bar").not_nil!.raw.should eq("string")
			Config.parse("foo: { bar: string }").dig?("foo", "bad").should be_nil
		end

		describe "with array" do
			Config.parse("foo: [1, 2, 3]").dig?("foo", 1).not_nil!.raw.should eq(2)
			Config.parse("foo: [1, 2, 3]").dig?("foo", 3).should be_nil
		end

		describe "with hash of array" do
			Config.parse("foo: { bar: [1, 2, 3] }").dig?("foo", "bar", 1).not_nil!.raw.should eq(2)
			Config.parse("foo: { bar: [1, 2, 3] }").dig?("foo", "bar", 3).should be_nil
		end

		describe "with array of hash" do
			Config.parse("foo: [ 1, { bar: string }, 3]").dig?("foo", 1, "bar").not_nil!.raw.should eq("string")
			Config.parse("foo: [ 1, { bar: string }, 3]").dig?("foo", 3, "bar").should be_nil
		end
	end

	it "traverses big structure" do
		obj = Config.parse("foo: {foo: [1, {bar: [2, 3]}]}").as_h("foo")
		obj["foo"][1]["bar"][1].as_i.should eq(3)
	end

	it "compares to other objects" do
		obj = Config.parse("foo: [1, 2]").as_a("foo")
		obj.should eq([1, 2])
		obj[0].should eq(1)
	end

	it "can compare with ===" do
		(1 === Config.parse("foo: 1")["foo"]).should be_truthy
	end

	it "exposes $~ when doing Regex#===" do
		(/o+/ === Config.parse("foo: foo").as_s("foo")).should be_truthy
		$~[0].should eq("oo")
	end

	it "parses tldr" do
		tldr = Config.parse("# TL;DR
							 $self = config.cr

							 json:    Too many quotes
							 yaml:    Pays attention to whitespace
							 ini:     No nesting
							 hjson:   Data oriented. Support?
							 openbsd: Macros are awesome

							 /* If only something combined the good
							    parts and got rid of the bad */

							 answer: $self")
		tldr.as_s("json").should	eq "Too many quotes"
		tldr.as_s("yaml").should	eq "Pays attention to whitespace"
		tldr.as_s("ini").should		eq "No nesting"
		tldr.as_s("hjson").should	eq "Data oriented. Support?"
		tldr.as_s("openbsd").should	eq "Macros are awesome"

		tldr.as_s("answer").should	eq "config.cr"
	end
end
