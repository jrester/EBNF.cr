require "string_scanner"
require "./grammar"
require "./macros"
require "./parser"

module EBNF
  module EBNF
    extend Base

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

      def initialize(@rules = Array(Rule).new, @type = Type::Optional); end

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
        @rules.each_with_index do |rule, i|
          rule.to_s io, grammar_type
          io << " | " unless i + 1 == @rules.size
        end
        io << enclosing_symbols[1]
      end
    end

    class Parser < ::EBNF::Parser
      SPECIAL_RIGHT_CHARACTERS = {:right_square_brace, :right_curly_brace,
                                  :right_brace, :exception}

      SPECIAL_LEFT_CHARACTERS = {:left_square_brace, :left_curly_brace, :left_brace}

      SPECIAL_CHARACTERS = SPECIAL_LEFT_CHARACTERS + SPECIAL_RIGHT_CHARACTERS

      RULE_CHARACTERS = {:special, :string, :nonterminal} + SPECIAL_CHARACTERS

      private def self.lex(string : String, exception? : Bool, stop_on_unknown? : Bool=false)
        tokens = Array(Token).new
        column = 0
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?
          if (s = scanner.skip(/\h+/)) || (s = scanner.skip(/\(\*([^\)\*])*\)\*/))
            column += s
            next
          end

          token = if s = scanner.scan(/=/)
                    :definition
                  elsif s = scanner.scan(/,/)
                    :concation
                  elsif s = scanner.scan(/;/)
                    :termination
                  elsif s = scanner.scan(/\[/)
                    :right_square_brace
                  elsif s = scanner.scan(/\]/)
                    :left_square_brace
                  elsif s = scanner.scan(/\{/)
                    :right_curly_brace
                  elsif s = scanner.scan(/\}/)
                    :left_curly_brace
                  elsif s = scanner.scan(/\(/)
                    :right_brace
                  elsif s = scanner.scan(/\)/)
                    :left_brace
                  elsif s = scanner.scan(/\?([^\"])*\?/)
                    :special
                  elsif s = scanner.scan(/\|/)
                    :bar
                  elsif s = scanner.scan(/\-/)
                    :exception
                  elsif s = scanner.scan(/\"([^\"])*"/)
                    :string
                  elsif s = scanner.scan(/\'([^\'])*'/)
                    :string
                  elsif s = scanner.scan(/(\w|\-|\_)+/)
                    :nonterminal
                  elsif s = scanner.scan(/\n/)
                    line += 1
                    :newline
                  elsif s = scanner.scan(/$/)
                    :EOF
                  else
                    if exception?
                      raise UnknownTokenError.new (scanner.peek 1), line, column
                    elsif stop_on_unknown?
                      return nil
                    else
                      s = scanner.peek 1
                      scanner.offset += 1
                      :unknown
                    end
                  end

          s = s.lchop.rchop if token == :string

          tokens << {token: token,
                     value: s,
                     pos:   {line, column}}

          token != :newline ? (column += s.size) : (column = 0)
        end

        tokens
      end

      parse_function_for Grammar::Type::EBNF

      private def self.parse_production(tokens : Array(Token), grammar : Grammar)
        rules = Array(Rule).new
        pos = -1
        accept = false

        until accept || pos >= tokens.size
          token = tokens[pos += 1]?.try &.[:token]
          break unless token
          lookahead = tokens[pos + 1]?.try &.[:token]
          break unless lookahead

          if token == :termination
            accept = true
          elsif token == :bar || token == :newline || token == :concation
            next
          elsif RULE_CHARACTERS.includes? token
            rule, pos_increment = parse_rule tokens[pos..-1], grammar
            rules << rule
            pos += pos_increment
          else
            raise UnexpectedTokenError.new token, tokens[pos][:pos][0], tokens[pos][:pos][1]
          end
        end
        {rules, pos}
      end

      private def self.parse_rule(tokens : Array(Token), grammar : Grammar)
        rule = Rule.new
        accept = false
        pos = -1

        until accept || pos + 1 >= tokens.size
          token = tokens[pos += 1]?.try &.[:token]
          break unless token

          if token == :nonterminal
            rule.atoms << Nonterminal.new tokens[pos][:value]
          elsif token == :string
            rule.atoms << Terminal.new tokens[pos][:value]
            grammar.terminals << tokens[pos][:value]
          elsif SPECIAL_RIGHT_CHARACTERS.includes? token
            special, pos_increment = parse_special token, tokens[pos..-1], grammar
            rule.atoms << special
            pos += pos_increment
          elsif token == :concation
            next
          else
            pos -= 1
            accept = true
          end
        end
        {rule, pos}
      end

      private def self.parse_special(special_type, tokens, grammar)
        special = Special.for special_type
        raise "BUG: Unable to parse #{special_type} correctly" unless special
        pos = 0
        # For an Exception we only need to parse the next token
        if special.type == Special::Type::Exception
          token = tokens[pos += 1][:token]

          if SPECIAL_RIGHT_CHARACTERS.includes? token
            special, pos_increment = parse_special token, tokens[pos..-1], grammar
            pos += pos_increment
            special.rules << Rule.new [special] of Atom
          elsif token == :nonterminal
            special.rules << Rule.new [Nonterminal.new tokens[pos][:value]] of Atom
          elsif token == :string
            special.rules << Rule.new [Terminal.new tokens[pos][:value]] of Atom
          end
        else
          end_token = Special.end_token_for special.type
          raise "Unknown end token for #{special.type}" unless end_token
          atoms = Array(Atom).new
          accept = false

          until accept || pos + 1 >= tokens.size
            token = tokens[pos += 1]?.try &.[:token]
            break unless token

            if token == end_token
              accept = true
            elsif token == :bar
              special.rules << Rule.new atoms.dup
              atoms.clear
            elsif token == :concation
              next
            elsif token == :nonterminal
              atoms << Nonterminal.new tokens[pos][:value]
            elsif token == :string
              atoms << Terminal.new tokens[pos][:value]
              grammar.terminals << tokens[pos][:value]
            elsif SPECIAL_RIGHT_CHARACTERS.includes? token
              special, pos_increment = parse_special token, tokens[pos..-1], grammar
              pos += pos_increment
              special.rules << Rule.new [special] of Atom
            else
              accept = true
            end
          end
          special.rules << Rule.new atoms unless atoms.empty?
        end
        {special, pos}
      end
    end # Parser
  end   # EBNF
end     # EBNF
