# config.cr

`config.cr` is a parser for a configuration format designed to be more effective then JSON, YAML, INI, HJSON. It inherits aspects from  'OpenBSD style' configs like macros.

```
# TL;DR
$self = config.cr

json:    Too many quotes
yaml:    Pays attention to whitespace
ini:     No nesting
hjson:   Data oriented. Support?
openbsd: Macros are awesome

/* If only something combined the good
   parts and got rid of the bad */

answer: $self
```


## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  config:
    github: chris-huxtable/config.cr
```


## Usage

```crystal
require "config"
```

You can parse a file with:
```
config = Config.file("/path/to/file.conf")
```

You can access the entries via the `Config::Any` objects.
```
config = Config.parse("username: chris, link: https://github.com/chris-huxtable/config.cr")

username = config.as_s("username")
link = config.as_a("link")
```


## Format

### Root Object:
The root is considered an object. That is to say you must provide a key for any root entry and you should not wrap entries in `{}`.
```
key: "value"
```


### Keys:
Unlike JSON, object keys can be specified without quotes.
```
rate: 1000
```


### Strings:
Unlike JSON, strings can be specified without quotes so long as it doesnt contain special characters like `:`, `=`, `{`, `}`, `[`, `]`, or `,`. Though, `:`, `=` are allowed if they are not a key.
```
rate: This is a string.
```


### Seporators:
Unlike JSON, entries can be seporated with commas, or newlines.
```
first: 1
second: 2, third: 3
```


### Comments:
There are three types of comments to support the common commenting styles.

#### Hash Comments:
A to-end-of-line comment initiated by a `#` symbol. As common in Crystal, Ruby, Python, Shell, Perl, et al.
```
# hash style comments
# (because it's just one character)
```

#### Line Comments:
A to-end-of-line comment initiated by a `//`. As common in C, Objective-C, C++, D, Swift, PHP, JavaScript, et al.
```
// line style comments
// (because it's like C/Objective-C/...)
```

#### Block Comments:
A block comment initiated by a `/*` and terminated by `*/`. As common in C, Objective-C, C++, D, Swift, PHP, et al.
```
/* block style comments because
   it allows you to comment out a block */
```
Note: This does not *yet* support nested comments.


### Macros:
A macro is a saved value which can be referenced in the rest fo the document. The key must be prefixed with a `$` and assigned with a `=` as opposed to a `:`.
```
$defaultName = "Default Name"
$nameKey = name

$defaultObject = {
	first: 1
	second: 2
}

$nameKey: $defaultName
object: $defaultObject
```

Note: Macro's cannot yet be inserted into strings.


### Fault Tolerance:
Recovers from easy to make  mistakes. Like useless comma's.
```
first: 1
second: 2,
third: 3,,,
```


## Contributing

1. Fork it ( https://github.com/chris-huxtable/config.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Chris Huxtable](https://github.com/chris-huxtable) - creator, maintainer
