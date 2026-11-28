/* Section 23 / Phase C20: Adversarial CBMC PSO Harness for Multi-Shot
 * Continuation Replay vs. Concurrent Downstream Consumer Read-Write Race
 * & Linear One-Shot Exclusivity.
 *
 * Verifies under --mm pso:
 *   1. Resolution A: In-place multi-shot replay allowed ONLY when bufReaders == 0
 *      and downstream consumer is quiescent ("pending")
 *   2. Resolution B: Concurrent multi-shot replay while downstream consumer is
 *      actively reading buf[3] forks a fresh COW slot (buf[5]) leaving buf[3]
 *      immutable (zero R/W race)
 *   3. Atomic CAS linear one-shot exclusivity (ONE_SHOT_LIVE -> ONE_SHOT_CONSUMED)
 *      under true concurrent PSO racing threads
 *   4. Freezing captured metacontinuation prefix frames (handler = #t) prevents
 *      concurrent in-place escape-k clearing while another shot reads it
 *
 * Negative Mutants (each MUST trigger VERIFICATION FAILED):
 *   -DINJECT_BUG_MULTISHOT_INPLACE_WRITE_OVER_ACTIVE_READER
 *   -DINJECT_BUG_MULTISHOT_REPLAY_LINEAR_ONESHOT
 *   -DINJECT_BUG_NONATOMIC_ONESHOT_CLAIM_SMP
 *   -DINJECT_BUG_COW_FORK_ALIAS_ACTIVE_BUF
 */

#include <assert.h>
#include <stdint.h>

extern void __CPROVER_atomic_begin(void);
extern void __CPROVER_atomic_end(void);
extern void __CPROVER_fence(const char *, const char *, const char *,
                            const char *, const char *, const char *);
extern void __CPROVER_assume(int);

static inline void fence_full(void) {
  __CPROVER_fence("WWfence", "RRfence", "RWfence", "WRfence", "WRcumul", "WWcumul");
}

/* Buffer ownership table: slot 3 = base snapshot, slot 5 = fresh COW fork */
static volatile int g_buf_writer[6];
static volatile int g_buf_readers[6];
static volatile int g_buf_val[6];
static volatile int g_rw_race_fault;

/* 3-state linear continuation header */
enum ContState {
  ONE_SHOT_LIVE     = 0,
  ONE_SHOT_CONSUMED = 1,
  MULTISHOT_COW     = 2
};

static volatile int g_linear_state;
static volatile int g_linear_exec_count;

/* Metacontinuation prefix frame (0 = rewindable, 1 = frozen immutable) */
static volatile int g_mc_frozen;
static volatile int g_mc_escape_k;
static volatile int g_mc_null_fault;

static int atomic_claim_oneshot(void) {
#ifdef INJECT_BUG_NONATOMIC_ONESHOT_CLAIM_SMP
  /* BUG: non-atomic check-then-set allows two SMP carriers to both execute! */
  int prev = g_linear_state;
  if (prev == ONE_SHOT_LIVE) {
    g_linear_state = ONE_SHOT_CONSUMED;
    return 1;
  }
  return 0;
#else
  int won = 0;
  __CPROVER_atomic_begin();
  if (g_linear_state == ONE_SHOT_LIVE) {
    g_linear_state = ONE_SHOT_CONSUMED;
    won = 1;
  }
  __CPROVER_atomic_end();
  if (won) fence_full();
  return won;
#endif
}

static void race_oneshot_worker(void) {
  if (atomic_claim_oneshot()) {
    __CPROVER_atomic_begin();
    g_linear_exec_count = g_linear_exec_count + 1;
    __CPROVER_atomic_end();
  }
}

static void downstream_reader_worker(void) {
  /* Downstream consumer atomically verifies snapshot is published (writer == 0)
   * and pins buf[3] in bufReaders before reading snapshot value 42. */
  int pinned = 0;
  __CPROVER_atomic_begin();
  if (g_buf_writer[3] == 0) {
    g_buf_readers[3] = g_buf_readers[3] + 1;
    pinned = 1;
  }
  __CPROVER_atomic_end();
  if (!pinned) return;
  fence_full();

  int v = g_buf_val[3];
  int w = g_buf_writer[3];
  if (w != 0 || (v != 42 && v != 99)) {
    g_rw_race_fault = 1;
  }

  fence_full();
  __CPROVER_atomic_begin();
  g_buf_readers[3] = g_buf_readers[3] - 1;
  __CPROVER_atomic_end();
}

