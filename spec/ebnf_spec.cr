require "./spec_helper"

describe "EBNF" do
  describe "#from" do
    it "returns grammar of type EBNF" do
      grammar = EBNF::EBNF.from EBNF_TEST_GRAMMAR
      grammar.should be_a(EBNF::Grammar)
      grammar.type.should eq(EBNF::Grammar::Type::EBNF)
    end
  end
end
