/* Actual walker and both actual handler conditionals. This bounded control
 * stops at the break before decoding; it supplies no cross-break witness. */
typedef long ___WORD;
typedef unsigned long ___UWORD, ___SIZE_TS;
typedef int ___BOOL;
#include "stack-claim-state.inc"
typedef struct {
  unsigned source_pins;
  void *stack_owner;
  enum stack_claim_state stack_state;
  ___WORD *parked_top, *parked_break;
} section_claim;
typedef struct { ___WORD *base; int copy_gate; } ___msection;
typedef struct { int unused; } ___msections;
typedef struct { int fs, link; } ___frame_descriptor;
struct context { ___WORD *stack_limit, *stack_break; };
struct processor { struct context *context; ___WORD internal_return; };
typedef struct processor *___processor_state;
static struct processor processor;
static struct context ctx;
static ___WORD stack[8];
static int extend_calls, lock_calls, gc_calls;
static int reload_ok, stack_ok, grant_ok, extension_ok, grant_after_extension;
static int physical_short, soft_publish_ok, soft_publish_calls;
static int ___rest_chain_gates, ___rest_chain_reads, ___rest_chain_ungated;
static int ___rest_chain_old_pins, ___rest_chain_old_reads, ___rest_chain_crossings, ___rest_chain_unpins;
static ___msections *the_msections;
static ___SIZE_TS tospace_offset;
#define ___PSTATE (&processor)
#define ___CAST(t,x) ((t)(x))
#define ___HIDDEN static
#define ___WS (sizeof(___WORD))
#define ___PAIR_SIZE 2
#include "object-layout.inc"
#include "native-limits.inc"
#include "fp-access.inc"
#include "frame-geometry.inc"
#include "live-source.inc"
#define ALLOC_MEM_LOCK() (++lock_calls)
#define ALLOC_MEM_UNLOCK() ((void)0)
#define REST_OBS(...) ((void)0)
#define CHECK(p,n) __CPROVER_assert((p),(n))
static section_claim *section_claim_at(___msection *s, ___SIZE_TS o)
{ (void)s; (void)o; return 0; }
static void ___gc_copy_acquire(int *g) { (void)g; }
static void ___gc_copy_release(int *g) { (void)g; }
static ___msection *resolve_source_half(___msections *s, ___WORD *p, ___SIZE_TS o, ___SIZE_TS *w)
{ (void)s; (void)p; (void)o; (void)w; return 0; }
static int read_admitted_stack_frame(const section_claim *c, ___WORD *p,
                                    ___SIZE_TS w, ___WORD *l, ___WORD *r,
                                    int carry, ___frame_descriptor *f, ___WORD **b)
{ (void)c; (void)p; (void)w; (void)l; (void)r; (void)carry; (void)f; (void)b; return 0; }
static int ___rest_extend_interval(___processor_state ps, ___WORD pending, ___WORD np)
{
  (void)ps; (void)pending; (void)np; ++extend_calls;
  if (extension_ok) grant_ok=grant_after_extension;
  return extension_ok;
}
static int ___rest_publish_owned_soft_edge(___processor_state ps, ___WORD pending, ___WORD np)
{
  (void)ps; (void)pending; (void)np; ++soft_publish_calls;
  if (soft_publish_ok) grant_ok=grant_after_extension;
  return soft_publish_ok;
}
#include "walker.inc"

/* Project the real guards, order, and terminal jumps. Runtime operations
 * outside this cut are summarized; no frame-write, GC or native claim proof. */
#define ___FP_SET_STK(...) ((void)0);
#define ___ADJFP(...) ((void)0);
#define ___W_FP ((void)0);
#define ___W_ALL ((void)0);
#define ___R_ALL ((void)0);
#define ___R_HEAP ((void)0);
#define ___SET_R0(...) ((void)0);
#define ___JUMPPRM(...) return cut;
#define ___rest_mark_attempt_cut(ps,hp,fp,k,n) (cut=(k))
#define ___rest_activation_cleanup(...) ((void)0)
#define ___rest_disarm_attempt() ((void)0)
#define ___rest_note_before_collect() ((void)0)
#define ___rest_note_attempt_view(...) ((void)0)
#define ___rest_note_attempt_acquired(...) ((void)0)
#define ___rest_reload_window(...) (reload_ok)
#define ___rest_stack_slots_fit(...) (stack_ok)
#define ___rest_grant_fits(...) (grant_ok)
#define ___rest_physical_tail_short(...) (physical_short)
#define ___garbage_collect(...) (++gc_calls,0)
#define ___heap_limit(...) (0)

