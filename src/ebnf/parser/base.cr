module EBNF
  # This module is included for each Grammar type. It implements a consistent interface for parsing
  module Base
    macro extended

      # Parses given string and returns `Grammar` or nil on unexpected/unknown token
      # If *stop_on_unkown* is false the whole string will be lexed and tried to be parsed
      def self.from?(input : String, resolve? : Bool=true, start : String|Symbol?=nil) :  Grammar|Nil
        grammar = Parser.parse?(input)
        grammar.resolve if grammar && resolve?
        grammar.start = start.to_s if start
        grammar
      end

      # Parses the given string and returns `Grammar` and raises UnexpectedTokenError or UnknownTokenError
      def self.from(input : String, resolve? : Bool=true, start : String|Symbol?=nil) : Grammar
        grammar = Parser.parse(input)
        grammar.resolve if resolve?
        grammar.start = start.to_s if start
        grammar
      end

      # Parsers the given file and returns `Grammar` and raises UnexpectedTokenError or UnknownTokenError
      def self.from_file(path : String, resolve? : Bool=true, start : String|Symbol?=nil) : Grammar
        from File.read(path), resolve?, start
      end

      # Parses the given file and returns `Grammar` or nil on unexpected/unknown token
      # If *stop_on_unkown* is false the whole string will be lexed and tried to be parsed
      def self.from_file?(path : String, resolve? : Bool=true, start : String|Symbol?=nil) : Grammar|Nil
        from? File.read(path), resolve?, start
      end
    end
  end
end
