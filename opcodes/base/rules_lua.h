#define NUM_OPCODES	((int)(OP_EXTRAARG) + 1)

#define lua_opvalid(o)  (LUA_OPADD <= (o) && (o) <= LUA_OPBNOT)

/* @TODO: OpCode */
/* true if opcode is foldable (that is, it is arithmetic or bitwise) */
#define foldop(o)  (OP_ADD <= (o) && (o) <= OP_SHR)

/*
** Unfolded foldop:
#define foldop(o) (                                                     \
  OP_ADD == (o) || OP_SUB == (o) || OP_MUL == (o) || OP_MOD == (o) ||   \
  OP_POW == (o) || OP_DIV == (o) || OP_IDIV == (o) || OP_BAND == (o) || \
  OP_BOR == (o) || OP_BXOR == (o) || OP_SHL == (o) || OP_SHR == (o)     \
)
*/
