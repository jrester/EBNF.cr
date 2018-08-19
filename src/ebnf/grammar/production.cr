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

    JSON.mapping(
      rules: Array(Rule)
    )

    def to_s(io, grammar_type = Grammar::Type::EBNF)
      @rules.join("\n  | ", io) { |r, io| r.to_s io, grammar_type }
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

    # Some helper functions

    def [](index : Int32)
      @rules[index]
    end

    def []?(index : Int32)
      @rules[index]?
    end

    def []=(index : Int32, rule : Rule)
      @rules[index] = rule
    end

    def <<(rule : Rule)
      @rules << rule
    end

    # Yields each rule
    def each
      @rules.each { |r| yield r }
    end

    # Check wether this production is of the form
    # A ::= B
    def unit?
      @rules.size == 1 && @rules[0].is_a? Nonterminal
    end

    def_hash @rules
  end
end
