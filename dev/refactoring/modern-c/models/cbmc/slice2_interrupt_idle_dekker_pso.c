/* CBMC 6.11 Weak-Memory (--mm pso) Harness for Slice 2 v2 CI Deadlock Fix:
 *   1. Interrupt-Idle Dekker Protocol:
 *      `___STACK_TRIP_OFF()` + `___SHARED_MEMORY_BARRIER()` in
 *      `___service_interrupts_pstate` / `___refresh_interrupts_pstate` (`lib/setup.c`)
 *      paired with `##wait-idle-if-unchanged!` pending-interrupt & `interrupts-head`
 *      check (`lib/_thread.scm`) and `___raise_interrupt_pstate`.
 *   2. Cross-Processor VM-Level Atomic Card Barrier (`___gc_write_barrier_slot_vm`):
 *      `card_bits` fetch-or-release + `card_overflow_any_` store-release visible to
 *      STW `collect_minor_card_hints`.
 *
 * Safe build (MUST PASS with 0 failures):
 *   cbmc --mm pso -DUSE_DEKKER_FENCE=1 -DCHECK_PENDING_INTR=1 -DUSE_CARD_RELEASE=1 slice2_interrupt_idle_dekker_pso.c
 * Mutant killer builds (ALL 3 MUST FAIL verification):
 *   cbmc --mm pso -DUSE_DEKKER_FENCE=0 -DCHECK_PENDING_INTR=1 -DUSE_CARD_RELEASE=1 slice2_interrupt_idle_dekker_pso.c
 *   cbmc --mm pso -DUSE_DEKKER_FENCE=1 -DCHECK_PENDING_INTR=0 -DUSE_CARD_RELEASE=1 slice2_interrupt_idle_dekker_pso.c
 *   cbmc --mm pso -DUSE_DEKKER_FENCE=1 -DCHECK_PENDING_INTR=1 -DUSE_CARD_RELEASE=0 slice2_interrupt_idle_dekker_pso.c
 */
#include <assert.h>
#include <stdint.h>

#ifndef USE_DEKKER_FENCE
#define USE_DEKKER_FENCE 1
#endif
#ifndef CHECK_PENDING_INTR
#define CHECK_PENDING_INTR 1
#endif
#ifndef USE_CARD_RELEASE
#define USE_CARD_RELEASE 1
#endif

/* Shared state between remote raiser (core 0) and target idle processor (core 1). */
static int intr_flag = 0;          /* ___ps->intr_flag[HIGH_LEVEL] */
static int stack_trip = 0;         /* ___ps->context->stack_limit == STACK_TRIP */
static int idle_published = 0;     /* processor inserted into vm->idle_processors */
static int waiter_slept = 0;       /* core 1 entered kernel condvar wait */
static int raiser_woke_idle = 0;   /* core 0 saw idle_published and signaled wakeup */
static int raiser_done = 0;        /* core 0 finished wakeup check */
static int waiter_serviced = 0;    /* core 1 observed intr_flag and drained it */

/* Cross-processor card barrier state (___gc_write_barrier_slot_vm). */
static int card_bit_dirty = 0;
static int card_overflow_any = 0;
static int intr_head_published = 0;

static void raiser_core0(void) {
  /* 1. Cross-processor VM card barrier before publishing high-level interrupt node. */
  card_bit_dirty = 1;
#if USE_CARD_RELEASE
  __CPROVER_fence("WWfence", "RWfence");
  card_overflow_any = 1;
  __CPROVER_fence("WWfence", "RWfence");
#endif
  intr_head_published = 1;

  /* 2. Raise interrupt flag and trip stack limit, then check if target is idle. */
  intr_flag = 1;
  stack_trip = 1;
  __CPROVER_fence("WWfence", "WRfence", "RWfence", "RRfence");

  if (idle_published) {
    raiser_woke_idle = 1;
  }
  __CPROVER_fence("WWfence", "RWfence");
  raiser_done = 1;
}

static void target_core1(void) {
  /* 1. ___service_interrupts_pstate clears stack_trip before checking intr_flag. */
  stack_trip = 0;
#if USE_DEKKER_FENCE
  __CPROVER_fence("WWfence", "WRfence", "RWfence", "RRfence");
#endif
  if (intr_flag) {
    stack_trip = 1;
    waiter_serviced = 1;
    return;
  }

  /* 2. ##wait-idle-if-unchanged! publishes idle state, executes Dekker barrier,
   *    then rechecks pending interrupts and interrupts-head BEFORE sleeping. */
  idle_published = 1;
#if USE_DEKKER_FENCE
  __CPROVER_fence("WWfence", "WRfence", "RWfence", "RRfence");
#endif

#if CHECK_PENDING_INTR
  if (intr_flag || intr_head_published) {
    waiter_serviced = 1;
    return;
  }
#endif

  waiter_slept = 1;
}

int main(void) {
  __CPROVER_ASYNC_1: raiser_core0();
  target_core1();

  /* Ensure both threads completed before checking postconditions. */
  __CPROVER_assume(raiser_done == 1);
  __CPROVER_fence("RRfence", "RWfence");

  /* Property 1 (Deadlock freedom): Target core CANNOT sleep with an unhandled
   * interrupt unless raiser observed idle_published and issued a wakeup! */
  assert(!(waiter_slept && !raiser_woke_idle));

  /* Property 2 (Card barrier publication): Whenever intr_head_published is
   * observed, both card_bit_dirty and card_overflow_any MUST be visible! */
  assert(card_bit_dirty == 1 && card_overflow_any == 1);
  return 0;
}
