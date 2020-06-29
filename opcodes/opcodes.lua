--[[
    Structured Opcode & Enumerated Type Data.

    Groupings: All subsets of opcodes, metatable tokens, (labeled as a codetype)
        etc. that have some relationship; Groupings.Unsorted maintains all
        remaining values.

    Grouping API:
        Shared: Enumerated types that are locally one-to-one, i.e., only their
            relative offsets are related, and often follow the form:
                "#define lua_to_meta(op) cast(TMS, ((op) - %s) + %s)"
        Unshared: Other codetypes that are related but don't require maintain
            a structural relationship.
        Local: If true, all codetypes within this grouping can be shuffled while
            maintaining any "Shared" relationships.
        Validate: Any additional constraints/rules on a shuffling of this
            grouping.
        Post: Post-processing meta/rule information, e.g., mapping macros,
            limits, etc.

    Structure: IO handlers & meta-information that exists over all groupings.
        OneToOne: Code types that have one-to-one relationship over the entire
            shuffling, e.g., if Enum.X = Y, then ((OtherEnum) Y) = related to X.
        Rules: IO handler for writing post-processed (see: Grouping.Post)
            rules/macros/mappings to file.
        Output: IO handler for writing shuffled enumerated types to file.

    CodeTypes:
        LuaOp: lua.h operations.
        TM: metamethods
            [Opr]: Enumerated type.
            [Names]: Metamethod event name
        UnOps: unary operators.
        BinOps: binary operators
            [Opr]: Enumerated type.
            [Priorty]: Priority table for binary operators.
        Instructions:
            [Codes]: Enumerated type.
            [Names]: Name
        Modes: opmodes

        KInstructions: Instruction edge-case requiring special ordering.
        KModes: Opmode edge-case requiring special ordering.

    @EDGECASES:
        (1) KInstructions/KModes
        (2) To satisfy lua.h operations the Unary grouping is appended to the
            binary operator grouping after shuffling; with the intent being to
            allow the future shuffling of unary operators.
--]]
HeaderData = {
    Groupings = { },
    Enums = {
        "Tests", "LuaOp", "UnOps", "TM", "BinOps", "Instructions", "Modes",
        "KModes", "KInstructions",
    },
}

local ac = "[,|/](.*)"

--[[ TODO: hack to avoid GCC warnings w/ (x <= o) && (o <= y) rules, where x == 0 --]]
local function rangemacro(name, first, last)
return ([[
  #define %s(o)  (%s <= (o) && (o) <= %s)
]]):format(name, first, last)
end

