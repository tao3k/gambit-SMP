#include <stdio.h>
#include <string.h>
#include "gambit.h"

static ___processor_state_struct state;
static ___WORD marker_body[2];
static int mode, made, killed, calls;

#undef ___PSTATE
#define ___PSTATE (&state)
#undef ___EXT
#define ___EXT(name) mock_##name

static ___SCMOBJ mock____make_sfun_stack_marker(
    ___processor_state ps, ___SCMOBJ *marker, ___SCMOBJ proc) {
  (void)ps;
  (void)proc;
  if (mode == 1) return ___FIX(___SFUN_HEAP_OVERFLOW_ERR);
  marker_body[0] = ___FAL;
  marker_body[1] = ___FIX(0);
  *marker = ___SUBTYPED_FROM_BODY(marker_body);
  made++;
  return ___FIX(___NO_ERR);
}

static void mock____kill_sfun_stack_marker(___SCMOBJ marker) {
  (void)marker;
  killed++;
}

static ___SCMOBJ mock____call(___processor_state ___ps, int nargs,
                            ___SCMOBJ proc, ___SCMOBJ marker) {
  (void)nargs;
  (void)proc;
  (void)marker;
  calls++;
  if (mode == 2 || (mode == 3 && calls == 2))
    ___THROW(___FIX(___UNKNOWN_ERR));
  ___ps->r[1] = ___FIX(42);
  return mode == 3 ? ___FIX(___UNKNOWN_ERR) : ___FIX(___NO_ERR);
}

static void mock____propagate_error(___processor_state ___ps, ___SCMOBJ error) {
  if (error != ___FIX(___NO_ERR)) ___THROW(error);
}

static int source_void(void) {
#define ___NARGS 0
  ___BEGIN_SFUN_VOID(___FAL)
  ___SFUN_CALL_VOID
  ___SFUN_ERROR_VOID
  ___END_SFUN_VOID
  return 42;
#undef ___NARGS
}

static int source_object(void) {
#define ___NARGS 0
  ___BEGIN_SFUN_SCMOBJ(___FAL)
  ___SFUN_CALL_SCMOBJ
  ___SFUN_SET_RESULT_SCMOBJ
  ___SFUN_ERROR_SCMOBJ
  ___SFUN_SET_RESULT_SCMOBJ
  ___END_SFUN_SCMOBJ
  return ___INT(___result);
#undef ___NARGS
}

static int source_integer(void) {
#define ___NARGS 0
  ___BEGIN_SFUN(___FAL, int result)
  ___SFUN_CALL { result = ___INT(___SFUN_RESULT); }
  ___SFUN_ERROR { result = ___INT(___SFUN_RESULT); }
  ___END_SFUN
  return result;
#undef ___NARGS
}

int main(void) {
  for (int kind = 0; kind < 3; kind++) {
    for (mode = 0; mode < 4; mode++) {
      memset(&state, 0, sizeof(state));
      made = killed = calls = 0;
      int result = -1, caught = 0;
      ___SCMOBJ error = ___FIX(___NO_ERR);
      ___ON_THROW({
        result = kind == 0 ? source_void() :
                 kind == 1 ? source_object() : source_integer();
      }, { caught = 1; error = ___err; });
      int expected = mode == 1 ? 0 : 1;
      int expected_calls = mode == 1 ? 0 : mode == 3 ? 2 : 1;
      ___SCMOBJ expected_error = mode == 1 ? ___FIX(___SFUN_HEAP_OVERFLOW_ERR) :
                                mode ? ___FIX(___UNKNOWN_ERR) : ___FIX(___NO_ERR);
      if (made != expected || killed != expected || calls != expected_calls ||
          caught != (mode != 0) || error != expected_error ||
          (mode == 0 && result != 42)) return 3;
#ifdef ___USE_SETJMP
      if (state.catcher != NULL) return 4;
#endif
      printf("SFUN-CATCHER:kind=%d,mode=%d,made=%d,killed=%d,calls=%d,caught=%d\n",
             kind, mode, made, killed, calls, caught);
    }
  }
  return 0;
}
