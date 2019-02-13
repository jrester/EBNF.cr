require "../grammar"

module EBNF
  abstract class Parser
    private def self._parse(input : String, exception? : Bool)
    end

    private macro error(exception)
      exception? ? {{exception}} : return nil
    end

    private def self.next_char_no_whitespace(input : String, index : Int32)
      while (char = input[index]?).try &.whitespace?
        index += 1
      end
      index
    end

    # Parses *input* and raises UnexpectedTokenError/UnkownTokenError
    def self.parse(input : String) : Grammar
      _parse(input, true).not_nil!
    end

    # Parses *input* and returns nil on an unexpected/unknown token
    def self.parse?(input : String) : Grammar | Nil
      _parse input, false
    end
  end
end
