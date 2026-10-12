/* Actual field declarations/tree/loop/startup; only resize work is injected. */
#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define ___VOLATILE volatile
typedef long ___SCMOBJ;
typedef int ___BOOL;
typedef struct processor *___processor_state;
typedef struct vm *___virtual_machine_state;
typedef struct { int op; long arg[2]; } ___sync_op_struct;
typedef struct { void *data_ptr; long data_scmobj; } ___thread;
struct processor {
  int id;
  struct vm *vm;
  pthread_mutex_t sync_mut;
  pthread_cond_t sync_cv;
  #include "flag-fields-source.inc"
  long intr_flag[1];
};
struct vm { _Atomic int processor_count; };
static struct processor states[3];
static pthread_t threads[3];
static long results[3];
static int scenario;
static _Thread_local int iteration;
static _Atomic int bodies, launched;
static _Atomic int reads, writes;
static _Atomic int bad_results;
static struct { int setup_state; } global = {2};
#define ___GSTATE (&global)
#define ___MUTEX_DECL(id) pthread_mutex_t id;
#define ___CONDVAR_DECL(id) pthread_cond_t id;
#define ___P(args, old) args
#define ___HIDDEN static
#define ___PSD ___processor_state ___ps,
#define ___PSV ___ps,
#define ___PSDKR
#define ___PSGET
#define ___PSP ___ps,
#define ___FIX(x) (x)
#define ___NO_ERR 0
#define ___CAST(type, value) ((type)(value))
#define ___VMSTATE_FROM_PSTATE(ps) ((ps)->vm)
#define ___PROCESSOR_ID(ps, vm) ((ps)->id)
#define ___PSTATE_FROM_PROCESSOR_ID(id, vm) (&states[(id)])
#define ___CPU_RELAX() ((void)0)
#define ___SHARED_MEMORY_BARRIER() atomic_thread_fence(memory_order_seq_cst)
#define ___MUTEX_LOCK(m) pthread_mutex_lock(&(m))
#define ___MUTEX_UNLOCK(m) pthread_mutex_unlock(&(m))
#define ___CONDVAR_WAIT(c, m) pthread_cond_wait(&(c), &(m))
#define ___CONDVAR_SIGNAL(c) pthread_cond_signal(&(c))
#define ___ACTLOG_BEGIN_PS(a, b) ((void)0)
#define ___ACTLOG_END_PS() ((void)0)
#define ___INTR_SYNC_OP 0
static void ___sync_wait(___processor_state ___ps);
static int tracked_load(volatile int *ptr, int order) {
  atomic_fetch_add(&reads, 1);
  return __atomic_load_n(ptr, order);
}
static void tracked_store(volatile int *ptr, int value, int order) {
  atomic_fetch_add(&writes, 1);
  __atomic_store_n(ptr, value, order);
}
#define __atomic_load_n(ptr, order) tracked_load(ptr, order)
#define __atomic_store_n(ptr, value, order) tracked_store(ptr, value, order)
static void ___throw_error(___processor_state ps, long err) {
  (void)ps; (void)err; abort();
}
#include "tree-source.inc"
static void *startup(void *argument);
static long ___vm_resize_pstate(___processor_state ps, long thunk, long target) {
  (void)thunk;
  int initial = ps->vm->processor_count;
  int failed = scenario == 1 || (scenario == 6 && (iteration & 1));
  ___sync_op_struct op = {OP_NOOP, {0, 0}};
  if (ps->id == 0 && !failed) {
    op.op = OP_SET_PROCESSOR_COUNT;
    op.arg[0] = target;
  }
  barrier_sync_op(ps, &op);
  if (failed) return ps->id == 0 ? 11 : 0;
  if (ps->id >= target) pthread_exit(NULL);
  if (ps->id == 0 && target > initial) {
    if (pthread_create(&threads[2], NULL, startup, &states[2])) abort();
  }
  if (ps->id == 0 && target < initial) {
    if (pthread_join(threads[2], NULL)) abort();
  }
  return 0;
}
static long ___garbage_collect_pstate(___processor_state ps, long words) {
  (void)ps; (void)words; abort();
}
static void ___actlog_start_pstate(___processor_state ps) { (void)ps; }
static void ___actlog_stop_pstate(___processor_state ps) { (void)ps; }
#include "execute-source.inc"
#include "loop-source.inc"
static void ___thread_set_pstate(___processor_state ps) { (void)ps; }
static void ___run_and_throw_error_on_processor_0(___processor_state ps, long thunk) {
  (void)ps; (void)thunk; atomic_fetch_add(&bodies, 1);
}
#include "startup-source.inc"
static void *startup(void *argument) {
  ___thread thread = {argument, 123};
  start_processor_execution(&thread);
  return NULL;
}
static void *old_processor(void *argument) {
  struct processor *ps = argument;
  while (!atomic_load(&launched)) ___CPU_RELAX();
  for (iteration = 0; iteration < (scenario >= 5 ? 1000 : 1); ++iteration) {
    ___sync_op_struct op = {OP_NOOP, {0, 0}};
    if (ps->id == 1) {
      op.op = OP_VM_RESIZE;
      op.arg[0] = 123;
      op.arg[1] = scenario == 3 ? 2 : scenario == 2 ? 3 : 2;
    }
    execute_sync_op_loop(ps, &op, 1);
    results[ps->id] = op.arg[0];
    if (ps->id == 1 && op.arg[0] !=
        (scenario == 1 || (scenario == 6 && (iteration & 1)) ? 11 : 0))
      atomic_fetch_add(&bad_results, 1);
  }
  return NULL;
}
int main(int argc, char **argv) {
  if (argc != 2) return 2;
  scenario = atoi(argv[1]);
  if (scenario < 0 || scenario > 6) return 2;
  struct vm vm = {scenario == 3 ? 3 : 2};
  int initial = vm.processor_count;
  for (int i = 0; i < 3; ++i) {
    states[i].id = i; states[i].vm = &vm;
    states[i].sync_id0 = states[i].sync_id1 = states[i].sync_id2 = -1;
    if (pthread_mutex_init(&states[i].sync_mut, NULL) ||
        pthread_cond_init(&states[i].sync_cv, NULL)) abort();
  }
  if (scenario == 4) {
    ___processor_state ___ps = &states[0];
    int sid;
    states[0].sync_id0 = 17;
#ifdef SYNC_LOAD_MSG
    SYNC_GET_MSG(sid, states[0].sync_id0);
#else
    SYNC_GET_MSG(sid = states[0].sync_id0);
#endif
    SYNC_INIT_MSG(states[0].sync_id0);
    SYNC_SEND_MSG(___ps, sync_id0, 23);
    int invalid = sid != 17 || reads != 1 || writes != 2;
    printf("{\"reads\":%d,\"writes\":%d,\"invalid\":%d}\n",
           (int)reads, (int)writes, invalid);
    return invalid ? 1 : 0;
  }
  for (int i = 0; i < initial; ++i)
    if (pthread_create(&threads[i], NULL, old_processor, &states[i])) abort();
  atomic_store(&launched, 1);
  for (int i = 0; i < 2; ++i)
    if (pthread_join(threads[i], NULL)) abort();
  if (scenario == 2 && pthread_join(threads[2], NULL)) abort();
  int invalid = bad_results || results[1] != (scenario == 1 || scenario == 6 ? 11 : 0) ||
    bodies != (scenario == 2 ? 1 : 0) ||
    vm.processor_count != (scenario == 2 ? 3 : 2);
  printf("{\"result\":%ld,\"population\":%d,\"bodies\":%d,\"invalid\":%d}\n",
         results[1], (int)vm.processor_count, (int)bodies, invalid);
  for (int i = 0; i < 3; ++i) {
    if (pthread_cond_destroy(&states[i].sync_cv) ||
        pthread_mutex_destroy(&states[i].sync_mut)) abort();
  }
  return invalid ? 1 : 0;
}
