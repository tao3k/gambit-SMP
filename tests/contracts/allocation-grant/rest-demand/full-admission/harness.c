/* Real grant predicates. The harness supplies an already owned heap and stack. */
typedef long ___WORD;
typedef unsigned long ___UWORD, ___SIZE_TS;
typedef int ___BOOL;
struct context { ___WORD *hp; };
struct processor {
  struct context *context;
  struct { ___WORD *alloc_heap_start_, *alloc_heap_limit_; } mem;
  ___WORD *heap_limit;
};
typedef struct processor *___processor_state;
static struct context ctx;
static struct processor processor;
static ___WORD heap[16], stack[4];
#define ___PSTATE (&processor)
#define REST_OBS(...) ((void)0)
#define CHECK(p,n) __CPROVER_assert((p),(n))
static int rest_force_slow;
static int rest_attempt_here(___processor_state ps) { return ps == ___PSTATE; }
static int ___owned_stack_span(___processor_state ps, ___WORD **lo, ___WORD **hi)
{
  *lo=stack; *hi=stack+4;
  return ps==___PSTATE;
}
static int invalid_cursor;
static void rc_contract_error(const char *message) { (void)message; invalid_cursor=1; }
#include "object-layout.inc"
#include "pair-layout.inc"
#include "signed-sum.inc"

#include "batch-demand.inc"
#include "interval.inc"
#include "grants.inc"

void check_full_admission(void)
{
  processor.context=&ctx;
  ctx.hp=heap;
  processor.mem.alloc_heap_start_=heap;
  processor.mem.alloc_heap_limit_=heap+16;
  processor.heap_limit=heap+9;
  CHECK(!___rest_fast_grant_fits(___PSTATE,heap,stack+2,2,3,1),"admission.fast-requires-full-ten");
  CHECK(!___rest_grant_fits(___PSTATE,heap,stack+2,2,3,1),"admission.recovery-requires-full-ten");
  CHECK(___rest_one_word_short(___PSTATE,heap,stack+2,2,3,1),"admission.nine-is-one-word-short");
  CHECK(!___rest_fast_grant_fits(___PSTATE,heap,stack,2,3,1),"admission.stack-slots-required");
  processor.heap_limit=heap+8;
  CHECK(!___rest_one_word_short(___PSTATE,heap,stack+2,2,3,1),"admission.larger-hole-is-not-one-word-short");
  processor.heap_limit=heap+10;
  CHECK(!___rest_one_word_short(___PSTATE,heap,stack+2,2,3,1),"admission.exact-ten-is-not-one-word-short");
  CHECK(___rest_fast_grant_fits(___PSTATE,heap,stack+2,2,3,1),"admission.exact-ten-fits");
  CHECK(ctx.hp==heap,"admission.check-does-not-debit");
}
