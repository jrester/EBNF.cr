require "./grammar"

module EBNF
  module BNF
    extend Base

    class Parser
      def self.parse(string : String)
        parse lex string
      end

      private def self.lex(string : String)
        tokens = Array(Token).new
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?
          next if scanner.skip(/\h+/)

          c = if s = scanner.scan(/::=/)
                :assign
              elsif s = scanner.scan(/\|/)
                :bar
              elsif s = scanner.scan(/\<(\w|\-)+\>/)
                :identifier
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
                puts "Unkown token #{scanner.peek 1}"
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

      private def self.parse(tokens)
        grammar = Grammar.new type: Grammar::GrammarType::BNF
        pos = -1

        while pos < tokens.size
          token = tokens[pos += 1]?
          break unless token
          lookahead = tokens[pos + 1]?
          break unless lookahead

          #puts "token: #{token}, lookahead: #{lookahead}"

          if token[:token] == :newline
            next
          elsif token[:token] == :identifier && lookahead[:token] == :assign
            rules, pos_increment = parse_production tokens[pos + 2..-1], grammar
            grammar.productions[token[:value].not_nil!] = Production.new rules
            pos += pos_increment + 2
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

          #puts "token: #{token}, lookahead: #{lookahead}, pos: #{pos}"

          if token == :newline
            if lookahead == :identifier
              accept = true
            else
              next
            end
          elsif token == :bar
            next
          elsif token == :identifier || token == :string
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

          if t[:token] == :identifier
            rule.atoms << Nonterminal.new t[:value].not_nil!.lchop.rchop
          elsif t[:token] == :string
            grammar.terminals << t[:value].not_nil!
            rule.atoms << Terminal.new t[:value].not_nil!.lchop.rchop
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
