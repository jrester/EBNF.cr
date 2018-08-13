# EBNF.cr

[![Built with Crystal](https://img.shields.io/badge/built%20with-crystal-000000.svg?style=flat-square)](https://crystal-lang.org/)

Library for working with Context free Grammar:
* Parse EBNF, BNF and Bison/Yacc Grammar
* Convert EBNF to BNF (Not Finished yet)
* Generate CNF
* Generate First/Follow sets
* Create DFA and LR(0) Parsing table (Not Finished yet)


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

<a name="parsing"/>

### Prase Grammar

Grammar can be built from a string directly with `#from` or from a file with `#from_file` which will return an `EBNF::Grammar`.


<a name="parsing-ebnf"/>


#### EBNF Grammar


```crystal
require "ebnf"

# Read from a file
ebnf = EBNF::EBNF.from_file "grammar.y" #=> EBNF::Grammar

grammar = <<-Grammar
letter = "A" | "B" | "C" | "D" | "E" | "F" | "G"
       | "H" | "I" | "J" | "K" | "L" | "M" | "N"
       | "O" | "P" | "Q" | "R" | "S" | "T" | "U"
       | "V" | "W" | "X" | "Y" | "Z" | "a" | "b"
       | "c" | "d" | "e" | "f" | "g" | "h" | "i"
       | "j" | "k" | "l" | "m" | "n" | "o" | "p"
       | "q" | "r" | "s" | "t" | "u" | "v" | "w"
       | "x" | "y" | "z" ;
digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
symbol = "[" | "]" | "{" | "}" | "(" | ")" | "<" | ">"
       | "'" | '"' | "=" | "|" | "." | "," | ";" ;
character = letter | digit | symbol | "_" ;

identifier = letter , { letter | digit | "_" } ;
terminal = "'" , character , { character } , "'"
         | '"' , character , { character } , '"' ;

lhs = identifier ;
rhs = identifier
     | terminal
     | "[" , rhs , "]"
     | "{" , rhs , "}"
     | "(" , rhs , ")"
     | rhs , "|" , rhs
     | rhs , "," , rhs ;

rule = lhs , "=" , rhs , ";" ;
grammar = { rule } ;
Grammar

# Parse the string directly
ebnf = EBNF::EBNF.from grammar #=> EBNF::Grammar
puts ebnf #=> letter = "A" | "B" | ...
```

<a name="parsing-bnf"/>

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

<a name="parsing-bison-yacc"/>

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


<a name="convert"/>

### Convert Grammar

<a name="ebnf-to-bnf"/>

#### Convert EBNF to BNF

This will convert the `grammar` to BNF.

```crystal
require "ebnf"

grammar = EBNF::EBNF.from_file "grammar.y"
grammar.to_bnf # => nil
grammar.type #=> EBNF::Grammar::GrammarType::BNF
```

#### Generate CNF

```crystal
grammar.to_cnf #=> nil
```

This will convert `grammar` to [CNF](htpps://https://en.wikipedia.org/wiki/Chomsky_normal_form). The order and number of steps can be specified by an Array of `EBNF::CNF::Step`.

```crystal
grammar.to_cnf [EBNF::CNF::START, EBNF::CNF::UNIT, EBNF::CNF::START]
```

This will run frist START, then UNIT and again START. The default order is:
* START
* TERM
* BIN
* DEL
* UNIT

> Note: Every step will be run in the way you pass it, so in the above example START will be run two times even if that wasn't your intention.


<a name="first-follow"/>

### FIRST/FOLLOW Set

`Grammar#first_follow` generates FIRST/FOLLOW sets. It returns a Tuple with two hashes each of them containing either the first or follow table indexed by each production.

The start production of the grammar will, if not other specified with `Grammar#start`,
be the first production of the parsed grammar.

```crystal
grammar.first_follow
  #=> (Hash(String, Set(Terminal)), Hash(String, Set(Terminal)))
```

### Create DFA

You can export a [DFA](https://en.wikipedia.org/wiki/Deterministic_finite_automaton) from `grammar` with `EBNF::Grammar#to_dfa`.

```crystal
grammar.to_dfa #=> EBNF::DFA::State
```

## Development

* Imporve docs
* EBNF to BNF
* DFA and LR(0) generation
* Add tests
* Benchmarks

## Contributing

1. Fork it (<https://github.com/TheKingsJrester/ebnf/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [TheKingsJrester](https://github.com/TheKingsJrester) TheKingsJrester - creator, maintainer
