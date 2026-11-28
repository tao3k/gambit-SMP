/*
 * CBMC Weak-Memory (--mm pso) Contract Verification Harness:
 * Single-Word Packed `(gen << 1) | has_waiters` Futex/Ulock Generation Barrier
 * (`vendor/gambit/lib/setup.c`: `barrier_sync_noop` & `barrier_sync_op_ex`).
 *
 * Models 3 scenarios under --mm pso:
 *   0. Concurrent parker (w0) vs last arriver (w1) in generation 0.
 *   1. Cross-generation EAGAIN race: w0 sets waiter bit in gen 0, gets preempted
 *      before kernel wait; gen 0->1 advances; w2 sets waiter bit and sleeps in
 *      gen 1; w0 wakes/returns EAGAIN from gen 0 and MUST NOT clear gen 1's bit.
 *   2. PSO store-buffer reordering check between gen release and waiter read.
 *
 * Negative Mutants (each MUST FAIL CBMC):
 *   -DINJECT_BUG_CHECK_BEFORE_SET_WAITER
 *   -DINJECT_BUG_CLEAR_NEXT_GEN_WAITER_BIT
 *   -DINJECT_BUG_NONATOMIC_GEN_RELEASE_AND_WAITER_READ
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern int nondet_int(void);

static inline void fence_acq_rel(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

static inline uint32_t load_acq_u32(volatile uint32_t *p) {
  uint32_t v = *p;
  fence_acq_rel();
  return v;
}

static inline uint32_t xchg_acq_rel_u32(volatile uint32_t *p, uint32_t nv) {
  uint32_t old;
  fence_acq_rel();
  __CPROVER_atomic_begin();
  old = *p;
  *p = nv;
  __CPROVER_atomic_end();
  fence_acq_rel();
  return old;
}

static inline uint32_t cas_acq_rel_u32(volatile uint32_t *p, uint32_t expected,
                                       uint32_t desired) {
  uint32_t prev;
  fence_acq_rel();
  __CPROVER_atomic_begin();
  prev = *p;
  if (prev == expected) {
    *p = desired;
  }
  __CPROVER_atomic_end();
  fence_acq_rel();
  return prev;
}

/* Scenario 0 & 2: single generation (gen=0 -> gen=1) parker vs last arriver */
static volatile uint32_t g_bar_word;
static volatile uint32_t g_split_gen;
static volatile uint32_t g_split_waiters;
static volatile int g_w0_sleeping;
static volatile int g_w0_done;
static volatile int g_w1_done;
static volatile int g_lost_wakeup;

static void s0_parker(void) {
  uint32_t my_gen = 0u;
#ifdef INJECT_BUG_NONATOMIC_GEN_RELEASE_AND_WAITER_READ
  /* Split counters without SEQ_CST fence under PSO */
  g_split_waiters = 1u;
  if (g_split_gen == my_gen) {
    __CPROVER_atomic_begin();
    if (g_split_gen == my_gen)
      g_w0_sleeping = 1;
    __CPROVER_atomic_end();
  }
#elif defined(INJECT_BUG_CHECK_BEFORE_SET_WAITER)
  /* Check gen before publishing waiter bit -> lost wakeup */
  if ((load_acq_u32(&g_bar_word) >> 1) == my_gen) {
    __CPROVER_atomic_begin();
    g_bar_word |= 1u;
    g_w0_sleeping = 1;
    if ((g_bar_word >> 1) != my_gen)
      g_lost_wakeup = 1;
    __CPROVER_atomic_end();
  }
#else
  uint32_t expected = my_gen << 1;
  uint32_t waiter_word = expected | 1u;
  uint32_t obs = cas_acq_rel_u32(&g_bar_word, expected, waiter_word);
  if (obs == expected || obs == waiter_word) {
    /* Kernel atomic `__ulock_wait(&g_bar_word, waiter_word)` */
    __CPROVER_atomic_begin();
    if (g_bar_word == waiter_word)
      g_w0_sleeping = 1;
    __CPROVER_atomic_end();
  }
#endif
  fence_acq_rel();
  g_w0_done = 1;
}

