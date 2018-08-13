require "string_scanner"
require "./grammar"
require "./macros"
require "./parser"

module EBNF
  module Bison
    extend EBNF::Base

    class Rule < EBNF::Rule
      def initialize(@atoms = Array(Atom).new, @action = nil)
      end

      JSON.mapping(
        atoms: Array(Atom),
        action: String?
      )

      def to_s(io, grammar_type = Grammar::Type::Bison)
        super(io, grammar_type)
        io << "\t\t\t{#{@action}}" if @action
      end
    end

    class Parser < EBNF::Parser
      private def self.lex(string)
        tokens = Array(Token).new
        column = 0
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?
          # skip spaces and comments
          if (s = scanner.skip(/\h+/)) || (s = scanner.skip(/\/\*(|[^\*\/])\*\//))
            column += s
            next
          end

          token = if s = scanner.scan(/:/)
                    :colon
                  elsif s = scanner.scan(/\|/)
                    :bar
                  elsif s = scanner.scan(/\;/)
                    :semicolon
                  elsif s = scanner.scan(/[a-z]([a-z0-9]|\_|\-)*/)
                    :nonterminal
                  elsif s = scanner.scan(/[A-Z]([A-Z0-9]|\_|\-)*/)
                    :terminal
                  elsif s = scanner.scan(/\'(.|[^\'])'/)
                    s = s.lchop.rchop
                    :terminal
                  elsif s = scanner.scan(/\{[^\}]+\}/)
                    :code
                  elsif s = scanner.scan(/\n/)
                    line += 1
                    :newline
                  elsif s = scanner.scan(/$/)
                    :EOF
                  else
                    raise UnknownTokenError.new scanner.peek 1, line, scanner.offset
                  end

          tokens << {token: token,
                     value: s,
                     pos:   {line, column}}

          token != :newline ? (column += s.size) : (column = 0)
        end
        tokens
      end

      parse_function_for Grammar::Type::Bison

      private def self.parse_production(tokens, grammar)
        pos = -1
        accept = false
        rules = Array(::EBNF::Rule).new

        until accept || pos >= tokens.size
          token = tokens[pos += 1]?.try &.[:token]
          lookahead = tokens[pos + 1]?.try &.[:token]

          # puts "token: #{token}, lookahead: #{lookahead}, pos: #{pos}"

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
          end
        end
        {rules, pos}
      end

      private def self.parse_rule(tokens, grammar)
        rule = Bison::Rule.new
        pos = -1

        tokens.each do |t|
          if t[:token] == :nonterminal
            rule.atoms << Nonterminal.new t[:value]
          elsif t[:token] == :terminal
            grammar.terminals << t[:value].not_nil!
            rule.atoms << Terminal.new t[:value]
          elsif t[:token] == :code
            rule.action = t[:value][1..-2] # remove { and } from code
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
