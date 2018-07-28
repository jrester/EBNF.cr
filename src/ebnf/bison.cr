require "string_scanner"
require "./grammar"

module EBNF
  module Bison
    class Rule < EBNF::Rule
      property action : String|Nil

      def initialize(@atoms = Array(Atom).new, @action = nil)
      end
    end

    class Empty < EBNF::Rule
      def initialize
        @atoms = Array(Atom).new
      end
    end

    class Parser
      def self.parse(string : String)
        parse lex string
      end

      private def self.lex(string)
        tokens = Array(Token).new
        line = 0

        scanner = StringScanner.new string

        while !scanner.eos?
          # skip spaces and comments
          next if (s = scanner.skip(/\s+/)) || (s = scanner.skip(/\/\*(|[^\*\/])\*\//))

          c = if s = scanner.scan(/:/)
                :colon
              elsif s = scanner.scan(/\|/)
                :bar
              elsif s = scanner.scan(/\;/)
                :semicolon
              elsif s = scanner.scan(/[a-z]([a-z0-9]|\_|\-)*/)
                :nonterminal
              elsif s = scanner.scan(/[A-Z]([A-Z0-9]|\_|\-)*/)
                :terminal
              elsif s = scanner.scan(/\{[^\}]+\}/)
                :code
              elsif s = scanner.scan(/\n/)
                line += 1
                :newline
              else
                scanner.offset += 1 # Otherwise we would test the same string all the time again without reaching an end
                :unknown
              end

          tokens << {token: c, value: s, line: line, pos: s ? (scanner.offset - s.size) : scanner.offset - 1}
        end

        tokens
      end

      private def self.parse(tokens)
        productions = Array(Production).new
        pos = -1

        while tokens.size > pos
          token = tokens[pos += 1]
          lookahead = tokens[pos += 1]

          if token[:token] == :newline
            next
          elsif token[:token] == :nonterminal && lookahead[:token] == :colon
            rules, pos_increment = parse_production(tokens[pos..-1])
            productions << Production.new token[:value].not_nil!, rules
            pos += pos_increment
          end
        end
        productions
      end

      private def self.parse_production(tokens)
        pos = -1
        rules = Array(EBNF::Rule).new

        while tokens.size > pos
          token = tokens[pos += 1]
          if token[:token] == :newline
            next
          elsif token[:token] == :bar
            if tokens[pos + 1][:token] != :nonterminal || tokens[pos + 1][:token] != :terminal
              rules << Empty.new
            else
              rule, pos_increment = parse_rule tokens[pos..-1]
              rules << rule
              pos += pos_increment
            end
          elsif token[:token] == :terminal || token[:token] == :nonterminal
            rule, pos_increment = parse_rule tokens[pos..-1]
            rules << rule
            pos += pos_increment
          end
        end
        {rules, pos}
      end

      private def self.parse_rule(tokens)
        rule = Bison::Rule.new
        pos = 0

        tokens.each do |t|
          pos += 1
          if t[:token] == :nonterminal
            rule.atoms << Atom.new t[:value].not_nil!, false
          elsif t[:token] == :terminal
            rule.atoms << Atom.new t[:value].not_nil!, true # remove ' and ' from string value
          elsif t[:token] == :code
            rule.action = t[:value].not_nil![1..-2] # remove { and } from code value
            break
          else
            break
          end
        end
        {rule, pos}
      end
    end

    def self.from(string)
      Parser.parse string
    end

    def self.from_file(path : String)
      from File.read path
    end
  end
end
