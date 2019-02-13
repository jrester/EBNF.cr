require "./spec_helper"

describe "Grammar type recognizer" do
  it "Should recognize BNF Grammar" do
    EBNF::TypeRecognizer.recognize(BNF_TEST_GRAMMAR).should eq(EBNF::Grammar::Type::BNF)
  end

  it "Should recognize EBNF Grammar" do
    EBNF::TypeRecognizer.recognize(EBNF_TEST_GRAMMAR).should eq(EBNF::Grammar::Type::EBNF)
  end

  it "Should recognize Bison Grammar" do
    EBNF::TypeRecognizer.recognize(BISON_TEST_GRAMMAR_LONG).should eq(EBNF::Grammar::Type::Bison)
  end
end
