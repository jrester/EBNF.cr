require "./spec_helper"

describe "Grammar Conversion" do
  it "Should convert EBNF to BNF" do
    grammar = EBNF::EBNF.from EBNF_TEST_GRAMMAR
    grammar.to_bnf.type.should eq(EBNF::Grammar::Type::BNF)
  end

  it "Should convert Bison/YACC to BNF" do
    grammar = EBNF::Bison.from BISON_TEST_GRAMMAR_SHORT
    grammar.to_bnf.type.should eq(EBNF::Grammar::Type::BNF)
  end
end
