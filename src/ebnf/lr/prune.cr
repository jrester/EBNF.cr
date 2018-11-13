module EBNF::LR
  class TransitionTable
    def build_lookahead_set
      @states.each_with_object Array(String).new do |(item_set, data), lookahead|
        lookahead |= @grammar.follow[]
      end
    end

    def prune
      @states.each do |item_set, (id, action)|
        reductions = @actions[action].select { |elem| elem[0] == :reduce }

        reductions.each do |reduction|
          production = reduction[1].as(String)
        end
      end
    end
  end
end
