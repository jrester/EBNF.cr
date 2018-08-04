require "string_scanner"
require "./grammar"
require "./macros"

module EBNF
  module EBNF
    extend Base


    class Special < Atom
      enum Type
        Optional,
        Repetion,
        Grouping,
        Special_Sequence
      end

      def initialize(@childs, @type); end

      JSON.mapping(
        childs: Array(Atom),
        type: Type
      )
    end

    class Parser
      def self.parse(input : String)
        parse lex input
      end

      private def self.lex(string : String)
        tokens = Array(Token).new
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?

          next if scanner.skip(/h+/) || scanner.skip(/\(\*[^\)\*]\)\*/)

          c = if s = scanner.scan(/=/)
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
            :left_brace
          elsif s = scanner.scan(/\)/)
            :right_brace
          elsif s = scanner.scan(/\?/)
            :question
          elsif s = scanner.scan(/\|/)
            :bar
          elsif s = scanner.scan(/\-/)
            :exception
          elsif s = scanner.scan(/\"\w*\"/)
            :string
          elsif s = scanner.scan(/\'\w*\'/)
            :string
          elsif s = scanner.scan(/\w*/)
            :identifier
          else
            scanner.offset += 1
            :unknown
          end

          tokens << {token: c, value: s, line: line, pos: s ? (scanner.offset - s.size) : scanner.offset - 1}
        end

        tokens
      end

      private def self.parse(tokens : Array(Token))
        grammar = Grammar.new type: Grammar::GrammarType::EBNF
        pos = -1
        while pos < tokens.size
          token = tokens[pos += 1]?
          break unless token
          lookahead = tokens[pos + 1]?
          break unless lookahead

          if token[:token] == :newline
            next
          elsif token[:token] == :identifier && lookahead[:token] == :definition
            pos_increment = parse_production token[pos + 2...-1], grammar
            pos += pos_increment
          else
            raise "Unexpected token #{token[:token]} at #{token[:line]}:#{token[:pos]}"
          end
        end

        grammar
      end

      private def self.parse_production(tokens, grammar)
        pos = -1
        accept = false
        rules = Array(Rule).new

        until accept || pos + 1 >= tokens.size
          token = tokens[pos += 1][:token]
          lookahead = tokens[pos + 1][:token]

          if token == :termination
            accept = true
          elsif token == :bar
            # After bar we expected any rule starting symbol but no newline
            raise "Empty rule" if lookahead == :newline
          elsif token == :newline
          end
        end
      end

      private def self.parse_rule

      end

      private macro match(name, lhs, rhs)
        private def self.match_{{name}}(tokens : Array(Token))
          pos = 0
          if tokens[pos][:token] == lhs
            until tokens[pos += 1][:token] == rhs
              pos += 1
            end
            pos
          else
            -1
          end
        end
      end

      match(optional, :right_square_brace, :left_square_brace)
      match(repetition, :right_curly_brace, :left_square_brace)
      match(grouping, :right_brace, :left_brace)
      match(special, :question, :question)
    end   # Parser
  end   # EBNF
end   # EBNF
