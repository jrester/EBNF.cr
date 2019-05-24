require "colorize"

module EBNF
  class Error < Exception
    def self.error(msg, io)
      io.print "Error: ".colorize.red.bold
      io.puts msg.colorize.bright
    end

    def self.error_at(msg, pos, io)
      error msg, io
      io.puts " (#{pos[0]}:#{pos[1]})"
    end

    def self.error_with_source(msg, source, pos : {line: Int32, col: Int32, length: Int32}, io)
      error_at msg, {pos[:line], pos[:col]}, io
      io.puts
      io.puts source.each_line.to_a[pos[:line] - 1]
      pos[:col].times { io.print ' ' }
      io.print '^'
      (pos[:length] - 1).times { io.print '-' }
      io.puts
    end

    def print(io : IO)
      Error.error @message, io
    end
  end

  class ParserError < Error
    def initialize(@msg : String, @code = "", @pos = {line: 0, col: 0, length: 0})
      super(@msg)
    end

    def print(io : IO)
      Error.error_with_source @msg, @code, @pos, io
    end
  end

  class UnknownTokenError < ParserError
    def initialize(@char : Char | String, @line : Int32, @column : Int32)
      super("Unkown token #{@char} at #{@line}:#{@column}")
    end
  end

  class UnexpectedTokenError < ParserError
    def initialize(@token : Char, @code, @pos)
      super("unexpected token #{@token}", @code, @pos)
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
