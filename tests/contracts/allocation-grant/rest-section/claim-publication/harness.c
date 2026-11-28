/* Actual extension, candidate selection, commit and heap/stack publication.
 * The allocation lock is a serialized environment boundary; no interleaving
 * or full-VM/processor admission is assumed proved by this harness. */
#include <limits.h>
typedef long ___WORD;
typedef unsigned long ___UWORD, ___SIZE_TS, ___SIZE_T;
typedef int ___BOOL;
typedef struct { int heap_used; void *stack_owner; int stack_state; } section_claim;
typedef struct msection { ___WORD *base; struct msection *next; section_claim claim; } ___msection;
struct context { ___WORD *hp, *fp; };
struct processor { struct context *context; ___WORD *heap_limit; };
typedef struct processor *___processor_state;
static struct processor processor;
static struct context context;
#define ___PSTATE (&processor)
#define ___HIDDEN
#define ___P(proto,legacy) proto
#define ___PAIR_SIZE 2
#include "object-layout.inc"
#include "native-limits.inc"
#define HALF (___MSECTION_SIZE>>1)
#define REST_OBS(...) ((void)0)
#define CHECK(p,n) __CPROVER_assert((p),(n))
static ___WORD old_space[HALF], candidate_space[HALF];
static ___msection old, candidate, *alloc_msection, *heap_msection, *stack_msection;
static struct sections_s { ___msection *head; int nb_sections; } sections;
static struct sections_s *the_msections = &sections;
static const struct { struct { ___SIZE_T max_heap; } setup_params; } globals;
#define ___GSTATE (&globals)
static int nb_msections_assigned, custom_msection_alloc, lock_depth, lock_entries, vm_admitted;
static ___SIZE_TS tospace_offset;
static ___SIZE_TS heap_size;
static ___WORD words_prev_msections;
static ___WORD *alloc_heap_ptr, *alloc_heap_start, *alloc_heap_limit;
static ___WORD *alloc_stack_ptr, *alloc_stack_limit, *alloc_stack_start;
#define ALLOC_MEM_LOCK() do { CHECK(lock_depth==0,"section.lock-entry"); ++lock_depth; ++lock_entries; } while (0)
#define ALLOC_MEM_UNLOCK() do { CHECK(lock_depth==1,"section.lock-exit"); --lock_depth; } while (0)
static void clear_fast_span(___processor_state ps) { (void)ps; }
static void publish_fast_span(___processor_state ps) { (void)ps; }
static ___SIZE_TS compute_free_heap_space_approximately(void) { return ___MSECTION_SIZE; }
static void adjust_msections(void *m, int n) { (void)m; (void)n; }
static ___SIZE_TS compute_heap_size(void) { return heap_size; }
static int current_heap_interval_matches(___processor_state ps, ___WORD *hp)
{ return ps==___PSTATE && hp==old_space && alloc_heap_start==old_space; }
static int ___rest_new_section_admitted(___processor_state ps, ___SIZE_T max_heap)
{ (void)max_heap; return ps==___PSTATE && vm_admitted; }
static section_claim *section_claim_at(___msection *ms, ___SIZE_TS offset)
{ CHECK(offset==0,"section.selected-half"); return &ms->claim; }
#define start_of_tospace(ms) ((ms)->base+tospace_offset)
static void fatal_heap_overflow(void) { CHECK(0,"section.admitted-split-is-not-fatal"); }
static int nondet_int(void);
#include "claim.inc"
#include "publish.inc"
#include "extend.inc"

static void setup(int has_candidate, int occupied, int hard_room)
{
  processor.context=&context;
  processor.heap_limit=old_space+4;
  old.base=old_space;
  candidate.base=candidate_space;
  old.claim=(section_claim){0};
  candidate.claim=(section_claim){0};
  if (occupied==1) candidate.claim.stack_owner=___PSTATE;
  if (occupied==2) candidate.claim.stack_state=1;
  if (occupied==3) candidate.claim.heap_used=1;
  old.next=has_candidate ? &candidate : 0;
  sections.head=&old;
  sections.nb_sections=has_candidate ? 2 : 1;
  alloc_msection=heap_msection=&old;
  stack_msection=&old;
  nb_msections_assigned=1;
  vm_admitted=1;
  lock_entries=0;
  alloc_heap_start=alloc_heap_ptr=context.hp=old_space;
  alloc_heap_limit=old_space+___MSECTION_FUDGE+hard_room;
  alloc_stack_limit=alloc_heap_limit;
  alloc_stack_start=alloc_stack_ptr=context.fp=old_space+HALF;
}

void check_publication(void)
{
  int candidate_present=nondet_int(), occupied=nondet_int(), admitted=nondet_int();
  __CPROVER_assume(candidate_present>=0 && candidate_present<=1 && admitted>=0 && admitted<=1);
  __CPROVER_assume(occupied>=0 && occupied<=3);
  setup(candidate_present,occupied,9);
  vm_admitted=admitted;
  CHECK(___rest_physical_tail_short(___PSTATE,2,3) &&
        !___rest_publish_owned_soft_edge(___PSTATE,2,3) &&
        processor.heap_limit==old_space+4,"section.one-short-physical-tail-cannot-publish-owned-edge");
  ___SIZE_TS predicted=0;
  int valid=rest_predicted_soft_room(___PSTATE,&candidate,context.fp,&predicted);
  int ok=___rest_extend_interval(___PSTATE,2,3);
  CHECK(lock_depth==0 && lock_entries==1,"section.lock-balanced");
  if (candidate_present && !occupied && admitted && valid && predicted>=10) {
    CHECK(ok && context.hp==candidate_space && processor.heap_limit==candidate_space+predicted,
          "section.prediction-publishes-complete-room");
    CHECK(nb_msections_assigned==2 && alloc_msection==&candidate,
          "section.fresh-claim-counted-once");
    CHECK(candidate.claim.heap_used==1,"section.owner-publishes-selected-candidate");
  } else {
    CHECK(!ok && nb_msections_assigned==1 && alloc_msection==&old &&
          context.hp==old_space && processor.heap_limit==old_space+4 &&
          candidate.claim.heap_used==(occupied==3) &&
          candidate.claim.stack_owner==(occupied==1 ? ___PSTATE : 0) &&
          candidate.claim.stack_state==(occupied==2),"section.rejection-preserves-pool");
  }
}

void check_fresh_claim_reachable(void)
{
  setup(1,0,9);
  int ok=___rest_extend_interval(___PSTATE,2,3);
  CHECK(!(ok && alloc_msection==&candidate && nb_msections_assigned==2),
        "control.real-fresh-claim-and-publication");
}

void check_soft_only_shortage(void)
{
  setup(1,0,10);
  CHECK(!___rest_physical_tail_short(___PSTATE,2,3),"section.soft-only-tail-fits");
  int ok=___rest_publish_owned_soft_edge(___PSTATE,2,3);
  CHECK(lock_depth==0 && nb_msections_assigned==1 && alloc_msection==&old &&
        !candidate.claim.heap_used,"section.soft-only-preserves-pool");
  CHECK(!(ok && !lock_entries && context.hp==old_space && processor.heap_limit==old_space+10),
        "control.soft-only-publishes-owned-edge-without-section-claim");
}