static void s0_last_arriver(void) {
  uint32_t my_gen = 0u;
#ifdef INJECT_BUG_NONATOMIC_GEN_RELEASE_AND_WAITER_READ
  g_split_gen = my_gen + 1u;
  /* Missing SEQ_CST fence under PSO allows reading stale g_split_waiters == 0 */
  if (g_split_waiters > 0u) {
    __CPROVER_atomic_begin();
    g_w0_sleeping = 0;
    __CPROVER_atomic_end();
  }
#else
  uint32_t next_word = (my_gen + 1u) << 1;
  uint32_t old_word = xchg_acq_rel_u32(&g_bar_word, next_word);
  if (old_word & 1u) {
    __CPROVER_atomic_begin();
    g_w0_sleeping = 0;
    __CPROVER_atomic_end();
  }
#endif
  fence_acq_rel();
  g_w1_done = 1;
}

/* Scenario 1: cross-generation EAGAIN non-interference (gen=0 -> gen=1 -> gen=2) */
static volatile uint32_t g2_bar_word;
static volatile int g2_w2_sleeping;
static volatile int g2_w0_done;
static volatile int g2_w1_done;

static void s1_stale_gen0_eagain_worker(void) {
  /* w0 previously set waiter bit in gen=0, was preempted before kernel wait;
   * now gen=1 is active with w2 sleeping (`g2_bar_word == (1<<1)|1`). */
  uint32_t waiter_word_g0 = (0u << 1) | 1u;
  __CPROVER_atomic_begin();
  /* Kernel `__ulock_wait(&g2_bar_word, waiter_word_g0)` sees mismatch -> EAGAIN */
  int matched = (g2_bar_word == waiter_word_g0);
  __CPROVER_atomic_end();
  (void)matched;
#ifdef INJECT_BUG_CLEAR_NEXT_GEN_WAITER_BIT
  /* BUG: clearing waiter bit on EAGAIN wipes gen=1's waiter bit! */
  __CPROVER_atomic_begin();
  g2_bar_word &= ~1u;
  __CPROVER_atomic_end();
#endif
  fence_acq_rel();
  g2_w0_done = 1;
}

static void s1_gen1_last_arriver(void) {
  /* w1 finishes gen=1 while w0 returns EAGAIN from gen=0 */
  uint32_t old_word = xchg_acq_rel_u32(&g2_bar_word, (2u << 1));
  if (old_word & 1u) {
    __CPROVER_atomic_begin();
    g2_w2_sleeping = 0;
    __CPROVER_atomic_end();
  }
  fence_acq_rel();
  g2_w1_done = 1;
}

int main(void) {
  int scen = nondet_int() & 1;

  if (scen == 0) {
    g_bar_word = 0u;
    g_split_gen = 0u;
    g_split_waiters = 0u;
    g_w0_sleeping = 0;
    g_w0_done = 0;
    g_w1_done = 0;
    g_lost_wakeup = 0;

  __CPROVER_ASYNC_0:
    s0_parker();
    s0_last_arriver();

    if (g_w0_done && g_w1_done) {
      fence_acq_rel();
      assert(g_lost_wakeup == 0);
      assert(g_w0_sleeping == 0);
    }
  } else {
    /* Gen=1 active with w2 already sleeping and bit 0 set */
    g2_bar_word = (1u << 1) | 1u;
    g2_w2_sleeping = 1;
    g2_w0_done = 0;
    g2_w1_done = 0;

  __CPROVER_ASYNC_1:
    s1_stale_gen0_eagain_worker();
    s1_gen1_last_arriver();

    if (g2_w0_done && g2_w1_done) {
      fence_acq_rel();
      assert(g2_w2_sleeping == 0);
    }
  }

  return 0;
}
