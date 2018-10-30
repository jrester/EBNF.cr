module EBNF
  class Error < Exception
  end

  # Thrown by a Lexer if it sees an unknown token
  class UnknownTokenError < Error
    def initialize(@char : Char | String, @line : Int32, @column : Int32)
      super("Unkown token #{@char} at #{@line}:#{@column}")
    end
  end

  # Thrown by the parser when another token was expected
  class UnexpectedTokenError < Error
    def initialize(@token : Symbol, @value : String, @line : Int32, @column : Int32, @else : Array(Symbol) | Nil = nil)
      super("Unexpted token #{@token}(#{@value}) at #{@line}:#{@column}!#{"\nExpected: #{@else.not_nil!.join(", ")}" if @else}")
    end
  end

  class InvalidGrammarType < Exception
    def initialize(grammar_type : String|Int32)
      super("Invalid grammar type: #{grammar_type}")
    end
  end
end
