/* Mapping binary operators to other enumerators */
#define op_to_meta(op) cast(TMS, ((op) - OP_ADD) + TM_ADD)
#define binop_to_meta(opr) cast(TMS, ((opr) - OPR_ADD) + TM_ADD)
#define binop_to_lua(opr) (((opr) - OPR_ADD) + LUA_OPADD)
#define unarop_to_lua(op) (((op) - OPR_MINUS) + LUA_OPUNM)
#define binop_to_kop(opr) cast(OpCode, ((opr) - OPR_ADD) + OP_ADDK);
#define binop_to_op(opr) cast(OpCode, ((opr) - OPR_ADD) + OP_ADD);
#define unarop_to_op(op) cast(OpCode, ((op) - OPR_MINUS) + OP_UNM)

#define cmpop_to_op(opr) cast(OpCode, ((opr) - OPR_EQ) + OP_EQ)
#define ncmpop_to_op(opr) cast(OpCode, ((opr) - OPR_NE) + OP_EQ)
#define opcmp_to_opicmp(op) cast(OpCode, ((op) - OP_LT) + OP_LTI)

/* true if operation is foldable (that is, it is arithmetic or bitwise) */
#define foldbinop(op)  (OPR_ADD <= (op) && (op) <= OPR_SHR)

/*
** Unfolded-foldbinop
#define foldbinop(op) ( \
  OPR_ADD == (op) || OPR_SUB == (op) || OPR_MUL == (op) || OPR_MOD == (op) || \
  OPR_POW == (op) || OPR_DIV == (op) || OPR_IDIV == (op) ||                   \
  OPR_BAND == (op) || OPR_BOR == (op) || OPR_BXOR == (op) ||                  \
  OPR_SHL == (op) || OPR_SHR == (op)                                          \
)
*/
