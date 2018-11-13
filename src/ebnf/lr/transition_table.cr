require "./item"
require "./actions"

module EBNF::LR
  class TransitionTable
    getter states : Hash(Set(Item), {Int32, Int32})
    getter actions : Array(Hash(String, Array(Action)))
    getter grammar : Grammar

    def initialize(@grammar)
      @actions = Array(Hash(String, Array(Action))).new
      @states = Hash(Set(Item), {Int32, Int32}).new
    end

    # Collects each nonterminal following the items in this state and adds them to it's kernel
    @[AlwaysInline]
    def close_state(item_set : Set(Item))
      self.class.close_state item_set, @grammar
    end

    # Collects each nonterminal following the items in this state and adds them to it's kernel
    def self.close_state(item_set : Set(Item), grammar : Grammar)
      # Make sure we don't end up in an infinite loop
      (items = item_set.to_a).each do |item|
        # Check for a following nonterminal
        if (following = item.next) && grammar.nonterminal? following
          # Add each rule of the production to the item set
          grammar[following.to_s].each do |p_|
            item_set << Item.new 0, following.to_s, p_
          end
        end
      end
    end

    def to_s(io)
      @states.each do |item_set, (id, action)|
        io << id
        io << "     "
        io << @actions[action]
        io << "\n"
      end
    end

    def pretty_print(pp)
      pp.text to_s
      pp
    end
  end
end
