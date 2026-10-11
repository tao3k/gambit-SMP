/* Only primitive resources are mocked; the two helper functions are extracted. */
#include <stdio.h>
#include <string.h>
typedef int ___SCMOBJ;
typedef struct processor {
  int fail, os_live, mem_live, os_releases, mem_releases, invalid;
} *___processor_state;
#define ___P(args, old) args
#define ___HIDDEN static
#define ___FIX(value) (value)
#define ___NO_ERR 0
static int ___setup_os_pstate(___processor_state ps) {
  if (ps->fail == 1) return 11;
  ps->os_live = 1;
  return 0;
}
static int ___setup_mem_pstate(___processor_state ps) {
  if (!ps->os_live) ++ps->invalid;
  if (ps->fail == 2) return 22;
  ps->mem_live = 1;
  return 0;
}
static void ___cleanup_mem_pstate(___processor_state ps) {
  ++ps->mem_releases;
  if (!ps->mem_live) ++ps->invalid;
  ps->mem_live = 0;
}
static void ___cleanup_os_pstate(___processor_state ps) {
  ++ps->os_releases;
  if (!ps->os_live || ps->mem_live) ++ps->invalid;
  ps->os_live = 0;
}
#include "pstate-os-mem-source.inc"
int main(void) {
  struct processor ps;
  memset(&ps, 0, sizeof ps);
  ps.fail = 1;
  if (setup_os_and_mem_pstate(&ps) != 11 || ps.os_live || ps.mem_live ||
      ps.os_releases || ps.mem_releases || ps.invalid) return 1;
  puts("OS-FAILURE NO-OWNED-RESOURCES");
  memset(&ps, 0, sizeof ps);
  ps.fail = 2;
  if (setup_os_and_mem_pstate(&ps) != 22 || ps.os_live || ps.mem_live ||
      ps.os_releases != 1 || ps.mem_releases || ps.invalid) return 2;
  puts("MEM-FAILURE OS-ALREADY-RELEASED");
  memset(&ps, 0, sizeof ps);
  if (setup_os_and_mem_pstate(&ps) || !ps.os_live || !ps.mem_live) return 3;
  cleanup_os_and_mem_pstate(&ps);
  if (ps.os_live || ps.mem_live || ps.os_releases != 1 || ps.mem_releases != 1 || ps.invalid) return 4;
  puts("SUCCESS MEMORY-BEFORE-OS");
  memset(&ps, 0, sizeof ps);
  ps.fail = 2;
  if (setup_os_and_mem_pstate(&ps) != 22) return 5;
  cleanup_os_and_mem_pstate(&ps); /* Explicit negative policy, not the current caller. */
  if (ps.os_releases != 2 || ps.mem_releases != 1 || ps.invalid != 2) return 6;
  puts("BLIND-CLEANUP TWO-INVALID-RELEASES");
  puts("PSTATE-OS-MEM-TRANSACTION-OBSERVED");
  return 0;
}
