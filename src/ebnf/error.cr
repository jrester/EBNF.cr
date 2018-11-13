module EBNF
  class Error < Exception
  end

  class LexerError < Error
  end

  class ParserError < Error
  end

  # Thrown by a Lexer if it sees an unknown token
  class UnknownTokenError < LexerError
    def initialize(@char : Char | String, @line : Int32, @column : Int32)
      super("Unkown token #{@char} at #{@line}:#{@column}")
    end
  end

  # Thrown by the parser when another token was expected
  class UnexpectedTokenError < ParserError
    def initialize(@token : Symbol, @value : String, @line : Int32, @column : Int32, @else : Array(Symbol) | Nil = nil)
      super("Unexpted token #{@token}(#{@value}) at #{@line}:#{@column}!#{"\nExpected: #{@else.not_nil!.join(", ")}" if @else}")
    end
  end

  class InvalidGrammarType < Error
    def initialize(@grammar_type : String | Int32 | Grammar::Type, @message : String? = nil)
      super("Invalid grammar type: #{@grammar_type}#{(": #{@message}!" if @message)}")
    end
  end

  class ConversionError < Error
  end
end
