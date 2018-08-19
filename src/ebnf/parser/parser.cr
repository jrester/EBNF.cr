require "../grammar"

module EBNF
  alias Token = NamedTuple(token: Symbol, value: String, pos: {Int32, Int32})

  abstract class Parser
    # Lexes *input* and raises UnknownTokenError
    def self.lex(input : String) : Array(Token)
      lex(input, true).not_nil!
    end

    # Lexes *input* and returns nil on unknown token
    def self.lex?(input : String) : Array(Token) | Nil
      lex input, false
    end

    # Lexes *input* but doesn't stop on unknown token when *stop_on_unkown* is false abd returns `Array(Token)` with `:unknown` in it
    def self.lex?(input : String, stop_on_unknown? : Bool) : Array(Token) | Nil
      lex input, false, stop_on_unknown?
    end

    # Parses *input* and raises UnexpectedTokenError/UnkownTokenError
    def self.parse(input : String) : Grammar
      parse(lex(input, true).not_nil!, true).not_nil!
    end

    # Parses *input* and returns nil on an unexpected/unknown token
    def self.parse?(input : String) : Grammar | Nil
      parse? input, false
    end

    def self.parse?(input : String, stop_on_unknown? : Bool) : Grammar | Nil
      tokens = lex?(input, stop_on_unknown?)
      parse tokens, false if tokens
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
      private def self.parse(tokens : Array(Token), exception? : Bool)
        grammar = Grammar.new type: {{type}}
        pos = -1

        while pos < tokens.size
          token = tokens[pos += 1]?
          break unless token
          lookahead = tokens[pos + 1]?
          break unless lookahead

          #puts "#{token}, #{lookahead}"

          if token[:token] == :newline
            next
          elsif token[:token] == :nonterminal && (lookahead[:token] == :definition || lookahead[:token] == :newline)
            if lookahead[:token] == :definition
              # Must be 'pos + 2' so we don't parse the :definition again
              rules, pos_increment = parse_production tokens[pos + 2..-1], grammar, exception?
              return nil unless pos_increment
              # we must add 2 to pos_increment because we passed 'tokens[pos + 2..-1]'
              pos += pos_increment + 2
            elsif lookahead[:token] == :newline && ((tokens[pos + 2]?.try &.[:token]) == :definition )
              rules, pos_increment = parse_production tokens[pos + 3..-1], grammar, exception?
              return nil unless pos_increment
              pos += pos_increment + 2
            end
            # `return nil unless rules || pos_increment` doesn't work
            # See https://github.com/crystal-lang/crystal/issues/3266 and #3412 for more information
            return nil unless rules
            grammar.productions[token[:value]] = Production.new rules
          elsif token[:token] == :EOF
            break
          else
            if exception?
              raise UnexpectedTokenError.new token[:token], token[:value], *token[:pos], [:newline, :nonterminal, :EOF]
            else
              return nil
            end
          end
        end
        grammar
      end
    end
  end
end
