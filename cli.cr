require "./src/ebnf"
require "option_parser"


def grammar_type_from_string(type : String) : EBNF::Grammar::Type
  case type.upcase
  when "EBNF" then EBNF::Grammar::Type::EBNF
  when "BNF" then EBNF::Grammar::Type::BNF
  when "BISON", "YACC" then EBNF::Grammar::Type::Bison
  else
    raise EBNF::InvalidGrammarType.new type
  end
end

class Config
  property stdin = false
  property file : String?
  property identify = false
  property grammar_type = EBNF::Grammar::Type::EBNF
  property verbose = false
end

config = Config.new

OptionParser.parse! do |parser|
  parser.banner = "Usage: ebnf [OPTION] file"
  parser.on("--stdin", "Read from stdin") { config.stdin = true }
  parser.on("-t TYPE", "--type=TYPE") { |type| config.grammar_type = grammar_type_from_string type }
  parser.on("-i", "--identify") { config.identify = true }
  parser.on("-v", "--verbose") { config.verbose = true }
  parser.on("-h", "--help", "Show this help") { puts parser }
  parser.unknown_args do |args|
    config.file = args[0]?
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option!"
    STDERR.puts "See --help for usage"
    exit(1)
  end
end

if (file = config.file).is_a? String
  puts "Reading from file"
  if config.identify
    pp EBNF::TypeRecognizer.recognize File.read(file)
  end
else

end
