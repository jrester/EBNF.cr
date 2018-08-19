require "string_scanner"
require "../grammar"
require "../macros"
require "./parser"

module EBNF
  module EBNF
    extend Base

    class Parser < ::EBNF::Parser
      SPECIAL_RIGHT_CHARACTERS = {:right_square_brace, :right_curly_brace,
                                  :right_brace, :exception}

      SPECIAL_LEFT_CHARACTERS = {:left_square_brace, :left_curly_brace, :left_brace}

      SPECIAL_CHARACTERS = SPECIAL_LEFT_CHARACTERS + SPECIAL_RIGHT_CHARACTERS

      RULE_CHARACTERS = {:special, :terminal, :nonterminal} + SPECIAL_CHARACTERS

      private def self.lex(string : String, exception? : Bool, stop_on_unknown? : Bool = false)
        tokens = Array(Token).new
        column = 0
        line = 0

        scanner = StringScanner.new string

        until scanner.eos?
          if (s = scanner.skip(/\h+/)) || (s = scanner.skip(/\(\*([^\)\*])*\)\*/))
            column += s
            next
          end

          token = if s = scanner.scan(/=/)
                    :definition
                  elsif s = scanner.scan(/,/)
                    :concation
                  elsif s = scanner.scan(/;/)
                    :termination
                  elsif s = scanner.scan(/\[/)
                    :right_square_brace
                  elsif s = scanner.scan(/\]/)
                    :left_square_brace
                  elsif s = scanner.scan(/\{/)
                    :right_curly_brace
                  elsif s = scanner.scan(/\}/)
                    :left_curly_brace
                  elsif s = scanner.scan(/\(/)
                    :right_brace
                  elsif s = scanner.scan(/\)/)
                    :left_brace
                  elsif s = scanner.scan(/\?([^\"])*\?/)
                    :special
                  elsif s = scanner.scan(/\|/)
                    :bar
                  elsif s = scanner.scan(/\-/)
                    :exception
                  elsif s = scanner.scan(/\"([^\"])*"/)
                    :terminal
                  elsif s = scanner.scan(/\'([^\'])*'/)
                    :terminal
                  elsif s = scanner.scan(/(\w|\-|\_)+/)
                    :nonterminal
                  elsif s = scanner.scan(/\n/)
                    line += 1
                    :newline
                  elsif s = scanner.scan(/$/)
                    :EOF
                  else
                    if exception?
                      raise UnknownTokenError.new (scanner.peek 1), line, column
                    elsif stop_on_unknown?
                      return nil
                    else
                      s = scanner.peek 1
                      scanner.offset += 1
                      :unknown
                    end
                  end

          s = s.lchop.rchop if token == :terminal

          tokens << {token: token,
                     value: s,
                     pos:   {line, column}}

          token != :newline ? (column += s.size) : (column = 0)
        end

        tokens
      end

      parse_function_for Grammar::Type::EBNF

      private def self.parse_production(tokens : Array(Token), grammar : Grammar, exception? : Bool)
        rules = Array(Rule).new
        pos = -1
        accept = false

        until accept || pos >= tokens.size
          token = tokens[pos += 1]?.try &.[:token]
          break unless token
          lookahead = tokens[pos + 1]?.try &.[:token]
          break unless lookahead

          if token == :termination
            accept = true
          elsif token == :bar || token == :newline || token == :concation
            next
          elsif RULE_CHARACTERS.includes? token
            rule, pos_increment = parse_rule tokens[pos..-1], grammar
            rules << rule
            pos += pos_increment
          else
            if exception?
              raise UnexpectedTokenError.new token, tokens[pos][:value], *tokens[pos][:pos]
            else
              return {nil, nil}
            end
          end
        end
        {rules, pos}
      end

      private def self.parse_rule(tokens : Array(Token), grammar : Grammar)
        rule = Rule.new
        accept = false
        pos = -1

        until accept || pos + 1 >= tokens.size
          token = tokens[pos += 1]?.try &.[:token]
          break unless token

          if token == :nonterminal
            rule.atoms << Nonterminal.new tokens[pos][:value]
          elsif token == :terminal
            rule.atoms << Terminal.new tokens[pos][:value]
            grammar.terminals << tokens[pos][:value]
          elsif SPECIAL_RIGHT_CHARACTERS.includes? token
            special, pos_increment = parse_special token, tokens[pos..-1], grammar
            rule.atoms << special
            pos += pos_increment
          elsif token == :concation
            next
          else
            pos -= 1
            accept = true
          end
        end
        {rule, pos}
      end

      # OPTIMIZE
      private def self.parse_special(special_type, tokens, grammar)
        special = Special.for special_type
        raise "BUG: Unable to parse #{special_type} correctly" unless special
        pos = 0
        # For an Exception we only need to parse the next token
        if special.type == Special::Type::Exception
          token = tokens[pos += 1][:token]

          if SPECIAL_RIGHT_CHARACTERS.includes? token
            special, pos_increment = parse_special token, tokens[pos..-1], grammar
            pos += pos_increment
            special.rules << Rule.new [special] of Atom
          elsif token == :nonterminal
            special.rules << Rule.new [Nonterminal.new tokens[pos][:value]] of Atom
          elsif token == :terminal
            special.rules << Rule.new [Terminal.new tokens[pos][:value]] of Atom
          end
        else
          end_token = Special.end_token_for special.type
          raise "Unknown end token for #{special.type}" unless end_token
          atoms = Array(Atom).new
          accept = false

          until accept || pos + 1 >= tokens.size
            token = tokens[pos += 1]?.try &.[:token]
            break unless token

            if token == end_token
              accept = true
            elsif token == :bar
              special.rules << Rule.new atoms.dup
              atoms.clear
            elsif token == :concation
              next
            elsif token == :nonterminal
              atoms << Nonterminal.new tokens[pos][:value]
            elsif token == :terminal
              atoms << Terminal.new tokens[pos][:value]
              grammar.terminals << tokens[pos][:value]
            elsif SPECIAL_RIGHT_CHARACTERS.includes? token
              special, pos_increment = parse_special token, tokens[pos..-1], grammar
              pos += pos_increment
              special.rules << Rule.new [special] of Atom
            else
              accept = true
            end
          end
          special.rules << Rule.new atoms unless atoms.empty?
        end
        {special, pos}
      end
    end # Parser
  end   # EBNF
end     # EBNF
