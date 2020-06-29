/*
** $Id: lstring.h $
** String table (keep all strings handled by Lua)
** See Copyright Notice in lua.h
*/

#ifndef lstring_h
#define lstring_h

#include "lgc.h"
#include "lobject.h"
#include "lstate.h"


/*
** Memory-allocation error message must be preallocated (it cannot
** be created after memory is exhausted)
*/
#define MEMERRMSG       "not enough memory"


/*
** Size of a TString: Size of the header plus space for the string
** itself (including final '\0').
*/
#define sizelstring(l)  (offsetof(TString, contents) + ((l) + 1) * sizeof(char))

#define luaS_newliteral(L, s)	(luaS_newlstr(L, "" s, \
                                 (sizeof(s)/sizeof(char))-1))


/*
** test whether a string is a reserved word
*/
#define isreserved(s)	((s)->tt == LUA_VSHRSTR && (s)->extra > 0)


/*
** equality for short strings, which are always internalized
*/
#if defined(GRIT_POWER_SSID)

/* References are equal or non-zero IDs are equal */
#define eqinstshrstr(a, b) (((a) == (b)) || ((a)->id == (b)->id && (a)->id != 0))

#define eqshrstr(a,b)	check_exp((a)->tt == LUA_VSHRSTR, eqinstshrstr(a, b) || \
  ((a)->hash == (b)->hash && luaS_eqshrstr(a,b)))  /* memcmp the shrstrs */

#else
#define eqshrstr(a,b)	check_exp((a)->tt == LUA_VSHRSTR, (a) == (b))
#endif


LUAI_FUNC unsigned int luaS_hash (const char *str, size_t l,
                                  unsigned int seed, size_t step);
LUAI_FUNC unsigned int luaS_hashlongstr (TString *ts);
LUAI_FUNC int luaS_eqlngstr (TString *a, TString *b);
#if defined(GRIT_POWER_SSID)
LUAI_FUNC int luaS_eqshrstr (TString *a, TString *b);
#endif
LUAI_FUNC void luaS_resize (lua_State *L, int newsize);
LUAI_FUNC void luaS_clearcache (global_State *g);
LUAI_FUNC void luaS_init (lua_State *L);
LUAI_FUNC void luaS_remove (lua_State *L, TString *ts);
LUAI_FUNC Udata *luaS_newudata (lua_State *L, size_t s, int nuvalue);
LUAI_FUNC TString *luaS_newlstr (lua_State *L, const char *str, size_t l);
LUAI_FUNC TString *luaS_new (lua_State *L, const char *str);
LUAI_FUNC TString *luaS_createlngstrobj (lua_State *L, size_t l);

/*
** Create a non-internalized string of "L" bytes, where L is clamped from below
** to least (LUAI_MAXSHORTLEN + 1) bytes.
*/
LUAI_FUNC TString *luaS_newblob (lua_State *L, size_t l);

#if defined(GRIT_POWER_SHAREDTYPES)
/*
** Mark a string as "shared": give it a unique (process-global) identifier and
** extend its life indefinitely (or at least until marked unshared after that
** feature has been thoroughly tested).
**/
LUAI_FUNC void luaS_share (TString *ts);
#endif

#endif
