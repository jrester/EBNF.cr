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
        raise "Not Implemented!"
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
              elsif s = scanner.scan(/$/)
                :EOF
              else
                scanner.offset += 1
                :unknown
              end

          tokens << {token: c,
                     value: s,
                     line: line,
                     pos: s ? (scanner.offset - s.size) : scanner.offset - 1}
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
          elsif token[:token] == :EOF
            break
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

        until accept || pos >= tokens.size
          token = tokens[pos += 1]?.try &.[:token]
          break unless token
          lookahead = tokens[pos + 1]?.try &.[:token]
          break unless lookahead

          if token == :termination
            accept = true
          elsif token == :bar
            next
          elsif token == :newline
            next
          end
        end
      end

      private def self.parse_rule
      end

      private macro match(name, from, to)
        private def self.match_{{name}}(tokens : Array(Token))
          pos = 0
          if tokens[pos][:token] == from
            until tokens[pos += 1][:token] == to
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
    end # Parser
  end   # EBNF
end     # EBNF
