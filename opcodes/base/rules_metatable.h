#define lua_to_meta(op)     cast(TMS, ((op) - LUA_OPADD) + TM_ADD)

/* ORDER TM: Used to simplify logic in ltm.c: luaT_trybinTM */
#define tmbitop(o)  ((TM_BAND <= (o) && (o) <= TM_SHR) || (o) == TM_BNOT)

#define tmfast(o) (TM_INDEX <= (o) && (o) <= TM_EQ)

/*
** Unfolded timbitop:
#define tmbitop(o)  (                                                       \
  TM_BAND == (o) || TM_BOR == (o) || TM_BXOR == (o) || TM_BNOT == (o) ||    \
  TM_SHL == (o) || TM_SHR == (o)                                            \
)
*/

/*
** Unfolded tmfast:
#define tmfast(o) (                                        \
  TM_INDEX == (o) || TM_NEWINDEX == (o) || TM_GC == (o) || \
  TM_MODE == (o) || TM_LEN == (o) || TM_EQ == (o)          \
)
*/
