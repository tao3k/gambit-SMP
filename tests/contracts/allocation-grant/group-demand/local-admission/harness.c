/* Source projections contain the actual admission, attempt issuance and
 * commit. The environment supplies owner-published intervals and one
 * cooperative caller. There is no generated group body or concurrent GC. */
typedef long ___WORD;
typedef unsigned long ___UWORD;
typedef long ___SIZE_TS;
typedef long ___PTRDIFF_T;
typedef long ptrdiff_t;
typedef struct { ___WORD *hp, *fp; } ___execution_context;
typedef struct { int unused; } ___activation_record;

#define ___CAST(type, value) ((type)(value))
#define ___EXP_FUNC(type, name) type name
#define ___IMP_FUNC(type, name) type name
#define ___HIDDEN static
#define ___P(prototype, old) prototype
#define ___WORD_LOAD_ACQUIRE(address) (*(address))
#define ___MAX_FIX 2305843009213693951L
#define ___MAX_PROCESSORS 2
#define ___WS 8
#define CHECK(condition, label) __CPROVER_assert((condition), (label))

#include "demand-layout.inc"
#include "frame-layout.inc"
#include "register-count.inc"

typedef struct {
  ___group_demand group_demand[___MAX_PROCESSORS];
  ___activation_record *activations[___MAX_PROCESSORS];
  ___WORD incarnation;
  ___WORD group_demand_attempt_next;
} ___vm_lifecycle;
typedef struct vm_view {
  ___vm_lifecycle *lifecycle;
  struct { ___WORD nb_gcs_; } mem;
} *___virtual_machine_state;
typedef struct processor_view {
  ___execution_context *context;
  ___virtual_machine_state vm;
  int id;
  ___WORD *heap_origin, *heap_ptr, *heap_limit, *heap_end, *stack_lo, *stack_hi;
  ___WORD *next_heap_origin, *next_heap_end;
  ___SIZE_TS free_heap_space;
  int heap_owned, stack_owned, stack_section;
  int group_demand_active;
  ___UWORD stack_fast_floor_b, stack_fast_limit_b, heap_fast_lo_b, heap_fast_bytes;
} *___processor_state;

#define ___VMSTATE_FROM_PSTATE(ps) ((ps)->vm)
#define ___PROCESSOR_ID(ps, vm) ((ps)->id)
#define alloc_heap_start (___ps->heap_origin)
#define alloc_heap_ptr (___ps->heap_ptr)
#define alloc_heap_limit (___ps->heap_end)
#define alloc_stack_limit (___ps->stack_lo)
#define heap_msection 1
#define stack_msection (___ps->stack_section)
#define tospace_offset 0
static ___SIZE_TS harness_fudge = 2;
#define ___MSECTION_FUDGE harness_fudge
#define ___MSECTION_SIZE 16

static ___processor_state active_bump_ps;
static ___SIZE_TS compute_free_heap_space_approximately(void)
{
  return active_bump_ps ? active_bump_ps->free_heap_space : 0;
}
static void next_heap_msection(___processor_state ps)
{
  ps->heap_origin=ps->next_heap_origin;
  ps->heap_ptr=ps->next_heap_origin;
  ps->heap_end=ps->next_heap_end;
}

static struct { int heap_used; } heap_claim = {1};
#define section_claim_at(section, offset) (&heap_claim)

static int current_heap_interval_matches(___processor_state ps, ___WORD *hp)
{
  return ps->heap_owned && hp >= ps->heap_origin && hp <= ps->heap_end;
}

static int ___owned_stack_span(___processor_state ps, ___WORD **lo, ___WORD **hi)
{
  if (!ps->stack_owned) return 0;
  *lo=ps->stack_lo;
  *hi=ps->stack_hi;
  return 1;
}

static unsigned int shared_attempt_cas;
static ___WORD ___lifecycle_cas(___WORD *address, ___WORD old, ___WORD next)
{
  ___WORD found=*address;
  ++shared_attempt_cas;
  if (found==old) *address=next;
  return found;
}

/* The cut observes the return to the generated service edge. It neither
 * runs the handler nor claims the runtime's terminal error behaviour. */
static void rc_contract_error(const char *message) { (void)message; }

#include "fast-span.inc"
#include "capacity-checks.inc"
#include "demand-slots.inc"
#include "attempt-issue.inc"
#include "arm-and-commit.inc"
#include "after-service.inc"
#include "blocked.inc"
#include "retire.inc"
#include "bump-section.inc"
#include "entry.inc"
#include "generated-entry.inc"

