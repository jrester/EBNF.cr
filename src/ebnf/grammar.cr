require "json"
require "./macros"

module EBNF
  abstract class Atom
    def to_json(builder)
    end

    def to_s(io, grammar_type)
      raise "Atom#to_s not implemented because it is abstract!"
    end
  end

  # A String like 'a' or '+' in a grammar which does not represent a rule but a final symbol/word
  class Terminal < Atom
    def initialize(@value)
    end

    JSON.mapping(
      value: String
    )

    def to_s(io, grammar_type = Grammar::Type::EBNF)
      case grammar_type
      when Grammar::Type::EBNF
        io << "\""
        io << @value
        io << "\""
      when Grammar::Type::BNF
        io << "\""
        io << @value
        io << "\""
      when Grammar::Type::Bison
        io << @value
      end
    end

    # Some helper functions

    def ==(other : Terminal)
      @value == other.value
    end

    def ==(other : String)
      @value === other
    end

    def_hash @value
  end

  # A String which corresponds to an existing production
  class Nonterminal < Atom
    def initialize(@value)
    end

    JSON.mapping(
      value: String,
    )

    def to_s(io, grammar_type = Grammar::Type::EBNF)
      case grammar_type
      when Grammar::Type::EBNF
        io << @value
      when Grammar::Type::BNF
        io << "<"
        io << @value
        io << ">"
      when Grammar::Type::Bison
        io << @value
      end
    end
  end

  # A part of a production that consits of one or more Atoms
  class Rule
    def initialize(@atoms = Array(Atom).new)
    end

    JSON.mapping(
      atoms: Array(Atom)
    )

    def to_s(io, grammar_type = Grammar::Type::EBNF)
      @atoms.each_with_index do |a, i|
        a.to_s io, grammar_type
        if grammar_type == Grammar::Type::EBNF
          io << ", " unless i + 1 == @atoms.size
        else
          io << " "
        end
      end
    end

    def [](index : Int32)
      @atoms[index]
    end

    def []?(index : Int32)
      @atoms[index]?
    end
  end

  # An Empty `Rule` in a grammar
  #
  # <foo> ::= | '1' | '0'
  class Empty < EBNF::Rule
    def initialize
      @atoms = Array(Atom).new
    end

    def to_s(io, grammar_type = Grammar::Type::Bison)
    end
  end

  # A collection of one or more `Rule`s
  #
  #    <foo> ::= '1' | '2'
  #
  # A Production with 2 rules
  class Production
    def initialize(@rules = Array(Rule).new)
    end

    JSON.mapping(
      rules: Array(Rule)
    )

    def to_s(io, grammar_type = Grammar::Type::EBNF)
      @rules.each_with_index do |r, i|
        r.to_s io, grammar_type
        io << "\n  | " if i + 1 < @rules.size
      end
    end

    # Some helper functions

    def [](index : Int32)
      @rules[index]
    end

    def []?(index : Int32)
      @rules[index]?
    end

    def each
      @rules.each do |rule|
        yield rule
      end
    end

    # Check wether this production is of the form
    # A ::= B
    def unit?
      @rules.size == 1 && @rules[0].is_a? Nonterminal
    end
  end

  # Representation of a CFG
  class Grammar
    enum Type
      EBNF,
      BNF,
      Bison
    end

    # Creates a CFG with *productions* with specified `Grammar::Type` *type*
    # *start* will be first production found in *productions*
    # *terminals* will be added when `Grammar` is created
    #
    # To create `Grammar` use #from or #from_file on the module of the Grammar type you want to parse
    def initialize(@productions = Hash(String, Production).new,
                   @type = Type::EBNF,
                   @start = nil,
                   @terminals = Set(String).new)
    end

    def to_s(io)
      @productions.each do |key, p|
        io << key
        definition = case @type
                     when Type::EBNF  then " = "
                     when Type::BNF   then " ::= "
                     when Type::Bison then ":\n  "
                     end
        io << definition
        p.to_s io, @type
        io << "\n\n"
      end
    end

    JSON.mapping(
      type: Type, # FIXME: type is represented by an integer in json instead of a string
      productions: Hash(String, Production),
      start: String | Nil,
      terminals: Set(String),
    )

    # Converts self to BNF grammar. Returns nil if already BNF
    def to_bnf
      case @type
      when Type::BNF   then nil
      when Type::EBNF  then BNF.from_ebnf self
      when Type::Bison then BNF.from_bison self
      end
    end

    # Gets first production in grammar
    def start
      @start = @productions.first_key unless @start
      @start.not_nil!
    end

    # Gets all nonterminals in this grammar
    def nonterminals
      @productions.keys
    end

    # Access a production with *name*. Raises `KeyError` if not in grammar
    def [](name : String)
      @productions[name]
    end

    # Access a production with *name*. Returns `nil` if not in grammar
    def []?(name : String)
      @prodcuctions[name]?
    end

    # Sets a production with *name* to *production*
    def []=(name : String, production : Production)
      @productions[name] = production
    end
  end
end
