# EBNF.cr

A Parser for EBNF, BNF and Bison/Yacc Grammar

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  ebnf:
    github: TheKingsJrester/EBNF.cr
```

## Usage

Grammar can be built from a string directly with `#from` or from a file with `#from_file`. This will return a `EBNF::Grammar`.

#### EBNF Grammar

```crystal
require "ebnf"

# Read from a file
ebnf = EBNF::EBNF.from_file "grammar.y" #=> EBNF::Grammar

# Parse the string directly
ebnf = EBNF::EBNF.from #= EBNF::Grammar
```

#### BNF grammar

```crystal
require "ebnf"

grammar <<-BNF_Grammar
<root> ::= <foo> | <bar>
<foo> ::= "A" "B" | "B" "B"
<bar> ::= "B" "A" | "A" "B"
BNF_Grammar

bnf = EBNF::BNF.from grammar # => EBNF::Grammar
```


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

bison = EBNF::Bison.from grammar # => EBNF::Grammar
```

Every Grammar can be exported to json with `#to_json`
and be converted to BNF grammar using `#to_bnf`.


## Development


## Contributing

1. Fork it (<https://github.com/TheKingsJrester/ebnf/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [TheKingsJrester](https://github.com/TheKingsJrester) TheKingsJrester - creator, maintainer
