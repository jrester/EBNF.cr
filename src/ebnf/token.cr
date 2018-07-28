module EBNF
  alias Token = NamedTuple(token: Symbol, value: String | Nil, line: Int32, pos: Int32)
end
