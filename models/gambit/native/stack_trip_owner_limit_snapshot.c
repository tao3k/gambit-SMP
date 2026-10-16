/* Configured-header check of a split interrupt publication after owner switch.
   This forces the SC coordinates; it does not execute the production scheduler. */
#include "evidence/fixtures/darwin-stack-trip-owner-limit/configured/gambit.h"
#include <stdio.h>

#if !defined(__APPLE__) || !defined(__MACH__) || !defined(__GNUC__) || defined(__clang__)
#error This control must exercise the Darwin GNU candidate expansion.
#endif

static ___processor_state_struct state;

int main(void)
{
  ___WORD arena[256];
  ___processor_state ___ps = &state;
  ___WORD *___fp;
  int cases = 0, negatives = 0;
  for (int old = 8; old <= 24; old += 8)
    for (int limit = 64; limit <= 96; limit += 16)
      for (int burst = 1; burst <= 8; burst *= 2) {
        /* Sender samples old start; owner switches and refreshes; sender
           then publishes the stale address. All pointers share one arena. */
        ___ps->stack_start = arena + old;
        ___WORD *sampled = ___ps->stack_start;
        ___ps->stack_start = arena + limit + 16;
        ___ps->stack_limit = arena + limit;
        ___ps->stack_trip = ___ps->stack_limit;
        ___ps->stack_trip = sampled;
        ___fp = ___ps->stack_start;
        int steps = 0;
        while (!___STACK_TRIPPED && steps++ < 256) {
          ___fp -= burst;
          if (___fp < arena + limit - 8) return 1;
        }
        if (steps >= 256 || ___fp >= ___ps->stack_limit) return 2;
        /* Original trip-only predicate permits this same prefix to escape. */
        ___fp = ___ps->stack_start;
        while (!(___fp < ___ps->stack_trip)) {
          ___fp -= burst;
          if (___fp < arena + limit - 8) { negatives++; break; }
        }
        /* Preserve equality and ordinary interrupt semantics. */
        ___fp = ___ps->stack_limit;
        if (___STACK_TRIPPED) return 3;
        ___ps->stack_trip = ___ps->stack_start;
        if (!___STACK_TRIPPED) return 4;
        ___fp = ___ps->stack_start;
        if (___STACK_TRIPPED) return 5;
        cases++;
      }
  if (cases != 36 || negatives != cases) return 6;
  printf("STACK-TRIP-OWNER-LIMIT-OK %d %d\n", cases, negatives);
  return 0;
}
