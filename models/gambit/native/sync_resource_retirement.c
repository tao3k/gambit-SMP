/* Exact setup/cleanup source functions; resource accounting is mocked. */
#include <stdio.h>
typedef struct { int live; } resource;
typedef struct processor {
  int sync_id0, sync_id1, sync_id2;
  resource sync_mut, sync_cv;
} *___processor_state;
static int initialized, destroyed, double_init;
static int initialize(resource *r) {
  ++initialized;
  if (r->live) ++double_init;
  r->live = 1;
  return 1;
}
#define ___P(args, old) args
#define ___HIDDEN static
#define ___EXP_FUNC(type, name) type name
#define SYNC_INIT_MSG(field) ((field) = -1)
#define ___MUTEX_INIT(r) initialize(&(r))
#define ___CONDVAR_INIT(r) initialize(&(r))
static void cleanup_interrupts_pstate(___processor_state ps) { (void)ps; }
static void cleanup_os_and_mem_pstate(___processor_state ps) { (void)ps; }
#include "sync-resource-source.inc"
int main(void) {
  struct processor ps = {0};
  setup_sync_op_pstate(&ps);
  ___cleanup_pstate(&ps);
  setup_sync_op_pstate(&ps);
  printf("INITIALIZED %d DESTROYED %d DOUBLE_INIT %d\n",
         initialized, destroyed, double_init);
  if (initialized != 4 || destroyed != 0 || double_init != 2) return 1;
  puts("SOURCE-RESOURCE-REUSE-REPRODUCED");
  return 0;
}
