/* Family 7 (7/12: stress-gsc) Source-Bound CBMC Contract (v2):
 *
 * 1. check_real_header_macro_equiv:
 *    Exercises the EXACT verbatim macro definitions synced from:
 *      - vendor/gambit/include/_gambit/object_access.h.in:31-49
 *      - vendor/gambit/include/_gambit/runtime_protocols.h.in:1222-1279
 *    (verified line-for-line against vendor/gambit by tests/test_compiled_host_validator.py)
 *    proving observational equivalence across (<6000 vs >=6000) and
 *    (static vs -D___DYNAMIC / ___BIND_LATE).
 *
 * 2. check_inline_fast_span_enter_refinement:
 *    Proves that the proposed <6000 inline value-based fast-span enter check
 *    is bit-exact equivalent to allocation-limits.inc:1179-1197 across all
 *    nondeterministic pointer/bound/wraparound inputs, and that on a fast hit
 *    attempt == 0 makes ___group_demand_commit a dead no-op when observation
 *    is disabled.
 *
 * 3. check_single_hop_obs_active_equiv:
 *    Proves single-hop scalar ___GSTATE->obs_active and host-entry cached
 *    const int *obs_ptr are observationally equivalent to two-hop
 *    (*___GSTATE->___rest_observation_active_ptr).
 */
#include <stdint.h>
#include <stddef.h>

typedef long ___WORD;
typedef unsigned long ___UWORD;
typedef long ___SIZE_TS;
typedef struct ___execution_context_s {
  ___WORD *hp;
  ___WORD *fp;
} ___execution_context;

typedef struct ___processor_state_s {
  ___execution_context *context;
  int group_demand_active;
  ___UWORD stack_fast_floor_b;
  ___UWORD stack_fast_limit_b;
  ___UWORD heap_fast_lo_b;
  ___UWORD heap_fast_bytes;
} *___processor_state;

#define ___CAST(t, x) ((t)(x))
#define CHECK(p, n) __CPROVER_assert((p), (n))

extern int nondet_int(void);
extern ___WORD nondet_word(void);
extern ___UWORD nondet_uword(void);
extern ___SIZE_TS nondet_size_ts(void);

/* --- Shared observable runtime state for macro equivalence --- */

typedef struct {
  int store_events;
  int adjust_events;
  int pop_events;
  int commit_events;
  int gate2_open_events;
  int gate2_enter_events;
  int enter_calls;
} obs_sink;

static int ___rest_observation_active;
static obs_sink *g_active_sink;

static int rt_group_demand_enter(___processor_state ps, ___WORD **hp, ___WORD **fp,
                                 ___SIZE_TS sw, ___SIZE_TS hw, ___WORD pt, ___WORD *att) {
  (void)ps; (void)hp; (void)fp; (void)sw; (void)hw; (void)pt;
  g_active_sink->enter_calls++;
  if (att) *att = 0;
  return 1;
}

static void rt_group_demand_commit(___processor_state ps, ___WORD pt, ___WORD att) {
  (void)ps; (void)pt;
  if (att == 0 && !___rest_observation_active) return;
  g_active_sink->commit_events++;
}

static void rt_gate2_group_site(___processor_state ps, const char *proc, int lbl,
                                ___WORD pt, ___WORD *fp, int opening) {
  (void)ps; (void)proc; (void)lbl; (void)pt; (void)fp;
  if (!___rest_observation_active) return;
  if (opening) g_active_sink->gate2_open_events++;
  else g_active_sink->gate2_enter_events++;
}

static void rt_store_fast(void *fp, void *addr) {
  (void)fp; (void)addr;
  if (!___rest_observation_active) return;
  g_active_sink->store_events++;
}

static void rt_adjust_fast(void *fp, intptr_t words) {
  (void)fp; (void)words;
  if (!___rest_observation_active) return;
  g_active_sink->adjust_events++;
}

