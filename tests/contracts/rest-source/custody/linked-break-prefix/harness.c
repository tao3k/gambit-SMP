/* Real descriptor decode, directory lookup and caller-chain walk. The fixture
 * supplies one live non-internal label and a published two-section stack. */
#include <stdlib.h>
#include <pthread.h>
#include <assert.h>
typedef long ___WORD;
typedef unsigned long ___UWORD, ___SIZE_TS;
typedef int ___BOOL;
typedef struct processor *___processor_state;
typedef struct msection ___msection;
typedef struct { int nb_sections; ___msection **sections; } ___msections;
#define ___HIDDEN static
#define ___P(proto,legacy) proto
#define ___CAST(type,value) ((type)(value))
#define ___ALLOC_MEM_UP
#define ___WS 8
#include "native-limits.inc"
#include "object-layout.inc"
#include "pair-layout.inc"
#include "register-count.inc"
#include "frame-layout.inc"
#include "frame-ra.inc"
#include "fp-access.inc"
#include "claim-type.inc"

struct msection { ___WORD base[___MSECTION_SIZE]; ___WORD copy_gate; section_claim claims[2]; };
struct context { ___WORD *stack_limit, *stack_break; };
struct processor { struct context *context; ___WORD internal_return; };
static struct { ___WORD internal_return; } globals;
static ___msection *stack;
static ___msection *entries[2];
static ___msections directory={2,entries}, *the_msections=&directory;
static ___SIZE_TS tospace_offset;
#include "walk-counters.inc"
#define ___GSTATE (&globals)
/* Stand in for label table lookup; decode the real inline descriptor below. */
#define ___LABEL_DESCR_GET(ra) (ra)
#define REST_OBS(...) ((void)0)
static section_claim *section_claim_at(___msection *s, ___SIZE_TS offset)
{ return &s->claims[offset!=0]; }
static pthread_mutex_t directory_lock=PTHREAD_MUTEX_INITIALIZER;
static _Thread_local ___processor_state self;
#define ___PSTATE self
#define ALLOC_MEM_LOCK() pthread_mutex_lock(&directory_lock)
#define ALLOC_MEM_UNLOCK() pthread_mutex_unlock(&directory_lock)
#define ___VOLATILE volatile
#define ___USE_sync_builtins
#include "sync-builtins.inc"
#define ___CPU_RELAX() ((void)0)
#include "copy-gate.inc"
#ifndef GENMC_SOURCE_COUNTER
static int old_gates;
static void checked_copy_acquire(___WORD *gate)
{
  ___gc_copy_acquire(gate);
  if (gate==&stack[0].copy_gate) ++old_gates;
}
#define ___gc_copy_acquire(g) checked_copy_acquire(g)
#endif
#include "find.inc"
#include "resolve.inc"
#include "stack-mark.inc"
#include "decode.inc"
#include "walker.inc"

#ifndef GENMC_SOURCE_COUNTER
int main(void)
{
  struct processor processor={0};
  struct context ctx;
  stack=malloc(2*sizeof(*stack));
  assert(stack != 0);
  for (int w=0; w<256; ++w) { stack[0].base[w]=0; stack[1].base[w]=0; }
  entries[0]=&stack[0];
  entries[1]=&stack[1];
  stack[0].copy_gate=stack[1].copy_gate=0;
  ___WORD descriptor=___IFD(___RETN,2,1,0);
  ___WORD *old_top=stack[0].base+16;
  ___WORD *parent=stack[1].base+16;
  ___WORD *brk=parent+___FRAME_SPACE(2);
  stack[0].claims[0].stack_owner=&processor;
  stack[0].claims[0].stack_state=STACK_PARKED;
  stack[0].claims[0].stack_floor=stack[0].base;
  stack[0].claims[0].parked_top=old_top;
  stack[0].claims[0].parked_break=old_top+___FRAME_SPACE(2);
  ___FP_STK(stack[0].claims[0].parked_break,-___BREAK_FRAME_NEXT)=0;
  stack[1].claims[0].stack_owner=&processor;
  stack[1].claims[0].stack_state=STACK_ACTIVE;
  stack[0].claims[0].source_pins=stack[1].claims[0].source_pins=0;
  old_top[0]=descriptor;
  ___FP_STK(brk,-___BREAK_FRAME_NEXT)=___CAST(___WORD,old_top);
  ___FP_STK(brk,2)=descriptor;
  ___SIZE_TS old_words=0;
  int parked=resolve_source_half(the_msections,old_top,0,&old_words)==&stack[0] &&
    source_claim_is_live(&stack[0].claims[0]);
  assert(parked);
  processor.context=&ctx;
  self=&processor;
  ctx.stack_limit=stack[1].base;
  ctx.stack_break=brk;
  int reached=___rest_caller_chain(parent-2,2,descriptor,ctx.stack_limit,ctx.stack_break,0);
  assert(reached);
  assert(___rest_chain_reads >= 2 && ___rest_chain_gates >= 2 && old_gates == 1);
  assert(___rest_chain_crossings == 1 && ___rest_chain_old_pins >= 1);
  assert(___rest_chain_old_reads >= 1 && ___rest_chain_unpins >= 1);
  assert(stack[0].claims[0].source_pins == 0 && stack[1].claims[0].source_pins == 0);
  assert(!stack[0].copy_gate && !stack[1].copy_gate);
  free(stack);
  return 0;
}
#else
static struct processor processors[2];
static struct context contexts[2];

static void *walk(void *arg)
{
  self=arg;
  ___WORD *parent=self->context->stack_limit+16;
  int reached=___rest_caller_chain(parent-2,2,___IFD(___RETN,2,1,0),
                                  self->context->stack_limit,self->context->stack_break,0);
  assert(reached);
  return 0;
}

int main(void)
{
  pthread_t threads[2];
  stack=malloc(2*sizeof(*stack));
  assert(stack != 0);
  for (int w=0; w<256; ++w) { stack[0].base[w]=0; stack[1].base[w]=0; }
  for (int i=0;i<2;++i) {
    entries[i]=&stack[i];
    stack[i].copy_gate=0;
    stack[i].claims[0].stack_owner=&processors[i];
    stack[i].claims[0].stack_state=STACK_ACTIVE;
    ___WORD *brk=stack[i].base+16+___FRAME_SPACE(2);
    ___FP_STK(brk,-___BREAK_FRAME_NEXT)=0;
    ___FP_STK(brk,2)=___IFD(___RETN,2,1,0);
    contexts[i].stack_limit=stack[i].base;
    contexts[i].stack_break=brk;
    processors[i].context=&contexts[i];
  }
  pthread_create(&threads[0],0,walk,&processors[0]);
  pthread_create(&threads[1],0,walk,&processors[1]);
  pthread_join(threads[0],0);
  pthread_join(threads[1],0);
  free(stack);
  return 0;
}
#endif
