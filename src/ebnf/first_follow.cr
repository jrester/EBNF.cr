require "./grammar"

module EBNF
  class Grammar
    alias FirstFollowTable = Tuple(Hash(String, Set(Terminal)))

    def first(name : String, first_set : Hash(String, Set(Terminal))) : Set(Terminal)
      # Look if first (name) was already processed
      if set = first_set[name]?
        return set
      end
      production = @productions[name]?
      raise "BUG: Grammar#first instanstiated with 'name': #{name} which is not a valid production in this grammar" unless production

      first_set[name] = Set(Terminal).new
      production.each do |r|
        if r.is_a? Empty
          first_set[name] << Terminal.new "EMPTY"
        elsif (atom = r.atoms[0]).is_a? Nonterminal
          first_set[name].concat first atom.value, first_set
        elsif (atom = r.atoms[0]).is_a? Terminal
          first_set[name] << atom
        end
      end
      first_set[name]
    end

    def first
      first_set = Hash(String, Set(Terminal)).new
      @productions.each_key { |key| first key, first_set }
      first_set
    end

    def follow(first_set)
      follow_set = Hash(String, Set(Terminal)).new
      @productions.each_key { |key| follow_set[key] = Set(Terminal).new }
      follow_set[start] << Terminal.new "$"

      updated = true

      while updated
        updated = false
        follow_set_before = follow_set.dup
        @productions.each do |key, production|
          production.each do |rule|
            rule.atoms.each_with_index do |atom, i|
              if atom.is_a? Nonterminal
                if (_next = rule.atoms[i + 1]?).is_a? Terminal
                  follow_set[atom.value] << _next
                elsif (_next = rule.atoms[i + 1]?).is_a? Nonterminal
                  if i + 2 == rule.atoms.size && first_set[_next.value].includes? "EMPTY"
                    follow_set[atom.value].concat follow_set[key]
                  end
                  follow_set[atom.value].concat first_set[_next.value]
                  follow_set[atom.value].delete "EMPTY"
                elsif i + 1 == rule.atoms.size
                  follow_set[atom.value].concat follow_set[key]
                end
              end
            end
          end
        end
        unless follow_set_before == follow_set
          updated = true
        end
      end
      follow_set
    end

    def first_follow
      first_set = FirstFollow.first
      {first_set, FirstFollow.follow first_set}
    end
  end
end
