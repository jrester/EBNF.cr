require "./ebnf/*"

grammar = <<-Grammar
root:
    foo             { puts "foo" }
    | bar           { puts "bar" }

foo:
    A B
    | B B

bar:
    B A
    | A B
Grammar

bison = EBNF::Bison.from grammar
puts bison.to_json
