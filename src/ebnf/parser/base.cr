module EBNF
  # This module is included for each Grammar type. It implements a consistent interface for parsing
  module Base
    macro extended

      # Parses given string and returns `Grammar` or nil on unexpected/unknown token
      # If *stop_on_unkown* is false the whole string will be lexed and tried to be parsed
      def self.from?(input : String, stop_on_unknown? : Bool=true, resolve? : Bool=true, start : String|Symbol?=nil) :  Grammar|Nil
        grammar = Parser.parse?(input, stop_on_unknown?)
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
      def self.from_file?(path : String, stop_on_unknwon? : Bool=true, resolve? : Bool=true, start : String|Symbol?=nil) : Grammar|Nil
        from? File.read(path), stop_on_unknown?, resolve?, start
      end
    end
  end
end
