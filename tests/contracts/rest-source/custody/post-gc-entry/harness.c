/* Project the two actual handler condition chains. Source validity, root
 * reload, stack slots and destination heap capacity are separate results.
 * The grant call must receive the fp used after ___ADJFP(na). */
typedef long ___WORD;
typedef struct { ___WORD *stack_limit,*stack_break; } context;
typedef struct { context *context; ___WORD internal_return; } *___processor_state;
static struct { ___processor_state ps; } fixture;
enum route { REFUSE_SOURCE, REFUSE_RELOAD, REFUSE_STACK, EXTEND, READY };
static _Bool nondet_bool(void);
static _Bool source_ok,reload_ok,stack_ok,grant_ok,parent_grant_ok,grant_saw_current;
static unsigned extend_calls;
static ___WORD current_slot;
#define ___rest_caller_chain(...) (source_ok)
#define ___rest_reload_window(...) (reload_ok)
#define ___rest_stack_slots_fit(...) (stack_ok)
#define ___rest_grant_fits(ps,hp,fp,...) \
  (grant_saw_current=((___WORD)(fp)==current_slot), \
   grant_saw_current ? grant_ok : parent_grant_ok)
#define CHECK(p,n) __CPROVER_assert((p),(n))
static int ___rest_extend_interval(___processor_state ps, ___WORD pending, ___WORD np)
{ (void)ps; (void)pending; (void)np; ++extend_calls; return 0; }
static int ordinary_route(___processor_state ___ps)
{
  ___WORD i=2,np=3,___fp=current_slot,___hp=0,na=2,___R0=1,held_epoch=0;
  ___WORD *held=0,*repaired=0;
#include "ordinary-source-test.inc"
    return REFUSE_SOURCE;
#include "ordinary-reload-test.inc"
    return REFUSE_RELOAD;
#include "ordinary-stack-test.inc"
    return REFUSE_STACK;
#include "ordinary-grant-test.inc"
  {
#include "ordinary-extension-test.inc"
    return EXTEND;
  }
  return READY;
}

static int keyword_route(___processor_state ___ps)
{
  ___WORD i=2,np=3,___fp=current_slot,___hp=0,na=2,___R0=1,held_epoch=0;
  ___WORD nb_key=0,stack_slots=1;
  ___WORD *held=0,*repaired=0,*key_vals=0;
#include "keyword-source-test.inc"
    return REFUSE_SOURCE;
#include "keyword-reload-test.inc"
    return REFUSE_RELOAD;
#include "keyword-stack-test.inc"
    return REFUSE_STACK;
#include "keyword-grant-test.inc"
  {
#include "keyword-extension-test.inc"
    return EXTEND;
  }
  return READY;
}

void check_extension_entry(void)
{
  /* Saved parent fp is short; the fp after ___ADJFP(na) still fits. */
  source_ok=1; reload_ok=1; stack_ok=1; grant_ok=1; parent_grant_ok=0;
  current_slot=8; extend_calls=0; grant_saw_current=0;
  int ordinary_kept=ordinary_route(fixture.ps);
  CHECK(grant_saw_current && ordinary_kept==READY && extend_calls==0,
        "control.shared-half-uses-current-fp-when-parent-is-short");
  extend_calls=0; grant_saw_current=0;
  int keyword_kept=keyword_route(fixture.ps);
  CHECK(grant_saw_current && keyword_kept==READY && extend_calls==0,
        "control.keyword-shared-half-uses-current-fp-when-parent-is-short");
  /* The same pair reversed: only the current fp is short, so extension may start. */
  grant_ok=0; parent_grant_ok=1; extend_calls=0; grant_saw_current=0;
  int ordinary_short=ordinary_route(fixture.ps);
  CHECK(grant_saw_current && ordinary_short==EXTEND && extend_calls==1,
        "control.shared-half-current-fp-shortage-enters-extension");
  extend_calls=0; grant_saw_current=0;
  int keyword_short=keyword_route(fixture.ps);
  CHECK(grant_saw_current && keyword_short==EXTEND && extend_calls==1,
        "control.keyword-shared-half-current-fp-shortage-enters-extension");

  source_ok=nondet_bool();
  reload_ok=nondet_bool();
  stack_ok=nondet_bool();
  grant_ok=nondet_bool();
  parent_grant_ok=grant_ok;
  extend_calls=0;
  int result=nondet_bool() ? ordinary_route(fixture.ps) : keyword_route(fixture.ps);
  CHECK(source_ok || (result==REFUSE_SOURCE && extend_calls==0),
        "entry.invalid-source-refuses-without-extension");
  CHECK(!(source_ok && reload_ok && stack_ok && !grant_ok) ||
        (result==EXTEND && extend_calls==1),
        "entry.valid-source-and-missing-grant-route-to-extension");
  CHECK(!(source_ok && reload_ok && stack_ok && grant_ok) ||
        (result==READY && extend_calls==0),
        "entry.valid-source-and-grant-do-not-extend");
  CHECK(!(source_ok && !reload_ok) || (result==REFUSE_RELOAD && extend_calls==0),
        "control.failed-root-reload-must-not-enter-extension");
  CHECK(!(source_ok && reload_ok && !stack_ok) ||
        (result==REFUSE_STACK && extend_calls==0),
        "control.stack-shortage-must-not-enter-extension");
}
