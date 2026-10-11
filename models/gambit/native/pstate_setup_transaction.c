/* Actual candidate caller/helpers; primitive resources and VM layout are mocked. */
#include <stdio.h>
#include <string.h>
enum failure { NONE, INTERRUPT, OS, MEMORY, SYNC_MUTEX, SYNC_CONDITION };
typedef int ___SCMOBJ;
typedef int ___BOOL;
typedef struct resource { int role, live, held, attempts, releases; } resource;
typedef struct ___procedural_interrupt_header {
  struct ___procedural_interrupt_header *next;
} ___procedural_interrupt_header;
typedef struct vm { int unused; } *___virtual_machine_state;
#define HANDLERS \
  int handler_sfun_conv_error, handler_cfun_conv_error, handler_stack_limit, handler_heap_limit; \
  int handler_not_proc, handler_not_proc_glo, handler_wrong_nargs, handler_get_rest; \
  int handler_get_key, handler_get_key_rest, handler_force, handler_return_to_c; \
  int handler_break, internal_return, dynamic_env_bind_return;
typedef struct processor {
  HANDLERS
  ___virtual_machine_state vmstate;
  int id, intr_enabled, intr_mask, intr_flag[2], sync_id0, sync_id1, sync_id2;
  int r[2], saved[2], type_cache[2], catcher;
  int fail, os_live, mem_live, os_calls, mem_calls, os_releases, mem_releases;
  int invalid, queued_releases, object_live;
  resource procedural_interrupts_mut, sync_mut, sync_cv;
  ___procedural_interrupt_header *procedural_interrupts_head, *procedural_interrupts_tail;
} *___processor_state;
static struct { HANDLERS struct vm vmstate0; } global;
static ___processor_state current;
#define ___GSTATE (&global)
#define ___PROCESSOR_ID(ps, vm) ((ps)->id)
#define ___P(args, old) args
#define ___HIDDEN static
#define ___EXP_FUNC(type, name) type name
#define ___FIX(value) (value)
#define ___NO_ERR 0
#define ___UNKNOWN_ERR -1
#define ___VOID -2
#define ___NB_INTRS 2
#define ___INTR_SYNC_OP 0
#define ___USE_SETJMP
#define ___ACTLOG_PS(event, color) ((void)0)
#define ___CAST(type, value) ((type)(value))
#define SYNC_INIT_MSG(field) ((field) = -1)
static int initialize(resource *r) {
  ++r->attempts;
  if (r->live) ++current->invalid;
#ifdef TEST_POSIX
  if (current->fail == r->role) return 0;
#endif
  r->live = 1;
  return 1;
}
static int destroy(resource *r) {
  ++r->releases;
  if (!r->live || r->held) ++current->invalid;
  r->live = 0;
  return 1;
}
static int lock(resource *r) {
  if (!r->live || r->held) ++current->invalid;
  r->held = 1;
  return 1;
}
static int unlock(resource *r) {
  if (!r->live || !r->held) ++current->invalid;
  r->held = 0;
  return 1;
}
#ifdef TEST_POSIX
#define ___USE_POSIX_THREAD_SYSTEM
#define ___MUTEX_INIT(r) initialize(&(r))
#define ___CONDVAR_INIT(r) initialize(&(r))
#else
static void initialize_void(resource *r) { (void)initialize(r); }
#define ___MUTEX_INIT(r) initialize_void(&(r))
#define ___CONDVAR_INIT(r) initialize_void(&(r))
#endif
#define ___MUTEX_DESTROY(r) destroy(&(r))
#define ___MUTEX_LOCK(r) lock(&(r))
#define ___MUTEX_UNLOCK(r) unlock(&(r))
static void release_procedural_interrupt(void *intr) {
  (void)intr;
  ++current->queued_releases;
  if (!current->mem_live) ++current->invalid;
}
static int ___setup_os_pstate(___processor_state ps) {
  ++ps->os_calls;
  if (ps->fail == OS) return 2;
  ps->os_live = 1;
  return 0;
}
static int ___setup_mem_pstate(___processor_state ps) {
  ++ps->mem_calls;
  if (!ps->os_live) ++ps->invalid;
  if (ps->fail == MEMORY) return 3;
  ps->mem_live = 1;
  return 0;
}
static void ___cleanup_mem_pstate(___processor_state ps) {
  ++ps->mem_releases;
  if (!ps->mem_live) ++ps->invalid;
  ps->mem_live = 0;
  ps->object_live = 0;
}
static void ___cleanup_os_pstate(___processor_state ps) {
  ++ps->os_releases;
  if (!ps->os_live || ps->mem_live) ++ps->invalid;
  ps->os_live = 0;
}
static void setup_processor_scmobj_pstate(___processor_state ps) {
  if (!ps->mem_live) ++ps->invalid;
  ps->object_live = 1;
}
/* The unchanged source uses signed indices for these bounded sizeof loops. */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsign-compare"
#include "pstate-setup-source.inc"
#pragma GCC diagnostic pop
static void fresh(struct processor *ps, int id, int failure) {
  memset(ps, 0, sizeof *ps);
  current = ps;
  ps->id = id;
  ps->fail = failure;
  ps->procedural_interrupts_mut.role = INTERRUPT;
  ps->sync_mut.role = SYNC_MUTEX;
  ps->sync_cv.role = SYNC_CONDITION;
}
int main(void) {
#ifdef TEST_POSIX
  const int failures[] = { NONE, INTERRUPT, OS, MEMORY, SYNC_MUTEX, SYNC_CONDITION };
  const char *platform = "posix";
#else
  const int failures[] = { NONE, OS, MEMORY };
  const char *platform = "void-init";
#endif
  struct vm other;
  int checks = 0, invalid = 0;
  for (int context = 0; context < 3; ++context) {
    for (size_t index = 0; index < sizeof failures / sizeof failures[0]; ++index) {
      struct processor ps;
      ___procedural_interrupt_header pending = { NULL };
      int borrowed = context == 0, fail = failures[index], expected = 0;
      fresh(&ps, context == 1 ? 1 : 0, fail);
      ___virtual_machine_state vm = context == 2 ? &other : &global.vmstate0;
      if (borrowed) {
        ps.procedural_interrupts_mut.live = 1;
        ps.procedural_interrupts_head = ps.procedural_interrupts_tail = &pending;
      }
      if (fail == OS) expected = 2;
      else if (fail == MEMORY) expected = 3;
#ifdef TEST_POSIX
      else if ((fail == INTERRUPT && !borrowed) || fail == SYNC_MUTEX || fail == SYNC_CONDITION)
        expected = ___UNKNOWN_ERR;
#endif
      int error = ___setup_pstate(&ps, vm);
      if (error != expected) {
        puts("EXPECTED-SETUP-FAILURE-NOT-RETURNED");
        return 1;
      }
      if (ps.invalid || ps.procedural_interrupts_mut.held) return 2;
      if (borrowed && (!ps.procedural_interrupts_mut.live || ps.procedural_interrupts_mut.releases ||
          ps.procedural_interrupts_head != &pending || ps.procedural_interrupts_tail != &pending)) return 3;
      if (error) {
        if (ps.os_live || ps.mem_live || ps.sync_mut.live || ps.sync_cv.live || ps.object_live) return 4;
        if (!borrowed && ps.procedural_interrupts_mut.live) return 5;
        if (fail == SYNC_MUTEX && ps.sync_cv.attempts) return 6;
        if (fail == SYNC_CONDITION && (ps.sync_mut.releases != 1 || ps.sync_cv.releases)) return 7;
        if (fail == INTERRUPT && ps.os_calls) return 8;
        if (fail == OS && ps.mem_calls) return 9;
      } else if (!ps.os_live || !ps.mem_live || !ps.object_live || !ps.sync_mut.live || !ps.sync_cv.live ||
                 !ps.procedural_interrupts_mut.live || ps.os_releases || ps.mem_releases) return 10;
      invalid += ps.invalid;
      ++checks;
    }
  }
  /* Direct interrupt helper, not the full global constructor's failure unwind. */
  struct processor ps;
  fresh(&ps, 0, NONE);
  if (setup_interrupts_pstate(&ps) || !ps.procedural_interrupts_mut.live) return 11;
  ++checks;
#ifdef TEST_POSIX
  fresh(&ps, 0, INTERRUPT);
  if (setup_interrupts_pstate(&ps) != ___UNKNOWN_ERR || ps.procedural_interrupts_mut.live) return 12;
  ++checks;
#endif
  invalid += ps.invalid;
  printf("{\"platform\":\"%s\",\"checks\":%d,\"invalid\":%d}\n", platform, checks, invalid);
  return 0;
}
