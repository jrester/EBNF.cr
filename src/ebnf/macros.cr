module EBNF
  module Base
    macro extended
      def self.from(input : String)
        Parser.parse(input)
      end

      def self.from_file(path : String)
        from File.read path
      end
    end
  end
end
