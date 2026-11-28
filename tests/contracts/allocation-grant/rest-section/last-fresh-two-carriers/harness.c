/* Two carrier-owned intervals, one remaining VM section. Real allocation
 * ticket lock, admission, heap interval predicate, commit and publication. */
#include <pthread.h>
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
typedef long ___WORD;
typedef unsigned long ___UWORD, ___SIZE_TS, ___SIZE_T;
typedef int ___BOOL;
typedef struct processor *___processor_state;
typedef struct msection ___msection;
typedef struct { ___WORD next_ticket, current_ticket; } ___ticketlock_struct;
#define ___P(proto,legacy) proto
#define ___HIDDEN static
#define ___CAST(type,value) ((type)(value))
#define ___LWS 3
#define ___WS (1L<<___LWS)
#define ___TB_FIXNUM 2
#include "object-layout.inc"
#include "pair-layout.inc"
#include "native-limits.inc"
#include "fixnum.inc"
#include "ordered-word.inc"
/* No architecture-specific pause instruction in LLVM model execution. */
#define ___CPU_RELAX() ((void)0)
#include "ticket-lock.inc"
#include "alloc-lock.inc"
#include "claim-type.inc"
#define HALF (___MSECTION_SIZE>>1)

struct msection { ___WORD *base; ___msection *next; section_claim claim; };
struct context { ___WORD *hp,*fp; };
struct processor {
  struct context *context;
  ___WORD *heap_limit,*hstart,*hlimit,*hptr,*sstart,*slimit,*sptr;
  ___msection *heap,*stack;
  ___WORD prev_words;
  int result, requested, committed;
};
static struct processor carriers[2];
static struct context contexts[2];
static ___WORD (*storage)[HALF];
static ___msection sections[3];
static struct { ___msection *head; int nb_sections; } directory;
static ___msection *alloc_msection;
static int nb_msections_assigned;
static ___WORD occupied_words_still;
static ___ticketlock_struct alloc_mem_lock;
static struct { struct { ___SIZE_T max_heap; } setup_params; } globals;
static _Thread_local ___processor_state self;
#define ___PSTATE self
#define ___GSTATE (&globals)
#define the_msections (&directory)
#define heap_msection (___ps->heap)
#define stack_msection (___ps->stack)
#define alloc_heap_start (___ps->hstart)
#define alloc_heap_limit (___ps->hlimit)
#define alloc_heap_ptr (___ps->hptr)
#define alloc_stack_start (___ps->sstart)
#define alloc_stack_limit (___ps->slimit)
#define alloc_stack_ptr (___ps->sptr)
#define words_prev_msections (___ps->prev_words)
#define tospace_offset 0L
#define custom_msection_alloc 0
#define start_of_tospace(ms) ((ms)->base+tospace_offset)
static section_claim *section_claim_at(___msection *ms, ___SIZE_TS offset)
{ (void)offset; return &ms->claim; }
enum { REST_LOCK_REQUEST, REST_LOCK, REST_REFUSE, REST_UNLOCK, REST_CAPACITY, REST_CLAIM };
static void observe(int event, ___processor_state ps)
{
  if (event==REST_LOCK_REQUEST) ++ps->requested;
  if (event==REST_CLAIM) {
    ++ps->committed;
    assert(alloc_msection == &sections[2] && nb_msections_assigned == 3);
    /* The actual claim point still has the old carrier-local heap view. */
    assert(ps->heap == ps->stack && ps->context->hp == ps->hstart);
  }
}
#define REST_OBS(event,ps,...) observe(event,ps)
static void fatal_heap_overflow(void) { assert(0 && "unexpected shared split"); }
#include "resume-interval.inc"
#include "current-interval.inc"
#include "admission.inc"
#include "claim.inc"
#include "publish.inc"
#include "extend.inc"

static void *worker(void *arg)
{
  ___processor_state ps=arg;
  self=ps;
  ps->result=___rest_extend_interval(ps,2,3);
  return 0;
}

int main(void)
{
  pthread_t t[2];
  storage=malloc(3*sizeof(*storage));
  assert(storage != 0);
  occupied_words_still=23;
  globals.setup_params.max_heap=(4UL*___MSECTION_SIZE+23)*___WS;
  directory.head=&sections[0]; directory.nb_sections=3;
  alloc_msection=&sections[1]; nb_msections_assigned=2;
  sections[2].base=storage[2];
  for (int i=0;i<2;++i) {
    ___processor_state ps=&carriers[i];
    ___WORD *base=storage[i];
    sections[i]=(___msection){.base=base,.next=&sections[i+1],.claim={
      .stack_owner=ps,.stack_state=STACK_ACTIVE,.heap_used=1}};
    contexts[i]=(struct context){.hp=base,.fp=base+HALF-8};
    *ps=(struct processor){.context=&contexts[i],.heap_limit=base+9,
      .hstart=base,.hlimit=base+___MSECTION_FUDGE+9,.hptr=base,
      .sstart=base+HALF,.slimit=base+___MSECTION_FUDGE+9,.sptr=base+HALF-8,
      .stack=&sections[i],.heap=&sections[i]};
  }
  pthread_create(&t[0],0,worker,&carriers[0]);
  pthread_create(&t[1],0,worker,&carriers[1]);
  pthread_join(t[0],0);
  pthread_join(t[1],0);
  assert(carriers[0].requested == 1 && carriers[1].requested == 1);
  assert(carriers[0].result + carriers[1].result == 1);
  assert(nb_msections_assigned == 3 && alloc_msection == &sections[2] && sections[2].claim.heap_used == 1);
  for (int i=0;i<2;++i) {
    ___processor_state ps=&carriers[i];
    assert(ps->committed == ps->result);
    if (ps->result) {
      assert(ps->heap == &sections[2] && ps->context->hp == storage[2]);
      assert(ps->heap_limit == storage[2]+HALF-___MSECTION_FUDGE);
    } else {
      assert(ps->heap == &sections[i] && ps->context->hp == storage[i] && ps->heap_limit == storage[i]+9);
    }
  }
#ifdef EXPECTED_WINNER
#if EXPECTED_WINNER == 0
  assert(carriers[0].result == 1);
#else
  assert(carriers[1].result == 1);
#endif
#endif
  free(storage);
  return 0;
}
