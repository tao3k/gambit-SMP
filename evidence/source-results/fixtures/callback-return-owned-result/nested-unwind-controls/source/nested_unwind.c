#include <stdio.h>
#include <stdlib.h>
#include "gambit.h"

___BEGIN_C_LINKAGE
extern ___mod_or_lnk ___LNK_nestedunwind__ (___global_state);
extern int nested_outer(int migrate, int fail);
___END_C_LINKAGE

int main(int argc, char **argv) {
  if (argc != 4) return 2;
  int processors = atoi(argv[1]);
  int migrate = atoi(argv[2]);
  int fail = atoi(argv[3]);
  if (processors < 2 || migrate < 0 || migrate > 1 || fail < 0 || fail > 1)
    return 2;
  ___setup_params_struct parameters;
  ___setup_params_reset(&parameters);
  parameters.version = ___VERSION;
  parameters.linker = ___LNK_nestedunwind__;
  parameters.parallelism_level = processors;
  if (___setup(&parameters) != ___FIX(___NO_ERR)) return 3;
  int result = -1, threw = 0;
  ___SCMOBJ error = ___FIX(___NO_ERR);
  ___ON_THROW(result = nested_outer(migrate, fail),
    { threw = 1; error = ___err; });
  printf("NESTED-UNWIND:migrate=%d,fail=%d,result=%d,threw=%d,error=%ld\n",
         migrate, fail, result, threw, (long)___INT(error));
  fflush(stdout);
  if ((!fail && (threw || result != 42)) ||
      (fail && (!threw || error != ___FIX(___UNKNOWN_ERR)))) return 4;
  ___SCMOBJ cleanup = ___cleanup_checked();
  printf("NESTED-CLEANUP:error=%ld\n", (long)___INT(cleanup));
  fflush(stdout);
  return cleanup == ___FIX(___NO_ERR) ? 0 : 5;
}