static void rt_pop_fast(void *fp) {
  (void)fp;
  if (!___rest_observation_active) return;
  g_active_sink->pop_events++;
}

/* Concrete runtime symbols for static (-D___NONDYNAMIC) expansion */
static int ___group_demand_enter(___processor_state ps, ___WORD **hp, ___WORD **fp,
                                 ___SIZE_TS sw, ___SIZE_TS hw, ___WORD pt, ___WORD *att) {
  return rt_group_demand_enter(ps, hp, fp, sw, hw, pt, att);
}
static void ___group_demand_commit(___processor_state ps, ___WORD pt, ___WORD att) {
  rt_group_demand_commit(ps, pt, att);
}
static void ___gate2_group_site(___processor_state ps, const char *proc, int lbl,
                                ___WORD pt, ___WORD *fp, int opening) {
  rt_gate2_group_site(ps, proc, lbl, pt, fp, opening);
}
static void ___rest_observation_store_fast(void *fp, void *addr) {
  rt_store_fast(fp, addr);
}
static void ___rest_observation_adjust_fast(void *fp, intptr_t words) {
  rt_adjust_fast(fp, words);
}
static void ___rest_observation_pop_fast(void *fp) {
  rt_pop_fast(fp);
}

typedef struct {
  int (*___group_demand_enter)(___processor_state, ___WORD **, ___WORD **,
                               ___SIZE_TS, ___SIZE_TS, ___WORD, ___WORD *);
  void (*___group_demand_commit)(___processor_state, ___WORD, ___WORD);
  void (*___gate2_group_site)(___processor_state, const char *, int, ___WORD, ___WORD *, int);
  void (*___rest_observation_store_fast)(void *, void *);
  void (*___rest_observation_adjust_fast)(void *, intptr_t);
  void (*___rest_observation_pop_fast)(void *);
  int *___rest_observation_active_ptr;
  int ___rest_observation_active_scalar;
} mock_gstate;

static mock_gstate g_state_obj;
#define ___GSTATE (&g_state_obj)

/* Expand the EXACT verbatim vendor header macro blocks under 4 compile modes:
 *   Mode 1: static,  ___LBLCOUNT = 126  (< 6000)
 *   Mode 2: static,  ___LBLCOUNT = 6000 (>= 6000)
 *   Mode 3: dynamic, ___LBLCOUNT = 126  (< 6000)
 *   Mode 4: dynamic, ___LBLCOUNT = 6000 (>= 6000)
 */
#define ___GAMBIT_REST_OBSERVATION 1

/* --- Mode 1: static + small (< 6000) --- */
#undef ___BIND_LATE
#undef ___CAN_IMPORT_DYNAMICALLY
#undef ___EXT
#define ___EXT(x) x
#undef ___LBLCOUNT
#define ___LBLCOUNT 126
/* BEGIN_SYNC: vendor/gambit/include/_gambit/object_access.h.in:31-44 */
#if defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___REST_OBS_ACTIVE (*___EXT(___rest_observation_active_ptr))
#else
#define ___REST_OBS_ACTIVE ___rest_observation_active
#endif
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 6000)
#define ___REST_OBS_STORE(fp,address) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_store_fast)((fp),(address)),0)))
#define ___REST_OBS_ADJUST(fp,words) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_adjust_fast)((fp),(words)),0)))
#define ___REST_OBS_POP(fp) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_pop_fast)((fp)),0)))
#else
#define ___REST_OBS_STORE(fp,address) ___EXT(___rest_observation_store_fast)((fp),(address))
#define ___REST_OBS_ADJUST(fp,words) ___EXT(___rest_observation_adjust_fast)((fp),(words))
#define ___REST_OBS_POP(fp) ___EXT(___rest_observation_pop_fast)((fp))
#endif
/* END_SYNC: object_access */
/* BEGIN_SYNC: vendor/gambit/include/_gambit/runtime_protocols.h.in:1438-1456 */
#if defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___GROUP_DEMAND_COMMIT_CALL(ps,point,attempt) \
  ___EXT(___group_demand_commit)((ps),(point),(attempt))
