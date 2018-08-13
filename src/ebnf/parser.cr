module EBNF
  abstract class Parser
    def self.parse(input : String)
      parse lex input
    end

    macro parse_function_for(type)
      private def self.parse(tokens : Array(Token))
        grammar = Grammar.new type: {{type}}
        pos = -1

        while pos < tokens.size
          token = tokens[pos += 1]?
          break unless token
          lookahead = tokens[pos + 1]?
          break unless lookahead

          if token[:token] == :newline
            next
          elsif token[:token] == :nonterminal && lookahead[:token] == :definition
            # Must be 'pos + 2' so we don't parse the :definition again
            rules, pos_increment = parse_production tokens[pos + 2..-1], grammar
            grammar.productions[token[:value]] = Production.new rules
            # we must add 2 to pos_increment because we passed 'tokens[pos + 2..-1]'
            pos += pos_increment + 2
          elsif token[:token] == :EOF
            break
          else
            raise UnexpectedTokenError.new token[:token], token[:pos][0], token[:pos][1]
          end
        end
        grammar
      end
    end
  end
end
