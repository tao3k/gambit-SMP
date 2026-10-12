/* Component schedule only: real POSIX calls, no Gambit VM or body tracing. */
#include "gambit.h"
#include <assert.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>

#if !defined(___USE_POSIX_THREAD_SYSTEM) || defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS)
#error This schedule requires the configured POSIX multiple/threaded-VM header.
#endif
#ifdef __clang__
#error GNU GCC is required.
#endif

static ___virtual_machine_state vm;
static ___processor_state ps;
static pthread_mutex_t gate_mut = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t gate_cv = PTHREAD_COND_INITIALIZER;
static int point, stage, allowed;
static _Thread_local int helper_role, publishing, restore_hook;
static _Atomic unsigned work_signals, wait_calls, wait_errors, nonzero_wakes;
static _Atomic int work_before_wait;

static void rendezvous(int wanted)
{
  assert(pthread_mutex_lock(&gate_mut) == 0);
  stage = wanted;
  assert(pthread_cond_broadcast(&gate_cv) == 0);
  while (allowed < wanted)
    assert(pthread_cond_wait(&gate_cv, &gate_mut) == 0);
  assert(pthread_mutex_unlock(&gate_mut) == 0);
}

static int observed_wait(pthread_cond_t *cv, pthread_mutex_t *mut)
{
  if (cv != &vm->mem.scan_termination_condvar_)
    return pthread_cond_wait(cv, mut);
  unsigned call = atomic_fetch_add(&wait_calls, 1);
  if (helper_role && call == 0)
    {
      if (point == 2 || point == 3) rendezvous(1);
      /* The work signal is forced before this actual wait call, independent
         of any later spurious wake or final termination notification. */
      atomic_store(&work_before_wait, atomic_load(&work_signals) == 1);
      rendezvous(2);
    }
  int error = pthread_cond_wait(cv, mut);
  if (error != 0) atomic_fetch_add(&wait_errors, 1);
  if (helper_role && error == 0 && vm->mem.scan_workers_count_[0] != 0)
    atomic_fetch_add(&nonzero_wakes, 1);
  return error;
}

static int observed_signal(pthread_cond_t *cv)
{
  if (publishing) atomic_fetch_add(&work_signals, 1);
  return pthread_cond_signal(cv);
}

#define pthread_cond_wait observed_wait
#define pthread_cond_signal observed_signal
#undef ___ACTLOG_BEGIN_PS
#undef ___ACTLOG_END_PS
#define ___ACTLOG_BEGIN_PS(a,b) ((void)0)
#define ___ACTLOG_END_PS() ((void)0)
#include "gc-publish-source.inc"

/* Only queue metadata is consumed; no object payloads are traced here. */
static void drain_queue(___processor_state ___ps)
{
  ___SPINLOCK_LOCK(heap_chunks_to_scan_lock);
  ___SHARED_MEMORY_BARRIER();
  heap_chunks_to_scan_head = heap_chunks_to_scan_tail;
  ___SHARED_MEMORY_BARRIER();
  ___SPINLOCK_UNLOCK(heap_chunks_to_scan_lock);
}

static void scan_schedule(___processor_state ___ps)
{
  ___VOLATILE ___WORD *workers_count = &vm->mem.scan_workers_count_[0];
  int np = 2, i;
  for (;;)
    {
      if (helper_role && point == 1 && atomic_load(&wait_calls) == 0) rendezvous(1);
      else drain_queue(___ps);
#include "gc-wait-source.inc"
      if (helper_role && point == 3 && !restore_hook && atomic_load(&nonzero_wakes) > 0)
        {
          restore_hook = 1;
          rendezvous(3);
        }
    }
}

static void *helper_main(void *unused)
{
  (void)unused;
  helper_role = 1;
  scan_schedule(ps);
  return NULL;
}

static void await_stage(int wanted)
{
  assert(pthread_mutex_lock(&gate_mut) == 0);
  while (stage < wanted) assert(pthread_cond_wait(&gate_cv, &gate_mut) == 0);
  assert(pthread_mutex_unlock(&gate_mut) == 0);
}

