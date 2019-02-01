require "./src/ebnf"
require "option_parser"
require "colorize"

def error(msg : String)
  STDERR.puts "#{"ERROR".colorize(:red)}: #{msg}"
  STDERR.puts "See --help for usage details"
  exit(1)
end

def grammar_type_from_string(type : String) : EBNF::Grammar::Type
  case type.upcase
  when "EBNF"          then EBNF::Grammar::Type::EBNF
  when "BNF"           then EBNF::Grammar::Type::BNF
  when "BISON", "YACC" then EBNF::Grammar::Type::Bison
  else
    raise EBNF::InvalidGrammarType.new type
  end
end

class Config
  property stdin = false
  property file : String?
  property identify = false
  property grammar_type : EBNF::Grammar::Type? = nil
  property verbose = false
  property json = false
  property cnf = false
end

config = Config.new

OptionParser.parse! do |parser|
  parser.banner = "Usage: ebnf [OPTION] file"
  parser.on("--stdin", "Read from stdin") { config.stdin = true }
  parser.on("-j", "--json", "Export Grammar as json") { config.json = true }
  parser.on("--cnf", "Convert grammar to cnf") { config.cnf = true }
  parser.on("-t TYPE", "--type=TYPE") { |type| config.grammar_type = grammar_type_from_string type }
  parser.on("-i", "--identify") { config.identify = true }
  parser.on("-v", "--verbose") { config.verbose = true }
  parser.on("-h", "--help", "Show this help") { puts parser }
  parser.unknown_args do |args|
    config.file = args[0]?
  end
  parser.invalid_option do |flag|
    error "#{flag} is not a valid option!"
  end
end

if config.file
  execute config, File.read(config.file.not_nil!)
elsif config.stdin
  execute config, STDIN.gets_to_end
else
  error "No input file given!"
end

def execute(config : Config, content : String)
  if config.identify
    grammar_type = EBNF::TypeRecognizer.recognize?(content)
    grammar_type.nil? ? (puts "Unknown") : (puts grammar_type)
  else
    grammar = if config.grammar_type
                case config.grammar_type
                when EBNF::Grammar::Type::EBNF
                  EBNF::EBNF.from content
                when EBNF::Grammar::Type::BNF
                  EBNF::BNF.from content
                when EBNF::Grammar::Type::Bison
                  EBNF::Bison.from content
                end
              else
                EBNF::Grammar.from content
              end
    if config.json
      puts grammar.to_json
    end
  end
end
