require "../src/ebnf"
require "colorize"

begin
    EBNF::CLI.new.run ARGV
rescue e : EBNF::Error
    e.print STDERR
    exit 1
end
