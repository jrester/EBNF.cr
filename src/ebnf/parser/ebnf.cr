require "string_scanner"

require "../grammar"

require "./base"
require "./parser"

module EBNF::EBNF
  extend Base

  class Parser < ::EBNF::Parser
    property in_double_string : Bool = false
    property in_single_string : Bool = false

    property index : Int32 = -1
    property line : Int32 = 1
    property col : Int32 = 0

    property terminal : String = String.new
    property nonterminal : String = String.new

    property in_rule : Bool = false
    property in_special : Bool = false
    property in_exception : Bool = false

    property special : Special = Special.new
    property rule : Rule = Rule.new
    # Used to store the rule before special
    property pre_rule : Rule? = nil
    property production : Production = Production.new

    property production_name : String = String.new

    property grammar : Grammar

    private def self._parse(input : String, exception? : Bool)
      parser = Parser.new(input, exception?)
      parser.grammar
    end

    def initialize(@input : String, @exception : Bool)
      @no_semicolon_backtrack = false
      @grammar = Grammar.new type: ::EBNF::Grammar::Type::EBNF
      parse
    end

    private def error(msg, length = 1)
      raise ParserError.new msg, @input, {line: @line, col: @col, length: length} if @exception
    end

    private def next_char
      @input[@index += 1]?
    end

    private def preprocess(char : Char) : Bool
      case char
      when ' '
        finish_nonterminal
      when ','
        finish_nonterminal
      when '\n'
        @line += 1
        @col = 0
      when '\\'
        parse_escape_char
      when '\''
        return false if @in_double_string
        @in_single_string ? in_string_add : (@in_single_string = true)
      when '"'
        return false if @in_single_string
        @in_double_string ? in_string_add : (@in_double_string = true)
      else
        return false
      end
      true
    end

    private def finish_nonterminal
      if @in_nonterminal && @in_rule
        @rule << Nonterminal.new @nonterminal
        @nonterminal = String.new
      end
      @in_nonterminal = false
    end

    private def parse_escape_char
      if @in_single_string || @in_double_string
        @terminal += "\\"
        @terminal += @input[@index += 1]
      elsif @in_nonterminal
        @nonterminal += "\\"
        @nonterminal += @input[@index += 1]
      end
    end

    private def close_special
      error "Missing starting token for special!" if @in_special == false
      return if @in_single_string || @in_double_string
      @in_special = false
      @special << @rule
      @pre_rule.not_nil! << @special
      @special = Special.new
      @rule = @pre_rule.not_nil!
    end

    private def start_special(type : Special::Type)
      @in_special = true
      @special.type = type
      @pre_rule = @rule
      @rule = Rule.new
    end

    private def in_string_add
      @rule << Terminal.new @terminal
      @terminal = String.new
      @in_double_string = false
      @in_single_string = false
    end

    private def get_last_nonterminal : String
      last_nonterminal = @nonterminal
      @nonterminal = String.new
      last_nonterminal
    end

    private def process(char : Char)
      case char
      when '='
        start_production
        @in_rule = true
      when '|'
        finish_rule
        @in_rule = true
      when ';'
        finish_rule
        @grammar.add_production @production_name, @production
        @in_rule = false
      when '{'
        start_special Special::Type::Repetion
      when '['
        start_special Special::Type::Optional
      when '('
        start_special Special::Type::Grouping
      when '-'
        start_special Special::Type::Exception
        @in_exception = true
      when '}'
        close_special
      when ']'
        close_special
      when ')'
        close_special
      when .ascii?
        @in_nonterminal = true
        @nonterminal += char
      else
        error "Unexpected character #{char}"
      end
    end

    private def finish_rule
      if @in_special
        @special << @rule
        if @in_exception
          @in_special = false
          @in_exception = false
        end
      else
        @production << @rule
      end
      @rule = Rule.new
    end

    private def start_production
      if @in_rule
        solve_missing_semicolon
      end
      @production = Production.new
      @production_name = get_last_nonterminal
    end

    private def solve_missing_semicolon
      error "Unexpected start of production! Maybe you forget a semicolon somewhere?" if @no_semicolon_backtrack
      last_rule = production.last?
      if last_rule
        if (nonterminal = last_rule.pop).is_a? Nonterminal
          @production_name = nonterminal.value
        else
          error "Unable to recover from missing semicolon: No nonterminal found"
        end
      else
        error "Unable to recover from missing semicolon: No previous rule found!"
      end
    end

    private def parse
      while (char = next_char)
        @col += 1
        next if preprocess char

        if @in_single_string || @in_double_string
          @terminal += char
          next
        end

        process char
      end
    end
  end
end # EBNF::EBNF
