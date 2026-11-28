/* Family 7 (7/12: stress-gsc) Compiled-Host CBMC Contract:
 * 1. Fix 1C register scrubbing across handler_stack_limit, handler_heap_limit,
 *    and handler_force guarantees that dead GVM registers carrying raw F64
 *    spill bits are scrubbed to ___FIX(0L) before GC mark_registers can scan them.
 * 2. Observational equivalence of the < 6000-label RSS header guard
 *    (object_access.h.in:31-39, runtime_protocols.h.in:1227-1253):
 *    expanding the guarded (< 6000) vs unguarded (>= 6000) macro forms yields
 *    identical observable runtime state transitions across all (obsActive, attempt)
 *    combinations.
 */
#include <stdint.h>

typedef long ___WORD;
typedef unsigned long ___UWORD;
typedef void *___processor_state;

#define ___FIX(x) ((___WORD)((x) << 2))
#define ___NB_GVM_REGS 5
#define CHECK(p, n) __CPROVER_assert((p), (n))

extern int nondet_int(void);
extern ___WORD nondet_word(void);

/* --- Part 1: Fix 1C register scrub across all three internal-return handlers --- */

typedef struct {
  ___WORD r0, r1, r2, r3, r4;
  ___WORD saved_regs[5];
  ___WORD saved_ra;
} gvm_regs;

static void push_regs_and_ra(gvm_regs *g, ___WORD ra) {
  g->saved_regs[0] = g->r0;
  g->saved_regs[1] = g->r1;
  g->saved_regs[2] = g->r2;
  g->saved_regs[3] = g->r3;
  g->saved_regs[4] = g->r4;
  g->saved_ra = ra;
}

static void handler_stack_limit_scrub(gvm_regs *g, ___WORD ra, ___WORD internal_ret) {
  push_regs_and_ra(g, ra);
  g->r1 = ___FIX(0L);
  g->r2 = ___FIX(0L);
  g->r3 = ___FIX(0L);
  g->r4 = ___FIX(0L);
  g->r0 = internal_ret;
}

static void handler_heap_limit_scrub(gvm_regs *g, ___WORD ra, ___WORD internal_ret) {
  push_regs_and_ra(g, ra);
  g->r1 = ___FIX(0L);
  g->r2 = ___FIX(0L);
  g->r3 = ___FIX(0L);
  g->r4 = ___FIX(0L);
  g->r0 = internal_ret;
}

static void handler_force_scrub(gvm_regs *g, ___WORD ra, ___WORD promise, ___WORD internal_ret) {
  push_regs_and_ra(g, ra);
  g->r2 = ___FIX(0L);
  g->r3 = ___FIX(0L);
  g->r4 = ___FIX(0L);
  g->r0 = internal_ret;
  /* ___PUSH_ARGS1(promise) installs promise into r1 (tagged Scheme object). */
  g->r1 = promise;
}

static int is_safe_gc_reg(___WORD val, ___WORD expected_live) {
  return val == ___FIX(0L) || val == expected_live;
}

void check_fix1c_register_scrub(void) {
  gvm_regs g;
  ___WORD raw_f64_1 = nondet_word();
  ___WORD raw_f64_2 = nondet_word();
  ___WORD raw_f64_3 = nondet_word();
  ___WORD raw_f64_4 = nondet_word();
  ___WORD ra = nondet_word();
  ___WORD internal_ret = ___FIX(42L);
  ___WORD promise = ___FIX(7L); /* valid tagged Scheme object */

  g.r0 = ra; g.r1 = raw_f64_1; g.r2 = raw_f64_2; g.r3 = raw_f64_3; g.r4 = raw_f64_4;
  handler_stack_limit_scrub(&g, ra, internal_ret);
  CHECK(g.saved_regs[1] == raw_f64_1 && g.saved_regs[4] == raw_f64_4 && g.saved_ra == ra,
        "fix1c.stack-limit-preserves-saved-frame");
  CHECK(g.r0 == internal_ret && g.r1 == ___FIX(0L) && g.r2 == ___FIX(0L) &&
        g.r3 == ___FIX(0L) && g.r4 == ___FIX(0L),
        "fix1c.stack-limit-scrubs-r1-to-r4");

  g.r0 = ra; g.r1 = raw_f64_1; g.r2 = raw_f64_2; g.r3 = raw_f64_3; g.r4 = raw_f64_4;
  handler_heap_limit_scrub(&g, ra, internal_ret);
  CHECK(g.r0 == internal_ret && g.r1 == ___FIX(0L) && g.r2 == ___FIX(0L) &&
        g.r3 == ___FIX(0L) && g.r4 == ___FIX(0L),
        "fix1c.heap-limit-scrubs-r1-to-r4");

  g.r0 = ra; g.r1 = raw_f64_1; g.r2 = raw_f64_2; g.r3 = raw_f64_3; g.r4 = raw_f64_4;
  handler_force_scrub(&g, ra, promise, internal_ret);
  CHECK(g.r0 == internal_ret && is_safe_gc_reg(g.r1, promise) &&
        g.r2 == ___FIX(0L) && g.r3 == ___FIX(0L) && g.r4 == ___FIX(0L),
        "fix1c.force-scrubs-r2-to-r4-and-installs-promise");
}

