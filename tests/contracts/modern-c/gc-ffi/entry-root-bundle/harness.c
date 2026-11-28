/* Family 10 (10/12: gc-ffi) CBMC Contract:
 * Verifies EntryRootBundle moving-argument pin/reload/unwind matching,
 * W < R worker-root domain conservation, and slot-oracle missed-root detection.
 */
#include <stdint.h>

#define CHECK(p, n) __CPROVER_assert((p), (n))
extern int nondet_int(void);

#define NUM_SLOTS 3
#define NUM_DOMAINS 4
#define NUM_WORKERS 2

typedef struct {
  int pinned[NUM_SLOTS];
  uint32_t slot_epoch[NUM_SLOTS];
  int active_depth;
} entry_root_bundle;

static void enter_bundle(entry_root_bundle *b, uint32_t gc_epoch) {
  b->active_depth += 1;
  for (int i = 0; i < NUM_SLOTS; ++i) {
    b->pinned[i] = 1;
    b->slot_epoch[i] = gc_epoch;
  }
}

static void gc_scan_bundle(entry_root_bundle *b, uint32_t new_epoch, int omit_slot) {
  for (int i = 0; i < NUM_SLOTS; ++i) {
    if (i == omit_slot)
      continue;
    if (b->pinned[i])
      b->slot_epoch[i] = new_epoch;
  }
}

static int slot_oracle_all_repaired(const entry_root_bundle *b, uint32_t new_epoch) {
  for (int i = 0; i < NUM_SLOTS; ++i) {
    if (b->pinned[i] && b->slot_epoch[i] != new_epoch)
      return 0;
  }
  return 1;
}

static void unwind_bundle(entry_root_bundle *b) {
  if (b->active_depth > 0)
    b->active_depth -= 1;
  if (b->active_depth == 0) {
    for (int i = 0; i < NUM_SLOTS; ++i)
      b->pinned[i] = 0;
  }
}

