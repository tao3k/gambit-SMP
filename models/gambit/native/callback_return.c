#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gambit.h"

___BEGIN_C_LINKAGE
extern ___mod_or_lnk ___LNK_callbackreturn__ (___global_state);
extern int callback_return_value(int migrate, int collect, int value);
extern char *callback_return_string(int migrate, int collect);
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
  parameters.linker = ___LNK_callbackreturn__;
  parameters.parallelism_level = processors;
  if (___setup(&parameters) != ___FIX(___NO_ERR)) return 3;
  int result = -1, threw = 0;
  ___SCMOBJ error = ___FIX(___NO_ERR);
  ___ON_THROW(result = callback_return_value(migrate, collect, 42),
    { threw = 1; error = ___err; });
  printf("CALLBACK-RESULT:migrate=%d,collect=%d,result=%d,threw=%d,error=%ld\n",
         migrate, collect, result, threw, (long)___INT(error));
  fflush(stdout);
  if (threw || result != 42) return 4;
  char *text = NULL;
  ___ON_THROW(text = callback_return_string(migrate, collect),
    { threw = 1; error = ___err; });
  if (threw || text == NULL) return 6;
  size_t length = strlen(text);
  int intact = length == 4096;
  for (size_t i = 0; intact && i < length; i++) intact = text[i] == 'x';
  ___release_string(text);
  printf("CALLBACK-ROOT:migrate=%d,collect=%d,length=%lu,intact=%d\n",
         migrate, collect, (unsigned long)length, intact);
  fflush(stdout);
  if (!intact) return 7;
  if (___cleanup_checked() != ___FIX(___NO_ERR)) return 5;
  return 0;
}
