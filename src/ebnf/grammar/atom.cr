require "json"

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
    property production : Nil | Production

    def initialize(@value, @production = nil)
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
      enum Type
        Optional,
        Repetion,
        Grouping,
        Exception
      end

      def self.end_token_for(special_type : Type)
        case special_type
        when Type::Optional then :left_square_brace
        when Type::Repetion then :left_curly_brace
        when Type::Grouping then :left_brace
        else
          nil
        end
      end

      def self.type_for(symbol : Symbol)
        case symbol
        when :right_square_brace then Type::Optional
        when :right_curly_brace  then Type::Repetion
        when :right_brace        then Type::Grouping
        when :exception          then Type::Exception
        else
          nil
        end
      end

      def self.for(symbol : Symbol)
        special_type = Special.type_for symbol
        return nil unless special_type
        Special.new type: special_type
      end

      def initialize(@rules = Array(Rule).new, @type = Type::Optional)
      end

      JSON.mapping(
        rules: Array(Rule),
        type: Type
      )

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

      def <<(item : Rule)
        @rules << item
      end

      def_hash @type, @rules
    end
  end
end
