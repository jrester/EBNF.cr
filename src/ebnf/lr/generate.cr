require "../grammar"
require "../cnf"

require "./actions"

module EBNF::LR
  class TransitionTable
    def self.generate(grammar : Grammar)
      stt = TransitionTable.new grammar
      # Create Start state
      start_item = Item.new 0, grammar.start, grammar[grammar.start][0]
      start_set = Set{start_item}
      close_state start_set, grammar
      stt.states[start_set] = {0, 0}
      # Generate the TransitionTable from this first state
      stt.generate
      stt
    end

    @[AlwaysInline]
    def collect_transitions(item_set : Set(Item))
      self.class.collect_transitions item_set
    end

    def self.collect_transitions(item_set : Set(Item))
      item_set.each_with_object(Hash(String, Set(Item)).new) do |item, transitions|
        if (following = item.next)
          transitions[following.to_s] ||= Set(Item).new
          transitions[following.to_s] << item.dup
        end
      end
    end

    def get_transition_actions(transitions)
      transitions.each_with_object(Hash(String, Array(Action)).new) do |(symbol, tstate), actions|
        tstate.each { |item| item.advance }
        close_state tstate

        id = @states[tstate]?.try &.[0] || @states.size
        @states[tstate] = {id, -1}

        actions[symbol] ||= Array(Action).new
        actions[symbol] << (@grammar.nonterminal?(symbol) ? GoTo.new id : Shift.new id)
      end
    end

    def get_reduce_accept_actions(item_set : Set(Item), actions : Hash(String, Array(Action)))
      item_set.each do |item|
        if item.end?
          if item.name == @grammar.start
            actions["EOS"] ||= Array(Action).new
            actions["EOS"] << Accept.new
          else
            reduce = Reduce.new item.name
            @grammar.terminals.each do |symbol|
              actions[symbol] ||= Array(Action).new
              actions[symbol] << reduce
            end
          end
        end
      end
    end

    def generate
      @states.each_key do |state|
        # collect each possible transition for this state
        transitions = collect_transitions state

        # Get all Shift and Goto actions for the transitions
        actions = get_transition_actions transitions

        # Add reduce and accept actions
        get_reduce_accept_actions state, actions

        # Look for cached action
        action_index = @actions.bsearch_index { |elem| elem == actions }
        unless action_index
          # No cached found so add them to @actions
          action_index = @actions.size
          @actions << actions
        end

        # Reasign with new action but old state id
        @states[state] = {@states[state][0], action_index}
      end
    end
  end

  def generate(grammar : Grammar)
    grammar = grammar.to_bnf if grammar.type == ::EBNF::Grammar::Type::EBNF
    grammar = grammar.to_cnf
    grammar.first_follow

    unless grammar[grammar.start].unit?
      grammar.new_start
    end

    grammar.follow_set

    TransitionTable.generate grammar
  end
end
