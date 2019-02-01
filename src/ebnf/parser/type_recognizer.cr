class EBNF::TypeRecognizer
  def self.recognize(input : String) : Grammar::Type
    grammar_type = TypeRecognizer.recognize? input
    raise UnkownGrammarError.new if grammar_type.nil?
    grammar_type
  end

  def self.recognize?(input : String) : Grammar::Type?
    index = 0
    in_string = false

    bison_def_count = 0
    bison_code_begin = false
    bison_code_count = 0

    ebnf_def_start = false
    ebnf_def_count = 0

    bnf_def_count = 0
    begin_bnf_ident = false
    bnf_ident_count = 0

    input.each_char do |char|
      index += 1

      case char
      when '"'
        if input[index - 1] != '\\'
          in_string ? (in_string = false) : (in_string = true)
        end
      when '\''
        if input[index - 1] != '\\'
          in_string ? (in_string = false) : (in_string = true)
        end
      end

      next if in_string

      case char
      when '<'
        begin_bnf_ident = true
      when '>'
        bnf_ident_count += 1 if begin_bnf_ident
        begin_bnf_ident = false
      when ':'
        bison_def_count += 1
      when '='
        if input[index - 1] == ':' && input[index - 2] == ':'
          bnf_def_count += 1
        else
          ebnf_def_start = true
        end
        bison_def_count -= 2
      when ';'
        ebnf_def_count += 1 if ebnf_def_start
        ebnf_def_start = false
      when '{'
        bison_code_begin = true
      when '}'
        bison_code_count += 1 if bison_code_begin
        bison_code_begin = false
      end
    end

    if bison_def_count == 0 && ebnf_def_count == 0 && bnf_def_count > 0 && bison_code_count == 0
      return Grammar::Type::BNF
    elsif bison_def_count == 0 && bnf_def_count == 0 && ebnf_def_count > 0 && bison_code_count == 0
      return Grammar::Type::EBNF
    elsif ebnf_def_count == 0 && bnf_def_count == 0 && bison_def_count > 0
      return Grammar::Type::Bison
    else
      return nil
    end
  end
end