static int enter_group(_Bool generated, ___processor_state ps,
                       ___WORD **hp, ___WORD **fp, ___SIZE_TS heap_words,
                       ___WORD *attempt)
{
  if (generated)
    return ___group_demand_enter(ps,hp,fp,2,heap_words,7,attempt);
#undef ___group_demand_enter
  return ___group_demand_enter(ps,hp,fp,2,heap_words,7,attempt);
}

static void commit_zero(_Bool generated, ___processor_state ps)
{
  if (generated) {
    ___group_demand_commit(ps,7,0);
    return;
  }
#undef ___group_demand_commit
  ___group_demand_commit(ps,7,0);
}

_Bool nondet_bool(void);
int nondet_int(void);

void local_admission_contract(void)
{
  ___WORD heap[8], next_heap[16], stack[32];
  ___WORD *hp=heap, *fp=stack+24;
  ___execution_context context={hp,fp};
  ___activation_record activation={0};
  ___vm_lifecycle life={.activations={&activation,0},.incarnation=1,
    .group_demand_attempt_next=1};
  struct vm_view vm={.lifecycle=&life,.mem={.nb_gcs_=1}};
  struct processor_view ps={.context=&context,.vm=&vm,.id=0,
    .heap_origin=heap,.heap_ptr=heap,.heap_limit=heap+5,.heap_end=heap+5,
    .next_heap_origin=next_heap,.next_heap_end=next_heap+16,.free_heap_space=0,
    .stack_lo=stack,.stack_hi=stack+32,
    .heap_owned=1,.stack_owned=1,.stack_section=2};
  ___group_demand *slot=&life.group_demand[0];
  const _Bool generated=nondet_bool();
  const int scenario=nondet_int();
  ___WORD attempt=-1;
  int granted;

  active_bump_ps=&ps;
  __CPROVER_assume(scenario>=0 && scenario<=14);
  switch (scenario) {
  case 0:
    granted=enter_group(generated,&ps,&hp,&fp,0,&attempt);
    CHECK(granted && attempt==0, "local.zero-fit");
    CHECK(shared_attempt_cas==0 && slot->phase==0 && slot->service_next==0,
          "local.zero-no-service");
    break;
  case 1:
    granted=enter_group(generated,&ps,&hp,&fp,5,&attempt);
    CHECK(granted && attempt==0, "local.five-exact-fit");
    CHECK(shared_attempt_cas==0 && slot->phase==0 && slot->service_next==0,
          "local.five-no-service");
    break;
  case 2:
    ps.heap_limit=ps.heap_end=heap+4;
    granted=enter_group(generated,&ps,&hp,&fp,5,&attempt);
    CHECK(!granted, "local.five-short-refuses-first-effect");
    CHECK(slot->phase==1 && slot->attempt!=0 && slot->heap_words==5,
          "local.short-keeps-complete-pending-demand");
    CHECK(slot->service_incarnation==life.incarnation && slot->service_next>slot->attempt &&
          life.group_demand[1].service_next==0 && shared_attempt_cas==0,
          "local.short-issues-only-in-owner-slot");
    break;
  case 3:
    *slot=(___group_demand){.context=&context,.activation=&activation,
      .group_point=7,.attempt=42,.phase=3,.epoch=1,.hp=hp,.fp=fp,
      .service_incarnation=1,.service_next=43};
    granted=enter_group(generated,&ps,&hp,&fp,0,&attempt);
    if (generated)
      CHECK(!granted, "local.generated-pending-refusal-precedes-zero-fit");
    else
      CHECK(!granted, "local.direct-pending-refusal-precedes-zero-fit");
    commit_zero(generated,&ps);
    CHECK(slot->phase==3 && slot->attempt==42 && slot->context==&context &&
          slot->service_next==43 && shared_attempt_cas==0,
          "local.zero-commit-preserves-refusal");
    break;
  case 4:
    ps.heap_owned=0;
    granted=enter_group(generated,&ps,&hp,&fp,5,&attempt);
    CHECK(!granted, "local.unowned-heap-refuses-first-effect");
    break;
  case 5:
    ps.stack_owned=0;
    granted=enter_group(generated,&ps,&hp,&fp,0,&attempt);
    CHECK(!granted, "local.unowned-stack-refuses-first-effect");
    break;
  case 6:
  case 7:
    hp=context.hp=ps.heap_origin=stack;
    ps.heap_limit=ps.heap_end=stack+8;
    ps.stack_section=1;
    ps.stack_lo=stack+(scenario==6 ? 5 : 4);
    granted=enter_group(generated,&ps,&hp,&fp,5,&attempt);
    if (scenario==6)
      CHECK(granted && attempt==0 && shared_attempt_cas==0 && slot->phase==0 &&
            slot->service_next==0,
            "local.shared-half-five-exact-fit");
    else
      CHECK(!granted, "local.shared-half-stack-floor-clips-heap");
    break;
  case 8:
    *slot=(___group_demand){.context=&context,.activation=&activation,
      .group_point=7,.attempt=42,.phase=2,.epoch=1,.hp=hp,.fp=fp,
      .service_incarnation=2,.service_next=43};
    CHECK(!___group_demand_granted(&ps,7,42,hp,fp), "local.stale-vm-grant-rejected");
    ___group_demand_commit(&ps,7,42);
    CHECK(slot->phase==2 && slot->attempt==42 && slot->service_next==43,
          "local.stale-vm-commit-rejected");
    break;
  case 9:
    ps.heap_limit=heap+4;
    ps.heap_end=heap+8;
    granted=enter_group(generated,&ps,&hp,&fp,5,&attempt);
    CHECK(granted && attempt!=0 && slot->phase==2 && slot->attempt==attempt &&
          slot->service_next>attempt && shared_attempt_cas==0,
          "local.soft-heap-limit-issues-tracked-fudge-grant");
    ___group_demand_commit(&ps,7,attempt);
    CHECK(slot->phase==0 && slot->attempt==0,
          "local.tracked-fudge-grant-commits-cleanly");
    break;
  case 10:
    ps.heap_limit=ps.heap_end=heap+4;
    ps.free_heap_space=___MSECTION_SIZE;
    granted=enter_group(generated,&ps,&hp,&fp,5,&attempt);
    CHECK(granted && attempt==0 && hp==next_heap &&
          ps.heap_limit==next_heap+(16-___MSECTION_FUDGE) &&
          shared_attempt_cas==0 && slot->phase==0 && slot->service_next==0,
          "local.bump-free-section-publishes-soft-limit");
    break;
  case 11:
    {
      ___WORD *fudge_fp;
      harness_fudge=16;
      fudge_fp=stack+harness_fudge+1;
      context.fp=fudge_fp;
      granted=enter_group(generated,&ps,&hp,&fudge_fp,0,&attempt);
      CHECK(!granted && slot->phase==1 && slot->attempt!=0 &&
            cursor_has_stack_room(&ps,fudge_fp,handler_spill_words()),
            "local.stack-fudge-reserve-triggers-shortage");
    }
    break;
  case 12:
    {
      ___WORD *handler_fp=stack+16;
      ___WORD nested_attempt=99;
      int nested_ok;
      *slot=(___group_demand){.context=&context,.activation=&activation,
        .group_point=7,.attempt=42,.phase=1,.epoch=1,.hp=hp,.fp=fp,.root_fp=fp,
        .stack_words=2,.heap_words=0,.service_incarnation=1,.service_next=43};
      context.fp=handler_fp;
      vm.mem.nb_gcs_=2;
      ___group_demand_after(&ps,0);
      CHECK(slot->phase==1 && slot->resume_query==1 && slot->epoch==2 &&
            slot->fp==fp,
            "local.after-service-preserves-phase1-until-unframe");
      nested_ok=___group_demand_enter(&ps,&hp,&handler_fp,2,0,9,&nested_attempt);
      CHECK(nested_ok && nested_attempt==0 && slot->phase==1 &&
            slot->resume_query==1 && slot->group_point==7 && slot->attempt==42,
            "local.nested-fitting-group-preserves-pending-slot");
    }
    break;
  case 13:
    {
      ___WORD *handler_fp=stack+16;
      *slot=(___group_demand){.context=&context,.activation=&activation,
        .group_point=7,.attempt=42,.phase=1,.epoch=1,.hp=hp,.fp=fp,.root_fp=fp,
        .stack_words=2,.heap_words=0,.service_incarnation=1,.service_next=43};
      context.fp=handler_fp;
      vm.mem.nb_gcs_=2;
      ___group_demand_after(&ps,0);
      context.fp=fp;
      granted=enter_group(generated,&ps,&hp,&fp,0,&attempt);
      CHECK(granted && attempt==42 && slot->phase==2 && slot->resume_query==0 &&
            slot->fp==fp && slot->epoch==2,
            "local.unwound-retry-arms-phase2-at-caller-fp");
      ___group_demand_commit(&ps,7,attempt);
      CHECK(slot->phase==0 && slot->attempt==0,
            "local.unwound-retry-commits-cleanly");
    }
    break;
  case 14:
    {
      const _Bool pre_fudge_tail=nondet_bool();
      hp=pre_fudge_tail ? next_heap+6 : next_heap;
      context.hp=hp;
      ps.heap_origin=next_heap;
      ps.heap_ptr=hp;
      ps.heap_limit=pre_fudge_tail ? next_heap+(10-___MSECTION_FUDGE) : next_heap+4;
      ps.heap_end=next_heap+10;
      ps.next_heap_origin=heap;
      ps.next_heap_end=heap+8;
      ps.free_heap_space=___MSECTION_SIZE;
      granted=enter_group(generated,&ps,&hp,&fp,pre_fudge_tail ? 3 : 5,&attempt);
      if (!pre_fudge_tail) {
        CHECK(granted && attempt==0 && hp==next_heap &&
              ps.heap_limit==next_heap+(10-___MSECTION_FUDGE) &&
              shared_attempt_cas==0 && slot->phase==0 && slot->service_next==0,
              "local.soft-poll-extends-in-section-before-bump");
      } else {
        CHECK(granted && attempt!=0 && hp==next_heap+6 &&
              slot->phase==2 && slot->attempt==attempt && shared_attempt_cas==0,
              "local.pre-fudge-tail-keeps-active-section");
        ___group_demand_commit(&ps,7,attempt);
        CHECK(slot->phase==0 && slot->attempt==0,
              "local.pre-fudge-tail-commits-cleanly");
      }
      hp=ps.heap_origin;
    }
    break;
  }
  CHECK(hp==ps.heap_origin && fp==stack+24, "local.entry-keeps-current-cursors");
}