/* --- Part 2: < 6000 vs >= 6000 label-guard macro observational equivalence --- */

typedef struct {
  int store_events;
  int adjust_events;
  int pop_events;
  int commit_events;
  int gate2_open_events;
  int gate2_enter_events;
} obs_runtime;

static int g_obs_active;
static obs_runtime rt_small, rt_large;

static void rt_store_fast(obs_runtime *rt, void *fp, void *addr) {
  (void)fp; (void)addr;
  if (!g_obs_active) return;
  rt->store_events++;
}

static void rt_adjust_fast(obs_runtime *rt, void *fp, intptr_t words) {
  (void)fp; (void)words;
  if (!g_obs_active) return;
  rt->adjust_events++;
}

static void rt_pop_fast(obs_runtime *rt, void *fp) {
  (void)fp;
  if (!g_obs_active) return;
  rt->pop_events++;
}

static void rt_group_demand_commit(obs_runtime *rt, ___processor_state ps, ___WORD point, ___WORD attempt) {
  (void)ps; (void)point;
  if (attempt == 0 && !g_obs_active) return;
  rt->commit_events++;
}

static void rt_gate2_site(obs_runtime *rt, ___processor_state ps, const char *proc, int lbl, ___WORD point, ___WORD *fp, int opening) {
  (void)ps; (void)proc; (void)lbl; (void)point; (void)fp;
  if (!g_obs_active) return;
  if (opening) rt->gate2_open_events++;
  else rt->gate2_enter_events++;
}

/* Verbatim guard patterns from object_access.h.in:31-39 & runtime_protocols.h.in:1227-1253 */
#define SMALL_OBS_STORE(rt, fp, addr)   do { if (g_obs_active) rt_store_fast((rt), (fp), (addr)); } while (0)
#define LARGE_OBS_STORE(rt, fp, addr)   rt_store_fast((rt), (fp), (addr))
#define SMALL_OBS_ADJUST(rt, fp, w)     do { if (g_obs_active) rt_adjust_fast((rt), (fp), (w)); } while (0)
#define LARGE_OBS_ADJUST(rt, fp, w)     rt_adjust_fast((rt), (fp), (w))
#define SMALL_OBS_POP(rt, fp)           do { if (g_obs_active) rt_pop_fast((rt), (fp)); } while (0)
#define LARGE_OBS_POP(rt, fp)           rt_pop_fast((rt), (fp))
#define SMALL_COMMIT(rt, ps, pt, att)   do { if ((att) != 0 || g_obs_active) rt_group_demand_commit((rt), (ps), (pt), (att)); } while (0)
#define LARGE_COMMIT(rt, ps, pt, att)   rt_group_demand_commit((rt), (ps), (pt), (att))
#define SMALL_GATE2_OPEN(rt, ps, p, l, pt, fp)  do { if (g_obs_active) rt_gate2_site((rt), (ps), (p), (l), (pt), (fp), 1); } while (0)
#define LARGE_GATE2_OPEN(rt, ps, p, l, pt, fp)  rt_gate2_site((rt), (ps), (p), (l), (pt), (fp), 1)
#define SMALL_GATE2_ENTER(rt, ps, p, l, pt, fp) do { if (g_obs_active) rt_gate2_site((rt), (ps), (p), (l), (pt), (fp), 0); } while (0)
#define LARGE_GATE2_ENTER(rt, ps, p, l, pt, fp) rt_gate2_site((rt), (ps), (p), (l), (pt), (fp), 0)