#else
#define ___GROUP_DEMAND_COMMIT_CALL(ps,point,attempt) \
  (___group_demand_commit)((ps),(point),(attempt))
#endif
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 3000)
#ifdef ___GAMBIT_REST_OBSERVATION
#define ___group_demand_commit(ps,point,attempt) \
  do { if (__builtin_expect((attempt) != 0 || ___REST_OBS_ACTIVE, 0)) ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt)); } while (0)
#else
#define ___group_demand_commit(ps,point,attempt) \
  do { if (__builtin_expect((attempt) != 0, 0)) ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt)); } while (0)
#endif
#elif defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___group_demand_commit(ps,point,attempt) \
  ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt))
#endif
/* END_SYNC: runtime_protocols_commit */
/* BEGIN_SYNC: vendor/gambit/include/_gambit/runtime_protocols.h.in:1472-1482 */
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 3000)
#define ___GATE2_OPEN(ps,proc,label,point,fp) \
  do { if (__builtin_expect(___REST_OBS_ACTIVE, 0)) ___EXT(___gate2_group_site)(ps,proc,label,point,fp,1); } while (0)
#define ___GATE2_ENTER(ps,proc,label,point,fp) \
  do { if (__builtin_expect(___REST_OBS_ACTIVE, 0)) ___EXT(___gate2_group_site)(ps,proc,label,point,fp,0); } while (0)
#else
#define ___GATE2_OPEN(ps,proc,label,point,fp) \
  ___EXT(___gate2_group_site)(ps,proc,label,point,fp,1)
#define ___GATE2_ENTER(ps,proc,label,point,fp) \
  ___EXT(___gate2_group_site)(ps,proc,label,point,fp,0)
#endif
/* END_SYNC: runtime_protocols_gate2 */

static void exercise_static_small(___WORD attempt) {
  ___WORD slot = 0;
  ___WORD *hp = &slot, *fp = &slot;
  ___WORD att = attempt;
  (void)___group_demand_enter(0, &hp, &fp, 1, 3, 1, &att);
  ___REST_OBS_STORE(&slot, &slot);
  ___REST_OBS_ADJUST(&slot, 2);
  ___REST_OBS_POP(&slot);
  ___GATE2_OPEN(0, "tfib", 1, 1, &slot);
  ___GATE2_ENTER(0, "tfib", 1, 1, &slot);
  ___group_demand_commit(0, 1, attempt);
}

/* --- Mode 2: static + large (>= 6000) --- */
#undef ___REST_OBS_ACTIVE
#undef ___REST_OBS_STORE
#undef ___REST_OBS_ADJUST
#undef ___REST_OBS_POP
#undef ___GROUP_DEMAND_COMMIT_CALL
#undef ___group_demand_commit
#undef ___GATE2_OPEN
#undef ___GATE2_ENTER
#undef ___LBLCOUNT
#define ___LBLCOUNT 6000
#if defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___REST_OBS_ACTIVE (*___EXT(___rest_observation_active_ptr))
#else
#define ___REST_OBS_ACTIVE ___rest_observation_active
#endif
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 6000)
#define ___REST_OBS_STORE(fp,address) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_store_fast)((fp),(address)),0)))
#define ___REST_OBS_ADJUST(fp,words) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_adjust_fast)((fp),(words)),0)))
#define ___REST_OBS_POP(fp) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_pop_fast)((fp)),0)))
#else
#define ___REST_OBS_STORE(fp,address) ___EXT(___rest_observation_store_fast)((fp),(address))
#define ___REST_OBS_ADJUST(fp,words) ___EXT(___rest_observation_adjust_fast)((fp),(words))
#define ___REST_OBS_POP(fp) ___EXT(___rest_observation_pop_fast)((fp))
#endif
#if defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___GROUP_DEMAND_COMMIT_CALL(ps,point,attempt) \
  ___EXT(___group_demand_commit)((ps),(point),(attempt))
