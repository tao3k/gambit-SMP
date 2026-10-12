/* Extracted source protocol with real POSIX calls; payload tracing is stubbed. */
#include "gambit.h"
#include <assert.h>
#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#if !defined(___USE_POSIX_THREAD_SYSTEM) || defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS)
#error A POSIX multiple/threaded-VM header is required.
#endif
#ifdef __clang__
#error GNU GCC is required.
#endif

static ___virtual_machine_state vm;
static pthread_mutex_t gate = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t gate_cv = PTHREAD_COND_INITIALIZER;
static int point, stage, allowed, np;
static _Thread_local int helper, publishing;
static _Atomic unsigned consumed, consumed_mask, signals, waits;
static _Atomic int signal_before_wait;
static ___WORD chunks[4][12];

static void rendezvous(int wanted)
{
  assert(pthread_mutex_lock(&gate) == 0);
  stage = wanted;
  assert(pthread_cond_broadcast(&gate_cv) == 0);
  while (allowed < wanted) assert(pthread_cond_wait(&gate_cv, &gate) == 0);
  assert(pthread_mutex_unlock(&gate) == 0);
}

static int observed_wait(pthread_cond_t *cv, pthread_mutex_t *mutex)
{
  if (cv == &vm->mem.scan_termination_condvar_)
    {
      unsigned call = atomic_fetch_add(&waits, 1);
      if (point < 3 && helper && call == 0)
        {
          if (point == 2) rendezvous(1);
          atomic_store(&signal_before_wait, atomic_load(&signals) != 0);
          rendezvous(2);
        }
    }
  {
    int error = pthread_cond_wait(cv, mutex);
    assert(error == 0);
    return error;
  }
}

static int observed_signal(pthread_cond_t *cv)
{
  if (publishing) atomic_fetch_add(&signals, 1);
  return pthread_cond_signal(cv);
}

#define pthread_cond_wait observed_wait
#define pthread_cond_signal observed_signal
#undef ___ACTLOG_BEGIN_PS
#undef ___ACTLOG_END_PS
#define ___ACTLOG_BEGIN_PS(a,b) ((void)0)
#define ___ACTLOG_END_PS() ((void)0)
#include "gc-publish-source.inc"

static void drain_all(void)
{
  int i;
  for (i=0; i<np; i++)
    {
      ___processor_state ps = ___PSTATE_FROM_PROCESSOR_ID(i,vm);
      ___SPINLOCK_LOCK(ps->mem.heap_chunks_to_scan_lock_);
      while (ps->mem.heap_chunks_to_scan_head_ != ps->mem.heap_chunks_to_scan_tail_)
        {
          ___VOLATILE ___WORD *head = ps->mem.heap_chunks_to_scan_head_;
          ps->mem.heap_chunks_to_scan_head_ = ___UNTAG_AS(*head, ___FORW);
          ___SHARED_MEMORY_BARRIER();
          /* Each publisher contributes one chunk; reject double consumption. */
          assert((atomic_fetch_or(&consumed_mask, 1u << i) & (1u << i)) == 0);
          atomic_fetch_add(&consumed, 1);
        }
      ___SPINLOCK_UNLOCK(ps->mem.heap_chunks_to_scan_lock_);
    }
}

static void scan_schedule(___processor_state ___ps)
{
  ___virtual_machine_state ___vms = vm;
  ___VOLATILE ___WORD *workers_count = &vm->mem.scan_workers_count_[0];
  int i, first = 1;
  (void)___ps;
  (void)___vms;
 continue_local_scan:
  drain_all();
  for (;;)
    {
      if (point == 1 && helper && first) rendezvous(1);
      first = 0;
#include "gc-wait-source.inc"
      goto continue_local_scan;
    }
}

static void *helper_main(void *identity)
{
  helper = 1;
  scan_schedule(___PSTATE_FROM_PROCESSOR_ID((int)(size_t)identity, vm));
  return NULL;
}

static void *publish_main(void *identity)
{
  int id = (int)(size_t)identity;
  publishing = 1;
  end_heap_chunk(___PSTATE_FROM_PROCESSOR_ID(id,vm));
  publishing = 0;
  if (point == 3) scan_schedule(___PSTATE_FROM_PROCESSOR_ID(id,vm));
  return NULL;
}

static void await_stage(int wanted)
{
  assert(pthread_mutex_lock(&gate) == 0);
  while (stage < wanted) assert(pthread_cond_wait(&gate_cv, &gate) == 0);
  assert(pthread_mutex_unlock(&gate) == 0);
}

static void release_stage(int wanted)
{
  assert(pthread_mutex_lock(&gate) == 0);
  allowed = wanted;
  assert(pthread_cond_broadcast(&gate_cv) == 0);
  assert(pthread_mutex_unlock(&gate) == 0);
}

