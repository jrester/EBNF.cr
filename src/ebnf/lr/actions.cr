module EBNF::LR
  alias Action = {Symbol, String | UInt64}

  # Those structs are used as an interface to create actions by just doing <Action>.new
  # instead of manually creating each action tuple

  struct GoTo
    def self.new(id : UInt64 | Int32) : Action
      {:goto, id.to_u64}
    end
  end

  struct Shift
    def self.new(id : UInt64 | Int32) : Action
      {:shift, id.to_u64}
    end
  end

  struct Accept
    def self.new : Action
      {:accept, 0_u64}
    end
  end

  struct Reduce
    def self.new(production : String) : Action
      {:reduce, production}
    end
  end
end
