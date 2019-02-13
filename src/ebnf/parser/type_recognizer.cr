class EBNF::TypeRecognizer
  def self.recognize(input : String) : Grammar::Type
    grammar_type = TypeRecognizer.recognize? input
    raise UnkownGrammarError.new if grammar_type.nil?
    grammar_type
  end

  def self.recognize?(input : String, strict? : Bool = false) : Grammar::Type?
    index = 0
    # This is necessary to recognize strings like "'" or '"'
    in_string_double = false
    in_string_single = false

    bison_def_count = 0

    curly_brace_begin = false
    curly_brace_count = 0

    brackets_begin = false
    brackets_count = 0

    ebnf_def_start = false
    ebnf_def_count = 0
    comma_count = 0

    bnf_def_count = 0
    begin_bnf_ident = false
    bnf_ident_count = 0

    index = -1
    while (char = input[index += 1]?)
      case char
      when "\\"
        index += 1
        next
      when '"'
        next if in_string_single
        in_string_double ? (in_string_double = false) : (in_string_double = true)
        next
      when '\''
        next if in_string_double
        in_string_single ? (in_string_single = false) : (in_string_single = true)
        next
      end

      next if in_string_double || in_string_single

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
          bison_def_count -= 2
        else
          ebnf_def_start = true
        end
      when ','
        comma_count += 1
      when ';'
        ebnf_def_count += 1 if ebnf_def_start
        ebnf_def_start = false
      when '{'
        curly_brace_begin = true
      when '}'
        curly_brace_count += 1 if curly_brace_begin
        curly_brace_begin = false
      when '['
        brackets_begin = true
      when ']'
        brackets_count += 1 if brackets_begin
        brackets_begin = false
      end
    end

    # Each grammar type has a possibility between 0 and 1
    ebnf = 0.0
    bnf = 0.0
    bison = 0.0

    if bison_def_count == 0 && ebnf_def_count == 0 && bnf_def_count > 0 && bnf_ident_count > 0 && curly_brace_count == 0 && brackets_count == 0
      bnf = 1.0
    elsif bison_def_count == 0 && bnf_def_count == 0 && ebnf_def_count > 0 && bnf_ident_count == 0 && brackets_count >= 0 && curly_brace_count >= 0
      ebnf = 1.0
    elsif ebnf_def_count == 0 && bnf_def_count == 0 && bison_def_count > 0 && bnf_ident_count == 0 && brackets_count == 0 && curly_brace_count >= 0
      bison = 1.0
    else
      unless strict?
        # TODO: Add prediction for grammar type
      end
    end

    if bnf < ebnf && bison < ebnf
      return Grammar::Type::EBNF
    elsif ebnf < bnf && bison < bnf
      return Grammar::Type::BNF
    elsif ebnf < bison && bnf < bison
      return Grammar::Type::Bison
    else
      return nil
    end
  end
end
