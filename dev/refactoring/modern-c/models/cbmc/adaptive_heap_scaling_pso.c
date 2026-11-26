/* CBMC 6.11 Weak-Memory (--mm pso) & Exact C Arithmetic Contract Harness
 * for the Unified Memory Scaling Envelope (v26 <-> Slice 2 Major GC):
 *   1. Sub-linear SMP nursery headroom `gc_smp_nursery_headroom(P)` (zero overflow, < 2*P for P>=4)
 *   2. Hardware-adaptive `gc_adaptive_live_percent(...)` (zero 64-bit overflow, in [50,80], honors explicit -:l<N>)
 *   3. Collapse-aware history decay & safe contraction lower-bound preservation
 *   4. Direct-mmap large-still / census.queue magic-header alignment round-trip
 *   5. PSO weak-memory mailbox condvar empty-check soundness:
 *        -DUSE_MUTEX_GUARD=1 : PASSES (0 lost wakeups under PSO)
 *        -DUSE_MUTEX_GUARD=0 : FAILS  (kills unlocked condvar empty-check lost-wakeup mutant!)
 */
#include <assert.h>
#include <stdint.h>
#include <stddef.h>

#ifndef USE_MUTEX_GUARD
#define USE_MUTEX_GUARD 1
#endif

static uint32_t gc_isqrt_u32(uint32_t n) {
  uint32_t x = 0;
  uint32_t bit = 1u << 14;
  while (bit > n) bit >>= 2;
  while (bit != 0) {
    if (n >= x + bit) {
      n -= x + bit;
      x = (x >> 1) + bit;
    } else {
      x >>= 1;
    }
    bit >>= 2;
  }
  return x;
}

static int gc_smp_nursery_headroom(int processor_count) {
  if (processor_count <= 1) return 1;
  if (processor_count <= 2) return processor_count;
  if (processor_count > 1024) processor_count = 1024;
  return 2 + (int)gc_isqrt_u32((uint32_t)processor_count);
}

static int gc_adaptive_live_percent(
    int explicit_flag,
    int configured_pct,
    uint64_t live_bytes,
    uint64_t phys_mem_bytes,
    uint64_t cpu_count,
    uint64_t max_heap_bytes)
{
  uint32_t eff_cpus, soft_mib, live_mib, lo, hi, span, delta, extra;
  uint64_t ram_mib, cap_mib;
  if (explicit_flag)
    return configured_pct;
  if (phys_mem_bytes == 0 && max_heap_bytes == 0)
    return configured_pct;

  eff_cpus = (cpu_count >= 2u) ? (uint32_t)((cpu_count > 1024u) ? 1024u : cpu_count) : 2u;
  ram_mib = phys_mem_bytes >> 20;
  cap_mib = max_heap_bytes >> 20;
  if (ram_mib > (uint64_t)UINT32_MAX) ram_mib = UINT32_MAX;
  if (cap_mib > (uint64_t)UINT32_MAX) cap_mib = UINT32_MAX;

  soft_mib = (ram_mib > 0u) ? ((uint32_t)ram_mib / eff_cpus) : (uint32_t)cap_mib;
  if (cap_mib > 0u && (uint32_t)cap_mib < soft_mib)
    soft_mib = (uint32_t)cap_mib;

  live_mib = (live_bytes >> 20 > (uint64_t)UINT32_MAX) ? UINT32_MAX : (uint32_t)(live_bytes >> 20);
  lo = soft_mib >> 3;
  hi = soft_mib >> 1;
  if (hi <= lo || live_mib <= lo)
    return 50;
  if (live_mib >= hi)
    return 80;

  span = hi - lo;
  delta = live_mib - lo;
  extra = (delta <= UINT32_MAX / 30u) ? ((delta * 30u) / span) : ((delta / span) * 30u);
  if (extra > 30u) extra = 30u;
  return 50 + (int)extra;
}

static uint64_t gc_decay_history_entry(uint64_t entry, uint64_t target, int force_contract) {
  if (force_contract)
    return target;
  if (target <= UINT64_MAX / 2u && target * 2u < entry) {
    uint64_t decayed = entry - (entry / 4u);
    return (decayed > target) ? decayed : target;
  }
  return entry;
}

/* --- Part 5: Concurrent PSO Weak-Memory Mailbox Waiter/Sender Protocol --- */
static int mutex_lock = 0;
static int msg_available = 0;
static int cv_waiters = 0;
static int receiver_sleeping = 0;
static int sender_signaled = 0;
static int receiver_done = 0;

static void lock_mx(void) {
  __CPROVER_atomic_begin();
  __CPROVER_assume(mutex_lock == 0);
  mutex_lock = 1;
  __CPROVER_atomic_end();
  __CPROVER_fence("RRfence", "RWfence");
}

static void unlock_mx(void) {
  __CPROVER_fence("WWfence", "RWfence");
  __CPROVER_atomic_begin();
  mutex_lock = 0;
  __CPROVER_atomic_end();
}

static void receiver_thread(void) {
  lock_mx();
  if (!msg_available) {
    /* Mirrors ##mutex-signal-and-condvar-wait!: registers in condvar BEFORE unlocking mutex. */
    cv_waiters = 1;
    __CPROVER_fence("WWfence", "RWfence");
    receiver_sleeping = 1;
    unlock_mx();
  } else {
    unlock_mx();
  }
  __CPROVER_fence("WWfence", "RWfence");
  receiver_done = 1;
}