static void release_stage(int wanted)
{
  assert(pthread_mutex_lock(&gate_mut) == 0);
  allowed = wanted;
  assert(pthread_cond_broadcast(&gate_cv) == 0);
  assert(pthread_mutex_unlock(&gate_mut) == 0);
}

int main(int argc, char **argv)
{
  pthread_t helper;
  ___WORD chunk[12] = {0};
  long restored_count = 0;
  if (argc != 2 || ((point = atoi(argv[1])) < 1 || point > 3)) return 2;
  vm = calloc(1, sizeof(*vm));
  assert(vm != NULL);
  ps = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
  ps->vmstate = vm;
  assert(___MUTEX_INIT(vm->mem.scan_termination_mutex_));
  assert(___CONDVAR_INIT(vm->mem.scan_termination_condvar_));
  ___SPINLOCK_INIT(ps->mem.heap_chunks_to_scan_lock_);
  ps->mem.heap_chunks_to_scan_ = NULL_CHUNK_LINK;
  ps->mem.heap_chunks_to_scan_head_ = &ps->mem.heap_chunks_to_scan_;
  ps->mem.heap_chunks_to_scan_tail_ = &ps->mem.heap_chunks_to_scan_;
  ps->mem.alloc_heap_chunk_start_ = &chunk[1];
  ps->mem.alloc_heap_ptr_ = &chunk[5];
  ps->mem.scan_ptr_ = &chunk[10];
  vm->mem.scan_workers_count_[0] = 2;
  assert(pthread_create(&helper, NULL, helper_main, NULL) == 0);
  await_stage(1);
  if (point != 3)
    {
      publishing = 1;
      end_heap_chunk(ps);
      publishing = 0;
    }
  release_stage(1);
  await_stage(2);
  release_stage(2);
  /* Acquisition blocks until the helper's actual wait registers and releases
     this mutex. Drain before the root's unchanged final count decrement. */
  assert(___MUTEX_LOCK(vm->mem.scan_termination_mutex_));
  if (point == 3)
    {
      publishing = 1;
      end_heap_chunk(ps);
      publishing = 0;
    }
  assert(___MUTEX_UNLOCK(vm->mem.scan_termination_mutex_));
  if (point == 3)
    {
      await_stage(3);
      assert(___MUTEX_LOCK(vm->mem.scan_termination_mutex_));
      restored_count = vm->mem.scan_workers_count_[0];
      assert(___MUTEX_UNLOCK(vm->mem.scan_termination_mutex_));
      release_stage(3);
    }
  drain_queue(ps);
  scan_schedule(ps);
  assert(pthread_join(helper, NULL) == 0);
  printf("{\"point\":%d,\"count\":%ld,\"queueEmpty\":%s,\"joined\":true,"
         "\"workSignalBeforeWait\":%s,\"workSignals\":%u,\"waitCalls\":%u,\"waitErrors\":%u,"
         "\"nonzeroWakeups\":%u,\"restoredCount\":%ld}\n",
         point, (long)vm->mem.scan_workers_count_[0],
         ps->mem.heap_chunks_to_scan_head_ == ps->mem.heap_chunks_to_scan_tail_ ? "true" : "false",
         atomic_load(&work_before_wait) ? "true" : "false", atomic_load(&work_signals),
         atomic_load(&wait_calls), atomic_load(&wait_errors), atomic_load(&nonzero_wakes), restored_count);
  ___SPINLOCK_DESTROY(ps->mem.heap_chunks_to_scan_lock_);
  assert(___CONDVAR_DESTROY(vm->mem.scan_termination_condvar_));
  assert(___MUTEX_DESTROY(vm->mem.scan_termination_mutex_));
  assert(pthread_cond_destroy(&gate_cv) == 0);
  assert(pthread_mutex_destroy(&gate_mut) == 0);
  free(vm);
  return 0;
}