static int queue_pending(int id)
{
  ___processor_state ps = ___PSTATE_FROM_PROCESSOR_ID(id,vm);
  int pending;
  ___SPINLOCK_LOCK(ps->mem.heap_chunks_to_scan_lock_);
  pending = ps->mem.heap_chunks_to_scan_head_ != ps->mem.heap_chunks_to_scan_tail_;
  ___SPINLOCK_UNLOCK(ps->mem.heap_chunks_to_scan_lock_);
  return pending;
}

int main(int argc, char **argv)
{
  pthread_t threads[4];
  int i, pending_at_wait = 0;
  long count_at_wait = 0;
  if (argc != 2 || (point=atoi(argv[1])) < 1 || point > 3) return 2;
  np = point == 3 ? 4 : 2;
  vm = calloc(1, sizeof(*vm));
  assert(vm != NULL);
  vm->processor_count = np;
  assert(___MUTEX_INIT(vm->mem.scan_termination_mutex_));
  assert(___CONDVAR_INIT(vm->mem.scan_termination_condvar_));
  vm->mem.scan_workers_count_[0] = np;
  for (i=0; i<np; i++)
    {
      ___processor_state ps = ___PSTATE_FROM_PROCESSOR_ID(i,vm);
      ps->vmstate = vm;
      ___SPINLOCK_INIT(ps->mem.heap_chunks_to_scan_lock_);
      ps->mem.heap_chunks_to_scan_ = NULL_CHUNK_LINK;
      ps->mem.heap_chunks_to_scan_head_ = &ps->mem.heap_chunks_to_scan_;
      ps->mem.heap_chunks_to_scan_tail_ = &ps->mem.heap_chunks_to_scan_;
      ps->mem.alloc_heap_chunk_start_ = &chunks[i][1];
      ps->mem.alloc_heap_ptr_ = &chunks[i][5];
      ps->mem.scan_ptr_ = &chunks[i][10];
    }
  if (point == 3)
    {
      for (i=2; i<4; i++) assert(pthread_create(&threads[i], NULL, helper_main, (void*)(size_t)i) == 0);
      for (i=0; i<2; i++) assert(pthread_create(&threads[i], NULL, publish_main, (void*)(size_t)i) == 0);
      for (i=0; i<4; i++) assert(pthread_join(threads[i], NULL) == 0);
    }
  else
    {
      assert(pthread_create(&threads[1], NULL, helper_main, (void*)1) == 0);
      await_stage(1);
      assert(pthread_create(&threads[0], NULL, publish_main, NULL) == 0);
      if (point == 1) assert(pthread_join(threads[0], NULL) == 0);
      else
        {
          /* Only force queue visibility, not completion of the M-protected signal. */
          struct timespec begin, now;
          assert(clock_gettime(CLOCK_MONOTONIC, &begin) == 0);
          while (!queue_pending(0))
            {
              assert(clock_gettime(CLOCK_MONOTONIC, &now) == 0);
              assert(now.tv_sec-begin.tv_sec < 2);
              sched_yield();
            }
          if (!PROTECTED_PUBLISHER)
            assert(pthread_join(threads[0], NULL) == 0);
        }
      release_stage(1);
      await_stage(2);
      release_stage(2);
      if (point == 2 && PROTECTED_PUBLISHER) assert(pthread_join(threads[0], NULL) == 0);
      assert(___MUTEX_LOCK(vm->mem.scan_termination_mutex_));
      pending_at_wait = queue_pending(0);
      count_at_wait = vm->mem.scan_workers_count_[0];
      if (point == 1 || atomic_load(&signal_before_wait))
        {
          /* Cleanup after observation; this forced termination never repairs a negative result. */
          vm->mem.scan_workers_count_[0] = 0;
          assert(___CONDVAR_SIGNAL(vm->mem.scan_termination_condvar_));
          assert(___MUTEX_UNLOCK(vm->mem.scan_termination_mutex_));
        }
      else
        {
          assert(___MUTEX_UNLOCK(vm->mem.scan_termination_mutex_));
          scan_schedule(___PSTATE_FROM_PROCESSOR_ID(0,vm));
        }
      assert(pthread_join(threads[1], NULL) == 0);
    }
  printf("{\"point\":%d,\"consumed\":%u,\"signals\":%u,\"waits\":%u,"
         "\"signalBeforeWait\":%s,\"pendingAtWait\":%s,\"countAtWait\":%ld,\"finalCount\":%ld,\"joined\":true}\n",
         point, atomic_load(&consumed), atomic_load(&signals), atomic_load(&waits),
         atomic_load(&signal_before_wait) ? "true" : "false", pending_at_wait ? "true" : "false",
         count_at_wait, (long)vm->mem.scan_workers_count_[0]);
  for (i=0; i<np; i++) ___SPINLOCK_DESTROY(___PSTATE_FROM_PROCESSOR_ID(i,vm)->mem.heap_chunks_to_scan_lock_);
  assert(___CONDVAR_DESTROY(vm->mem.scan_termination_condvar_));
  assert(___MUTEX_DESTROY(vm->mem.scan_termination_mutex_));
  assert(pthread_cond_destroy(&gate_cv) == 0);
  assert(pthread_mutex_destroy(&gate) == 0);
  free(vm);
  return 0;
}
