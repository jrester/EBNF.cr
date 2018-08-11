module EBNF
  module CNF
    enum Step
      START,
      TERM,
      BIN,
      DEL,
      UNIT
    end

    def self.start(grammar : Grammar)
      grammar.productions["S0"] = Production.new [Rule.new [Nonterminal.new grammar.start] of Atom]
      grammar.start = "S0"
    end

    def self.term(grammar : Grammar)
      grammar.productions.each_value do |production|
        production.rules.each do |rule|
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
      grammar.productions.each_value do |production|
        production.rules.each_with_index do |rule, i|
          non_terminal_count = 0
          rule.atoms.each do |atom|
            if atom.is_a? Nonterminal
              non_terminal_count += 1
            end
          end

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

    def self.unit(grammar : Grammar)
      grammar.productions.each_value do |production|
        production.rules.each_with_index do |rule, i|
          if rule.atoms.size == 1
            if (atom = rule.atoms[0]).is_a? Nonterminal
              rule.atoms.clear
              rules = grammar.productions[atom.value].rules
              production.rules.concat rules
            end
          end
        end
      end
    end
  end

  class Grammar
    def to_cnf(order = [CNF::Step::START, CNF::Step::TERM, CNF::Step::BIN, CNF::Step::DEL, CNF::Step::UNIT])
      order.each do |step|
        case step
        when CNF::Step::START then CNF.start self
        when CNF::Step::TERM  then CNF.term self
        when CNF::Step::BIN   then CNF.bin self
        when CNF::Step::DEL   then CNF.del self
        when CNF::Step::UNIT  then CNF.unit self
        end
      end
    end
  end
end
