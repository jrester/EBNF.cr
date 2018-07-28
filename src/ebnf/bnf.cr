require "./grammar"

module EBNF
  module BNF
    class Parser
      def self.parse(string : String)
        parse lex string
      end

      private def self.lex(string : String)
        tokens = Array(Token).new
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?
          next if scanner.skip(/\s+/)

          c = if s = scanner.scan(/\:\:\=/)
                :assign
              elsif s = scanner.scan(/\|/)
                :bar
              elsif s = scanner.scan(/\<\w+\>/)
                :ident
              elsif s = scanner.scan(/\"\w*\"/)
                :string
              elsif s = scanner.scan(/\'\w*\'/)
                :string
              elsif s = scanner.scan(/\n/)
                line += 1
                :newline
              else
                scanner.offset += 1
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
          elsif token[:token] == :ident && lookahead[:token] == :bar
            rules, pos_increment = parse_production(tokens[pos..-1])
            productions << Production.new token[:value].not_nil![1..-2], rules
            pos += pos_increment
          end
        end
        productions
      end

      private def self.parse_production(tokens)
        pos = -1
        rules = Array(Rule).new

        while tokens.size > pos
          token = tokens[pos += 1]
          if token[:token] == :newline
            next
          elsif token[:token] == :bar && (tokens[pos + 1][:token] == :ident || tokens[pos + 1][:token] == :string)
            rule, pos_increment = parse_rule tokens[pos + 1..-1]
            rules << rule
            pos += pos_increment
          elsif token[:token] == :ident || token[:token] == :string
            rule, pos_increment = parse_rule tokens[pos..-1]
            rules << rule
            pos += pos_increment
          end
        end
        {rules, pos}
      end

      private def self.parse_rule(tokens)
        rule = Rule.new
        pos = 0

        tokens.each do |t|
          pos += 1
          if t[:token] == :ident
            rule.atoms << Atom.new t[:value].not_nil![1..-2], false
          elsif t[:token] == :string
            rule.atoms << Atom.new t[:value].not_nil![1..-2], true
          else
            break
          end
        end
        {rule, pos}
      end
    end

    def self.from(string : String)
      Parser.parse string
    end

    def self.from_file(path : String)
      from File.read path
    end

    def self.from_ebnf(grammar : Grammar)
      raise "Not Implemented"
    end

    def self.from_bison(grammar : Grammar)

    end
  end
end
