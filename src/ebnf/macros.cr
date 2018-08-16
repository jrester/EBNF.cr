module EBNF
  module Base
    macro extended

      # Parses given string and returns `Grammar` or nil on unexpected/unknown token
      # If *stop_on_unkown* is false the whole string will be lexed and tried to be parsed
      def self.from?(input : String, stop_on_unknown? : Bool=true) :  Grammar|Nil
        Parser.parse?(input, stop_on_unknown?)
      end

      # Parses the given string and returns `Grammar` and raises UnexpectedTokenError or UnknownTokenError
      def self.from(input : String) : Grammar
        Parser.parse(input)
      end

      # Parsers the given file and returns `Grammar` and raises UnexpectedTokenError or UnknownTokenError
      def self.from_file(path : String) : Grammar
        from File.read path
      end

      # Parses the given file and returns `Grammar` or nil on unexpected/unknown token
      # If *stop_on_unkown* is false the whole string will be lexed and tried to be parsed
      def self.from_file?(path : String, stop_on_unknwon? : Bool=true) : Grammar|Nil
        from? File.read(path), stop_on_unknown?
      end
    end
  end
end