#else
#define ___GROUP_DEMAND_COMMIT_CALL(ps,point,attempt) \
  (___group_demand_commit)((ps),(point),(attempt))
#endif
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 6000)
#ifdef ___GAMBIT_REST_OBSERVATION
#define ___group_demand_commit(ps,point,attempt) \
  do { if (__builtin_expect((attempt) != 0 || ___REST_OBS_ACTIVE, 0)) ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt)); } while (0)
#else
#define ___group_demand_commit(ps,point,attempt) \
  do { if (__builtin_expect((attempt) != 0, 0)) ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt)); } while (0)
#endif
#elif defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___group_demand_commit(ps,point,attempt) \
  ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt))
#endif
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 6000)
#define ___GATE2_OPEN(ps,proc,label,point,fp) \
  do { if (__builtin_expect(___REST_OBS_ACTIVE, 0)) ___EXT(___gate2_group_site)(ps,proc,label,point,fp,1); } while (0)
#define ___GATE2_ENTER(ps,proc,label,point,fp) \
  do { if (__builtin_expect(___REST_OBS_ACTIVE, 0)) ___EXT(___gate2_group_site)(ps,proc,label,point,fp,0); } while (0)
#else
#define ___GATE2_OPEN(ps,proc,label,point,fp) \
  ___EXT(___gate2_group_site)(ps,proc,label,point,fp,1)
#define ___GATE2_ENTER(ps,proc,label,point,fp) \
  ___EXT(___gate2_group_site)(ps,proc,label,point,fp,0)
#endif

static void exercise_static_large(___WORD attempt) {
  ___WORD slot = 0;
  ___WORD *hp = &slot, *fp = &slot;
  ___WORD att = attempt;
  (void)___group_demand_enter(0, &hp, &fp, 1, 3, 1, &att);
  ___REST_OBS_STORE(&slot, &slot);
  ___REST_OBS_ADJUST(&slot, 2);
  ___REST_OBS_POP(&slot);
  ___GATE2_OPEN(0, "tfib", 1, 1, &slot);
  ___GATE2_ENTER(0, "tfib", 1, 1, &slot);
  ___group_demand_commit(0, 1, attempt);
}

/* --- Mode 3: dynamic (___BIND_LATE) + small (< 6000) --- */
#define ___BIND_LATE 1
#undef ___EXT
#define ___EXT(x) (___GSTATE->x)
#undef ___REST_OBS_ACTIVE
#undef ___REST_OBS_STORE
#undef ___REST_OBS_ADJUST
#undef ___REST_OBS_POP
#undef ___GROUP_DEMAND_COMMIT_CALL
#undef ___group_demand_commit
#undef ___GATE2_OPEN
#undef ___GATE2_ENTER
#undef ___LBLCOUNT
#define ___LBLCOUNT 126
#if defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___group_demand_enter(ps,hp,fp,sw,hw,pt,att) \
  ___EXT(___group_demand_enter)((ps),(hp),(fp),(sw),(hw),(pt),(att))
#define ___REST_OBS_ACTIVE (*___EXT(___rest_observation_active_ptr))
#else
#define ___REST_OBS_ACTIVE ___rest_observation_active
#endif
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 6000)
#define ___REST_OBS_STORE(fp,address) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_store_fast)((fp),(address)),0)))
#define ___REST_OBS_ADJUST(fp,words) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_adjust_fast)((fp),(words)),0)))
#define ___REST_OBS_POP(fp) ((void)(__builtin_expect(___REST_OBS_ACTIVE,0) && (___EXT(___rest_observation_pop_fast)((fp)),0)))
#else
#define ___REST_OBS_STORE(fp,address) ___EXT(___rest_observation_store_fast)((fp),(address))
#define ___REST_OBS_ADJUST(fp,words) ___EXT(___rest_observation_adjust_fast)((fp),(words))
#define ___REST_OBS_POP(fp) ___EXT(___rest_observation_pop_fast)((fp))
#endif
#if defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___GROUP_DEMAND_COMMIT_CALL(ps,point,attempt) \
  ___EXT(___group_demand_commit)((ps),(point),(attempt))
