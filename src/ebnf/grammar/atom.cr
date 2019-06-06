require "json"

module EBNF
  abstract class Atom
    def to_json(builder)
    end

    def to_s(io, grammar_type)
      raise "Atom#to_s not implemented because it is abstract!"
    end

    abstract def clone
  end

  # A String like 'a' or '+' in a grammar which does not represent a rule but a final symbol/word
  class Terminal < Atom
    property value : String

    def initialize(@value)
    end

    def initialize(builder : JSON::PullParser)
      @value = builder.read_string
    end

    def clone
      Terminal.new @value.clone
    end

    def to_json(builder : JSON::Builder)
      builder.string @value
    end

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
    property value : String
    property production : Nil | Production

    def initialize(@value, @production = nil)
    end

    def initialize(builder : JSON::PullParser)
      @value = builder.read_string
    end

    def clone
      Nonterminal.new @value.clone, nil
    end

    def to_json(builder : JSON::Builder)
      builder.string @value
    end

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

    def ==(other : Nonterminal)
      @value == other.value
    end

    def ==(other : String)
      @value == other
    end

    def_hash @value
  end

  module EBNF
    class Special < Atom
      property rules : Array(Rule)
      property type : Type

      enum Type
        Optional
        Repetion
        Grouping
        Exception
      end

      def initialize(@rules = Array(Rule).new, @type = Type::Optional)
      end

      def clone
        Special.new @rules.clone, @type
      end

      def resolve(grammar : Grammar, exception? : Bool)
        @rules.each do |rule|
          return nil unless exception? ? rule.resolve? grammar : rule.resolve grammar
        end
      end

      def to_s(io, grammar_type = Grammar::Type::EBNF)
        enclosing_symbols = case @type
                            when Type::Optional  then {'[', ']'}
                            when Type::Repetion  then {'{', '}'}
                            when Type::Grouping  then {'(', ')'}
                            when Type::Exception then {'-', nil}
                            else
                              {nil, nil}
                            end
        io << enclosing_symbols[0]
        io << " "
        @rules.join(" | ", io) { |r, io| r.to_s io, grammar_type }
        io << " "
        io << enclosing_symbols[1]
      end

      delegate :<<, :size, :empty?, to: @rules

      def_hash @type, @rules
    end
  end
end
