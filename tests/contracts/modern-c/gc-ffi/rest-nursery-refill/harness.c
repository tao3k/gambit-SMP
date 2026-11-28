/* CBMC bounded verification harness for Gambit-SMP rest-parameter
 * zero-growth budgeted nursery TLAB refill:
 *   vendor/gambit/lib/_mem/heap-sections.inc:___rest_take_free_section
 *   vendor/gambit/lib/_kernel.scm:handler_get_rest / handler_get_key_rest
 *
 * Verifies:
 *   1. Overflow-safe word demand calculation (pending * 3 + np + 1).
 *   2. Zero heap growth before GC (the_msections->nb_sections unchanged).
 *   3. Exact compute_free_heap_space_approximately() >= ___MSECTION_SIZE gate.
 *   4. Strict max_heap enforcement via ___rest_new_section_admitted.
 *   5. Unowned fresh section requirement (!stack_owner && !stack_state && !heap_used).
 *   6. Oversized demand refusal BEFORE commit_fresh_msection (0 wasted sections).
 *   7. Stack shortage isolation (never switches heap section on short stack).
 *   8. Planted one-word-short cut-9 dominance over refill and GC.
 *   9. Zero GC amplification while budgeted free nursery sections remain.
 */
#include <stdint.h>
#include <stddef.h>
#include <limits.h>

#ifdef __CPROVER__
#define CHECK(cond, msg) __CPROVER_assert((cond), (msg))
#define ASSUME(cond) __CPROVER_assume((cond))
extern int nondet_int(void);
extern unsigned int nondet_uint(void);
extern long nondet_long(void);
extern _Bool nondet_bool(void);
#else
#include <assert.h>
#define CHECK(cond, msg) assert((cond) && (msg))
#define ASSUME(cond) do { if (!(cond)) return 0; } while (0)
static int nondet_int(void) { return 0; }
static unsigned int nondet_uint(void) { return 0; }
static long nondet_long(void) { return 0; }
static _Bool nondet_bool(void) { return 0; }
#endif

#define MSECTION_SIZE  131072L
#define MSECTION_HALF  (MSECTION_SIZE >> 1)
#define MSECTION_FUDGE 9220L
#define PAIR_WORDS     3L
#define VECTOR_BODY    1L
#define WORD_MAX       LONG_MAX

typedef struct {
  int stack_owner;
  int stack_state;
  int heap_used;
  long base_offset;
} section_slot;

typedef struct {
  int nb_sections;
  int nb_assigned;
  int overflow_reserve_sections;
  long max_heap_sections; /* 0 = unbounded */
  int custom_alloc;
  int lifecycle_gc_admitted;
  int gc_count;
  int cut9_count;
  int refill_count;
  section_slot slots[16];
} vm_model;

static int compute_rest_words(long pending, long np, long *out_words)
{
  if (pending < 0 || np < 0) return 0;
  if (pending != 0 && PAIR_WORDS > WORD_MAX / pending) return 0;
  long pairs = pending * PAIR_WORDS;
  if (pairs > WORD_MAX - np) return 0;
  long payload = pairs + np;
  if (payload > WORD_MAX - VECTOR_BODY) return 0;
  *out_words = payload + VECTOR_BODY;
  return 1;
}

static long free_heap_space_approx(const vm_model *vm)
{
  return ((long)vm->nb_sections - (long)vm->nb_assigned -
          (long)vm->overflow_reserve_sections) * MSECTION_SIZE;
}

static int new_section_admitted(const vm_model *vm)
{
  if (vm->max_heap_sections == 0) return 1;
  return (long)vm->nb_assigned + 1L <= vm->max_heap_sections;
}

static int rest_take_free_section(vm_model *vm, long pending, long np,
                                  int stack_fits, int *granted_room_out)
{
  long words = 0;
  if (!compute_rest_words(pending, np, &words)) return 0;
  if (!stack_fits) return 0;
  if (vm->custom_alloc || vm->nb_sections <= 0) return 0;
  if (free_heap_space_approx(vm) < MSECTION_SIZE) return 0;
  if (!new_section_admitted(vm)) return 0;
  if (vm->nb_assigned < 0 || vm->nb_assigned >= vm->nb_sections) return 0;
  section_slot *fresh = &vm->slots[vm->nb_assigned];
  if (fresh->stack_owner || fresh->stack_state || fresh->heap_used) return 0;
  long room = MSECTION_HALF - MSECTION_FUDGE;
  if (room < words) return 0;

  /* Commit exactly one already-budgeted section; NEVER grow nb_sections. */
  vm->nb_assigned += 1;
  fresh->heap_used = 1;
  vm->refill_count += 1;
  *granted_room_out = (int)room;
  return 1;
}