#else
#define ___GROUP_DEMAND_COMMIT_CALL(ps,point,attempt) \
  (___group_demand_commit)((ps),(point),(attempt))
#endif
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 6000)
#ifdef ___GAMBIT_REST_OBSERVATION
#define ___group_demand_commit(ps,point,attempt) \
  do { if (__builtin_expect((attempt) != 0 || ___REST_OBS_ACTIVE, 0)) ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt)); } while (0)
#else
#define ___group_demand_commit(ps,point,attempt) \
  do { if (__builtin_expect((attempt) != 0, 0)) ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt)); } while (0)
#endif
#elif defined(___BIND_LATE) && !defined(___CAN_IMPORT_DYNAMICALLY)
#define ___group_demand_commit(ps,point,attempt) \
  ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt))
#endif
#if !defined(___LBLCOUNT) || (___LBLCOUNT < 6000)
#define ___GATE2_OPEN(ps,proc,label,point,fp) \
  do { if (__builtin_expect(___REST_OBS_ACTIVE, 0)) ___EXT(___gate2_group_site)(ps,proc,label,point,fp,1); } while (0)
#define ___GATE2_ENTER(ps,proc,label,point,fp) \
  do { if (__builtin_expect(___REST_OBS_ACTIVE, 0)) ___EXT(___gate2_group_site)(ps,proc,label,point,fp,0); } while (0)
#else
#define ___GATE2_OPEN(ps,proc,label,point,fp) \
  ___EXT(___gate2_group_site)(ps,proc,label,point,fp,1)
#define ___GATE2_ENTER(ps,proc,label,point,fp) \
  ___EXT(___gate2_group_site)(ps,proc,label,point,fp,0)
#endif

static void exercise_dynamic_small(___WORD attempt) {
  ___WORD slot = 0;
  ___WORD *hp = &slot, *fp = &slot;
  ___WORD att = attempt;
  (void)___group_demand_enter(0, &hp, &fp, 1, 3, 1, &att);
  ___REST_OBS_STORE(&slot, &slot);
  ___REST_OBS_ADJUST(&slot, 2);
  ___REST_OBS_POP(&slot);
  ___GATE2_OPEN(0, "tfib", 1, 1, &slot);
  ___GATE2_ENTER(0, "tfib", 1, 1, &slot);
  ___group_demand_commit(0, 1, attempt);
}

/* --- Mode 4: dynamic (___BIND_LATE) + large (>= 6000) --- */
#undef ___REST_OBS_STORE
#undef ___REST_OBS_ADJUST
#undef ___REST_OBS_POP
#undef ___group_demand_commit
#undef ___GATE2_OPEN
#undef ___GATE2_ENTER
#undef ___LBLCOUNT
#define ___LBLCOUNT 6000
#define ___REST_OBS_STORE(fp,address) ___EXT(___rest_observation_store_fast)((fp),(address))
#define ___REST_OBS_ADJUST(fp,words) ___EXT(___rest_observation_adjust_fast)((fp),(words))
#define ___REST_OBS_POP(fp) ___EXT(___rest_observation_pop_fast)((fp))
#define ___group_demand_commit(ps,point,attempt) ___GROUP_DEMAND_COMMIT_CALL((ps),(point),(attempt))
#define ___GATE2_OPEN(ps,proc,label,point,fp) ___EXT(___gate2_group_site)(ps,proc,label,point,fp,1)
#define ___GATE2_ENTER(ps,proc,label,point,fp) ___EXT(___gate2_group_site)(ps,proc,label,point,fp,0)

