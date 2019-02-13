require "./spec_helper"

bison_maleformed = <<-Maleformed_Grammar
root:
  789ß
  | bar
Maleformed_Grammar

describe "Bison" do
  describe "#from" do
    it "returns grammar of type Bison" do
      grammar = EBNF::Bison.from BISON_TEST_GRAMMAR_SHORT
      grammar.should be_a(EBNF::Grammar)
      grammar.type.should eq(EBNF::Grammar::Type::Bison)
    end

    it "should work" do
      grammar = EBNF::Bison.from BISON_TEST_GRAMMAR_LONG
    end
  end

  describe "#from?" do
    it "returns nil" do
      EBNF::Bison.from?(bison_maleformed).should be_nil
    end
  end

  describe "#from_file" do
    grammar = EBNF::Bison.from_file "./spec/bison.grammar"
  end
end
