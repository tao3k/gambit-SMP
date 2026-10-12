#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "gambit.h"

___BEGIN_C_LINKAGE
extern ___mod_or_lnk ___LNK_sfunfamilies__ (___global_state);
extern void family_void(int migrate, int fail);
extern ___SCMOBJ family_object(int migrate, int fail);
extern int family_integer(int migrate, int fail);
extern int nested_markers_made(void);
extern int nested_markers_killed(void);
___END_C_LINKAGE

static double monotonic_seconds(void) {
  struct timespec now;
  if (clock_gettime(CLOCK_MONOTONIC, &now)) exit(7);
  return now.tv_sec + now.tv_nsec * 1e-9;
}

int main(int argc, char **argv) {
  if (argc != 4) return 2;
  int processors = atoi(argv[1]), kind = atoi(argv[2]), iterations = atoi(argv[3]);
  if (processors < 2 || kind < 0 || kind > 2 || iterations < 1) return 2;
  ___setup_params_struct parameters;
  ___setup_params_reset(&parameters);
  parameters.version = ___VERSION;
  parameters.linker = ___LNK_sfunfamilies__;
  parameters.parallelism_level = processors;
  if (___setup(&parameters) != ___FIX(___NO_ERR)) return 3;
  int failed = 0;
  volatile int completed = 0;
  ___SCMOBJ ___temp;
  double started = monotonic_seconds();
  ___ON_THROW({
    for (int i = 0; i < iterations; i++) {
      if (kind == 0) family_void(0, 0);
      else if (kind == 1) {
        ___SCMOBJ object = family_object(0, 0);
        if (!___VECTORP(object) || ___INT(___VECTORLENGTH(object)) != 1 ||
            ___VECTORELEM(object, 0) != ___FIX(42)) { failed = 1; break; }
      } else if (family_integer(0, 0) != 42) { failed = 1; break; }
      completed++;
    }
  }, { failed = 1; });
  double seconds = monotonic_seconds() - started;
  int made = nested_markers_made(), killed = nested_markers_killed();
  printf("SFUN-COST:kind=%d,iterations=%d,completed=%d,made=%d,killed=%d,seconds=%.9f\n",
         kind, iterations, completed, made, killed, seconds);
  fflush(stdout);
  if (failed || completed != iterations || made != iterations || killed != iterations)
    return 4;
  return ___cleanup_checked() == ___FIX(___NO_ERR) ? 0 : 5;
}