#define ROUTE_LOCALS int cut=0, overflow=0; ___WORD i=2,np=3;
static int ordinary_route(___processor_state ___ps, ___WORD *___fp, ___WORD na, ___WORD ___R0)
{
  ROUTE_LOCALS
#include "ordinary-route.inc"
  return cut;
}

static int keyword_route(___processor_state ___ps, ___WORD *___fp, ___WORD na, ___WORD ___R0)
{
  ROUTE_LOCALS
#include "keyword-route.inc"
  return cut;
}

static void setup(void)
{
  processor.context=&ctx;
  ctx.stack_limit=stack;
  ctx.stack_break=stack+4;
  /* Owned, in-bounds terminal break metadata, not a successor frame. */
  ctx.stack_break[___BREAK_FRAME_NEXT]=0;
  reload_ok=stack_ok=grant_ok=1;
  physical_short=1;
}

void check_prefix_route(void)
{
  setup();
  CHECK(ordinary_route(___PSTATE,stack+2,2,1)==0 && gc_calls==1,
        "source.ordinary-break-prefix-selects-gc");
  CHECK(keyword_route(___PSTATE,stack+2,2,1)==0 && gc_calls==2,
        "source.keyword-break-prefix-selects-gc");
  CHECK(lock_calls==0 && extend_calls==0,"source.prefix-does-not-reach-extension-or-pin");
}

void check_handler_routes(void)
{
  setup();
  /* This is a diagnostic input, not a claim that an admitted rest can have RA=0. */
  CHECK(ordinary_route(___PSTATE,stack+2,2,0)==5 &&
        keyword_route(___PSTATE,stack+2,2,0)==5 &&
        !gc_calls && !lock_calls && !extend_calls,"source.invalid-refuses-before-gc-or-extension");
  reload_ok=0; stack_ok=0; grant_ok=0;
  CHECK(ordinary_route(___PSTATE,stack+2,2,1)==6 &&
        keyword_route(___PSTATE,stack+2,2,1)==6 &&
        gc_calls==2 && !extend_calls,"source.reload-refusal-does-not-extend");
  reload_ok=1;
  CHECK(ordinary_route(___PSTATE,stack+2,2,1)==7 &&
        keyword_route(___PSTATE,stack+2,2,1)==7 &&
        gc_calls==4 && !extend_calls,"source.stack-refusal-does-not-extend");
  stack_ok=1;
  CHECK(ordinary_route(___PSTATE,stack+2,2,1)==2 &&
        keyword_route(___PSTATE,stack+2,2,1)==2 &&
        gc_calls==6 && extend_calls==2 && !soft_publish_calls,
        "source.physical-heap-miss-reaches-extension");
  extension_ok=1;
  CHECK(ordinary_route(___PSTATE,stack+2,2,1)==1 &&
        keyword_route(___PSTATE,stack+2,2,1)==1 &&
        extend_calls==4,"source.extension-success-does-not-bypass-renewed-grant");
  grant_after_extension=1;
  int ordinary=ordinary_route(___PSTATE,stack+2,2,1);
  grant_ok=0;
  int keyword=keyword_route(___PSTATE,stack+2,2,1);
  CHECK(ordinary==0 && keyword==0 && extend_calls==6,"source.renewed-grant-continues");
  physical_short=0; grant_ok=0;
  CHECK(ordinary_route(___PSTATE,stack+2,2,1)==8 &&
        keyword_route(___PSTATE,stack+2,2,1)==8 &&
        soft_publish_calls==2 && extend_calls==6,"source.soft-only-refusal-does-not-extend");
  soft_publish_ok=1; grant_after_extension=0;
  CHECK(ordinary_route(___PSTATE,stack+2,2,1)==1 &&
        keyword_route(___PSTATE,stack+2,2,1)==1 &&
        soft_publish_calls==4 && extend_calls==6,"source.soft-publication-rechecks-grant");
  grant_after_extension=1;
  ordinary=ordinary_route(___PSTATE,stack+2,2,1);
  grant_ok=0;
  keyword=keyword_route(___PSTATE,stack+2,2,1);
  CHECK(ordinary==0 && keyword==0 && soft_publish_calls==6 && extend_calls==6,
        "source.soft-only-renewed-grant-continues-without-extension");
}

void check_prefix_is_not_handoff(void)
{
  setup();
  int cut=ordinary_route(___PSTATE,stack+2,2,1);
  CHECK(!(cut==0 && gc_calls==1 && !lock_calls && !___rest_chain_reads),
        "control.prefix-completes-without-handoff");
}
