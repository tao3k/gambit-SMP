#ifndef GAMBIT_TEST_MAP_WORKER_STOP_OVERLAY_H
#define GAMBIT_TEST_MAP_WORKER_STOP_OVERLAY_H

#include <pthread.h>
#include <stdbool.h>
#include <stdlib.h>

/* Test-owned records only. No collector slot, queue, participant count or
 * heap allocation is changed here. Run this control outside GC barriers. */
struct map_worker_stop {
  pthread_mutex_t lock;
  pthread_cond_t changed;
  bool admitted;
  bool release_helper;
  bool closed;
  bool sealed;
  bool carrier_present;
  bool bank_pinned;
  unsigned generation;
  unsigned permits;
  unsigned repaired_slots;
  unsigned frontier;
  unsigned child;
  unsigned child_publications;
};

static bool map_worker_acquire(struct map_worker_stop *s, unsigned generation)
{
  bool ok = !s->closed && generation == s->generation;
  if (ok)
    ++s->permits;
  return ok;
}

static void *map_worker_helper(void *data)
{
  struct map_worker_stop *s = data;
  pthread_mutex_lock(&s->lock);
  s->admitted = map_worker_acquire(s, 1);
  pthread_cond_signal(&s->changed);
  while (!s->release_helper)
    pthread_cond_wait(&s->changed, &s->lock);
  if (s->admitted) {
    s->repaired_slots = 1; /* Last helper effect, before permit release. */
    --s->permits;
  }
  pthread_mutex_unlock(&s->lock);
  return NULL;
}

static bool map_worker_seal(struct map_worker_stop *s)
{
  if (!s->closed || s->permits != 0 || s->repaired_slots != 1 || s->child != 17)
    return false;
  s->frontier = s->repaired_slots;
  s->sealed = true;
  return true;
}

static bool map_worker_publish_child(struct map_worker_stop *s, unsigned key)
{
  if (!s->child) {
    s->child = key;
    ++s->child_publications;
  }
  return s->child == key;
}

static bool map_worker_stop_control(bool carrier_present, bool lose_child_reply,
                                    bool omit_query)
{
  struct map_worker_stop s = {
    .generation = 1, .carrier_present = carrier_present, .bank_pinned = true
  };
  pthread_t helper;
  if (pthread_mutex_init(&s.lock, NULL) != 0)
    return false;
  if (pthread_cond_init(&s.changed, NULL) != 0) {
    pthread_mutex_destroy(&s.lock);
    return false;
  }
  if (pthread_create(&helper, NULL, map_worker_helper, &s) != 0) {
    pthread_cond_destroy(&s.changed);
    pthread_mutex_destroy(&s.lock);
    return false;
  }

  pthread_mutex_lock(&s.lock);
  while (!s.admitted)
    pthread_cond_wait(&s.changed, &s.lock);
  s.closed = true;
  bool ok = !map_worker_acquire(&s, 1) && !map_worker_seal(&s);
  s.release_helper = true;
  pthread_cond_signal(&s.changed);
  pthread_mutex_unlock(&s.lock);
  /* The join certifies termination of this fixture helper. It cannot stand
   * in for a carrier rendezvous or closure of untracked native writers. */
  if (pthread_join(helper, NULL) != 0)
    abort();
  pthread_mutex_lock(&s.lock);
  bool committed = map_worker_publish_child(&s, 17);
  bool received = committed && !lose_child_reply;
  if (!received && !omit_query)
    received = s.child == 17; /* Exact query, not a retry of publication. */
  ok = ok && received && s.child_publications == 1;
  if (received)
    ok = map_worker_seal(&s) && ok;

  if (s.sealed && s.carrier_present) {
    s.generation = 2; /* Both generation and frontier protected by the gate. */
    s.closed = false;
    ok = ok && !map_worker_acquire(&s, 1);
    bool successor = map_worker_acquire(&s, 2);
    ok = ok && successor && s.frontier == 1;
    if (successor) {
      s.frontier = 2;
      --s.permits;
      s.bank_pinned = false;
    }
  }
  ok = ok && (s.carrier_present
               ? s.generation == 2 && s.frontier == 2 && !s.bank_pinned
               : s.generation == 1 && s.frontier == 1 && s.bank_pinned);
  pthread_mutex_unlock(&s.lock);
  pthread_cond_destroy(&s.changed);
  pthread_mutex_destroy(&s.lock);
  return ok;
}

#endif
