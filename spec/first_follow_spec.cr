require "./spec_helper"

describe "First-Follow" do
  describe "EBNF Grammar" do
    it "Generates First-Follow-Table" do
      grammar = EBNF::EBNF.from EBNF_TEST_GRAMMAR
      grammar.first_follow
    end
  end
end
