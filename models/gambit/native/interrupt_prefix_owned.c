/* Locked interrupt setup/post/queue cleanup/owned cleanup; bounded callers. */
#include <pthread.h>
#include <stdio.h>
#include <string.h>
typedef int ___SCMOBJ;
typedef struct node { struct node *next; int id; } ___procedural_interrupt_header;
typedef struct { pthread_mutex_t native; int live, attempts, destroys; } mutex_t;
typedef struct processor {
  int intr_enabled, intr_mask, intr_flag[4], procedural_interrupts_ready;
  ___procedural_interrupt_header *procedural_interrupts_head, *procedural_interrupts_tail;
  mutex_t procedural_interrupts_mut;
} *___processor_state;
static int fail_init, invalid, checks, releases, released_mask;
#define ___HIDDEN static
#define ___EXP_FUNC(type, name) type name
#define ___P(args, old) args
#define ___FIX(x) (x)
#define ___CAST(type, value) ((type)(value))
#define ___NO_ERR 0
#define ___UNKNOWN_ERR -1
#define ___INTR_SYNC_OP 0
#define ___INTR_OTHER 1
#define ___NB_INTRS 4

static int init_mutex(mutex_t *m) {
  ++m->attempts;
  if (m->live) { ++invalid; return 0; }
  if (fail_init) return 0;
#ifdef MODE_REAL_POSIX
  if (pthread_mutex_init(&m->native, NULL)) { ++invalid; return 0; }
#endif
  m->live = 1;
  return 1;
}
static void lock_mutex(mutex_t *m) {
  if (!m->live) { ++invalid; return; }
#ifdef MODE_REAL_POSIX
  if (pthread_mutex_lock(&m->native)) ++invalid;
#endif
}
static void unlock_mutex(mutex_t *m) {
  if (!m->live) { ++invalid; return; }
#ifdef MODE_REAL_POSIX
  if (pthread_mutex_unlock(&m->native)) ++invalid;
#endif
}
static void destroy_mutex(mutex_t *m) {
  ++m->destroys;
  if (!m->live) { ++invalid; return; }
#ifdef MODE_REAL_POSIX
  if (pthread_mutex_destroy(&m->native)) ++invalid;
#endif
  m->live = 0;
}
#ifdef MODE_VOID
static void init_mutex_void(mutex_t *m) { (void)init_mutex(m); }
#define ___MUTEX_INIT(m) init_mutex_void(&(m))
#else
#define ___USE_POSIX_THREAD_SYSTEM
#define ___MUTEX_INIT(m) init_mutex(&(m))
#endif
#define ___MUTEX_LOCK(m) lock_mutex(&(m))
#define ___MUTEX_UNLOCK(m) unlock_mutex(&(m))
#define ___MUTEX_DESTROY(m) destroy_mutex(&(m))
static void release_procedural_interrupt(void *arg) {
  ___procedural_interrupt_header *n = arg;
  if (released_mask & (1 << n->id)) ++invalid;
  released_mask |= 1 << n->id;
  ++releases;
}
static void ___raise_interrupt_pstate(___processor_state ps, int kind) {
  (void)ps; (void)kind;
}
#include "interrupt-setup.inc"
#include "interrupt-post.inc"
#include "interrupt-queue-cleanup.inc"
#ifndef PARENT_SETUP
#include "interrupt-owned-cleanup.inc"
#else
static void cleanup_interrupt_resources_pstate(___processor_state ps) { (void)ps; }
#endif

#ifdef MODE_REAL_POSIX
struct post { ___processor_state ps; ___procedural_interrupt_header *node; };
static void *post_one(void *arg) {
  struct post *p = arg;
  ___raise_procedural_interrupt_pstate(p->ps, p->node);
  return NULL;
}
#endif
static void post_two(___processor_state ps, ___procedural_interrupt_header nodes[2]) {
  int i;
  nodes[0].id = 0; nodes[1].id = 1;
#ifdef MODE_REAL_POSIX
  pthread_t workers[2];
  struct post args[2];
  int started = 0;
  for (i = 0; i < 2; ++i) {
    args[i].ps = ps; args[i].node = &nodes[i];
    if (pthread_create(&workers[i], NULL, post_one, &args[i])) { ++invalid; break; }
    ++started;
  }
  for (i = 0; i < started; ++i) if (pthread_join(workers[i], NULL)) ++invalid;
#else
  for (i = 0; i < 2; ++i) ___raise_procedural_interrupt_pstate(ps, &nodes[i]);
#endif
}
int main(void) {
  int cycle;
  for (cycle = 0; cycle < 2; ++cycle) {
    struct processor ps;
    ___procedural_interrupt_header nodes[2];
    int attempts, destroys, reuse;
    memset(&ps, 0, sizeof(ps));
#ifndef MODE_VOID
    fail_init = 1;
    if (setup_interrupts_pstate(&ps) != -1 || ps.procedural_interrupts_ready) ++invalid;
    cleanup_interrupts_pstate(&ps);
    cleanup_interrupt_resources_pstate(&ps);
    if (ps.procedural_interrupts_mut.live || ps.procedural_interrupts_mut.destroys) ++invalid;
    fail_init = 0;
    ++checks;
#endif
    if (setup_interrupts_pstate(&ps) != 0 || !ps.procedural_interrupts_ready ||
        !ps.procedural_interrupts_mut.live || ps.intr_enabled != 1 || ps.intr_mask) ++invalid;
    attempts = ps.procedural_interrupts_mut.attempts;
    ++checks;
    releases = released_mask = 0;
    post_two(&ps, nodes);
    cleanup_interrupts_pstate(&ps);
    if (releases != 2 || released_mask != 3 || ps.procedural_interrupts_head ||
        ps.procedural_interrupts_tail || !ps.procedural_interrupts_mut.live) ++invalid;
    ++checks;
    for (reuse = 0; reuse < 3; ++reuse) {
      if (setup_interrupts_pstate(&ps) != 0 ||
          ps.procedural_interrupts_mut.attempts != attempts) ++invalid;
      ++checks;
    }
    releases = released_mask = 0;
    post_two(&ps, nodes);
    cleanup_interrupt_resources_pstate(&ps);
    destroys = ps.procedural_interrupts_mut.destroys;
    cleanup_interrupt_resources_pstate(&ps);
    if (releases != 2 || released_mask != 3 || ps.procedural_interrupts_ready ||
        ps.procedural_interrupts_mut.live || ps.procedural_interrupts_mut.destroys != destroys) ++invalid;
    ++checks;
  }
  printf("interrupt_prefix_owned checks=%d invalid=%d\n", checks, invalid != 0);
  return invalid != 0;
}
