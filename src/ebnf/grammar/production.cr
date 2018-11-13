require "json"

module EBNF
  # A collection of one or more `Rule`s
  #
  #    <foo> ::= '1' | '2'
  #
  # A Production with 2 rules
  class Production
    def initialize(@rules = Array(Rule).new)
    end

    def clone
      Production.new @rules.clone
    end

    JSON.mapping(
      rules: Array(Rule)
    )

    def to_s(io, grammar_type = Grammar::Type::EBNF)
      @rules.join("\n  | ", io) { |r, io| r.to_s io, grammar_type }
    end

    def pretty_print(pp)
      pp.text self.to_s
    end

    def resolve(grammar : Grammar)
      @rules.each do |rule|
        rule.resolve grammar
      end
    end

    def resolve?(grammar : Grammar)
      @rules.each do |rule|
        rule.resolve? grammar
      end
    end

    # Check wether this production is of the form
    # A ::= B
    def unit?
      @rules.size == 1 && @rules[0].is_a? Nonterminal
    end

    delegate :[], :[]?, :[]=, :<<, to: @rules
    delegate :size, :delete_at, :delete, :empty?, :each, to: @rules

    def_hash @rules
  end
end