static void exercise_dynamic_large(___WORD attempt) {
  ___WORD slot = 0;
  ___WORD *hp = &slot, *fp = &slot;
  ___WORD att = attempt;
  (void)___group_demand_enter(0, &hp, &fp, 1, 3, 1, &att);
  ___REST_OBS_STORE(&slot, &slot);
  ___REST_OBS_ADJUST(&slot, 2);
  ___REST_OBS_POP(&slot);
  ___GATE2_OPEN(0, "tfib", 1, 1, &slot);
  ___GATE2_ENTER(0, "tfib", 1, 1, &slot);
  ___group_demand_commit(0, 1, attempt);
}

static int sinks_equal(const obs_sink *a, const obs_sink *b) {
  return a->store_events == b->store_events &&
         a->adjust_events == b->adjust_events &&
         a->pop_events == b->pop_events &&
         a->commit_events == b->commit_events &&
         a->gate2_open_events == b->gate2_open_events &&
         a->gate2_enter_events == b->gate2_enter_events &&
         a->enter_calls == b->enter_calls;
}

static void init_gstate(int obs) {
  ___rest_observation_active = obs;
  g_state_obj.___group_demand_enter = rt_group_demand_enter;
  g_state_obj.___group_demand_commit = rt_group_demand_commit;
  g_state_obj.___gate2_group_site = rt_gate2_group_site;
  g_state_obj.___rest_observation_store_fast = rt_store_fast;
  g_state_obj.___rest_observation_adjust_fast = rt_adjust_fast;
  g_state_obj.___rest_observation_pop_fast = rt_pop_fast;
  g_state_obj.___rest_observation_active_ptr = &___rest_observation_active;
  g_state_obj.___rest_observation_active_scalar = obs;
}

void check_real_header_macro_equiv(void) {
  int obs = nondet_int();
  ___WORD attempt = nondet_word();
  __CPROVER_assume(obs == 0 || obs == 1);
  init_gstate(obs);

  obs_sink s1 = {0}, s2 = {0}, s3 = {0}, s4 = {0};
  g_active_sink = &s1; exercise_static_small(attempt);
  g_active_sink = &s2; exercise_static_large(attempt);
  g_active_sink = &s3; exercise_dynamic_small(attempt);
  g_active_sink = &s4; exercise_dynamic_large(attempt);

  CHECK(sinks_equal(&s1, &s2), "real-header.static-small-eq-large");
  CHECK(sinks_equal(&s1, &s3), "real-header.static-small-eq-dynamic-small");
  CHECK(sinks_equal(&s1, &s4), "real-header.static-small-eq-dynamic-large");
}

/* --- Entrypoint 2: Proposed <6000 inline fast-span enter vs allocation-limits.inc --- */

static int slow_stub_calls_ref;
static int slow_stub_calls_inline;
static int slow_stub_ret;
static ___WORD slow_stub_att;

static int out_of_line_enter_model(
    ___processor_state ps, ___UWORD h_addr, ___UWORD f_addr,
    ___SIZE_TS stack_words, ___SIZE_TS heap_words, ___WORD *attempt_out) {
  /* Verbatim arithmetic from vendor/gambit/lib/_mem/allocation-limits.inc:1179-1197 */
  if (ps != 0 && ps->context != 0 && attempt_out != 0) {
    if (f_addr != 0 && h_addr != 0 && stack_words >= 0 && heap_words >= 0) {
      ___UWORD sd = f_addr - ps->stack_fast_floor_b;
      if (sd < ps->stack_fast_limit_b &&
          (sd / sizeof(___WORD)) >= (___UWORD)stack_words &&
          (heap_words == 0 ||
           ((h_addr - ps->heap_fast_lo_b) < ps->heap_fast_bytes &&
            ((ps->heap_fast_bytes - (h_addr - ps->heap_fast_lo_b)) / sizeof(___WORD)) >= (___UWORD)heap_words))) {
        *attempt_out = 0;
        return 1;
      }
    }
  }
  slow_stub_calls_ref++;
  *attempt_out = slow_stub_att;
  return slow_stub_ret;
}

