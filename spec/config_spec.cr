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


private def it_parses(string, expected, file = __FILE__, line = __LINE__)
	it "parses #{string}", file, line do
		Config.parse(string).raw.should eq(expected)
	end
end

private def it_raises_on_parse(string, file = __FILE__, line = __LINE__)
	it "raises on parse #{string}", file, line do
		expect_raises Config::ParseException do
			Config.parse(string)
		end
	end
end

describe Config::Parser do

	it "parses basics" do
		it_parses "foo: 1",							{ "foo" => 1 }
		it_parses "foo: 2.5",						{ "foo" => 2.5 }

		it_parses "foo: 0xdeadbeef",				{ "foo" => 0xdeadbeef }
		it_parses "foo: 0Xdeadbeef",				{ "foo" => 0xdeadbeef }
		it_parses "foo: 0o7654321",					{ "foo" => 0o7654321 }
		it_parses "foo: 0O7654321",					{ "foo" => 0o7654321 }
		it_parses "foo: 0b1010101010",				{ "foo" => 0b1010101010 }
		it_parses "foo: 0B1010101010",				{ "foo" => 0b1010101010 }

		it_parses "foo: \"hello\"",					{ "foo" => "hello" }
		it_parses "foo: hello",						{ "foo" => "hello" }
		it_parses "\"foo\": hello",					{ "foo" => "hello" }
		it_parses "foo: true",						{ "foo" => true }
		it_parses "foo: false",						{ "foo" => false }
		it_parses "foo: null",						{ "foo" => nil }
		it_parses "foo: this is multi word",		{ "foo" => "this is multi word" }
		it_parses "foo: this is\nbar: multi line",	{ "foo" => "this is", "bar" => "multi line" }

		link = "https://github.com/chris-huxtable/config.cr"
		it_parses "link: #{link}", 					{ "link" => link }

		it_parses "foo: []",						{ "foo" => Array(Config::Type).new() }
		it_parses "foo: [1]",						{ "foo" => [1] }
		it_parses "foo: [1, 2, 3]",					{ "foo" => [1, 2, 3] }
		it_parses "foo: [1.5]",						{ "foo" => [1.5] }
		it_parses "foo: [null]",					{ "foo" => [nil] }
		it_parses "foo: [true]",					{ "foo" => [true] }
		it_parses "foo: [false]",					{ "foo" => [false] }
		it_parses "foo: [hello]",					{ "foo" => ["hello"] }
		it_parses "foo: [\"hello\"]",				{ "foo" => ["hello"] }
		it_parses "foo: [0]",						{ "foo" => [0] }
		it_parses "foo: [[0]]",						{ "foo" => [[0]] }

		it_parses "foo: {}",						{ "foo" => Hash(String, Config::Type).new() }
		it_parses "foo: {bar: 1}",					{ "foo" => {"bar" => 1} }
		it_parses "foo: {bar: 1, foo: 1.5}",		{ "foo" => {"bar" => 1, "foo" => 1.5} }
		it_parses "foo: {bar: 1\n foo: 1.5}",		{ "foo" => {"bar" => 1, "foo" => 1.5} }
	end

	it "parses odd entries" do
		it_parses "foo: {\"ba\\nr\": 1}",			{ "foo" => {"ba\nr" => 1} }

		it_parses "foo: [{bar: 1}]",				{ "foo" => [{"bar" => 1}] }

		it_parses "foo: { 	\n}",					{ "foo" => Hash(String, Config::Type).new() }
		it_parses "foo: [ 	\n]",					{ "foo" => Array(Config::Type).new() }
		it_parses " 	foo: [ 0 ] ",				{ "foo" => [0] }
		it_parses " 	foo: { bar: 0 } ",			{ "foo" => { "bar" => 0} }
		it_parses "foo : bar",						{ "foo" => "bar" }

		it_parses "foo: \"hello\tworld\"",			{ "foo" => "hello\tworld" }
		it_parses "foo: \"hello\nworld\"",			{ "foo" => "hello\nworld" }

		it_parses "foo: 1\u{0}",					{ "foo" => 1 }
	end

	it "parses non-ascii" do
		it_parses "foo: 日",						{ "foo" => "日" }
		it_parses "foo: \"日\"",					{ "foo" => "日" }
		it_parses "foo: [日]",						{ "foo" => ["日"] }
		it_parses "foo: [\"日\"]",					{ "foo" => ["日"] }
		it_parses "日: 日",							{ "日" => "日" }

		it_parses "foo: 💩",						{ "foo" => "💩" }
		it_parses "foo: \"💩\"",					{ "foo" => "💩" }
		it_parses "foo: [💩]",						{ "foo" => ["💩"] }
		it_parses "foo: [\"💩\"]",					{ "foo" => ["💩"] }
		it_parses "💩: 💩",						{ "💩" => "💩" }

		it_parses "foo: \"\\u201cel\nwor\"",		{ "foo" => "\u201cel\nwor" }
		it_parses "foo: \"\\u201cel\twor\"",		{ "foo" => "\u201cel\twor" }
	end

	it "parses comments" do
		empty_hash = Hash(String, Config::Any).new()

		it_parses "",								empty_hash
		it_parses " ",								empty_hash
		it_parses "#",								empty_hash
		it_parses "# comment",						empty_hash
		it_parses "# comment\n# Another Line",		empty_hash
		it_parses "# pure comment\nfoo: 0",			{ "foo" => 0 }
		it_parses "// pure comment",				empty_hash
		it_parses "// pure comment\nfoo: 0",		{ "foo" => 0 }
		it_parses "/* pure comment */",				empty_hash
		it_parses "/* pure comment */ foo: 0",		{ "foo" => 0 }
	end

	it "parses mistakes" do
		it_parses "foo: [1,]",						{ "foo" => [1] }
		it_parses "foo: {\"bar\": 1,}",				{ "foo" => { "bar" => 1 } }
		it_parses "foo: [1, true],",				{ "foo" => [1, true] }
	end

	it "fails parsing" do
		it_raises_on_parse "foo: {1}"
		it_raises_on_parse "foo: {\"foo\"1}"
		it_raises_on_parse "foo: \"{\"foo\":}"
		it_raises_on_parse "foo: [0]1"
		it_raises_on_parse "foo: [0] 1 "
		it_raises_on_parse "foo: [\"\\u123z\"]"
		it_raises_on_parse "foo: {bar: 1 foo: 2}"
		it_raises_on_parse "foo: [2.]"
		it_raises_on_parse "foo: \"unterminated string"
		it_raises_on_parse "foo: "

		it_raises_on_parse "foo \t\n: \t\nbar"
	end

	it "allows macros" do
		it_parses "$macro = test, foo: $macro",		{ "foo" => "test" }
		it_parses "$macro = 0, foo: $macro",		{ "foo" => 0 }
		it_parses "$macro = 1.25, foo: $macro",		{ "foo" => 1.25 }
		it_parses "$macro = 0xbeef, foo: $macro",	{ "foo" => 0xbeef }
		it_parses "$macro = 0o7654, foo: $macro",	{ "foo" => 0o7654 }
		it_parses "$macro = 0b1010, foo: $macro",	{ "foo" => 0b1010 }
		it_parses "$macro = true, foo: $macro",		{ "foo" => true }
		it_parses "$macro = false, foo: $macro",	{ "foo" => false }
		it_parses "$macro = null, foo: $macro",		{ "foo" => nil }
		it_parses "$macro = [0], foo: $macro",		{ "foo" => [0] }
		it_parses "$macro = [0,1,2], foo: $macro",	{ "foo" => [0,1,2] }
		it_parses "$macro = {bar: 0}, foo: $macro",	{ "foo" => {"bar" => 0} }

		it_parses "$macro0 = test, $macro1 = $macro0, foo: $macro1", { "foo" => "test" }
		it_parses "$macro = test, $macro: foo",		{ "test" => "foo" }

		it_raises_on_parse "$macro = $macro, foo: $macro"
	end

end
