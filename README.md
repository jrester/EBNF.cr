# EBNF.cr

[![Built with Crystal](https://img.shields.io/badge/built%20with-crystal-000000.svg?style=flat-square)](https://crystal-lang.org/)
[![Built Status](https://img.shields.io/travis/jrester/EBNF.cr/master.svg?style=flat-square)](https://travis-ci.org/jrester/EBNF.cr)
[![MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://en.wikipedia.org/wiki/MIT_License)

Library for working with Context free Grammar:
* Parse EBNF, BNF and Bison/Yacc Grammar
* Convert EBNF to BNF
* Generate CNF
* Generate First/Follow sets
* More Features comming

> Note:
> EBNF Grammar should follow the ISO/IEC 14977 standard as it is described [here](https://www.cl.cam.ac.uk/~mgk25/iso-14977.pdf)

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  ebnf:
    github: jrester/EBNF.cr
```

## Usage

* [Parse Grammar](#parsing)
  - [EBNF Grammar](#ebnf-grammar)
  - [BNF Grammar](#bnf-grammar)
  - [Bison/YACC Grammar](#bisonyacc-grammar)
* [Convert Grammar](#conversions)
  - [EBNF to BNF](#ebnf-to-bnf)
  - [Generate CNF](#cnf)
* [FIRST/FOLLOW Set](#firstfollow-set)

## Parsing

Grammar can be built from a string directly with `#from` or from a file with `#from_file` which will return an `EBNF::Grammar`.
`#from` and `#from_file` raise UnknownTokenError when a token is not known and UnexpectedTokenError if the token was not expected.
`#from?` and `from_file?` will return nil if an error is encountered.


### EBNF Grammar

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

> Note: The parser is not built for parsing c/c++ code!
> Each code segment should contain crystal code otherwise the parser will fail

Every Grammar can be exported to json with `#to_json`
and be converted to BNF grammar using `#to_bnf`.


### Conversions

#### EBNF to BNF

Use `Grammar#to_bnf` to convert the grammar to BNF. This will modifie the grammar.
If you want a new grammar pass `true` to `Grammar#to_bnf`

> Note: This may intruduce new production each of them with a unique name like 'Special_350257660880508218'
> To make sure each name is unique the hash value of the rules in a special segment is used.

```crystal
require "ebnf"

grammar = EBNF::EBNF.from_file "grammar.y"
grammar.to_bnf.type # =>  #=> EBNF::Grammar::GrammarType::BNF
```

#### CNF

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


### FIRST/FOLLOW Set

`Grammar#first_follow` generates FIRST/FOLLOW sets. It returns a Tuple with two hashes each of them containing either the first or follow table indexed by each production.

The start production of the grammar will, if not other specified with `Grammar#start`,
be the first production of the parsed grammar.

```crystal
grammar.first_follow
  #=> (Hash(String, Set(Terminal)), Hash(String, Set(Terminal)))
```
## Roadmap

- [ ] Parser
  * [x] EBNF
  * [x] BNF
  * [x] Bison/YACC
  * [ ] JSON
  * [ ] YAML
- [ ] Conversions
  * [x] EBNF to BNF
  * [x] Bison to BNF
  * [x] CNF
  * [ ] JSON
  * [ ] YAML
- [x] FIRST/FOLLOW Set
- [ ] DFA
  - [ ] Generate DFA
  - [ ] Use DFA to test wether a string belongs to a given grammar
  - [ ] LR(0) Parsing Tables
- [ ] 100% Test coverage :)

## Contributing

1. Fork it (<https://github.com/jrester/ebnf/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [jrester](https://github.com/jrester) jrester - creator, maintainer
