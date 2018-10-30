require "string_scanner"

require "../grammar"

require "./base"
require "./parser"

module EBNF
  module Bison
    extend Base

    class Parser < Parser
      private def self.lex(string, exception? : Bool, stop_on_unknown? : Bool = true)
        tokens = Array(Token).new
        column = 0
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?
          # skip spaces and comments
          if (s = scanner.skip(/\h+/)) || (s = scanner.skip(/\/\*(.)*\*\//))
            column += s
            next
          end

          token = if s = scanner.scan(/:/)
                    :definition
                  elsif s = scanner.scan(/\|/)
                    :bar
                  elsif s = scanner.scan(/\;/)
                    :semicolon
                  elsif s = scanner.scan(/[a-z]([a-z0-9]|\_|\-)*/)
                    :nonterminal
                  elsif s = scanner.scan(/[A-Z]([A-Z0-9]|\_|\-)*/)
                    :terminal
                  elsif s = scanner.scan(/\'([^\'])*'/)
                    s = s.lchop.rchop
                    :terminal
                  elsif s = scanner.scan(/\{[^\}]*\}/)
                    line += s.count "\n"
                    :code
                  elsif s = scanner.scan(/\n/)
                    line += 1
                    :newline
                  elsif s = scanner.scan(/$/)
                    :EOF
                  else
                    if exception?
                      raise UnknownTokenError.new scanner.peek(1), line, scanner.offset
                    elsif stop_on_unknown?
                      return nil
                    else
                      s = scanner.peek 1
                      scanner.offset += 1
                      :unknown
                    end
                  end

          tokens << {token: token,
                     value: s,
                     pos:   {line, column}}

          token != :newline ? (column += s.size) : (column = 0)
        end
        tokens
      end

      parse_function_for Grammar::Type::Bison

      def self.parse_production(tokens, grammar, exception? : Bool)
        pos = -1
        accept = false
        rules = Array(::EBNF::Rule).new

        until accept || pos >= tokens.size
          token = tokens[pos += 1]?.try &.[:token]
          break unless token
          lookahead = tokens[pos + 1]?.try &.[:token]
          unless lookahead && token != :EOF
            lookahead = :EOF
          end

          # puts "token: #{token}, lookahead: #{lookahead}, pos: #{tokens[pos][:pos]}"

          if token == :newline
            if lookahead == :bar
              # if this is the first token we have 'nonterminal:\n|' which results in an empty rule
              pos == 0 ? rules << Empty.new : next
            elsif pos == 0 && (lookahead == :nonterminal || lookahead == :terminal)
              # Only on the first token the next one can be nonterminal or terminal
              # Otherwise it is a new production
              next
            else
              accept = true
            end
          elsif token == :bar
            if lookahead == :newline || pos == 0
              # Allow: "| \n\n" and "foo: |"
              rules << Empty.new
            else
              next
            end
          elsif token == :nonterminal || token == :terminal
            rule, pos_increment = parse_rule tokens[pos..-1], grammar
            rules << rule
            pos += pos_increment
          else
            if exception?
              raise UnexpectedTokenError.new token, tokens[pos][:value], *tokens[pos][:pos]
            else
              return {nil, nil}
            end
          end
        end
        {rules, pos}
      end

      def self.parse_rule(tokens, grammar)
        rule = Bison::Rule.new
        pos = -1

        tokens.each do |t|
          if t[:token] == :nonterminal
            rule << Nonterminal.new t[:value]
          elsif t[:token] == :terminal
            grammar.terminals << t[:value].not_nil!
            rule << Terminal.new t[:value]
          elsif t[:token] == :code
            rule.action = t[:value][1..-2] # remove { and } from code
            pos += 1
            break
          else
            break
          end

          # Must be after the if's so pos is not incremented if we break
          pos += 1
        end
        {rule, pos}
      end
    end
  end
end