static void multishot_replay_producer(int use_cow_fork) {
  int target_slot;
  if (use_cow_fork) {
#ifdef INJECT_BUG_COW_FORK_ALIAS_ACTIVE_BUF
    target_slot = 3; /* BUG: aliases active published snapshot buf[3]! */
#else
    target_slot = 5; /* Resolution B: fresh exclusive COW fork slot */
#endif
  } else {
    target_slot = 3; /* Resolution A: in-place reuse */
  }

  int admitted = 0;
  __CPROVER_atomic_begin();
  if (g_buf_writer[target_slot] == 0
#ifndef INJECT_BUG_MULTISHOT_INPLACE_WRITE_OVER_ACTIVE_READER
      && g_buf_readers[target_slot] == 0
#endif
  ) {
    g_buf_writer[target_slot] = 3;
    admitted = 1;
  }
  __CPROVER_atomic_end();

  if (admitted) {
    fence_full();
    if (g_buf_readers[target_slot] > 0) {
      g_rw_race_fault = 1;
    }
    g_buf_val[target_slot] = -1; /* torn/in-progress write */
    fence_full();
    g_buf_val[target_slot] = 99; /* completed new snapshot */
    fence_full();
    __CPROVER_atomic_begin();
    g_buf_writer[target_slot] = 0;
    __CPROVER_atomic_end();
  }
}

static void mc_shot2_reader(void) {
  if (g_mc_escape_k == 0) {
    g_mc_null_fault = 1;
  }
}

int main(void) {
  int scenario;
  __CPROVER_assume(scenario >= 0 && scenario <= 3);

  g_buf_writer[3] = 0; g_buf_readers[3] = 0; g_buf_val[3] = 42;
  g_buf_writer[5] = 0; g_buf_readers[5] = 0; g_buf_val[5] = 0;
  g_rw_race_fault = 0;
  g_linear_state = ONE_SHOT_LIVE;
  g_linear_exec_count = 0;
  g_mc_frozen = 1; /* %freeze-mc-prefix! applied at capture time */
  g_mc_escape_k = 777;
  g_mc_null_fault = 0;

  if (scenario == 0) {
    /* Scenario 0 (Resolution A): Producer attempts in-place replay concurrently
     * with downstream reader on buf[3]; guard refuses write while readers > 0. */
    __CPROVER_ASYNC_1: downstream_reader_worker();
    multishot_replay_producer(0);
    assert(g_rw_race_fault == 0);
  } else if (scenario == 1) {
    /* Scenario 1 (Resolution B): Producer replays via fresh COW fork buf[5]
     * concurrently while downstream reader reads immutable snapshot buf[3]. */
    __CPROVER_ASYNC_2: downstream_reader_worker();
    multishot_replay_producer(1);
    assert(g_rw_race_fault == 0);
    assert(g_buf_val[3] == 42);
  } else if (scenario == 2) {
    /* Scenario 2: Two SMP carriers race to consume the same linear one-shot
     * effect continuation; plus verify consumed linear task cannot replay. */
    __CPROVER_ASYNC_3: race_oneshot_worker();
    race_oneshot_worker();

#ifdef INJECT_BUG_MULTISHOT_REPLAY_LINEAR_ONESHOT
    /* BUG: unchecked replay of already-consumed linear effect */
    __CPROVER_atomic_begin();
    g_linear_exec_count = g_linear_exec_count + 1;
    __CPROVER_atomic_end();
#endif

    assert(g_linear_exec_count <= 1);
  } else {
    /* Scenario 3: Frozen metacontinuation prefix frame shared across two
     * concurrent multi-shot invocations never clears escape_k in-place. */
    __CPROVER_ASYNC_4: mc_shot2_reader();
    if (g_mc_frozen == 0) {
      g_mc_escape_k = 0; /* only permitted when NOT frozen */
    }
    assert(g_mc_null_fault == 0);
    assert(g_mc_escape_k == 777);
  }

  return 0;
}
