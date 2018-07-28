module EBNF
  class Atom
    property value : String
    property terminal : Bool

    def initialize(@value, @terminal)
    end
  end

  class Rule
    property atoms : Array(Atom)

    def initialize(@atoms = Array(Atom).new)
    end
  end

  class Production
    property name : String
    property rules : Array(Rule)

    def initialize(@name, @rules = Array(Rule).new)
    end
  end

  class Grammar
    enum GrammarType
      EBNF,
      BNF,
      Bison
    end

    property productions : Array(Production)
    property type : GrammarType

    def initialize(@productions, @type)
    end

    def to_s
    end

    def to_json
    end

    def to_bnf
      case @type
      when :BNF then raise "Grammar is already BNF"
      when :EBNF then BNF::from_ebnf self
      when :Bison then BNF::from_bison self
      end
    end
  end
end
