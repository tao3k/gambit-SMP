#include <stdio.h>
#include <string.h>
#include "gambit.h"

static ___processor_state_struct state;
static ___WORD marker_body[2];
static int mode, made, killed, live;

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
  live++;
  return ___FIX(___NO_ERR);
}

static void mock____kill_sfun_stack_marker(___SCMOBJ marker) {
  (void)marker;
  killed++;
  live--;
}

static ___SCMOBJ mock____call(___processor_state ___ps, int nargs,
                            ___SCMOBJ proc, ___SCMOBJ marker) {
  (void)nargs;
  (void)proc;
  (void)marker;
  if (mode == 2) ___THROW(___FIX(___UNKNOWN_ERR));
  ___ps->r[1] = ___FIX(42);
  return ___FIX(___NO_ERR);
}

static void mock____propagate_error(___processor_state ___ps, ___SCMOBJ error) {
  if (error != ___FIX(___NO_ERR)) ___THROW(error);
}

static ___SCMOBJ source_sfun(void) {
#define ___NARGS 0
  ___BEGIN_SFUN_SCMOBJ(___FAL)
  ___SFUN_CALL_SCMOBJ
  ___SFUN_SET_RESULT_SCMOBJ
  ___SFUN_ERROR_SCMOBJ
  ___SFUN_SET_RESULT_SCMOBJ
  ___END_SFUN_SCMOBJ
  return ___result;
#undef ___NARGS
}

int main(void) {
#ifndef ___USE_SETJMP
  fputs("UNSUPPORTED-EXCEPTION-MODE\n", stderr);
  return 2;
#endif
  for (mode = 0; mode < 3; mode++) {
    memset(&state, 0, sizeof(state));
    made = killed = live = 0;
    int caught = 0;
    ___SCMOBJ result = ___FAL;
    ___ON_THROW(result = source_sfun(), { caught = 1; });
    printf("SFUN-TAIL:mode=%d,made=%d,killed=%d,live=%d,caught=%d\n",
           mode, made, killed, live, caught);
    if (mode == 0 && (caught || result != ___FIX(42) || made != 1 || killed != 1 || live))
      return 3;
    if (mode == 1 && (!caught || made || killed || live)) return 4;
    if (mode == 2 && (!caught || made != 1 || killed || live != 1)) return 5;
  }
  return 0;
}
