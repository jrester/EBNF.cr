require "colorize"

module EBNF
  class Error < Exception
    def error(msg, pos, io)
      io.print "Error: ".colorize.red.bold
      io.print msg.colorize.bright
      io.puts " (#{pos[0]}:#{pos[1]})"
    end

    private def source_to_line(source : String, line_num : Int32)
      source.each_line.to_a[line_num - 1]
    end

    def error_with_source(msg, source, pos : {line: Int32, col: Int32, length: Int32}, io)
      error msg, {pos[:line], pos[:col]}, io
      io.puts
      io.puts source_to_line source, pos[:line]
      pos[:col].times { io.print ' ' }
      io.print '^'
      (pos[:length] - 1).times { io.print '-' }
      io.puts
    end
  end

  class LexerError < Error
  end

  class ParserError < Error
    def initialize(@msg : String, @code = "", @pos = {line: 0, col: 0, length: 0})
      super(@msg)
    end

    def initialize(@msg : String, @code : String, @pos : {line: Int32, col: Int32, length: Int32})
      error_with_source @msg, @code, @pos, STDERR
    end
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

  class UnkownGrammarError < Error
    def initialize
      super("Couldn't recognize grammar type!")
    end
  end

  class ConversionError < Error
  end
end
