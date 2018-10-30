require "string_scanner"

require "../grammar"

require "./base"
require "./parser"

module EBNF
  module BNF
    extend Base

    class Parser < Parser
      private def self.lex(string : String, exception? : Bool, stop_on_unknown? : Bool = false)
        tokens = Array(Token).new
        column = 0
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?
          if s = scanner.skip(/\h+/)
            column += s
            next
          end

          token = if s = scanner.scan(/::=/)
                    :definition
                  elsif s = scanner.scan(/\|/)
                    :bar
                  elsif s = scanner.scan(/\<(\w|\-|\_)+\>/)
                    :nonterminal
                  elsif s = scanner.scan(/\"([^\"])*\"/)
                    :terminal
                  elsif s = scanner.scan(/\'([^\'])*\'/)
                    :terminal
                  elsif s = scanner.scan(/\n/)
                    line += 1
                    :newline
                  elsif s = scanner.scan(/$/)
                    :EOF
                  else
                    if exception?
                      raise UnknownTokenError.new scanner.peek(1), line, column
                    elsif stop_on_unknown?
                      return nil
                    else
                      s = scanner.peek 1
                      scanner.offset += 1
                      :unknown
                    end
                  end

          # strip ", ' and < >
          s = s.lchop.rchop if token == :nonterminal || token == :terminal

          tokens << {token: token,
                     value: s,
                     pos:   {line, column}}

          token != :newline ? (column += s.size) : (column = 0)
        end
        tokens
      end

      parse_function_for Grammar::Type::BNF

      def self.parse_production(tokens, grammar, exception? : Bool)
        pos = -1
        accept = false
        rules = Array(Rule).new

        until accept || pos >= tokens.size
          token = tokens[pos += 1]?.try &.[:token]
          break unless token
          lookahead = tokens[pos + 1]?.try &.[:token]
          break unless lookahead

          # puts "token: #{token}, lookahead: #{lookahead}, pos: #{pos}"

          if token == :newline
            if lookahead == :nonterminal
              accept = true
            else
              next
            end
          elsif token == :bar
            next
          elsif token == :nonterminal || token == :terminal
            rule, pos_increment = parse_rule tokens[pos..-1], grammar
            rules << rule
            pos += pos_increment
          else
            if exception?
              raise UnexpectedTokenError.new token, tokens[pos][:value], *tokens[pos][:pos], [:newline, :bar, :nonterminal, :terminal]
            else
              return {nil, nil}
            end
          end
        end
        {rules, pos}
      end

      def self.parse_rule(tokens, grammar)
        rule = Rule.new
        pos = -1

        tokens.each do |t|
          if t[:token] == :nonterminal
            rule << Nonterminal.new t[:value]
          elsif t[:token] == :terminal
            grammar.terminals << t[:value]
            rule << Terminal.new t[:value]
          else
            break
          end

          pos += 1
        end
        {rule, pos}
      end
    end
  end
end
