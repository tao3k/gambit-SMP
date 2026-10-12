/* Locked setup/cleanup bodies; returning init failures and real POSIX reuse. */
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <stdatomic.h>

typedef int ___SCMOBJ;
typedef struct { pthread_mutex_t native; int live, attempts, destroys; } mutex_t;
typedef struct { pthread_cond_t native; int live, attempts, destroys; } cond_t;
typedef struct processor {
  int sync_id0, sync_id1, sync_id2, sync_resources_ready;
  mutex_t sync_mut;
  cond_t sync_cv;
} *___processor_state;
static int invalid, checks, fail_mutex, fail_condition;
#define ___HIDDEN static
#define ___P(args, old) args
#define ___FIX(x) (x)
#define ___NO_ERR 0
#define ___UNKNOWN_ERR -1
#define SYNC_INIT_MSG(value) ((value) = -1)

static int mutex_init(mutex_t *m) {
  ++m->attempts;
  if (m->live) { ++invalid; return 0; }
  if (fail_mutex) return 0;
#ifdef MODE_REAL_POSIX
  if (pthread_mutex_init(&m->native, NULL)) { ++invalid; return 0; }
#endif
  m->live = 1;
  return 1;
}
static int condition_init(cond_t *c) {
  ++c->attempts;
  if (c->live) { ++invalid; return 0; }
  if (fail_condition) return 0;
#ifdef MODE_REAL_POSIX
  if (pthread_cond_init(&c->native, NULL)) { ++invalid; return 0; }
#endif
  c->live = 1;
  return 1;
}
static void mutex_destroy(mutex_t *m) {
  ++m->destroys;
  if (!m->live) { ++invalid; return; }
#ifdef MODE_REAL_POSIX
  if (pthread_mutex_destroy(&m->native)) ++invalid;
#endif
  m->live = 0;
}
static void condition_destroy(cond_t *c) {
  ++c->destroys;
  if (!c->live) { ++invalid; return; }
#ifdef MODE_REAL_POSIX
  if (pthread_cond_destroy(&c->native)) ++invalid;
#endif
  c->live = 0;
}
#ifdef MODE_VOID
static void mutex_init_void(mutex_t *m) { (void)mutex_init(m); }
static void condition_init_void(cond_t *c) { (void)condition_init(c); }
#define ___MUTEX_INIT(m) mutex_init_void(&(m))
#define ___CONDVAR_INIT(c) condition_init_void(&(c))
#else
#define ___USE_POSIX_THREAD_SYSTEM
#define ___MUTEX_INIT(m) mutex_init(&(m))
#define ___CONDVAR_INIT(c) condition_init(&(c))
#endif
#define ___MUTEX_DESTROY(m) mutex_destroy(&(m))
#define ___CONDVAR_DESTROY(c) condition_destroy(&(c))

#include "sync-setup.inc"
#ifndef PARENT_SETUP
#include "sync-cleanup.inc"
#else
static void cleanup_sync_op_pstate(___processor_state ps) { (void)ps; }
#endif

#ifdef MODE_REAL_POSIX
static atomic_int published, finish_tail;
static void *old_sender(void *arg) {
  ___processor_state ps = arg;
  if (pthread_mutex_lock(&ps->sync_mut.native)) return (void *)1;
  ps->sync_id0 = 7;
  atomic_store_explicit(&published, 1, memory_order_release);
  while (!atomic_load_explicit(&finish_tail, memory_order_acquire)) { }
  if (pthread_mutex_unlock(&ps->sync_mut.native)) return (void *)1;
  if (pthread_cond_signal(&ps->sync_cv.native)) return (void *)1;
  return NULL;
}
static void overlapping_reuse(___processor_state ps) {
  pthread_t sender;
  void *result;
  atomic_store(&published, 0);
  atomic_store(&finish_tail, 0);
  if (pthread_create(&sender, NULL, old_sender, ps)) { ++invalid; return; }
  while (!atomic_load_explicit(&published, memory_order_acquire)) { }
  if (setup_sync_op_pstate(ps) != 0) ++invalid;
  if (ps->sync_id0 != -1 || !ps->sync_resources_ready) ++invalid;
  atomic_store_explicit(&finish_tail, 1, memory_order_release);
  if (pthread_join(sender, &result) || result) ++invalid;
}
#endif

int main(void) {
  int cycle;
  for (cycle = 0; cycle < 2; ++cycle) {
    struct processor ps;
    int mutex_attempts, condition_attempts, mutex_destroys, condition_destroys, reuse;
    memset(&ps, 0, sizeof(ps));
#ifndef MODE_VOID
    fail_mutex = 1;
    if (setup_sync_op_pstate(&ps) != -1 || ps.sync_resources_ready ||
        ps.sync_mut.live || ps.sync_cv.live || ps.sync_cv.attempts) ++invalid;
    ++checks;
    fail_mutex = 0;
    fail_condition = 1;
    if (setup_sync_op_pstate(&ps) != -1 || ps.sync_resources_ready ||
        ps.sync_mut.live || ps.sync_cv.live || ps.sync_mut.destroys != 1) ++invalid;
    ++checks;
    fail_condition = 0;
#endif
    if (setup_sync_op_pstate(&ps) != 0 || !ps.sync_resources_ready ||
        !ps.sync_mut.live || !ps.sync_cv.live) ++invalid;
    ++checks;
    mutex_attempts = ps.sync_mut.attempts;
    condition_attempts = ps.sync_cv.attempts;
    for (reuse = 0; reuse < 3; ++reuse) {
      ps.sync_id0 = ps.sync_id1 = ps.sync_id2 = 99;
#ifdef MODE_REAL_POSIX
      overlapping_reuse(&ps);
#else
      if (setup_sync_op_pstate(&ps) != 0) ++invalid;
#endif
      if (ps.sync_id0 != -1 || ps.sync_id1 != -1 || ps.sync_id2 != -1 ||
          ps.sync_mut.attempts != mutex_attempts ||
          ps.sync_cv.attempts != condition_attempts) ++invalid;
      ++checks;
    }
    cleanup_sync_op_pstate(&ps);
    mutex_destroys = ps.sync_mut.destroys;
    condition_destroys = ps.sync_cv.destroys;
    cleanup_sync_op_pstate(&ps);
    if (ps.sync_resources_ready || ps.sync_mut.live || ps.sync_cv.live ||
        ps.sync_mut.destroys != mutex_destroys ||
        ps.sync_cv.destroys != condition_destroys) ++invalid;
    ++checks;
  }
  printf("sync_slot_retained_resources checks=%d invalid=%d\n", checks, invalid != 0);
  return invalid != 0;
}
