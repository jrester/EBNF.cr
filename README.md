# EBNF.cr

Library for working with Context free Grammar:
* Parse EBNF, BNF and Bison/Yacc Grammar
* Convert EBNF to BNF
* Generate CNF
* Generate First/Follow sets


> Note:
> EBNF Grammar should follow the ISO/IEC 14977 standard as it is described [here](https://www.cl.cam.ac.uk/~mgk25/iso-14977.pdf)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  ebnf:
    github: TheKingsJrester/EBNF.cr
```

## Usage

* [Parse Grammar](#parsing)
  - [EBNF Grammar](#parsing-ebnf)
  - [BNF Grammar](#parsing-bnf)
  - [Bison/YACC Grammar](#parsing-bison-yacc)
* [Convert Grammar](#convert)
  - [EBNF to BNF](#ebnf-to-bnf)
  - [Generate CNF](#cnf)
* [FIRST/FOLLOW Set](#first-follow)

<a name="parsing">
### Prase Grammar

Grammar can be built from a string directly with `#from` or from a file with `#from_file`. This will return a `EBNF::Grammar`.

<a name="parsing-ebnf">
#### EBNF Grammar

```crystal
require "ebnf"

# Read from a file
ebnf = EBNF::EBNF.from_file "grammar.y" #=> EBNF::Grammar

# Parse the string directly
ebnf = EBNF::EBNF.from #= EBNF::Grammar
```
<a name="parsing-bnf">
#### BNF Grammar

```crystal
require "ebnf"

grammar <<-BNF_Grammar
<root> ::= <foo> | <bar>
<foo> ::= "A" "B" | "B" "B"
<bar> ::= "B" "A" | "A" "B"
BNF_Grammar

bnf = EBNF::BNF.from grammar # => EBNF::Grammar
```

<a name="parsing-bison-yacc">
#### Bison/Yacc Grammar

```crystal
require "ebnf"

grammar = <<-Grammar
root:
    foo             { puts "foo" }
    | bar           { puts "bar" }

foo:
    A B
    | B B

bar:
    B A
    | A B
Grammar

bison = EBNF::Bison.from grammar #=> EBNF::Grammar
```

Every Grammar can be exported to json with `#to_json`
and be converted to BNF grammar using `#to_bnf`.

<a name="convert">
### Convert Grammar

<a name="first-follow">
### FIRST/FOLLOW Set

`Grammar#first_follow` generates FIRST/FOLLOW sets. It returns an Array with two hashes each of them containing either the first or follow table indexed by each production.

The start production of the grammar will, if not other specified with `Grammar#start`,
be the first production of the parsed grammar.

```crystal
require "ebnf"

grammar = EBNF::Bison.from_file "grammar.y" #=> EBNF::Grammar
grammar.first_follow
  #=> [Hash(String, Set(Terminal)), Hash(String, Set(Terminal))]

```

## Development

* Error handling
* EBNF to BNF
* Add tests

## Contributing

1. Fork it (<https://github.com/TheKingsJrester/ebnf/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [TheKingsJrester](https://github.com/TheKingsJrester) TheKingsJrester - creator, maintainer
