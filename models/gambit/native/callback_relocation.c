#include <stdio.h>
#include <stdlib.h>
#include "gambit.h"

___BEGIN_C_LINKAGE
extern ___mod_or_lnk ___LNK_callbackrelocation__ (___global_state);
extern ___SCMOBJ callback_return_relocation(int migrate, int collect);
extern unsigned long long callback_payload_before(void);
___END_C_LINKAGE

int main(int argc, char **argv) {
  if (argc != 4) return 2;
  int processors = atoi(argv[1]);
  int migrate = atoi(argv[2]);
  int collect = atoi(argv[3]);
  if (processors < 2 || migrate < 0 || migrate > 1 || collect < 0 || collect > 1)
    return 2;
  ___setup_params_struct parameters;
  ___setup_params_reset(&parameters);
  parameters.version = ___VERSION;
  parameters.linker = ___LNK_callbackrelocation__;
  parameters.parallelism_level = processors;
  if (___setup(&parameters) != ___FIX(___NO_ERR)) return 3;
  ___SCMOBJ value = ___FAL;
  ___SCMOBJ ___temp;
  ___SCMOBJ error = ___FIX(___NO_ERR);
  int threw = 0;
  ___ON_THROW(value = callback_return_relocation(migrate, collect),
    { threw = 1; error = ___err; });
  if (threw || !___VECTORP(value)) return 4;
  int intact = ___INT(___VECTORLENGTH(value)) == 32;
  for (int i = 0; intact && i < 32; i++)
    intact = ___FIXEQ(___VECTORELEM(value, i), ___FIX(42));
  unsigned long long before = callback_payload_before();
  unsigned long long after = (unsigned long long)value;
  int moved = before != after;
  printf("CALLBACK-RELOCATION:migrate=%d,collect=%d,moved=%d,intact=%d,threw=%d,error=%ld\n",
         migrate, collect, moved, intact, threw, (long)___INT(error));
  fflush(stdout);
  // The old address is an unregistered integer observation, never dereferenced.
  if (!intact || (migrate && collect && !moved)) return 5;
  if (___cleanup_checked() != ___FIX(___NO_ERR)) return 6;
  return 0;
}
