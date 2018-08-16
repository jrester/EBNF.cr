module EBNF
  class Error < Exception
  end

  class UnknownTokenError < Error
    def initialize(@char : Char | String, @line : Int32, @column : Int32)
      super("Unkown token #{@char} at #{@line}:#{@column}")
    end
  end

  class UnexpectedTokenError < Error
    def initialize(@token : Symbol, @value : String, @line : Int32, @column : Int32, @else : Array(Symbol) | Nil = nil)
      super("Unexpted token #{@token}(#{@value}) at #{@line}:#{@column}!#{"\nExpected: #{@else.not_nil!.join(", ")}" if @else}")
    end
  end
end
