require "./spec_helper"

bnf_maleformed_grammar = <<-Grammar_Maleformed
<root>
Grammar_Maleformed

describe "BNF" do
  describe "#from" do
    it "returns grammar of type BNF" do
      grammar = EBNF::BNF.from BNF_TEST_GRAMMAR
      grammar.should be_a(EBNF::Grammar)
      grammar.type.should eq(EBNF::Grammar::Type::BNF)
    end
  end
end
