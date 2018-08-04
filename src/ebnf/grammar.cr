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

  class Terminal < Atom
    def initialize(@value)
    end

    JSON.mapping(
      value: String
    )

    def to_s(io, grammar_type = Grammar::GrammarType::EBNF)
      case grammar_type
      when Grammar::GrammarType::EBNF
        io << "\""
        io << @value
        io << "\""
      when Grammar::GrammarType::BNF
        io << "<"
        io << @value
        io << ">"
      when Grammar::GrammarType::Bison
        io << @value
      end
    end

    def ==(other : Terminal)
      @value == other.value
    end

    def ==(other : String)
      @value === other
    end

    def_hash @value
  end

  class Nonterminal < Atom
    def initialize(@value)
    end

    JSON.mapping(
      value: String,
    )

    def to_s(io, grammar_type = Grammar::GrammarType::EBNF)
      case grammar_type
      when Grammar::GrammarType::EBNF
         io << @value
      when Grammar::GrammarType::BNF
        io << "<"
        io << @value
        io << ">"
      when Grammar::GrammarType::Bison
        io << @value
      end
    end
  end

  class Rule
    def initialize(@atoms = Array(Atom).new)
    end

    JSON.mapping(
      atoms: Array(Atom)
    )

    def to_s(io, grammar_type = Grammar::GrammarType::EBNF)
      @atoms.each do | a |
        a.to_s io, grammar_type
        io << " "
      end
    end
  end

  class Empty < EBNF::Rule
    def initialize
      @atoms = Array(Atom).new
    end

    def to_s(io, grammar_type = Grammar::GrammarType::Bison)
    end
  end

  class Production
    def initialize(@rules = Array(Rule).new)
    end

    JSON.mapping(
      rules: Array(Rule)
    )

    def to_s(io, grammar_type = Grammar::GrammarType::EBNF)
      case grammar_type
      when Grammar::GrammarType::EBNF
      when Grammar::GrammarType::BNF
      when Grammar::GrammarType::Bison then
        @rules.each_with_index do | r, i |
          r.to_s io, grammar_type
          io << "\n  | " if i + 1 < @rules.size
        end
      end
    end
  end

  class Grammar
    enum GrammarType
      EBNF,
      BNF,
      Bison
    end

    def initialize(@productions = Hash(String, Production).new,
                   @type = GrammarType::EBNF,
                   @start = nil,
                   @terminals = Set(String).new)
    end

    def to_s(io)
      @productions.each do | key, p |
        io << key
        io << ":\n  "
        p.to_s io, @type
        io << "\n\n"
      end
    end

    JSON.mapping(
      type: GrammarType,    # FIXME: type is represented by an integer in json instead of a string
      productions: Hash(String, Production),
      start: String|Nil,
      terminals: Set(String),
    )

    def to_bnf
      case @type
      when BNF then raise "Grammar is already BNF"
      when EBNF then BNF.from_ebnf self
      when Bison then BNF.from_bison self
      end
    end
  end
end
