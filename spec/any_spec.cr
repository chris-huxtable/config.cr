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

	describe "casts" do

		it "gets nil" do
			Config.parse("foo: null").as_nil("foo").should be_nil
		end

		it "gets bool" do
			Config.parse("foo: true").as_bool("foo").should be_true
			Config.parse("foo: false").as_bool("foo").should be_false
			Config.parse("foo: true").as_bool?("foo").should be_true
			Config.parse("foo: false").as_bool?("foo").should be_false
			Config.parse("foo: 2").as_bool?("foo").should be_nil
		end

		it "gets int" do
			Config.parse("foo: 123").as_i("foo").should eq(123)
			Config.parse("foo: 123456789123456").as_i64("foo").should eq(123456789123456)
			Config.parse("foo: 123").as_i?("foo").should eq(123)
			Config.parse("foo: 123456789123456").as_i64?("foo").should eq(123456789123456)
			Config.parse("foo: true").as_i?("foo").should be_nil
			Config.parse("foo: true").as_i64?("foo").should be_nil
		end

		it "gets float" do
			Config.parse("foo: 123.45").as_f("foo").should eq(123.45)
			Config.parse("foo: 123.45").as_f32("foo").should eq(123.45_f32)
			Config.parse("foo: 123.45").as_f?("foo").should eq(123.45)
			Config.parse("foo: 123.45").as_f32?("foo").should eq(123.45_f32)
			Config.parse("foo: true").as_f?("foo").should be_nil
			Config.parse("foo: true").as_f32?("foo").should be_nil
		end

		it "gets string" do
			Config.parse("foo: \"hello\"").as_s("foo").should eq("hello")
			Config.parse("foo: \"hello\"").as_s?("foo").should eq("hello")
			Config.parse("foo: true").as_s?("foo").should be_nil
		end

		it "gets array" do
			Config.parse("foo: [1, 2, 3]").as_a("foo").should eq([1, 2, 3])
			Config.parse("foo: [1, 2, 3]").as_a?("foo").should eq([1, 2, 3])
			Config.parse("foo: true").as_a?("foo").should be_nil
		end

		it "gets hash" do
			Config.parse("foo: {foo: bar}").as_h("foo").should eq({"foo" => Config::Any.new("bar")})
			Config.parse("foo: {foo: bar}").as_h?("foo").should eq({"foo" => Config::Any.new("bar")})
			Config.parse("foo: true").as_h?("foo").should be_nil
		end

		it "gets array of type" do
			Config.parse("foo: [this, is, a, test]").as_a("foo", String).should eq(["this", "is", "a", "test"])
			Config.parse("foo: [this, is, a, test]").as_a?("foo", String).should eq(["this", "is", "a", "test"])

			expect_raises Exception do
				Config.parse("foo: [0, 1, 2, 3]").as_a("foo", String)
			end
			Config.parse("foo: [0, 1, 2, 3]").as_a?("foo", String).should be_nil

		end

		it "gets hash of type" do
			Config.parse("foo: {this: is, a: test}").as_h("foo", String).should eq({"this" => "is", "a" => "test"})
			Config.parse("foo: {this: is, a: test}").as_h?("foo", String).should eq({"this" => "is", "a" => "test"})

			expect_raises Exception do
				Config.parse("foo: {this: 1, a: 3}").as_h("foo", String)
			end
			Config.parse("foo: {this: 1, a: 3}").as_h?("foo", String).should be_nil
		end
	end

	describe "#size" do
		it "of array" do
			Config.parse("foo: [1, 2, 3]").as_a("foo").size.should eq(3)
		end

		it "of hash" do
			Config.parse("foo: {foo: bar}").as_h("foo").size.should eq(1)
		end
	end

	describe "#[]" do
		it "of array" do
			Config.parse("foo: [1, 2, 3]").as_a("foo")[1].raw.should eq(2)
		end

		it "of hash" do
			Config.parse("foo: {foo: bar}").as_h("foo")["foo"].raw.should eq("bar")
		end
	end

	describe "#[]?" do
		it "of array" do
			Config.parse("foo: [1, 2, 3]").as_a("foo")[1]?.not_nil!.raw.should eq(2)
			Config.parse("foo: [1, 2, 3]").as_a("foo")[3]?.should be_nil
			Config.parse("foo: [true, false]").as_a("foo")[1]?.should eq false
		end

		it "of hash" do
			Config.parse("foo: {foo: bar}").as_h("foo")["foo"]?.not_nil!.raw.should eq("bar")
			Config.parse("foo: {foo: bar}").as_h("foo")["fox"]?.should be_nil
			Config.parse("foo: {foo: false}").as_h("foo")["foo"]?.should eq false
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
