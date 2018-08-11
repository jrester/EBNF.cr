module EBNF
  module Base
    macro extended
      # Parses the given string and returns `Grammar`
      def self.from(input : String)
        Parser.parse(input)
      end

      # Parsers the given file and returns `Grammar`
      def self.from_file(path : String)
        from File.read path
      end
    end
  end
end
