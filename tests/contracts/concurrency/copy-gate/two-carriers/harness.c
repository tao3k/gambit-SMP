/* Actual Gambit gate and selected GNU sync macros, projected unchanged.
 * This finite two-thread harness is not a native SMP acceptance workload. */
#include <pthread.h>
#include <assert.h>
typedef long ___WORD;
#define ___VOLATILE volatile
#define ___USE_sync_builtins
#include "sync-builtins.inc"
#include "relax.inc"
#include "copy-gate.inc"
static ___WORD gate;
static int counter;
static void *worker(void *unused) {
  ___gc_copy_acquire(&gate);
  int previous=counter;
  counter=previous+1;
  ___gc_copy_release(&gate);
  return 0;
}
int main(void) {
  pthread_t first, second;
  pthread_create(&first,0,worker,0);
  pthread_create(&second,0,worker,0);
  pthread_join(first,0);
  pthread_join(second,0);
  assert(counter == 2);
  return 0;
}
