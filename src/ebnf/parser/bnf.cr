require "../grammar"

require "./base"
require "./parser"

module EBNF
  module BNF
    extend Base

    class Parser < Parser
      private def self._parse(input : String, exception? : Bool = true)
        grammar = Grammar.new type: Grammar::Type::BNF
        line = 1
        col = 0

        in_string_double = false
        in_string_single = false
        in_nonterminal = false

        cur_rule : Rule? = nil
        cur_production : Production? = nil

        terminal = String.new
        nonterminal = String.new
        string_stack = Array(String).new

        index = -1
        while (char = input[index += 1]?)
          col += 1

          case char
          when ' '
            next
          when '\n'
            line += 1
            col = 0
            next
          when '\\'
            if in_string_double || in_string_single
              terminal += '\\'
              terminal += input[index += 1]
              col += 1
            elsif in_nonterminal
              nonterminal += '\\'
              nonterminal += input[index += 1]
              col += 1
            end
            next
          when '"'
            next if in_string_single
            if in_string_double
              if cur_rule
                cur_rule << Terminal.new terminal
                grammar.terminals << terminal
              end
              terminal = String.new
            end
            in_string_double ? (in_string_double = false) : (in_string_double = true)
            next
          when '\''
            next if in_string_double
            if in_string_single
              if cur_rule
                cur_rule << Terminal.new terminal
                grammar.terminals << terminal
              end
              terminal = String.new
            end
            in_string_single ? (in_string_single = false) : (in_string_single = true)
            next
          when '>'
            if in_nonterminal
              grammar.nonterminals << nonterminal
              if cur_rule
                cur_rule << Nonterminal.new nonterminal
              else
                string_stack << nonterminal
              end
              nonterminal = String.new
            end
            in_nonterminal = false
            next
          end

          if in_string_double || in_string_single
            terminal += char
            next
          elsif in_nonterminal
            if char.ascii?
              nonterminal += char
              next
            end
          end

          case char
          when ':'
            if (input[index + 1] == ':')
              if (input[index + 2] == '=')
                # Create new Production with name of prev nonterminal
                cur_production = Production.new
                if cur_rule
                  grammar[cur_rule.pop.as(Nonterminal).value] = cur_production
                else
                  grammar[string_stack.pop] = cur_production
                end
                if (next_char = next_char_no_whitespace(input, index)) == '|'
                  cur_rule = Empty.new
                else
                  cur_rule = Rule.new
                end
                cur_production << cur_rule
                index += 2
                col += 2
              else
                error raise ParserError.new "Expected '=' after '::'", input, {line: line, col: col - 1, length: 2}
              end
            elsif (input[index + 1]? == '=')
              error raise ParserError.new "Expected another ':' between ':' and '='", input, {line: line, col: col - 1, length: 2}
            else
              error raise ParserError.new "Unexpected ':'! You may want to replace it with '::='", input, {line: line, col: col, length: 1}
            end
          when '|'
            error raise ParserError.new "Unexpted '|'", input, {line: line, col: col, length: 1} unless cur_production
            if cur_production.empty?
              cur_rule = Empty.new
            else
              cur_rule = Rule.new
            end
            cur_production << cur_rule
          when '<'
            in_nonterminal = true
          else
            error raise ParserError.new "Unexpected character '#{char}'", input, {line: line, col: col, length: 1}
          end
        end
        grammar
      end
    end
  end
end