static int rest_handler_slow_path(vm_model *vm, long pending, long np,
                                  int planted_short, int one_word_short,
                                  int attempt_blocked, int stack_fits)
{
  int granted_room = 0;
  if (planted_short && one_word_short) {
    vm->cut9_count += 1;
    return -9; /* Cut 9 refusal */
  }
  if (attempt_blocked) {
    return -1; /* Cut 1 refusal */
  }
  if (!planted_short && rest_take_free_section(vm, pending, np, stack_fits, &granted_room)) {
    long words = 0;
    CHECK(compute_rest_words(pending, np, &words), "words_valid_after_refill");
    CHECK(granted_room >= words, "granted_room_covers_full_demand");
    return 1; /* Admitted on free nursery section, 0 GCs */
  }
  if (!vm->lifecycle_gc_admitted && !planted_short && stack_fits &&
      new_section_admitted(vm)) {
    return 2; /* Pre-GC bootstrap extension */
  }
  vm->gc_count += 1;
  return 0; /* Entered root-window + ___garbage_collect */
}

int main(void)
{
  /* 1. Symbolic single-step verification over all inputs */
  vm_model vm = {0};
  vm.nb_sections = nondet_int();
  vm.nb_assigned = nondet_int();
  vm.overflow_reserve_sections = nondet_int();
  vm.max_heap_sections = nondet_int();
  vm.custom_alloc = nondet_bool();
  vm.lifecycle_gc_admitted = 1;

  ASSUME(vm.nb_sections >= 4 && vm.nb_sections <= 16);
  ASSUME(vm.nb_assigned >= 1 && vm.nb_assigned <= vm.nb_sections);
  ASSUME(vm.overflow_reserve_sections >= 1 && vm.overflow_reserve_sections <= 4);
  ASSUME(vm.max_heap_sections >= 0 && vm.max_heap_sections <= 16);
  ASSUME(vm.max_heap_sections == 0 || vm.nb_assigned <= vm.max_heap_sections);

  if (vm.nb_assigned < vm.nb_sections) {
    vm.slots[vm.nb_assigned].stack_owner = nondet_bool();
    vm.slots[vm.nb_assigned].stack_state = nondet_bool();
    vm.slots[vm.nb_assigned].heap_used = nondet_bool();
  }

  long pending = nondet_long();
  long np = nondet_long();
  ASSUME(pending >= -1 && pending <= 30000);
  ASSUME(np >= -1 && np <= 100);

  int planted_short = nondet_bool();
  int one_word_short = nondet_bool();
  int attempt_blocked = nondet_bool();
  int stack_fits = nondet_bool();

  int before_total = vm.nb_sections;
  int before_assigned = vm.nb_assigned;
  long before_free = free_heap_space_approx(&vm);

  int rc = rest_handler_slow_path(&vm, pending, np, planted_short,
                                  one_word_short, attempt_blocked, stack_fits);

  /* Invariant A: NEVER grows totalSections pre-GC */
  CHECK(vm.nb_sections == before_total, "zero_heap_growth_pre_gc");

  /* Invariant B: max_heap strictly respected */
  CHECK(vm.max_heap_sections == 0 || vm.nb_assigned <= vm.max_heap_sections,
        "max_heap_bound_respected");

  /* Invariant C: Planted 1-word-short cut-9 dominance */
  if (planted_short && one_word_short) {
    CHECK(rc == -9 && vm.nb_assigned == before_assigned && vm.gc_count == 0,
          "planted_short_cut9_dominates");
  }

  /* Invariant D: Stack shortage never consumes a heap section */
  if (!stack_fits) {
    CHECK(vm.nb_assigned == before_assigned && vm.refill_count == 0,
          "stack_short_never_refills_heap");
  }

  /* Invariant E: Exhausted free nursery never refills and must route to GC */
  if (!planted_short && !attempt_blocked && before_free < MSECTION_SIZE) {
    CHECK(rc == 0 && vm.gc_count == 1 && vm.nb_assigned == before_assigned,
          "exhausted_nursery_routes_to_gc");
  }

  /* Invariant F: Oversized demand (> MSECTION_HALF - MSECTION_FUDGE) never wastes a section */
  long words = 0;
  if (compute_rest_words(pending, np, &words) && words > MSECTION_HALF - MSECTION_FUDGE) {
    CHECK(vm.nb_assigned == before_assigned && vm.refill_count == 0,
          "oversized_demand_never_commits_section");
  }

  /* 2. Multi-step zero-amplification verification: 6 consecutive TLAB shortages
   *    against 6 free nursery sections produce 6 refills and 0 GCs, then the 7th
   *    shortage triggers exactly 1 genuine GC! */
  vm_model multi = {0};
  multi.nb_sections = 10;
  multi.nb_assigned = 2;
  multi.overflow_reserve_sections = 2; /* 6 free nursery sections */
  multi.max_heap_sections = 0;
  multi.lifecycle_gc_admitted = 1;

  for (int k = 0; k < 6; k++) {
    int r = rest_handler_slow_path(&multi, 100, 3, 0, 0, 0, 1);
    CHECK(r == 1, "free_nursery_refill_succeeds");
  }
  CHECK(multi.gc_count == 0 && multi.refill_count == 6 &&
        multi.nb_assigned == 8 && multi.nb_sections == 10,
        "zero_gc_amplification_across_free_nursery");

  int r7 = rest_handler_slow_path(&multi, 100, 3, 0, 0, 0, 1);
  CHECK(r7 == 0 && multi.gc_count == 1 && multi.nb_sections == 10,
        "seventh_shortage_triggers_genuine_gc");

  /* 3. Symbolic verification of ___heap_continue_on_free_section + ___stack_limit
   *    heap-exhaustion path (allocation-limits.inc:311-368, 1058-1079):
   *    Once lifecycle_gc_admitted == 1 and primlock_depth == 0:
   *      - NEVER grows nb_sections pre-GC (zero 0-GC 1.5x heap leak!)
   *      - Free nursery exhausted (or past hard edge) ALWAYS yields limit_kind == 2 -> GC! */
  {
    vm_model sl = {0};
    sl.nb_sections = nondet_int();
    sl.nb_assigned = nondet_int();
    sl.overflow_reserve_sections = nondet_int();
    sl.max_heap_sections = nondet_int();
    sl.lifecycle_gc_admitted = nondet_bool();
    ASSUME(sl.nb_sections >= 4 && sl.nb_sections <= 16);
    ASSUME(sl.nb_assigned >= 1 && sl.nb_assigned <= sl.nb_sections);
    ASSUME(sl.overflow_reserve_sections >= 1 && sl.overflow_reserve_sections <= 4);
    ASSUME(sl.max_heap_sections >= 0 && sl.max_heap_sections <= 16);
    ASSUME(sl.max_heap_sections == 0 || sl.nb_assigned <= sl.max_heap_sections);

    int primlock_depth = nondet_bool() ? 1 : 0;
    int past_hard_edge = nondet_bool();
    int before_n = sl.nb_sections;
    long before_free_sl = free_heap_space_approx(&sl);

    /* Step A: ___heap_continue_on_free_section */
    int continued = 0;
    if (!past_hard_edge) {
      if (!sl.lifecycle_gc_admitted && before_free_sl < MSECTION_SIZE &&
          sl.max_heap_sections == 0) {
        int add = sl.nb_sections / 2;
        if (add < 8) add = 8;
        sl.nb_sections += add;
      }
      if (free_heap_space_approx(&sl) >= MSECTION_SIZE && new_section_admitted(&sl)) {
        sl.nb_assigned += 1;
        continued = 1;
      }
    }

    /* Step B: ___stack_limit fallback when Step A returned 0 */
    int limit_kind = 0;
    if (!continued) {
      if (past_hard_edge) {
        limit_kind = 2; /* must trigger GC without rewinding hp */
      } else if (free_heap_space_approx(&sl) >= MSECTION_SIZE && new_section_admitted(&sl)) {
        sl.nb_assigned += 1;
        limit_kind = 0;
      } else if (primlock_depth > 0 && new_section_admitted(&sl)) {
        sl.nb_sections += 1;
        sl.nb_assigned += 1;
        limit_kind = 0;
      } else {
        limit_kind = 2;
      }
    }
    if (limit_kind != 0)
      sl.gc_count += 1;

    /* Invariants */
    if (sl.lifecycle_gc_admitted && primlock_depth == 0) {
      CHECK(sl.nb_sections == before_n, "admitted_heap_continue_never_grows_pool");
    }
    if (sl.lifecycle_gc_admitted && primlock_depth == 0 &&
        (past_hard_edge || before_free_sl < MSECTION_SIZE)) {
      CHECK(limit_kind == 2 && sl.gc_count == 1, "admitted_exhausted_nursery_triggers_gc");
    }
    if (past_hard_edge) {
      CHECK(limit_kind == 2 && sl.nb_sections == before_n, "past_hard_edge_always_triggers_gc");
    }
    CHECK(sl.max_heap_sections == 0 || sl.nb_assigned <= sl.max_heap_sections,
          "stack_limit_respects_max_heap");
  }

  return 0;
}
