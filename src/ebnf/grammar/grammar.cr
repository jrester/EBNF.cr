require "json"
require "./atom"
require "./rule"
require "./production"

module EBNF
  # Representation of a CFG
  class Grammar
    getter resolved : Bool # Indicate wether this grammar was already resolved
    property productions : Hash(String, Production)
    property type : Type
    property start : String | Nil
    property terminals : Set(String)

    enum Type
      EBNF,
      BNF,
      Bison
    end

    # Creates a CFG with *productions* with specified `Grammar::Type` *type*
    # *start* will be first production found in *productions*
    # *terminals* will be added when `Grammar` is created
    #
    # To create `Grammar` use #from or #from_file on the module of the Grammar type you want to parse
    def initialize(@productions = Hash(String, Production).new,
                   @type = Type::EBNF,
                   @start = nil,
                   @terminals = Set(String).new)
      @resolved = false
    end

    def to_s(io)
      @productions.each do |key, p|
        definition = case @type
                     when Type::EBNF  then "#{key} = "
                     when Type::BNF   then "<#{key}> ::= "
                     when Type::Bison then "#{key}:\n  "
                     else raise InvalidGrammarType.new @type
                     end
        io << definition
        p.to_s io, @type
        io << "\n\n"
      end
    end

    # Gets first production in grammar
    def start
      @start = @productions.first_key unless @start
      @start.not_nil!
    end

    # Gets all nonterminals in this grammar
    def nonterminals
      @productions.keys
    end

    # Changes name for each key value pair
    # See `#change_name`
    def change_name(prev_new : Hash(String, String))
      prev_new.each do |prev, new|
        change_name prev, new
      end
    end

    # Changes name of production *prev* with name *new*
    def change_name(prev : String, new : String)
      if @productions.has_key? prev
        @productions[new] = @productions[prev]
        @productiones.delete prev
      end
    end

    # Link each nonterminal with it's corresponding production
    # If no production exists for a nonterminal raises else returns self
    def resolve
      unless @resolved
        @productions.each_value do |production|
          production.resolve self
        end
        @resolved = true
      end
      self
    end

    # Link each nonterminal to it's corresponding production
    # If no production exists for a nonterminal returns nil else self
    def resolve?
      unless @resolved
        @productions.each_value do |production|
          return nil unless production.resolve? self
        end
        @resolved = true
      end
      self
    end

    # Access a production with *name*. Raises `KeyError` if not in grammar
    def [](name : String)
      @productions[name]
    end

    # Access a production with *name*. Returns `nil` if not in grammar
    def []?(name : String)
      @productions[name]?
    end

    # Sets a production with *name* to *production*
    def []=(name : String, production : Production)
      @productions[name] = production
    end

    def add_production(name : String, rules : Array(Rules))
      add_production name, Production.new(rules)
    end

    def add_production(name : String, production : Production)
      @productions[name] = production
    end

    # Yields each productions' name and rules
    def each
      @productions.each { |k, v| yield k, v }
    end

    # Yields each productions' rules
    def each_production
      @productions.each_value { |production| yield production }
    end

    def each_rule
      @productions.each_value &.each { |rule| yield rule }
    end
  end
end
