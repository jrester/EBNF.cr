require "../grammar"

require "./base"
require "./parser"

module EBNF::Bison
  extend Base

  class Parser < Parser
    private macro error_loc
      {line: line, col: col - 1, length: 1}
    end

    private def self._parse(input : String, exception? : Bool)
      grammar = Grammar.new type: Grammar::Type::Bison
      line = 1
      col = 0

      cur_production : Production? = nil
      cur_rule : Rule? = nil

      nonterminal = String.new
      terminal = String.new
      code = String.new

      in_nonterminal = false
      in_terminal = false
      in_code = false
      in_string = false

      index = -1
      while (char = input[index += 1]?)
        col += 1

        case char
        when ' '
          if cur_rule
            if in_nonterminal
              cur_rule << Nonterminal.new nonterminal unless nonterminal.empty?
              nonterminal = String.new
            elsif in_terminal
              cur_rule << Terminal.new terminal
              terminal = String.new
            end
          end
          in_nonterminal = false
          in_terminal = false
          next
        when '\n'
          line += 1
          col = 0
          if cur_rule
            if in_nonterminal
              cur_rule << Nonterminal.new nonterminal unless nonterminal.empty?
              nonterminal = String.new
            elsif in_terminal
              cur_rule << Terminal.new terminal
              terminal = String.new
            end
          end
          in_nonterminal = false
          in_terminal = false
          next
        when '\\'
          next_char = "#{char}#{input[index += 1]}"
          col += 1
          if in_string
            terminal += next_char
          elsif in_code
            code += next_char
          elsif in_nonterminal
            nonterminal += next_char
          end
          next
        when '}'
          next if in_string
          in_code ? (in_code = false) : (error raise ParserError.new "Unexpected end of code section!", input, error_loc)
          next
        when '\''
          in_string ? (in_string = false) : (in_string = true)
          if cur_rule
            cur_rule << Terminal.new terminal
            terminal = String.new
          end
          next
        end

        if in_string
          terminal += char
          next
        elsif in_code
          code += char
          next
        end

        case char
        when ':'
          cur_production = Production.new
          production_name = String.new
          if nonterminal.empty?
            if cur_rule
              _production_name = cur_rule.pop
              if _production_name.is_a? Terminal
                error raise ParserError.new "Expected nonterminal before production definition!", input, error_loc
              elsif _production_name.is_a? Nonterminal
                production_name = _production_name.value
              end
            end
          else
            production_name = nonterminal
            nonterminal = String.new
          end
          cur_rule = Rule.new
          cur_production << cur_rule
          grammar.add_production production_name, cur_production
        when '|'
          unless cur_production.nil?
            unless cur_rule.nil?
              unless nonterminal.empty?
                cur_rule << Nonterminal.new nonterminal
                nonterminal = String.new
              end
              unless terminal.empty?
                cur_rule << Terminal.new terminal
                terminal = String.new
              end
            end
            cur_rule = Rule.new
            cur_production << cur_rule
          else
            error raise ParserError.new "Unexpected rule divider!", input, error_loc
          end
        when ';'
          if cur_production.nil?
            error raise ParserError.new "Production termination out of Production definition!", input, error_loc
          else
            cur_production = nil
          end
        when '{'
          in_code = true
        when .lowercase?
          in_nonterminal = true
          nonterminal += char
        when .uppercase?
          in_terminal = true
          terminal += char
        when '_'
          if in_terminal
            terminal += char
          elsif in_nonterminal
            nonterminal += char
          else
            error raise UnexpectedTokenError.new char, input, error_loc
          end
        else
          error raise UnexpectedTokenError.new  char, input, error_loc
        end
      end
      return grammar
    end
  end
end