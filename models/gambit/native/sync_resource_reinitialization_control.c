/* Locked source helpers, mocked resource accounting, no POSIX runtime claim. */
#include <stdio.h>
#include <stdlib.h>

typedef struct { int live; } resource;
typedef struct processor {
  int sync_id0, sync_id1, sync_id2;
  resource sync_mut, sync_cv;
} *___processor_state;

static int initialized, double_init;
static int initialize(resource *value) {
  initialized++;
  if (value->live) double_init++;
  value->live = 1;
  return 1;
}

#define ___P(args, old) args
#define ___HIDDEN static
#define ___EXP_FUNC(type, name) type name
#define SYNC_INIT_MSG(field) ((field) = -1)
#define ___MUTEX_INIT(value) initialize(&(value))
#define ___CONDVAR_INIT(value) initialize(&(value))
static void cleanup_interrupts_pstate(___processor_state ps) { (void)ps; }
static void cleanup_os_and_mem_pstate(___processor_state ps) { (void)ps; }
#include "sync-resource-source.inc"

int main(int argc, char **argv) {
  if (argc != 2 || (argv[1][0] != '0' && argv[1][0] != '1') || argv[1][1] != '\0') return 2;
  struct processor ps = {0};
  setup_sync_op_pstate(&ps);
  ___cleanup_pstate(&ps);
  if (argv[1][0] == '1') setup_sync_op_pstate(&ps);
  printf("INITIALIZED %d DOUBLE_INIT %d\n", initialized, double_init);
  if (double_init != 0) {
    puts("RESOURCE-REUSE-DENIED");
    return 1;
  }
  if (initialized != 2 || ps.sync_id0 != -1 || ps.sync_id1 != -1 || ps.sync_id2 != -1) return 3;
  puts("SINGLE-INITIALIZATION-OBSERVED");
  return 0;
}
