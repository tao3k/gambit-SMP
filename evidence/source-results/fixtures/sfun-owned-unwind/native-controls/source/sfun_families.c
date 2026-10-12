#include <stdio.h>
#include <stdlib.h>
#include "gambit.h"

___BEGIN_C_LINKAGE
extern ___mod_or_lnk ___LNK_sfunfamilies__ (___global_state);
extern void family_void(int migrate, int fail);
extern ___SCMOBJ family_object(int migrate, int fail);
extern int family_integer(int migrate, int fail);
extern int nested_markers_made(void);
extern int nested_markers_killed(void);
___END_C_LINKAGE

int main(int argc, char **argv) {
  if (argc != 5) return 2;
  int processors = atoi(argv[1]), kind = atoi(argv[2]);
  int migrate = atoi(argv[3]), fail = atoi(argv[4]);
  if (processors < 2 || kind < 0 || kind > 2 || migrate < 0 || migrate > 1 ||
      fail < 0 || fail > 2 || (fail == 2 && kind != 2)) return 2;
  ___setup_params_struct parameters;
  ___setup_params_reset(&parameters);
  parameters.version = ___VERSION;
  parameters.linker = ___LNK_sfunfamilies__;
  parameters.parallelism_level = processors;
  if (___setup(&parameters) != ___FIX(___NO_ERR)) return 3;
  int result = -1, threw = 0;
  ___SCMOBJ error = ___FIX(___NO_ERR), object = ___FAL, ___temp;
  ___ON_THROW({
    if (kind == 0) { family_void(migrate, fail); result = 42; }
    else if (kind == 1) {
      object = family_object(migrate, fail);
      if (___VECTORP(object) && ___INT(___VECTORLENGTH(object)) == 1 &&
          ___VECTORELEM(object, 0) == ___FIX(42)) result = 42;
    } else result = family_integer(migrate, fail);
  }, { threw = 1; error = ___err; });
  int made = nested_markers_made(), killed = nested_markers_killed();
  printf("SFUN-FAMILY:kind=%d,migrate=%d,fail=%d,result=%d,threw=%d,error=%ld,made=%d,killed=%d\n",
         kind, migrate, fail, result, threw, (long)___INT(error), made, killed);
  fflush(stdout);
  if ((!fail && (threw || result != 42)) ||
      (fail && (!threw || error == ___FIX(___NO_ERR)))) return 4;
  if (made != 1 || killed != 1) return 5;
  ___SCMOBJ cleanup = ___cleanup_checked();
  printf("SFUN-FAMILY-CLEANUP:error=%ld\n", (long)___INT(cleanup));
  fflush(stdout);
  return cleanup == ___FIX(___NO_ERR) ? 0 : 6;
}