HeaderData.Groupings.Comparison = {
    Local = false,
    Unshared = { },
    Shared = { "BinOps", "Instructions", "Modes" },

    Validate = function(self, order) return true end,
    Post = function(rules, self, order, directory)
        local cmpop_to_op = "#define cmpop_to_op(opr) cast(OpCode, ((opr) - OPR_EQ) + OP_EQ)"
        local ncmpop_to_op = "#define ncmpop_to_op(opr) cast(OpCode, ((opr) - OPR_NE) + OP_EQ)"
        local opcmp_to_opicmp = "#define opcmp_to_opicmp(op) cast(OpCode, ((op) - OP_LT) + OP_LTI)"

        rules.BinOps[#rules.BinOps + 1] = cmpop_to_op
        rules.BinOps[#rules.BinOps + 1] = ncmpop_to_op
        rules.BinOps[#rules.BinOps + 1] = opcmp_to_opicmp
    end,

    Enums = {
        BinOps = {
            Opr = {
                "OPR_EQ, /* comparison operator */",
                "OPR_LT, /* comparison operator */",
                "OPR_LE, /* comparison operator */",
                "OPR_NE, /* comparison operator */",
                "OPR_GT, /* comparison operator */",
                "OPR_GE, /* comparison operator */",
                "",
                "",
                "",
                "",
                "",
                "",
            },
            Priority = {
                "{3, 3}, /* == */",
                "{3, 3}, /* < */",
                "{3, 3}, /* <= */",
                "{3, 3}, /* ~= */",
                "{3, 3}, /* > */",
                "{3, 3}, /* >= */",
                "",
                "",
                "",
                "",
                "",
                "",
            },
        },
        Instructions = {
            Codes = {
                "OP_EQ, /* A B k   if ((R[A] == R[B]) ~= k) then pc++ */",
                "OP_LT, /* A B k   if ((R[A] <  R[B]) ~= k) then pc++ */",
                "OP_LE, /* A B k   if ((R[A] <= R[B]) ~= k) then pc++ */",
                "",
                "",
                "",
                "OP_EQK, /* A B  k  if ((R[A] == K[B]) ~= k) then pc++ */",
                "OP_EQI, /* A sB k  if ((R[A] == sB) ~= k) then pc++   */",
                "OP_LTI, /* A sB k  if ((R[A] < sB) ~= k) then pc++    */",
                "OP_LEI, /* A sB k  if ((R[A] <= sB) ~= k) then pc++   */",
                "OP_GTI, /* A sB k  if ((R[A] > sB) ~= k) then pc++    */",
                "OP_GEI, /* A sB k  if ((R[A] >= sB) ~= k) then pc++   */",
            },
            Names = {
                "\"EQ\",",
                "\"LT\",",
                "\"LE\",",
                "",
                "",
                "",
                "\"EQK\",",
                "\"EQI\",",
                "\"LTI\",",
                "\"LEI\",",
                "\"GTI\",",
                "\"GEI\",",
            },
        },
        Modes = {
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_EQ */",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_LT */",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_LE */",
            "",
            "",
            "",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_EQK */",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_EQI */",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_LTI */",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_LEI */",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_GTI */",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_GEI */",
        },
    }
}

HeaderData.Groupings.FastAccess = {
    Local = true,
    Unshared = { },
    Shared = { "TM" },

    Validate = function(self, order) return true end,
    Post = function(rules, self, order, directory)
        --local tmfast = "#define tmfast(o) (%s <= (o) && (o) <= %s)"
        --rules.TM[#rules.TM + 1] = tmfast:format(first, last)

        local TM = self.Enums.TM
        local first = string.rtrim(TM.Opr[order[1]], ac)
        local last = string.rtrim(TM.Opr[order[#order]], ac)
        rules.TM[#rules.TM + 1] = rangemacro("tmfast", first, last)
    end,

    Enums = {
        TM = {
            Opr = {
                "TM_INDEX,",
                "TM_NEWINDEX,",
                "TM_GC,",
                "TM_MODE,",
                "TM_LEN,",
                "TM_EQ,",
            },
            Names = {
                "\"__index\",",
                "\"__newindex\",",
                "\"__gc\",",
                "\"__mode\",",
                "\"__len\",",
                "\"__eq\",",
            },
        },
    }
}

--[[
@TODO:
    (1) Allow unary operators to be sorted
--]]
HeaderData.Groupings.Unary = {
    Local = false,
    Unshared = {  },
    Shared = { "TM", "LuaOp", "UnOps", "Instructions", "Modes", "Tests" },

    Validate = function(self, order) return true end,
    Post = function(rules, self, order, directory)
        local unarop_to_lua = "#define unarop_to_lua(op) (((op) - %s) + %s)"
        local unarop_to_op = "#define unarop_to_op(op) cast(OpCode, ((op) - %s) + %s)"

        local f = order[1]
        local uop_f = string.rtrim(self.Enums.UnOps[f], ac)
        local luop_f = string.rtrim(self.Enums.LuaOp[f], ac)
        local iuop_f = string.rtrim(self.Enums.Instructions.Codes[f], ac)
        rules.BinOps[#rules.BinOps + 1] = unarop_to_lua:format(uop_f, luop_f)
        rules.BinOps[#rules.BinOps + 1] = unarop_to_op:format(uop_f, iuop_f)
    end,
    Enums = {
        Tests = {
            "_",
            "!",
            "",
            "",
        },
        TM = {
            Opr = {
                "TM_UNM,",
                "TM_BNOT,",
                "",
                "",
            },
            Names = {
                "\"__unm\",",
                "\"__bnot\",",
                "",
                "",
            },
        },
        LuaOp = {
            "LUA_OPUNM   ",
            "LUA_OPBNOT  ",
            "",
            "",
        },
        UnOps = {
            "OPR_MINUS,",
            "OPR_BNOT,",
            "OPR_NOT,",
            "OPR_LEN,",
        },
        Instructions = {
            Codes = {
                "OP_UNM,        /* A B R[A] := -R[B]            */",
                "OP_BNOT,       /* A B R[A] := ~R[B]            */",
                "OP_NOT,        /* A B R[A] := not R[B]         */",
                "OP_LEN,        /* A B R[A] := length of R[B]   */",
            },
            Names = {
                "\"UNM\",",
                "\"BNOT\",",
                "\"NOT\",",
                "\"LEN\",",
            },
        },
        Modes = {
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_UNM */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_BNOT */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_NOT */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_LEN */",
        },
    }
}

HeaderData.Groupings.Binary = {
    Local = true,
    Unshared = { },
    Shared = { "TM", "LuaOp", "BinOps", "Instructions", "KInstructions", "Modes", "KModes" },

    Validate = function(self, order) return true end,
    Post = function(rules, self, order, directory)
        local lua_to_meta = "#define lua_to_meta(op) cast(TMS, ((op) - %s) + %s)"
        local op_to_meta = "#define op_to_meta(op) cast(TMS, ((op) - %s) + %s)"
        local binop_to_meta = "#define binop_to_meta(opr) cast(TMS, ((opr) - %s) + %s)"
        local binop_to_lua = "#define binop_to_lua(opr) (((opr) - %s) + %s)"
        local binop_to_kop = "#define binop_to_kop(opr) cast(OpCode, ((opr) - %s) + %s);"
        local binop_to_op = "#define binop_to_op(opr) cast(OpCode, ((opr) - %s) + %s);"

        --local foldop = "#define foldop(o)  (%s <= (o) && (o) <= %s)"
        --local foldbinop = "#define foldbinop(op)  (%s <= (op) && (op) <= %s)"
        local tmbitop = [[
#define tmbitop(o)  (                                                       \
  TM_BAND == (o) || TM_BOR == (o) || TM_BXOR == (o) || TM_BNOT == (o) ||    \
  TM_SHL == (o) || TM_SHR == (o)                                            \
)]]

        local f,l = order[1],order[self.Enums.MagicNumberPleaseFix]
        local op_f = string.rtrim(self.Enums.Instructions.Codes[f], ac)
        local op_l = string.rtrim(self.Enums.Instructions.Codes[l], ac)
        local kop_f = string.rtrim(self.Enums.KInstructions.Codes[f], ac)
        local bin_f = string.rtrim(self.Enums.BinOps.Opr[f], ac)
        local bin_l = string.rtrim(self.Enums.BinOps.Opr[l], ac)
        local tm_f = string.rtrim(self.Enums.TM.Opr[f], ac)
        local lop_f = self.Enums.LuaOp[f]

        rules.LuaOp[#rules.LuaOp + 1] = rangemacro("foldop", op_f, op_l)
        rules.BinOps[#rules.BinOps + 1] = rangemacro("foldbinop", bin_f, bin_l)

        rules.TM[#rules.TM + 1] = tmbitop
        rules.TM[#rules.TM + 1] = lua_to_meta:format(lop_f, tm_f)

        rules.BinOps[#rules.BinOps + 1] = op_to_meta:format(op_f, tm_f)
        rules.BinOps[#rules.BinOps + 1] = binop_to_meta:format(bin_f, tm_f)
        rules.BinOps[#rules.BinOps + 1] = binop_to_lua:format(bin_f, lop_f)
        rules.BinOps[#rules.BinOps + 1] = binop_to_kop:format(bin_f, kop_f)
        rules.BinOps[#rules.BinOps + 1] = binop_to_op:format(bin_f, op_f)
    end,

    Enums = {
        MagicNumberPleaseFix = 12, -- Unary is appended ... fix this magic #
        Tests = {
            "+",
            "-",
            "*",
            "%",
            "^",
            "/",
            "\\\\",
            "&",
            "|",
            "~",
            "<",
            ">",
        },
        TM = {
            Opr = {
                "TM_ADD,",
                "TM_SUB,",
                "TM_MUL,",
                "TM_MOD,",
                "TM_POW,",
                "TM_DIV,",
                "TM_IDIV,",
                "TM_BAND,",
                "TM_BOR,",
                "TM_BXOR,",
                "TM_SHL,",
                "TM_SHR,",
            },
            Names = {
                "\"__add\",",
                "\"__sub\",",
                "\"__mul\",",
                "\"__mod\",",
                "\"__pow\",",
                "\"__div\",",
                "\"__idiv\",",
                "\"__band\",",
                "\"__bor\",",
                "\"__bxor\",",
                "\"__shl\",",
                "\"__shr\",",
            },
        },
        LuaOp = {
            "LUA_OPADD   ",
            "LUA_OPSUB   ",
            "LUA_OPMUL   ",
            "LUA_OPMOD   ",
            "LUA_OPPOW   ",
            "LUA_OPDIV   ",
            "LUA_OPIDIV  ",
            "LUA_OPBAND  ",
            "LUA_OPBOR   ",
            "LUA_OPBXOR  ",
            "LUA_OPSHL   ",
            "LUA_OPSHR   ",
        },
        BinOps = {
            Opr = {
                "OPR_ADD, /* arithmetic operator */",
                "OPR_SUB, /* arithmetic operator */",
                "OPR_MUL, /* arithmetic operator */",
                "OPR_MOD, /* arithmetic operator */",
                "OPR_POW, /* arithmetic operator */",
                "OPR_DIV, /* arithmetic operator */",
                "OPR_IDIV, /* arithmetic operator */",
                "OPR_BAND, /* bitwise operator */",
                "OPR_BOR, /* bitwise operator */",
                "OPR_BXOR, /* bitwise operator */",
                "OPR_SHL, /* bitwise operator */",
                "OPR_SHR, /* bitwise operator */",
            },
            Priority = {
                "{10, 10}, /* '+' */",
                "{10, 10}, /* '-' */",
                "{11, 11}, /* '*' */",
                "{11, 11}, /* '%' */",
                "{14, 13}, /* '^' (right associative) */",
                "{11, 11}, /* '/' */",
                "{11, 11}, /* '//' */",
                "{6, 6}, /* '&' */",
                "{4, 4}, /* '|' */",
                "{5, 5}, /* '~' */",
                "{7, 7}, /* '<<' */",
                "{7, 7}, /* ''>>' */",
            },
        },
        Instructions = {
            Codes = {
                "OP_ADD,  /* A B C   R[A] := R[B] + R[C]  */",
                "OP_SUB,  /* A B C   R[A] := R[B] - R[C]  */",
                "OP_MUL,  /* A B C   R[A] := R[B] * R[C]  */",
                "OP_MOD,  /* A B C   R[A] := R[B] % R[C]  */",
                "OP_POW,  /* A B C   R[A] := R[B] ^ R[C]  */",
                "OP_DIV,  /* A B C   R[A] := R[B] / R[C]  */",
                "OP_IDIV, /* A B C   R[A] := R[B] // R[C] */",
                "OP_BAND, /* A B C   R[A] := R[B] & R[C]  */",
                "OP_BOR,  /* A B C   R[A] := R[B] | R[C]  */",
                "OP_BXOR, /* A B C   R[A] := R[B] ~ R[C]  */",
                "OP_SHL,  /* A B C   R[A] := R[B] << R[C] */",
                "OP_SHR,  /* A B C   R[A] := R[B] >> R[C] */",
            },
            Names = {
                "\"ADD\",",
                "\"SUB\",",
                "\"MUL\",",
                "\"MOD\",",
                "\"POW\",",
                "\"DIV\",",
                "\"IDIV\",",
                "\"BAND\",",
                "\"BOR\",",
                "\"BXOR\",",
                "\"SHL\",",
                "\"SHR\",",
            },
        },
        Modes = {
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_ADD */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_SUB */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_MUL */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_MOD */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_POW */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_DIV */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_IDIV */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_BAND */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_BOR */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_BXOR */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_SHL */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_SHR */",
        },
        KInstructions = {
            Codes = {
                "OP_ADDK,  /* A B C   R[A] := R[B] + K[C]         */",
                "OP_SUBK,  /* A B C   R[A] := R[B] - K[C]         */",
                "OP_MULK,  /* A B C   R[A] := R[B] * K[C]         */",
                "OP_MODK,  /* A B C   R[A] := R[B] % K[C]         */",
                "OP_POWK,  /* A B C   R[A] := R[B] ^ K[C]         */",
                "OP_DIVK,  /* A B C   R[A] := R[B] / K[C]         */",
                "OP_IDIVK, /* A B C   R[A] := R[B] // K[C]        */",
                "OP_BANDK, /* A B C   R[A] := R[B] & K[C]:integer */",
                "OP_BORK,  /* A B C   R[A] := R[B] | K[C]:integer */",
                "OP_BXORK, /* A B C   R[A] := R[B] ~ K[C]:integer */",
                "OP_SHRI,  /* A B sC  R[A] := R[B] >> sC          */",
                "OP_SHLI,  /* A B sC  R[A] := sC << R[B]          */",
            },
            Names = {
                "\"ADDK\",",
                "\"SUBK\",",
                "\"MULK\",",
                "\"MODK\",",
                "\"POWK\",",
                "\"DIVK\",",
                "\"IDIVK\",",
                "\"BANDK\",",
                "\"BORK\",",
                "\"BXORK\",",
                "\"SHRI\",",
                "\"SHLI\",",
            },
        },
        KModes = {
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_ADDK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_SUBK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_MULK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_MODK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_POWK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_DIVK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_IDIVK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_BANDK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_BORK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_BXORK */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_SHRI */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_SHLI */",
        },
    }
}

HeaderData.Groupings.Instructions = {
    Local = true,
    Unshared = {  },
    Shared = { "Instructions", "Modes", },

    Validate = function(self, order) return true end,
    Enums = {
        Instructions = {
            Codes = {
                "OP_MOVE,       /* A B R[A] := R[B]                                  */",
                "OP_LOADI,      /* A sBx   R[A] := sBx                               */",
                "OP_LOADF,      /* A sBx   R[A] := (lua_Number)sBx                   */",
                "OP_LOADK,      /* A Bx    R[A] := K[Bx]                             */",
                "#if defined(GRIT_USE_PATH)\nOP_LOADKPATH, /* A Bx    R[A] := Kst(Bx) */\n#endif",
                "OP_LOADKX,     /* A   R[A] := K[extra arg]                          */",
                "OP_LOADFALSE,  /* A   R[A] := false                                 */",
                "OP_LFALSESKIP, /* A   R[A] := false; pc++                           */",
                "OP_LOADTRUE,   /* A   R[A] := true                                  */",
                "OP_LOADNIL,    /* A B R[A], R[A+1], ..., R[A+B] := nil              */",
                "OP_GETUPVAL,   /* A B R[A] := UpValue[B]                            */",
                "OP_SETUPVAL,   /* A B UpValue[B] := R[A]                            */",
                "OP_GETTABUP,   /* A B C   R[A] := UpValue[B][K[C]:string]           */",
                "OP_GETTABLE,   /* A B C   R[A] := R[B][R[C]]                        */",
                "OP_GETI,       /* A B C   R[A] := R[B][C]                           */",
                "OP_GETFIELD,   /* A B C   R[A] := R[B][K[C]:string]                 */",
                "OP_SETTABUP,   /* A B C   UpValue[A][K[B]:string] := RK(C)          */",
                "OP_SETTABLE,   /* A B C   R[A][R[B]] := RK(C)                       */",
                "OP_SETI,       /* A B C   R[A][B] := RK(C)                          */",
                "OP_SETFIELD,   /* A B C   R[A][K[B]:string] := RK(C)                */",
                "OP_NEWTABLE,   /* A B C k R[A] := {}                                */",
                "OP_SELF,       /* A B C   R[A+1] := R[B]; R[A] := R[B][RK(C):string]*/",
                "OP_ADDI,       /* A B sC  R[A] := R[B] + sC                         */",
                "OP_MMBIN,      /* A B C   call C metamethod over R[A] and R[B]      */",
                "OP_MMBINI,     /* A sB C k    call C metamethod over R[A] and sB    */",
                "OP_MMBINK,     /* A B C k     call C metamethod over R[A] and K[B]  */",
                "OP_CONCAT,     /* A B R[A] := R[A].. ... ..R[A + B - 1]             */",
                "OP_CLOSE,      /* A   close all upvalues >= R[A]                    */",
                "OP_TBC,        /* A   mark variable A \"to be closed\"              */",
                "OP_JMP,        /* sJ  pc += sJ                                      */",
                "OP_TEST,       /* A k if (not R[A] == k) then pc++                  */",
                "OP_TESTSET,    /* A B k   if (not R[B] == k) then pc++ else R[A] := R[B]  */",
                "OP_CALL,       /* A B C   R[A], ... ,R[A+C-2] := R[A](R[A+1], ... ,R[A+B-1]) */",
                "OP_TAILCALL,   /* A B C k return R[A](R[A+1], ... ,R[A+B-1])        */",
                "OP_RETURN,     /* A B C k return R[A], ... ,R[A+B-2]  (see note)    */",
                "OP_RETURN0,    /* return                                            */",
                "OP_RETURN1,    /* A   return R[A]                                   */",
                "OP_FORLOOP,    /* A Bx    update counters; if loop continues then pc-=Bx; */",
                "OP_FORPREP,    /* A Bx    <check values and prepare counters>; if not to run then pc+=Bx+1; */",
                "OP_TFORPREP,   /* A Bx    create upvalue for R[A + 3]; pc+=Bx       */",
                "OP_TFORCALL,   /* A C R[A+4], ... ,R[A+3+C] := R[A](R[A+1], R[A+2]);*/",
                "OP_TFORLOOP,   /* A Bx    if R[A+2] ~= nil then { R[A]=R[A+2]; pc -= Bx } */",
                "OP_SETLIST,    /* A B C k R[A][(C-1)*FPF+i] := R[A+i], 1 <= i <= B  */",
                "OP_CLOSURE,    /* A Bx    R[A] := closure(KPROTO[Bx])               */",
                "OP_VARARG,     /* A C R[A], R[A+1], ..., R[A+C-2] = vararg          */",
                "OP_VARARGPREP, /* A   (adjust vararg parameters)                    */",
                "OP_EXTRAARG,   /* Ax  extra (larger) argument for previous opcode   */",
            },
            Names = {
                "\"MOVE\",",
                "\"LOADI\",",
                "\"LOADF\",",
                "\"LOADK\",",
                "#if defined(GRIT_USE_PATH)\n\"LOADKPATH\",\n#endif",
                "\"LOADKX\",",
                "\"LOADFALSE\",",
                "\"LFALSESKIP\",",
                "\"LOADTRUE\",",
                "\"LOADNIL\",",
                "\"GETUPVAL\",",
                "\"SETUPVAL\",",
                "\"GETTABUP\",",
                "\"GETTABLE\",",
                "\"GETI\",",
                "\"GETFIELD\",",
                "\"SETTABUP\",",
                "\"SETTABLE\",",
                "\"SETI\",",
                "\"SETFIELD\",",
                "\"NEWTABLE\",",
                "\"SELF\",",
                "\"ADDI\",",
                "\"MMBIN\",",
                "\"MMBINI\",",
                "\"MMBINK\",",
                "\"CONCAT\",",
                "\"CLOSE\",",
                "\"TBC\",",
                "\"JMP\",",
                "\"TEST\",",
                "\"TESTSET\",",
                "\"CALL\",",
                "\"TAILCALL\",",
                "\"RETURN\",",
                "\"RETURN0\",",
                "\"RETURN1\",",
                "\"FORLOOP\",",
                "\"FORPREP\",",
                "\"TFORPREP\",",
                "\"TFORCALL\",",
                "\"TFORLOOP\",",
                "\"SETLIST\",",
                "\"CLOSURE\",",
                "\"VARARG\",",
                "\"VARARGPREP\",",
                "\"EXTRAARG\",",
            },
        },
        Modes = {
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_MOVE */",
            "opmode(0, 0, 0, 0, 1, iAsBx),      /* OP_LOADI */",
            "opmode(0, 0, 0, 0, 1, iAsBx),      /* OP_LOADF */",
            "opmode(0, 0, 0, 0, 1, iABx),       /* OP_LOADK */",
            "#if defined(GRIT_USE_PATH)\n,opmode(0, 0, 0, 0, 1, iABx)       /* OP_LOADKPATH */\n#endif",
            "opmode(0, 0, 0, 0, 1, iABx),       /* OP_LOADKX */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_LOADFALSE */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_LFALSESKIP */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_LOADTRUE */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_LOADNIL */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_GETUPVAL */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_SETUPVAL */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_GETTABUP */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_GETTABLE */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_GETI */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_GETFIELD */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_SETTABUP */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_SETTABLE */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_SETI */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_SETFIELD */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_NEWTABLE */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_SELF */",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_ADDI */",
            "opmode(1, 0, 0, 0, 0, iABC),       /* OP_MMBIN */",
            "opmode(1, 0, 0, 0, 0, iABC),       /* OP_MMBINI*/",
            "opmode(1, 0, 0, 0, 0, iABC),       /* OP_MMBINK*/",
            "opmode(0, 0, 0, 0, 1, iABC),       /* OP_CONCAT */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_CLOSE */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_TBC */",
            "opmode(0, 0, 0, 0, 0, isJ),        /* OP_JMP */",
            "opmode(0, 0, 0, 1, 0, iABC),       /* OP_TEST */",
            "opmode(0, 0, 0, 1, 1, iABC),       /* OP_TESTSET */",
            "opmode(0, 1, 1, 0, 1, iABC),       /* OP_CALL */",
            "opmode(0, 1, 1, 0, 1, iABC),       /* OP_TAILCALL */",
            "opmode(0, 0, 1, 0, 0, iABC),       /* OP_RETURN */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_RETURN0 */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_RETURN1 */",
            "opmode(0, 0, 0, 0, 1, iABx),       /* OP_FORLOOP */",
            "opmode(0, 0, 0, 0, 1, iABx),       /* OP_FORPREP */",
            "opmode(0, 0, 0, 0, 0, iABx),       /* OP_TFORPREP */",
            "opmode(0, 0, 0, 0, 0, iABC),       /* OP_TFORCALL */",
            "opmode(0, 0, 0, 0, 1, iABx),       /* OP_TFORLOOP */",
            "opmode(0, 0, 1, 0, 0, iABC),       /* OP_SETLIST */",
            "opmode(0, 0, 0, 0, 1, iABx),       /* OP_CLOSURE */",
            "opmode(0, 1, 0, 0, 1, iABC),       /* OP_VARARG */",
            "opmode(0, 0, 1, 0, 1, iABC),       /* OP_VARARGPREP */",
            "opmode(0, 0, 0, 0, 0, iAx),        /* OP_EXTRAARG */",
        }
    }
}

HeaderData.Groupings.Unsorted = {
    Local = true,
    Unshared = { "LuaOp", "UnOps", "TM", "BinOps", "Tests", "Instructions", "Modes", "KModes", "KInstructions", },
    Shared = { },

    Validate = function(self, order) return true end,
    Post = function(rules, self, order, directory)
        local lua_opvalid = "#define lua_opvalid(o) (%s <= (o) && (o) <= %s)"
        local lua_numop = "#define NUM_OPCODES  ((int)(%s) + 1)"

        local luaop = self.Enums.LuaOp
        local instructions = self.Enums.Instructions

        local luop_f = string.rtrim(luaop[1], ac)
        local luop_l = string.rtrim(luaop[#luaop], ac)
        local numOps = string.rtrim(instructions.Codes[#instructions.Codes], ac)

        rules.LuaOp[#rules.LuaOp + 1] = lua_opvalid:format(luop_f, luop_l)
        rules.LuaOp[#rules.LuaOp + 1] = lua_numop:format(numOps)
    end,

    Enums = {
        Tests = { },
        LuaOp = { },
        UnOps = { },
        Modes = { },
        Instructions = { Codes = { }, Names = { }, },
        TM = {
            Opr = {
                "TM_LT,",
                "TM_LE,",
                "TM_CONCAT,",
                "TM_CALL,",
                "TM_CLOSE,",
                "#if defined(GRIT_POWER_OITER)\nTM_ITER,\n#endif",
            },
            Names = {
                "\"__lt\",",
                "\"__le\",",
                "\"__concat\",",
                "\"__call\",",
                "\"__close\",",
                "#if defined(GRIT_POWER_OITER)\n\"__iter\",\n#endif",
            },
        },
        BinOps = {
            Opr = {
                "OPR_CONCAT, /* string operator */",
                "OPR_AND, /* logical operator */",
                "OPR_OR, /* logical operator */",
            },
            Priority = {
                "{9, 8}, /* '..' (right associative) */",
                "{2, 2}, /* and */",
                "{1, 1}, /* or */",
            },
        },
        KModes = { },
        KInstructions = { Codes = { }, Names = { }, },
    }
}

HeaderData.Structure = {
    OneToOne = {
        Modes = { Instructions = true, Modes = true, },
        Instructions = { Instructions = true, Modes = true, },
    },

    UnOps = {
        Output = function(result, directory)
            local fh = assert(io.open(string.concat_dir(directory, "opr_unary.h"), "w"))
            fh:write(table.concat(result, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
    },
    LuaOp = {
        Output = function(result, directory)
            local fmt = "#define %s %d"
            local formatted = { }
            for i=1,#result do -- Assign integers to the #defines
                formatted[i] = fmt:format(result[i], i - 1)
            end

            local fh = assert(io.open(string.concat_dir(directory, "lua_op.h"), "w"))
            fh:write(table.concat(formatted, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
        Rules = function(rules, directory)
            local fh = assert(io.open(string.concat_dir(directory, "rules_lua.h"), "w"))
            fh:write(table.concat(rules, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
    },
    TM = {
        Substructs = { "Opr", "Names" },
        Output = function(result, directory)
            local fh = assert(io.open(string.concat_dir(directory, "metatable_enum.h"), "w"))
            fh:write(table.concat(result.Opr, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()

            local fh = assert(io.open(string.concat_dir(directory, "metatable_names.h"), "w"))
            fh:write(table.concat(result.Names, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
        Rules = function(rules, directory)
            local fh = assert(io.open(string.concat_dir(directory, "rules_metatable.h"), "w"))
            fh:write("/* Mapping binary operators to other enumerators */")
            fh:write("\n")
            fh:write(table.concat(rules, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
    },
    Tests = {
        Output = function(result, directory)
            local fmt = "static const char ops[] = \"%s\";"
            local fh = assert(io.open(string.concat_dir(directory, "opr_ltest.h"), "w"))

            fh:write(fmt:format(table.concat(result, "")))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
    },
    BinOps = {
        Substructs = { "Opr", "Priority" },
        Output = function(result, directory)
            local fh = assert(io.open(string.concat_dir(directory, "opr_bin.h"), "w"))
            fh:write(table.concat(result.Opr, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()

            local fh = assert(io.open(string.concat_dir(directory, "opr_priority.h"), "w"))
            fh:write(table.concat(result.Priority, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
        Rules = function(rules, directory)
            local fh = assert(io.open(string.concat_dir(directory, "rules_bin.h"), "w"))
            fh:write("/* Mapping binary operators to other enumerators */")
            fh:write("\n")
            fh:write(table.concat(rules, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
    },
    Modes = {
        OneToOne = { Instructions = true, Modes = true, },
        Output = function(result, directory)
            local fh = assert(io.open(string.concat_dir(directory, "op_mode.h"), "w"))
            fh:write(table.concat(result, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
    },
    Instructions = {
        Substructs = { "Codes", "Names" },
        Output = function(result, directory)
            local opcodes = table.concat(result.Codes, "\n")
            local jumptable,_ = opcodes:gsub("OP_", "&&L_OP_")

            local fh = assert(io.open(string.concat_dir(directory, "op_opcode.h"), "w"))
            fh:write(opcodes)
            fh:write("\n")
            fh:flush()
            fh:close()

            local fh = assert(io.open(string.concat_dir(directory, "op_names.h"), "w"))
            fh:write(table.concat(result.Names, "\n"))
            fh:write("\n")
            fh:flush()
            fh:close()

            local fh = assert(io.open(string.concat_dir(directory, "op_jumptable.h"), "w"))
            fh:write(jumptable)
            fh:write("\n")
            fh:flush()
            fh:close()
        end,
    },

    KInstructions = { Substructs = { "Codes", "Names" }, Output = function(result, directory) end, },
    KModes = { Output = function(result, directory) end, },
}

return HeaderData