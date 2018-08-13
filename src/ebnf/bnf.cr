require "./grammar"
require "./parser"

module EBNF
  module BNF
    extend Base

    class Parser < EBNF::Parser
      private def self.lex(string : String)
        tokens = Array(Token).new
        column = 0
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?
          if s = scanner.skip(/\h+/)
            column += scan
            next
          end

          token = if s = scanner.scan(/::=/)
                    :definition
                  elsif s = scanner.scan(/\|/)
                    :bar
                  elsif s = scanner.scan(/\<(\w|\-)+\>/)
                    :nonterminal
                  elsif s = scanner.scan(/\"([^\"])*\"/)
                    :string
                  elsif s = scanner.scan(/\'([^\'])*\'/)
                    :string
                  elsif s = scanner.scan(/\n/)
                    line += 1
                    :newline
                  elsif s = scanner.scan(/$/)
                    :EOF
                  else
                    raise UnknownTokenError.new scanner.peek 1, line, scanner.peek
                  end

          # strip ", ' and < >
          s = s.lchop.rchop if token == :nonterminal || token == :string

          tokens << {token: token,
                     value: s,
                     pos:   {line, column}}

          token != :newline ? (column += s.size) : (column = 0)
        end
        tokens
      end

      parse_function_for Grammar::Type::BNF

      private def self.parse_production(tokens, grammar)
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
          elsif token == :nonterminal || token == :string
            rule, pos_increment = parse_rule tokens[pos..-1], grammar
            rules << rule
            pos += pos_increment
          end
        end
        {rules, pos}
      end

      private def self.parse_rule(tokens, grammar)
        rule = Rule.new
        pos = -1

        tokens.each do |t|
          if t[:token] == :nonterminal
            rule.atoms << Nonterminal.new t[:value]
          elsif t[:token] == :string
            grammar.terminals << t[:value]
            rule.atoms << Terminal.new t[:value]
          else
            break
          end

          pos += 1
        end
        {rule, pos}
      end
    end

    def self.from_ebnf(grammar : Grammar)
      raise "Not Implemented"
    end
  end
end
