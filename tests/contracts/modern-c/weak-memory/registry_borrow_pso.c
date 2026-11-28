/* Multi-threaded Weak-Memory (PSO/TSO) CBMC Contract:
 * Family 8 VM Registry concurrent reader-borrow vs slot-reclamation protocol.
 *
 * Reader borrows slot with token `expected_inc = 1`: atomically validates
 * `(phase == ACTIVE && incarnation == 1)` and increments `borrowers`, then
 * reads `occupant_tag` and asserts it was NOT clobbered to 0/99 by reclaimer.
 * Reclaimer drains slot (`phase = DRAINING`), waits for `borrowers == 0`,
 * then reclaims (`incarnation++`, `occupant_tag = 0`) and reuses (`occupant_tag = 99`).
 *
 * Under `--mm pso`:
 *   - `-DUSE_ATOMIC=1` (atomic critical section modeling CAS/lock + acquire/release):
 *     VERIFICATION SUCCESSFUL (zero use-after-reclaim!).
 *   - `-DUSE_ATOMIC=0` (racy check-then-increment without atomic section):
 *     VERIFICATION FAILED with concrete concurrent use-after-reclaim counterexample!
 */
#include <stdint.h>

#ifndef USE_ATOMIC
#define USE_ATOMIC 1
#endif

enum { SLOT_EMPTY = 0, SLOT_ACTIVE = 1, SLOT_DRAINING = 2 };

static volatile uint32_t slot_incarnation = 1;
static volatile int slot_phase = SLOT_ACTIVE;
static volatile uint32_t slot_borrowers = 0;
static volatile int slot_occupant = 42;

static void reader_borrow_and_use(void) {
  int borrowed = 0;
#if USE_ATOMIC
  __CPROVER_atomic_begin();
  if (slot_phase == SLOT_ACTIVE && slot_incarnation == 1u) {
    slot_borrowers = slot_borrowers + 1u;
    borrowed = 1;
  }
  __CPROVER_atomic_end();
#else
  if (slot_phase == SLOT_ACTIVE && slot_incarnation == 1u) {
    /* BUG: reclaimer can drain & reclaim right here before borrowers++! */
    slot_borrowers = slot_borrowers + 1u;
    borrowed = 1;
  }
#endif
  if (borrowed) {
    int occ = slot_occupant;
    __CPROVER_assert(occ == 42, "pso.registry-borrower-sees-live-occupant");
#if USE_ATOMIC
    __CPROVER_atomic_begin();
    slot_borrowers = slot_borrowers - 1u;
    __CPROVER_atomic_end();
#else
    slot_borrowers = slot_borrowers - 1u;
#endif
  }
}

static void reclaimer_drain_and_reuse(void) {
  int reclaimed = 0;
#if USE_ATOMIC
  __CPROVER_atomic_begin();
  slot_phase = SLOT_DRAINING;
  if (slot_borrowers == 0u) {
    slot_incarnation = slot_incarnation + 1u;
    slot_occupant = 0;
    slot_phase = SLOT_EMPTY;
    reclaimed = 1;
  }
  __CPROVER_atomic_end();
#else
  slot_phase = SLOT_DRAINING;
  if (slot_borrowers == 0u) {
    slot_incarnation = slot_incarnation + 1u;
    slot_occupant = 0;
    slot_phase = SLOT_EMPTY;
    reclaimed = 1;
  }
#endif
  if (reclaimed) {
    slot_incarnation = slot_incarnation + 1u;
    slot_occupant = 99;
    slot_phase = SLOT_ACTIVE;
  }
}

int main(void) {
  __CPROVER_ASYNC_1: reclaimer_drain_and_reuse();
  reader_borrow_and_use();
  return 0;
}
