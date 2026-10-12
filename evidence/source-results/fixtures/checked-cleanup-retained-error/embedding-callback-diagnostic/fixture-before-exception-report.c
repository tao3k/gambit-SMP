#include <stdio.h>
#include <stdlib.h>
#include "gambit.h"

___BEGIN_C_LINKAGE
extern ___mod_or_lnk ___LNK_cleanupembed__ (___global_state);
extern int embedding_gc_round(int processors);
___END_C_LINKAGE

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  int processors = atoi(argv[1]);
  if (processors < 2) return 2;
  if (___cleanup_checked() != ___FIX(___NO_ERR)) return 3;
  for (int generation = 0; generation < 2; generation++) {
    ___setup_params_struct parameters;
    ___setup_params_reset(&parameters);
    parameters.version = ___VERSION;
    parameters.linker = ___LNK_cleanupembed__;
    parameters.parallelism_level = processors;
    ___SCMOBJ setup = ___setup(&parameters);
    if (setup != ___FIX(___NO_ERR)) {
      printf("SETUP-DENY:generation=%d,error=%ld\n", generation, (long)setup);
      return 4;
    }
    int population = 0, threw = 0;
    ___SCMOBJ error = ___FIX(___NO_ERR);
    ___ON_THROW(population = embedding_gc_round(processors),
      { threw = 1; error = ___err; });
    if (threw || population != processors) {
      printf("CALLBACK-DENY:generation=%d,threw=%d,error=%ld,population=%d,expected=%d\n",
        generation, threw, (long)error, population, processors);
      fflush(stdout);
      return 5;
    }
    ___SCMOBJ cleanup = ___cleanup_checked();
    if (cleanup != ___FIX(___NO_ERR)) return 6;
    if (___cleanup_checked() != ___FIX(___NO_ERR)) return 7;
    printf("EMBEDDING-OK:generation=%d,processors=%d\n", generation, population);
    fflush(stdout);
  }
  return 0;
}
