module EBNF
  class Error < Exception
  end

  class UnknownTokenError < Error
    def initialize(@char : Char | String, @line : Int32, @column : Int32)
      super("Unkown token #{@char} at #{@line}:#{@column}")
    end
  end

  class UnexpectedTokenError < Error
    def initialize(@token : Symbol, @line : Int32, @column : Int32)
      super("Unexpted token #{@token} at #{@line}:#{@column}")
    end
  end
end
