class EBNF::TypeRecognizer
  # Recognizes type of grammar by counting different tokens
  def self._recognize(input : String) : Grammar::Type
    words = input.split(" ").size
    colon_count = input.count(':')
    semi_colon_count = input.count(';')
    equal_count = input.count('=')
    ebnf_def_end_ratio = (equal_count / semi_colon_count).round
    bnf_ident_ratio = (input.count('<') / input.count('>')).round
    bnf_def_ratio = ((colon_count / 2) / equal_count).round

    if bnf_ident_ratio == 1 && bnf_def_ratio == 1 && colon_count == 0
      Grammar::Type::BNF
    elsif ebnf_def_end_ratio == 1 && equal_count > 0 && semi_colon_count > 0
      Grammar::Type::EBNF
    elsif
      Grammar::Type::Bison
    else
      raise UnkownGrammarError.new
    end
  end

  def self.recognize(input : String) : Grammar::Type
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
          if input[index - 1] == ':' && input[index -2] == ':'
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

    if bison_def_count == 0 && ebnf_def_count == 0 && bnf_def_count > 0
      return Grammar::Type::BNF
    elsif bison_def_count == 0 && bnf_def_count == 0 && ebnf_def_count > 0
      return Grammar::Type::EBNF
    elsif ebnf_def_count == 0 && bnf_def_count == 0 && bison_def_count > 0
      return Grammar::Type::Bison
    else
      raise UnkownGrammarError.new
    end
  end
end
