require "json"

module EBNF
  # A collection of one or more `Rule`s
  #
  #    <foo> ::= '1' | '2'
  #
  # A Production with 2 rules
  class Production
    property rules : Array(Rule)

    def initialize(@rules = Array(Rule).new)
    end

    def initialize(rules : Array(Array(String)), nonterminals : Array(String))
      @rules = Array(Rule).new
      rules.each { |rule| @rules << Rule.new rule, nonterminals }
    end

    def clone
      Production.new @rules.clone
    end

    def to_json(builder : JSON::Builder)
      builder.array do
        @rules.each { |rule| rule.to_json(builder) }
      end
    end

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

    # Crystal version 0.25.0 can't handle delegation of []= correctly
    def []=(index : Int32, rule : Rule)
      @rules[index] = rule
    end

    delegate :[], :[]?, :<<, to: @rules
    delegate :size, :delete_at, :delete, :empty?, :each, :last?, to: @rules

    def_hash @rules
  end
end
