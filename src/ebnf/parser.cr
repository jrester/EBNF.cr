module EBNF
  abstract class Parser
    # Lexes *input* and raises UnknownTokenError
    def self.lex(intput : String)
      lex input, true
    end

    # Lexes *input* and returns nil on unknown token
    def self.lex?(input : String)
      lex? input, true
    end

    # Lexes *input* but doesn't stop on unknown token when *stop_on_unkown* is false abd returns `Array(Token)` with `:unknown` in it
    def self.lex?(input : String, stop_on_unknown? : Bool)
      lex input, false, stop_on_unknown?
    end

    # Parses *input* and returns nil on an unexpected/unknown token
    def self.parse?(input : String)
      parse? input, false
    end

    def self.parse?(input : String, stop_on_unknown? : Bool)
      parse lex?(input, stop_on_unknown?), false
    end

    # Parses *input* and raises UnexpectedTokenError/UnkownTokenError
    def self.parse(input : String)
      parse lex(input, true), true
    end

    # The parse function is the same for each CFG type
    #
    # To include the parse function for EBNF:
    #
    #     parse_function_for Grammar::Type::EBNF
    #
    macro parse_function_for(type)
      # Parses *tokens* and returns `Grammar`
      # If *exception?* is true, raises UnexpectedTokenError else returns nil
      private def self.parse(tokens : Array(Token)|Nil, exception? : Bool)
        return nil unless tokens
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
            if exception?
              nil
            else
              raise UnexpectedTokenError.new token[:token], token[:pos][0], token[:pos][1]
            end
          end
        end
        grammar
      end
    end
  end
end
