module EBNF
  class Item
    property rule
    property name
    property dot

    def initialize(@dot : Int32, @name : String, @rule : Rule)
    end

    def clone
      Item.new @dot, @name.clone, @rule.clone, @production
    end

    def advance
      if @dot < @rule.size
        @dot += 1
      end
    end

    def next
      if @dot < @rule.size
        @rule[@dot]
      end
    end

    def end?
      @dot == @rule.size
    end
  end
end
