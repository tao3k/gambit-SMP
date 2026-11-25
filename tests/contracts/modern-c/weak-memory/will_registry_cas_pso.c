/* Multi-threaded Weak-Memory (PSO) CBMC Contract:
 * Lock-free CAS `##final-will-registry` push vs concurrent take-all (`lib/_kernel.scm`).
 *
 * Thread 1 pushes will W1 (bit 1) into `registry_mask`.
 * Thread 2 concurrently pushes will W2 (bit 2) into `registry_mask`.
 * After both finish, `registry_mask` MUST contain BOTH W1 and W2 (no lost will!).
 *
 * Under `--mm pso`:
 *   - `-DUSE_CAS=1` (atomic CAS loop matching `##vector-cas!` in `##final-will-registry-push!`):
 *     VERIFICATION SUCCESSFUL (zero lost wills!).
 *   - `-DUSE_CAS=0` (unlocked read-modify-write matching pre-fix `macro-fifo-insert-at-head!`):
 *     VERIFICATION FAILED with concurrent lost-will counterexample!
 */
#include <stdint.h>

#ifndef USE_CAS
#define USE_CAS 1
#endif

static volatile unsigned int registry_mask = 0;

static void push_will(unsigned int bit) {
#if USE_CAS
  int done = 0;
  for (int tries = 0; tries < 4 && !done; ++tries) {
    unsigned int cur = registry_mask;
    unsigned int next = cur | bit;
    __CPROVER_atomic_begin();
    if (registry_mask == cur) {
      registry_mask = next;
      done = 1;
    }
    __CPROVER_atomic_end();
  }
  __CPROVER_assume(done == 1);
#else
  unsigned int cur = registry_mask;
  registry_mask = cur | bit;
#endif
}

static volatile int t1_done = 0;

static void thread1(void) {
  push_will(1u);
  __CPROVER_fence("WWfence", "RWfence", "WRfence", "RRfence");
  t1_done = 1;
}

int main(void) {
  __CPROVER_ASYNC_1: thread1();
  push_will(2u);
  __CPROVER_assume(t1_done == 1);
  __CPROVER_fence("RRfence", "RWfence", "WRfence", "WWfence");
  __CPROVER_assert(registry_mask == 3u, "pso.final-will-registry-no-lost-will");
  return 0;
}