void fast_span_contract(void)
{
  ___WORD heap[8], next_heap[16], stack[32];
  ___WORD *hp=heap, *fp=stack+24;
  ___execution_context context={hp,fp};
  ___activation_record activation={0};
  ___vm_lifecycle life={.activations={&activation,0},.incarnation=1,
    .group_demand_attempt_next=1};
  struct vm_view vm={.lifecycle=&life,.mem={.nb_gcs_=1}};
  struct processor_view ps={.context=&context,.vm=&vm,.id=0,
    .heap_origin=heap,.heap_ptr=heap,.heap_limit=heap+5,.heap_end=heap+5,
    .next_heap_origin=next_heap,.next_heap_end=next_heap+16,.free_heap_space=0,
    .stack_lo=stack,.stack_hi=stack+32,
    .heap_owned=1,.stack_owned=1,.stack_section=2};
  ___group_demand *slot=&life.group_demand[0];
  const _Bool generated=nondet_bool();
  const int scenario=nondet_int();
  ___WORD attempt=-1;
  int granted;

  active_bump_ps=&ps;
  __CPROVER_assume(scenario>=0 && scenario<=2);
  switch (scenario) {
  case 0:
    {
      ___WORD *short_hp=heap+1;
      publish_fast_span(&ps);
      granted=enter_group(generated,&ps,&hp,&fp,5,&attempt);
      CHECK(granted && attempt==0 && shared_attempt_cas==0 && slot->phase==0,
            "local.fast-span-exact-fit-admits");
      granted=enter_group(generated,&ps,&short_hp,&fp,5,&attempt);
      CHECK(!granted && slot->phase==1 && ps.group_demand_active==1 &&
            ps.stack_fast_limit_b==0 && ps.heap_fast_bytes==0,
            "local.fast-span-short-clears-span");
      ___group_demand_retire(&ps);
      CHECK(ps.group_demand_active==0 && ps.stack_fast_limit_b>0 &&
            ps.heap_fast_bytes==(5*sizeof(___WORD)),
            "local.fast-span-retire-republishes");
    }
    break;
  case 1:
    {
      ___WORD *fudge_fp;
      harness_fudge=16;
      fudge_fp=stack+harness_fudge+1;
      publish_fast_span(&ps);
      context.fp=fudge_fp;
      granted=enter_group(generated,&ps,&hp,&fudge_fp,0,&attempt);
      CHECK(!granted && slot->phase==1 && ps.group_demand_active==1 &&
            ps.stack_fast_limit_b==0,
            "local.fast-span-fudge-boundary-refuses");
    }
    break;
  case 2:
    {
      ps.heap_limit=heap+4;
      ps.heap_end=heap+8;
      publish_fast_span(&ps);
      granted=enter_group(generated,&ps,&hp,&fp,5,&attempt);
      CHECK(granted && attempt!=0 && slot->phase==2 &&
            ps.group_demand_active==1 && ps.stack_fast_limit_b==0,
            "local.fast-span-active-demand-clears-span");
      ___group_demand_commit(&ps,7,attempt);
      CHECK(slot->phase==0 && ps.group_demand_active==0 &&
            ps.stack_fast_limit_b>0 && ps.heap_fast_bytes==(4*sizeof(___WORD)),
            "local.fast-span-commit-republishes");
    }
    break;
  }
}
