require "option_parser"

class EBNF::CLI
    property parser

    # Arguments
    property file : String? = nil
    property outfile : String? = nil
    property grammar_type : ::EBNF::Grammar::Type? = nil

    enum Action
        JSON,
        CNF,
        BNF,
        IDENTIFY
    end

    property action : Action? = nil

    # Flags
    property stdin = false
    property verbose = false


    def initialize
        @parser = OptionParser.new do |parser|
            parser.banner = "Usage: ebnf [OPTIONS] file"
            parser.on("--stdin", "Read from stdin") { @stdin = true }
            parser.on("-j", "--json", "Export Grammar as json") { @action = Action::JSON }
            parser.on("-c", "--cnf", "Convert grammar to cnf") { @action = Action::CNF }
            parser.on("-b", "--bnf", "Convert grammar to bnf") { @action = Action::BNF }
            parser.on("-t TYPE", "--type=TYPE", "Provide type of grammar. If not provided grammar will be detected automatically.") { |type| @grammar_type = ::EBNF::Grammar::Type.from_string type }
            parser.on("-i", "--identify", "Identify grammar") { @action = Action::IDENTIFY }
            parser.on("-o FILE", "--out=FILE", "Output file") { |file| @outfile = file }
            parser.on("-v", "--verbose", "Be verbose") { @verbose = true }
            parser.on("-h", "--help", "Show this help") { puts parser; exit 0 }
           

            parser.unknown_args do |args|
              @file = args[0]?
            end

            parser.invalid_option do |option|
              raise Error.new("Unknown option: #{option}!")
            end
        end
    end

    def run(args = argv)
        @parser.parse args

        content = if (file = @file)
            File.read(file)
        elsif @stdin
            STDIN.gets_to_end
        else
            raise Error.new "No input file given!"
        end

        if (action = @action)
            execute action, content
        end
    end

    def execute(action : Action, content)
        grammar_type = @grammar_type.nil? ? TypeRecognizer.recognize(content) : @grammar_type.not_nil!

        if action == Action::IDENTIFY
            puts grammar_type
            exit 0
        else
            grammar = ::EBNF::Grammar.from content, grammar_type
            res = case action
            when Action::JSON
                grammar.to_json
            when Action::CNF
                grammar.to_cnf
            when Action::BNF
                grammar.to_bnf
            else
                raise Error.new "unknown action #{action}"
            end

            if (outfile = @outfile)
                File.write(outfile, res)
            else
                puts res
            end
        end
    end
end