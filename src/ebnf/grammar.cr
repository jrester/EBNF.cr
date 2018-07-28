require "json"

module EBNF
  class Atom
    def initialize(@value, @terminal)
    end

    JSON.mapping(
      value: String,
      terminal: Bool
    )
  end

  class Rule
    def initialize(@atoms = Array(Atom).new)
    end

    JSON.mapping(
      atoms: Array(Atom)
    )
  end

  class Production
    def initialize(@name, @rules = Array(Rule).new)
    end

    JSON.mapping(
      name: String,
      rules: Array(Rule)
    )
  end

  class Grammar
    enum GrammarType
      EBNF,
      BNF,
      Bison
    end

    def initialize(@productions, @type)
    end

    def to_s
      puts @type
    end

    JSON.mapping(
      type: GrammarType,    # FIXME: type is represented by an integer in json instead of a string
      productions: Array(Production)
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
