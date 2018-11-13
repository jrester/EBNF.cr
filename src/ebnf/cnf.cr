module EBNF
  module CNF
    # The steps to perform for createing a CNF
    enum Step
      START,
      TERM,
      BIN,
      DEL,
      UNIT
    end

    DEFAULT_ORDER = [Step::START, Step::TERM, Step::BIN, Step::DEL, Step::UNIT]

    # Introduce a new start rule
    def self.start(grammar : Grammar)
      # Check if there is already a start rule of the from: S' -> S $
      unless grammar.productions[grammar.start].unit?
        # Create a new start production to point to the previous start production
        start_production = Production.new [Rule.new [Nonterminal.new grammar.start] of Atom]
        # Make sure the production "S'" does not already exists
        unless grammar.productions.keys.includes? "S\'"
          grammar.start = "S\'"
        else
          grammar.start = "S#{start_production.hash}"
        end
        # Set the new start production
        grammar[grammar.start] = start_production
      end
    end

    def self.term(grammar : Grammar)
      grammar.each_production do |production|
        production.each do |rule|
          terminal_count = 0
          rule.atoms.each do |atom|
            if atom.is_a? Terminal
              terminal_count += 1
            end
          end

          if terminal_count > 1
            rule.atoms.each_with_index do |atom, i|
              if atom.is_a? Terminal
                grammar.productions["n_#{atom.value.hash}"] = Production.new [Rule.new [atom] of Atom]
                rule.atoms[i] = Nonterminal.new "n_#{atom.value.hash}"
              end
            end
          end
        end
      end
    end

    def self.bin(grammar : Grammar)
      grammar.each_production do |production|
        production.rules.each_with_index do |rule, i|
          # count the nonterminals in a rule
          non_terminal_count = 0
          rule.atoms.each do |atom|
            if atom.is_a? Nonterminal
              non_terminal_count += 1
            end
          end

          # if there are more than 2 nonterminal in a rule we introduce a new production for it
          if non_terminal_count > 2
            remain = rule.atoms.shift
            grammar.productions["n_#{rule.hash}"] = Production.new [Rule.new rule.atoms]
            production.rules[i] = Rule.new [remain, Nonterminal.new "n_#{rule.hash}"] of Atom
          end
        end
      end
    end

    def self.del(grammar : Grammar)
    end

    # elimanites all unit rules
    def self.unit(grammar : Grammar)
      grammar.each_production do |production|
        production.rules.each_with_index do |rule, i|
          # Check wether production is of form A := B
          if rule.atoms.size == 1
            if (atom = rule.atoms[0]).is_a? Nonterminal
              # Remove the unit rule
              production.delete_at i
              # Get rules of for nonterminal in unit production
              rules = grammar.productions[atom.value].rules
              production.rules.concat rules
            end
          end
        end
      end
    end

    def self.grammar_to_cnf(grammar : Grammar, order : Array(CNF::Step))
      order.each do |step|
        case step
        when CNF::Step::START then CNF.start grammar
        when CNF::Step::TERM  then CNF.term grammar
        when CNF::Step::BIN   then CNF.bin grammar
        when CNF::Step::DEL   then CNF.del grammar
        when CNF::Step::UNIT  then CNF.unit grammar
        end
      end
      grammar
    end
  end

  class Grammar
    # Transforms this grammar to CNF Grammar based on *order* and returns self
    # The default order is usally fine
    def to_cnf!(order = CNF::DEFAULT_ORDER)
      CNF.grammar_to_cnf self, order
    end

    # Same as `to_cnf` but clones self and returns the new grammar
    def to_cnf(order = CNF::DEFAULT_ORDER)
      CNF.grammar_to_cnf self.dup, order
    end
  end
end