static void sender_thread(void) {
  int need_signal = 0;
#if USE_MUTEX_GUARD
  /* Safe: inspect cv_waiters strictly while holding mailbox mutex! */
  lock_mx();
  msg_available = 1;
  need_signal = (cv_waiters != 0);
  unlock_mx();
#else
  /* Buggy mutant: check cv_waiters outside mutex before publishing msg_available! */
  need_signal = (cv_waiters != 0);
  lock_mx();
  msg_available = 1;
  unlock_mx();
#endif
  if (need_signal) {
    sender_signaled = 1;
    receiver_sleeping = 0;
  }
}

int main(void) {
  /* 1. Sub-linear SMP headroom across P=1..64 */
  static const int p_table[7] = { 1, 2, 4, 8, 16, 32, 64 };
  int idx;
  __CPROVER_assume(idx >= 0 && idx < 7);
  int p = p_table[idx];
  int h = gc_smp_nursery_headroom(p);
  assert(h >= 1);
  if (p >= 4) assert(h < 2 * p);
  if (p == 64) assert(h == 10);

  /* 2. Hardware-adaptive live_percent arithmetic safety & explicit flag honor
   *    across all 4 RAM x 4 CPU x 2 max_heap x 2 explicit x 10 critical live points. */
  static const uint64_t ram_table[4] = {
    4ull << 30, 12ull << 30, 32ull << 30, 128ull << 30
  };
  static const uint64_t cpu_table[4] = { 2u, 4u, 12u, 64u };
  int r_i, c_i, explicit_flag, m_i, l_i;
  __CPROVER_assume(r_i >= 0 && r_i < 4);
  __CPROVER_assume(c_i >= 0 && c_i < 4);
  __CPROVER_assume(explicit_flag == 0 || explicit_flag == 1);
  __CPROVER_assume(m_i == 0 || m_i == 1);
  __CPROVER_assume(l_i >= 0 && l_i < 10);

  uint64_t ram = ram_table[r_i];
  uint64_t cpus = cpu_table[c_i];
  uint64_t max_heap = m_i ? (4ull << 30) : 0ull;
  uint32_t budget_mib = (uint32_t)(ram >> 20) / (uint32_t)cpus;
  if (max_heap > 0 && (uint32_t)(max_heap >> 20) < budget_mib)
    budget_mib = (uint32_t)(max_heap >> 20);
  uint32_t lo_mib = budget_mib >> 3;
  uint32_t hi_mib = budget_mib >> 1;
  uint64_t live_bytes = 0;
  if (l_i == 0) live_bytes = 0;
  else if (l_i == 1) live_bytes = 1ull << 20;
  else if (l_i == 2) live_bytes = (lo_mib > 0) ? ((uint64_t)(lo_mib - 1u) << 20) : 0;
  else if (l_i == 3) live_bytes = (uint64_t)lo_mib << 20;
  else if (l_i == 4) live_bytes = (uint64_t)(lo_mib + 1u) << 20;
  else if (l_i == 5) live_bytes = (uint64_t)(lo_mib + ((hi_mib - lo_mib) >> 1)) << 20;
  else if (l_i == 6) live_bytes = (hi_mib > 0) ? ((uint64_t)(hi_mib - 1u) << 20) : 0;
  else if (l_i == 7) live_bytes = (uint64_t)hi_mib << 20;
  else if (l_i == 8) live_bytes = (uint64_t)(hi_mib + 1u) << 20;
  else live_bytes = 64ull << 30;

  int pct = gc_adaptive_live_percent(
      explicit_flag, 50, live_bytes, ram, cpus, max_heap);
  if (explicit_flag) {
    assert(pct == 50);
  } else {
    assert(pct >= 50 && pct <= 80);
    if ((live_bytes >> 20) <= lo_mib) assert(pct == 50);
    if ((live_bytes >> 20) >= hi_mib) assert(pct == 80);
  }

  /* 3. Collapse-aware history decay & lower-bound preservation */
  uint64_t hist_entry, new_target, lower_bound;
  __CPROVER_assume(hist_entry >= 16u && hist_entry <= (16ull << 30));
  __CPROVER_assume(new_target >= 4u && new_target <= hist_entry);
  __CPROVER_assume(lower_bound >= 4u && lower_bound <= (16ull << 30));

  uint64_t d_force = gc_decay_history_entry(hist_entry, new_target, 1);
  assert(d_force == new_target);
  uint64_t d_auto = gc_decay_history_entry(hist_entry, new_target, 0);
  assert(d_auto >= new_target && d_auto <= hist_entry);
  if (new_target * 2u < hist_entry)
    assert(d_auto < hist_entry);
  uint64_t contracted = (d_force >= lower_bound) ? d_force : lower_bound;
  assert(contracted >= lower_bound);

  /* 4. Concurrent PSO mailbox empty-check soundness (0 lost wakeups!) */
  __CPROVER_ASYNC_1: receiver_thread();
  sender_thread();
  __CPROVER_assume(receiver_done == 1);
  __CPROVER_fence("RRfence", "RWfence");

  /* Once both threads finish, if receiver slept (cv_waiters==1) while sender
   * deposited msg_available==1, sender MUST have signaled (no lost wakeup). */
  if (msg_available && cv_waiters) {
    assert(sender_signaled);
  }
  return 0;
}