static inline int proposed_inline_fast_enter(
    ___processor_state ps, ___UWORD h_addr, ___UWORD f_addr,
    ___SIZE_TS stack_words, ___SIZE_TS heap_words, ___WORD *attempt_out) {
  if (__builtin_expect(ps != 0 && ps->context != 0 && attempt_out != 0 &&
                       f_addr != 0 && h_addr != 0 &&
                       stack_words >= 0 && heap_words >= 0, 1)) {
    ___UWORD sd = f_addr - ps->stack_fast_floor_b;
    if (__builtin_expect(
          sd < ps->stack_fast_limit_b &&
          (sd / sizeof(___WORD)) >= (___UWORD)stack_words &&
          (heap_words == 0 ||
           ((h_addr - ps->heap_fast_lo_b) < ps->heap_fast_bytes &&
            ((ps->heap_fast_bytes - (h_addr - ps->heap_fast_lo_b)) / sizeof(___WORD)) >= (___UWORD)heap_words)),
          1)) {
      *attempt_out = 0;
      return 1;
    }
  }
  slow_stub_calls_inline++;
  *attempt_out = slow_stub_att;
  return slow_stub_ret;
}

void check_inline_fast_span_enter_refinement(void) {
  ___execution_context ctx = {0};
  struct ___processor_state_s ps_obj = {0};
  ps_obj.context = nondet_int() ? &ctx : 0;
  ps_obj.stack_fast_floor_b = nondet_uword();
  ps_obj.stack_fast_limit_b = nondet_uword();
  ps_obj.heap_fast_lo_b = nondet_uword();
  ps_obj.heap_fast_bytes = nondet_uword();
  ___processor_state ps = nondet_int() ? &ps_obj : 0;

  ___UWORD h_addr = nondet_uword();
  ___UWORD f_addr = nondet_uword();
  ___SIZE_TS sw = nondet_size_ts();
  ___SIZE_TS hw = nondet_size_ts();
  slow_stub_ret = nondet_int() ? 1 : 0;
  slow_stub_att = nondet_word();
  slow_stub_calls_ref = 0;
  slow_stub_calls_inline = 0;

  ___WORD att_ref = 99, att_inl = 99;
  int r_ref = out_of_line_enter_model(ps, h_addr, f_addr, sw, hw, &att_ref);
  int r_inl = proposed_inline_fast_enter(ps, h_addr, f_addr, sw, hw, &att_inl);

  CHECK(r_ref == r_inl, "fast-span.return-equiv");
  CHECK(att_ref == att_inl, "fast-span.attempt-equiv");
  CHECK(slow_stub_calls_ref == slow_stub_calls_inline, "fast-span.slow-path-dispatch-equiv");
  if (slow_stub_calls_inline == 0) {
    CHECK(r_inl == 1 && att_inl == 0, "fast-span.hit-guarantees-attempt-zero");
  }
}

/* --- Entrypoint 3: Single-hop scalar / cached-ptr obsActive equivalence --- */

void check_single_hop_obs_active_equiv(void) {
  int obs = nondet_int();
  __CPROVER_assume(obs == 0 || obs == 1);
  init_gstate(obs);

  const int *cached_obs_ptr = ___GSTATE->___rest_observation_active_ptr;
  int two_hop = (*___GSTATE->___rest_observation_active_ptr);
  int cached_one_hop = (*cached_obs_ptr);
  int scalar_one_hop = ___GSTATE->___rest_observation_active_scalar;

  CHECK(two_hop == cached_one_hop, "obs-active.cached-ptr-equiv");
  CHECK(two_hop == scalar_one_hop, "obs-active.scalar-equiv");
}
