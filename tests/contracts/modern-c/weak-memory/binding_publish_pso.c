/* Multi-threaded Weak-Memory (PSO/TSO) CBMC Contract:
 * Single-page `primitive_value` publication (vendor/gambit/lib/_mem/global-bindings.inc).
 *
 * Writer stores `prim_cell = 42`, then publishes `prim_flag = 1`.
 * Reader loads `prim_flag`; if 1, reader loads `prim_cell` and asserts `prim_cell == 42`.
 *
 * Under `--mm pso` (Partial Store Order, modeling store-store reordering on ARM64/POWER):
 *   - `-DUSE_FENCE=1` (release fence between cell store and flag store + acquire fence
 *     between flag load and cell load): VERIFICATION SUCCESSFUL.
 *   - `-DUSE_FENCE=0` (relaxed stores/loads without fences): VERIFICATION FAILED
 *     with an automatic store-reordering counterexample!
 */
#include <stdint.h>

#ifndef USE_FENCE
#define USE_FENCE 1
#endif

static volatile int prim_cell = 0;
static volatile int prim_flag = 0;
static volatile int observed = -1;

static void writer_thread(void) {
  prim_cell = 42;
#if USE_FENCE
  __CPROVER_fence("WWfence", "RWfence", "WRfence", "RRfence");
#endif
  prim_flag = 1;
}

static void reader_thread(void) {
  int f = prim_flag;
#if USE_FENCE
  __CPROVER_fence("RRfence", "RWfence", "WRfence", "WWfence");
#endif
  if (f == 1) {
    int v = prim_cell;
    observed = v;
    __CPROVER_assert(v == 42, "pso.single-page-primitive-publish-visible");
  }
}

int main(void) {
  __CPROVER_ASYNC_1: writer_thread();
  reader_thread();
  return 0;
}
