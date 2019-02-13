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
    getter first_set : Hash(String, Set(Terminal))? = nil
    getter follow_set : Hash(String, Set(Terminal))? = nil

    enum Type
      EBNF,
      BNF,
      Bison

      def self.from_string(string : String)
        case string.upcase
        when "EBNF"          then EBNF
        when "BNF"           then BNF
        when "BISON", "YACC" then Bison
        else
          raise InvalidGrammarType.new string
        end
      end
    end

    def initialize(builder : JSON::PullParser)
      @productions = Hash(String, Production).new
      @type = Type::EBNF
      @start = nil
      @terminals = Set(String).new
      @resolved = false
      builder.read_begin_object
      while builder.kind != :end_object
        key = builder.read_object_key
        case key
        when "grammar_type"
          @type = Type.from_string builder.read_string
        when "root"
          @start = builder.read_string_or_null
        when "grammar"
          productions = Hash(String, Array(Array(String))).new(builder)
          productions.each do |key, production|
            @productions[key] = Production.new production, productions.keys
          end
          each_rule do |rule|
            @terminals = Set(String).new (rule.atoms.map { |atom| (atom.is_a?(Terminal) ? atom.value : nil) }).compact
          end
          resolve
        end
      end
      builder.read_end_object
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

    # Parses given string and returns `Grammar` or nil on unexpected/unknown token
    # If *stop_on_unkown* is false the whole string will be lexed and tried to be parsed
    def self.from?(input : String, stop_on_unknown? : Bool = true, resolve? : Bool = true, start : String | Symbol? = nil) : Grammar | Nil
      grammar_type = TypeRecognizer.recognize? input

      return if grammar_type.nil?

      case grammar_type
      when Type::EBNF
        EBNF.from?(input, stop_on_unkown, resolve?, start)
      when Type::BNF
        BNF.from?(input, stop_on_unkown, resolve?, start)
      when Type::Bison
        Bison.from?(input, stop_on_unkown, resolve?, start)
      end
    end

    # Parses the given string and returns `Grammar` and raises UnexpectedTokenError or UnknownTokenError
    def self.from(input : String, resolve? : Bool = true, start : String | Symbol? = nil) : Grammar
      case TypeRecognizer.recognize input
      when Type::EBNF
        EBNF.from(input, resolve?, start)
      when Type::BNF
        BNF.from(input, resolve?, start)
      when Type::Bison
        Bison.from(input, resolve?, start)
      else
        raise InvalidGrammarType.new 0
      end
    end

    # Parsers the given file and returns `Grammar` and raises UnexpectedTokenError or UnknownTokenError
    def self.from_file(path : String, resolve? : Bool = true, start : String | Symbol? = nil) : Grammar
      from File.read(path), resolve?, start
    end

    # Parses the given file and returns `Grammar` or nil on unexpected/unknown token
    # If *stop_on_unkown* is false the whole string will be lexed and tried to be parsed
    def self.from_file?(path : String, stop_on_unknwon? : Bool = true, resolve? : Bool = true, start : String | Symbol? = nil) : Grammar | Nil
      from? File.read(path), stop_on_unknown?, resolve?, start
    end

    def clone
      clone = Grammar.new @productions.clone, @type, @start.clone, @terminals.clone
      clone.resolve
    end

    def to_s(io = IO::Memory.new)
      @productions.each do |key, p|
        definition = case @type
                     when Type::EBNF  then "#{key} = "
                     when Type::BNF   then "<#{key}> ::= "
                     when Type::Bison then "#{key}:\n  "
                     else
                       raise InvalidGrammarType.new @type
                     end
        io << definition
        p.to_s io, @type
        io << "\n\n"
      end
      io
    end

    def to_json(builder : JSON::Builder)
      builder.object do
        builder.field "grammar_type", @type.to_s
        builder.field "root", @start
        builder.field "grammar", @productions
      end
    end

    def pretty_print(pp)
      pp.text self.to_s
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

    def nonterminal?(sym : Atom)
      if sym.is_a? Nonterminal
        nonterminal? sym.value
      else
        false
      end
    end

    def nonterminal?(sym : String)
      @productions[sym]? ? true : false
    end

    def terminal?(sym)
      if sym.is_a? Terminal
        nonterminal? sym.value
      else
        false
      end
    end

    def terminal?(sym)
      @terminals.includes? sym
    end

    def symbols
      nonterminals + terminals.to_a
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

    def new_start(name : String? = nil)
      start_production = Production.new [Rule.new [Nonterminal.new start] of Atom]
      start_name = (name ? name : "S_#{start_production.hash}")
      add_production start_name, start_production
      @start = start_name
      nil
    end
  end
end
