require "./grammar"

module EBNF
  module DFA
    alias Item = NamedTuple(production: String, dot_index: Int32)
    alias ItemSet = Hash(String, Array(Tuple(Rule, Int32)))


    class State
      def initialize(@kernel : Item, @item_set = ItemSet.new)
        @item_set << @kernel
      end
    end

    def self.closure(item : Item, grammar : Grammar)
      item_set = ItemSet.new
      grammar[item[:production]].each do | rule |
        item_set[item[:production]] = Array(Tuple(Rule, Int32)).new unless item_set[item[:production]]?
        item_set[item[:production]] << { rule, item[:dot_index]}
        if (nonterminal = rule[item[:dot_index]]?).is_a? Nonterminal
          item_set.merge! closure({production: nonterminal.value, dot_index: 0}, grammar) unless item_set[nonterminal.value]?
        end
      end
      item_set
    end

    def self.generate_dfa(grammar)
      start = grammar.start
      s0 = {production: start, dot_index: 0}
      item_set_0 = closure s0, grammar
      following = Set(String).new
      item_set_0.each do | key, value |
        value.each do | item |
          following << item[0][item[1]]
        end
      end
      following.each do | symbol |
        symbol
      end
    end

    def self.pp(item_set : ItemSet)
      item_set.each do | key, value |
        value.each do | rule |
          if key == item_set.first_key
            print "#{key} -> "
          else
            print "+ #{key} -> "
          end
          puts rule[0].to_s
        end
      end
    end

  end

  class Grammar
    # Create a DFA from the grammar
    #
    #
    def to_dfa(first_follow_table : FirstFollowTable? = nil, no_new_start : Bool = false)
      # Intruduce a new Start rule
      unless no_new_start && @productions[start].unit?
        productions["S#{start.hash}"] = Production.new [Rule.new [Nonterminal.new(start), Terminal.new "$"] of Atom ]
        @start = "S#{start.hash}"
      end

      # Generate First Follow if not given as argument
      first_follow_table = first_follow unless first_follow_table
      DFA.generate_dfa self
    end
  end
end
