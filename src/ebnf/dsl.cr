require "./grammar"
require "./parser"

module EBNF
  class DSL
    getter grammar

    def initialize(grammar_type = ::EBNF::Grammar::Type::EBNF)
      @grammar = ::EBNF::Grammar.new grammar_type
      case grammar_type
      when ::EBNF::Grammar::Type::EBNF  then @parser = ::EBNF::EBNF::Parser
      when ::EBNF::Grammar::Type::BNF   then @parser = ::EBNF::BNF::Parser
      when ::EBNF::Grammar::Type::Bison then @parser = ::EBNF::Bison::Parser
      else raise InvalidGrammarType.new grammar_type.to_s
      end
      @current_production = ""
    end

    def production(name, &block)
      if name.is_a? Symbol
        @current_production = name.to_s
      else
        @current_production = name
      end
      @grammar[@current_production] = Production.new
      with self yield
      @current_production = ""
    end

    def clause(expression)
      raise "Invalid call to clause outside a production Definition" if @current_production.empty?
      @grammar[@current_production] << @parser.parse_rule(@parser.lex(expression), @grammar)[0]
    end

    def self.define(grammar_type = ::EBNF::Grammar::Type::EBNF)
      dsl = new grammar_type
      dsl.define do |dsl|
        with dsl yield
      end
      return dsl.grammar
    end

    def define
      with self yield self
      return @grammar
    end
  end
end

module EBNF
  class Grammar
    macro define(type = EBNF::Grammar::Type::EBNF, &block)
      EBNF::DSL.define {{type}} {{block}}
    end
  end
end