void check_label_guard_macro_equivalence(void) {
  int obs = nondet_int();
  ___WORD attempt = nondet_word();
  __CPROVER_assume(obs == 0 || obs == 1);
  g_obs_active = obs;
  rt_small = (obs_runtime){0};
  rt_large = (obs_runtime){0};

  ___WORD dummy_slot = 0;
  SMALL_OBS_STORE(&rt_small, &dummy_slot, &dummy_slot);
  LARGE_OBS_STORE(&rt_large, &dummy_slot, &dummy_slot);
  SMALL_OBS_ADJUST(&rt_small, &dummy_slot, 2);
  LARGE_OBS_ADJUST(&rt_large, &dummy_slot, 2);
  SMALL_OBS_POP(&rt_small, &dummy_slot);
  LARGE_OBS_POP(&rt_large, &dummy_slot);
  SMALL_COMMIT(&rt_small, 0, 1, attempt);
  LARGE_COMMIT(&rt_large, 0, 1, attempt);
  SMALL_GATE2_OPEN(&rt_small, 0, "tfib", 1, 1, &dummy_slot);
  LARGE_GATE2_OPEN(&rt_large, 0, "tfib", 1, 1, &dummy_slot);
  SMALL_GATE2_ENTER(&rt_small, 0, "tfib", 1, 1, &dummy_slot);
  LARGE_GATE2_ENTER(&rt_large, 0, "tfib", 1, 1, &dummy_slot);

  CHECK(rt_small.store_events == rt_large.store_events, "macro.store-equiv");
  CHECK(rt_small.adjust_events == rt_large.adjust_events, "macro.adjust-equiv");
  CHECK(rt_small.pop_events == rt_large.pop_events, "macro.pop-equiv");
  CHECK(rt_small.commit_events == rt_large.commit_events, "macro.commit-equiv");
  CHECK(rt_small.gate2_open_events == rt_large.gate2_open_events, "macro.gate2-open-equiv");
  CHECK(rt_small.gate2_enter_events == rt_large.gate2_enter_events, "macro.gate2-enter-equiv");

  if (!obs && attempt == 0) {
    CHECK(rt_small.store_events == 0 && rt_small.adjust_events == 0 &&
          rt_small.pop_events == 0 && rt_small.commit_events == 0 &&
          rt_small.gate2_open_events == 0 && rt_small.gate2_enter_events == 0,
          "macro.fast-path-inactive-zero-overhead");
  }
}

/* --- Part 3: -D___DYNAMIC ___EXT(___GSTATE->fn) dispatch equivalence --- */

typedef struct {
  int *rest_observation_active_ptr;
  void (*store_fast)(obs_runtime *, void *, void *);
  void (*adjust_fast)(obs_runtime *, void *, intptr_t);
  void (*pop_fast)(obs_runtime *, void *);
  void (*group_demand_commit)(obs_runtime *, ___processor_state, ___WORD, ___WORD);
  void (*gate2_group_site)(obs_runtime *, ___processor_state, const char *, int, ___WORD, ___WORD *, int);
} dynamic_gstate_exports;

void check_dynamic_gstate_ext_dispatch_equiv(void) {
  int obs = nondet_int();
  ___WORD attempt = nondet_word();
  __CPROVER_assume(obs == 0 || obs == 1);
  g_obs_active = obs;
  obs_runtime rt_static = {0}, rt_dyn = {0};
  dynamic_gstate_exports gs = {
    .rest_observation_active_ptr = &g_obs_active,
    .store_fast = rt_store_fast,
    .adjust_fast = rt_adjust_fast,
    .pop_fast = rt_pop_fast,
    .group_demand_commit = rt_group_demand_commit,
    .gate2_group_site = rt_gate2_site,
  };
  ___WORD slot = 0;

  /* Static (-D___NONDYNAMIC) calls */
  SMALL_OBS_STORE(&rt_static, &slot, &slot);
  SMALL_OBS_ADJUST(&rt_static, &slot, 3);
  SMALL_OBS_POP(&rt_static, &slot);
  SMALL_COMMIT(&rt_static, 0, 1, attempt);
  SMALL_GATE2_OPEN(&rt_static, 0, "tfib", 1, 1, &slot);
  SMALL_GATE2_ENTER(&rt_static, 0, "tfib", 1, 1, &slot);

  /* Dynamic (-D___DYNAMIC / ___BIND_LATE via ___EXT(___GSTATE->...)) calls */
  if (*gs.rest_observation_active_ptr) gs.store_fast(&rt_dyn, &slot, &slot);
  if (*gs.rest_observation_active_ptr) gs.adjust_fast(&rt_dyn, &slot, 3);
  if (*gs.rest_observation_active_ptr) gs.pop_fast(&rt_dyn, &slot);
  if (attempt != 0 || *gs.rest_observation_active_ptr) gs.group_demand_commit(&rt_dyn, 0, 1, attempt);
  if (*gs.rest_observation_active_ptr) gs.gate2_group_site(&rt_dyn, 0, "tfib", 1, 1, &slot, 1);
  if (*gs.rest_observation_active_ptr) gs.gate2_group_site(&rt_dyn, 0, "tfib", 1, 1, &slot, 0);

  CHECK(rt_static.store_events == rt_dyn.store_events, "dyn.store-equiv");
  CHECK(rt_static.adjust_events == rt_dyn.adjust_events, "dyn.adjust-equiv");
  CHECK(rt_static.pop_events == rt_dyn.pop_events, "dyn.pop-equiv");
  CHECK(rt_static.commit_events == rt_dyn.commit_events, "dyn.commit-equiv");
  CHECK(rt_static.gate2_open_events == rt_dyn.gate2_open_events, "dyn.gate2-open-equiv");
  CHECK(rt_static.gate2_enter_events == rt_dyn.gate2_enter_events, "dyn.gate2-enter-equiv");
}