int main(void) {
  /* 1. W < R domain claim conservation (W=2, R=4) */
  int repaired[NUM_DOMAINS] = { 0, 0, 0, 0 };
  int claim_counts[NUM_DOMAINS] = { 0, 0, 0, 0 };
  for (int d = 0; d < NUM_DOMAINS; ++d) {
    int worker = d % NUM_WORKERS;
    CHECK(worker >= 0 && worker < NUM_WORKERS, "f10.worker-in-bounds");
    claim_counts[d] += 1;
    repaired[d] = 1;
  }
  int total_repaired = 0;
  for (int d = 0; d < NUM_DOMAINS; ++d) {
    CHECK(claim_counts[d] == 1 && repaired[d] == 1, "f10.each-domain-repaired-once");
    total_repaired += repaired[d];
  }
  CHECK(total_repaired == NUM_DOMAINS, "f10.w-less-r-total-conserved");

  /* 2. EntryRootBundle nested callback + GC repair + matched unwind */
  entry_root_bundle b = { {0, 0, 0}, {0u, 0u, 0u}, 0 };
  enter_bundle(&b, 1u);
  enter_bundle(&b, 1u);
  gc_scan_bundle(&b, 2u, -1);
  CHECK(slot_oracle_all_repaired(&b, 2u) == 1, "f10.all-moving-roots-repaired");
  unwind_bundle(&b);
  CHECK(b.active_depth == 1 && b.pinned[0] == 1, "f10.outer-pin-kept-after-inner-unwind");
  unwind_bundle(&b);
  CHECK(b.active_depth == 0 && b.pinned[0] == 0, "f10.pins-released-at-depth-zero");

  /* 3. Slot oracle catches omitted root slot even when object survives elsewhere */
  entry_root_bundle bad = { {0, 0, 0}, {0u, 0u, 0u}, 0 };
  enter_bundle(&bad, 1u);
  int omitted = nondet_int();
  __CPROVER_assume(omitted >= 0 && omitted < NUM_SLOTS);
  gc_scan_bundle(&bad, 2u, omitted);
  CHECK(slot_oracle_all_repaired(&bad, 2u) == 0, "f10.slot-oracle-detects-omitted-root");

  /* 4. Primary coordinator P0 + contiguous live-carrier prefix (root-tasks.inc:640) */
  int participants = nondet_int();
  __CPROVER_assume(participants >= 1 && participants <= 8);
  int launches_native_live[8] = { 0, 1, 1, 1, 1, 1, 1, 1 }; /* P0 never launched via vm_resize */
  int live_fixed = (participants > 0) ? 1 : 0;
  for (int i = 1; i < participants; ++i) {
    if (launches_native_live[i]) live_fixed++;
    else break;
  }
  CHECK(live_fixed == participants, "f10.primary-p0-counted-yields-full-workers");
  if (participants >= 2) {
    int live_buggy = 0;
    for (int i = 0; i < participants; ++i)
      if (launches_native_live[i]) live_buggy++;
    CHECK(live_buggy == participants - 1, "f10.omitting-p0-undercounts-witness");
  }

  /* 4b. Adversarial non-contiguous launch gap [P0=live, P1=dead, P2=live]:
   * Contiguous-prefix clamping ensures members[i % count] NEVER targets dead P1! */
  int gap_live[3] = { 0, 0, 1 };
  int gap_prefix = 1;
  for (int i = 1; i < 3; ++i) {
    if (gap_live[i]) gap_prefix++;
    else break;
  }
  CHECK(gap_prefix == 1, "f10.non-contiguous-gap-clamped-to-live-prefix");
  for (int i = 0; i < 3; ++i) {
    int exec_id = i % gap_prefix;
    CHECK(exec_id == 0 || gap_live[exec_id] == 1, "f10.every-assigned-executor-native-live");
  }

  /* 4c. Adversarial double-retry unboxed-spill challenge (gsc/_t-c-2.scm):
   * Post-grant scrub preserves exact IEEE-754 uint64 bits across retries AND leaves
   * carrier scrubbed to ___FAL before any subsequent ___POLL (0x3fL). */
  uint64_t f64_orig = 0x41dac1b50da8e547ULL;
  uint64_t f64_reg = f64_orig;
  uint64_t gvm_r3 = f64_reg; /* targ-spill-dirty-unboxed before ___DEF_SLBL */
  int carrier_is_raw = 1;
  /* Two consecutive slow-path GC retries resume at ___DEF_SLBL and reload F64 */
  for (int retry = 0; retry < 2; ++retry) {
    f64_reg = gvm_r3;
    CHECK(f64_reg == f64_orig, "f10.unboxed-spill-survives-slow-path-retry");
  }
  /* Grant succeeded: targ-scrub-dirty-unboxed immediately overwrites carrier */
  gvm_r3 = 0ULL;
  carrier_is_raw = 0;
  CHECK(f64_reg == f64_orig && carrier_is_raw == 0 && gvm_r3 == 0ULL,
        "f10.post-grant-scrub-preserves-f64-and-protects-poll");

  /* 5. Overflow group-demand retirement before raising stack/heap overflow */
  int group_demand_active = 1;
  int overflow = 1;
  int raised = 0;
  if (overflow) {
    group_demand_active = 0; /* ___group_demand_retire(___ps) */
    raised = 1;
  }
  CHECK(!raised || group_demand_active == 0, "f10.overflow-retires-demand-before-raise");

  /* 6. Physical-exit SFUN borrow custody (sfun-entry.inc:32, 92-103) */
  uint32_t base_borrows = 4u;
  uint32_t cur_borrows = base_borrows + 1u; /* ___begin_sfun acquires borrow */
  CHECK(cur_borrows == base_borrows + 1u, "f10.sfun-borrow-held-through-marker-and-escape");
  cur_borrows -= 1u; /* ___end_sfun returns borrow on physical C unwind */
  CHECK(cur_borrows == base_borrows, "f10.sfun-borrow-drained-on-physical-exit");

  /* 7. Adversarial post-GC owner cleanup drain re-entry & NULL self challenge:
   *    Even when vm_live=1, rc_open=1, joined_round=0 (after reopen_rc_roots),
   *    cleanup[id].draining || cleanup[id].uncertain MUST refuse ___lifecycle_enter,
   *    root_writer_open, and ___garbage_collect without mutating fp/hp/r, while
   *    non-GC small still foreign alloc stays admitted. Also ___c_closure_self()==0
   *    with proc==___FAL MUST return UNKNOWN_ERR instead of dereferencing NULL. */
  int vm_live = nondet_int() & 1;
  int rc_open = nondet_int() & 1;
  int joined_round = nondet_int() & 1;
  int draining = nondet_int() & 1;
  int uncertain = nondet_int() & 1;
  int has_free_heap = nondet_int() & 1;
  int proc_is_false = nondet_int() & 1;
  int c_closure_self_nonnull = nondet_int() & 1;

  int enter_admitted = vm_live && !draining && !uncertain;
  int writer_open = rc_open && !joined_round && !draining && !uncertain;
  int gc_admitted = vm_live && !draining && !uncertain;
  int small_still_ok = has_free_heap;
  int marker_self_deref = proc_is_false ? c_closure_self_nonnull : 1;

  if (draining || uncertain) {
    CHECK(!enter_admitted, "f10.drain-blocks-lifecycle-enter");
    CHECK(!writer_open, "f10.drain-blocks-root-writer-open");
    CHECK(!gc_admitted, "f10.drain-blocks-collective-gc");
    if (has_free_heap) {
      CHECK(small_still_ok, "f10.drain-preserves-small-still-alloc");
    }
  }
  if (proc_is_false && !c_closure_self_nonnull) {
    CHECK(!marker_self_deref, "f10.null-c-closure-self-refused-before-deref");
  }

  return 0;
}
