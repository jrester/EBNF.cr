require "./spec_helper"

bison_maleformed = <<-Maleformed_Grammar
root:
  789ß
  | bar
Maleformed_Grammar

bison_test_grammar = <<-Bison_Grammar

Bison_Grammar

describe "Bison" do
  describe "#from" do
    it "returns grammar of type Bison with terminals 'A' and 'B'" do
      grammar = EBNF::Bison.from BISON_TEST_GRAMMAR_SHORT
      grammar.should be_a(EBNF::Grammar)
      grammar.type.should eq(EBNF::Grammar::Type::Bison)
    end

    it "should work" do
      grammar = EBNF::Bison.from bison_test_grammar
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

  describe "#lex" do
    it "raises UnknownTokenError" do
      expect_raises(EBNF::UnknownTokenError) do
        EBNF::Bison::Parser.lex bison_maleformed
      end
    end
  end

  describe "#lex?" do
    it "returns nil" do
      EBNF::Bison::Parser.lex?(bison_maleformed).should be_nil
    end

    it "returns tokens with ':unknown'" do
      tokens = EBNF::Bison::Parser.lex?(bison_maleformed, false).not_nil!
      flag = false
      tokens.each do |token|
        if token[:token] == :unknown
          flag = true
        end
      end
      flag.should be_true
    end
  end
end
