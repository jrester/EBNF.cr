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

    def_hash @value
  end

  # A part of a production that consits of one or more Atoms
  class Rule
    def initialize(@atoms = Array(Atom).new)
    end

    JSON.mapping(
      atoms: Array(Atom)
    )

    def to_s(io, grammar_type = Grammar::Type::EBNF)
      if grammar_type == Grammar::Type::EBNF
        @atoms.join(", ", io) { |a, io| a.to_s io, grammar_type }
      else
        @atoms.join(" ", io) { |a, io| a.to_s io, grammar_type }
      end
    end

    def [](index : Int32)
      @atoms[index]
    end

    def []?(index : Int32)
      @atoms[index]?
    end

    # Yields each atom
    def each
      @atoms.each { |a| yield a }
    end

    def_hash @atoms
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
      @rules.join("\n  | ", io) { |r, io| r.to_s io, grammar_type }
    end

    # Some helper functions

    def [](index : Int32)
      @rules[index]
    end

    def []?(index : Int32)
      @rules[index]?
    end

    def []=(index : Int32, rule : Rule)
      @rules[index] = rule
    end

    def <<(rule : Rule)
      @rules << rule
    end

    # Yields each rule
    def each
      @rules.each { |r| yield r }
    end

    # Check wether this production is of the form
    # A ::= B
    def unit?
      @rules.size == 1 && @rules[0].is_a? Nonterminal
    end

    def_hash @rules
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
        definition = case @type
                     when Type::EBNF  then "#{key} = "
                     when Type::BNF   then "<#{key}> ::= "
                     when Type::Bison then "#{key}:\n  "
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

    # Gets first production in grammar
    def start
      @start = @productions.first_key unless @start
      @start.not_nil!
    end

    # Gets all nonterminals in this grammar
    def nonterminals
      @productions.keys
    end

    # Changes name for each key value pair
    # See `#change_name`
    def change_name(prev_new : Hash(String, String))
      prev_new.each do |prev, new|
        change_name prev, new
      end
    end

    # Changes name of production *prev* with name *new*
    def change_name(prev : String, new : String)
      if @productions.has_key? prev
        @productions[new] = @productions[prev]
        @productiones.delete prev
      end
    end

    # Access a production with *name*. Raises `KeyError` if not in grammar
    def [](name : String)
      @productions[name]
    end

    # Access a production with *name*. Returns `nil` if not in grammar
    def []?(name : String)
      @productions[name]?
    end

    # Sets a production with *name* to *production*
    def []=(name : String, production : Production)
      @productions[name] = production
    end

    # Yields each productions' name and rules
    def each
      @productions.each { |k, v| yield k, v }
    end

    # Yields each productions' rules
    def each_production
      @productions.each_value { |production| yield production }
    end
  end
end
