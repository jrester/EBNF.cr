module EBNF
  module BNF
    def self.from_bison(grammar : Grammar)
      grammar.type = Grammar::Type::BNF

      grammar.each_production do |production|
        production.rules.each_with_index do |rule, i|
          if (bison_rule = rule).is_a? Bison::Rule
            production[i] = Rule.new bison_rule.atoms
          end
        end
      end
    end

    def self.from_ebnf(grammar : Grammar)
      grammar.type = Grammar::Type::BNF

      grammar.each_production do |production|
        production.rules.each do |rule|
          rule.atoms.each_with_index do |atom, j|
            if (special = atom).is_a? EBNF::Special
              case special.type
              when EBNF::Special::Type::Optional
                # TODO: When [] is surrounded by two other atoms we can intruduce two new rules
                # One with the items of Special and one without them
                # if (prev = rule.atoms[j - 1]?) && (_next = rule.atoms[j + 1]?)
                # production.rules.delete_at i
                # production.rules << Rule.new rule.atoms.insert(special.rules).flatten
                # production.rules << Rule.new (rule.atoms[j] = nil).compact!
                # else
                nonterminal = "Optional_#{special.hash}"
                grammar[nonterminal] = Production.new ([Empty.new] of Rule).concat(special.rules)
                rule.atoms[j] = Nonterminal.new nonterminal
                # end
              when EBNF::Special::Type::Repetion
                nonterminal_name = "Repetion_#{special.hash}"
                nonterminal = Nonterminal.new nonterminal_name

                unless grammar[nonterminal_name]?
                  # Otherwise there is no end
                  new_production = Production.new [Empty.new] of Rule

                  # Prepend the new nonterminal to each rule
                  special.rules.each do |special_rule|
                    special_rule.atoms.unshift nonterminal
                    new_production << special_rule
                  end

                  grammar[nonterminal_name] = new_production
                end
                rule.atoms[j] = nonterminal
              when EBNF::Special::Type::Grouping
                nonterminal_name = "Grouping_#{special.hash}"
                nonterminal = Nonterminal.new nonterminal_name

                unless grammar[nonterminal_name]?
                  grammar[nonterminal_name] = Production.new special.rules
                end

                rule.atoms[j] = nonterminal
              when EBNF::Special::Type::Exception
              end
            end
          end
        end
      end
      grammar
    end
  end

  class Grammar
    # Converts self to BNF grammar. Returns nil if already BNF
    def to_bnf
      dup = self.clone
      case @type
      when Type::BNF   then dup
      when Type::EBNF  then BNF.from_ebnf dup
      when Type::Bison then BNF.from_bison dup
      else
        raise InvalidGrammarType.new @type, "Trying to convert #{@type} to BNF"
      end
      dup
    end

    def to_bnf!
      case @type
      when Type::BNF   then self
      when Type::EBNF  then BNF.from_ebnf self
      when Type::Bison then BNF.from_bison self
      else
        raise InvalidGrammarType.new @type, "Trying to convert #{@type} to BNF"
      end
      self
    end
  end
end
