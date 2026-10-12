#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <sched.h>
#include <unistd.h>
typedef long ___SCMOBJ;
typedef int ___BOOL;
typedef struct { int op; ___SCMOBJ arg[2]; } ___sync_op_struct;
typedef struct processor {
  int id;
  volatile int sync_id0, sync_id1, sync_id2;
  ___sync_op_struct sync_op0, sync_op1, sync_op2;
  pthread_mutex_t sync_mut;
  pthread_cond_t sync_cv;
  struct { pthread_mutex_t lock; int heap_chunks_to_scan_lock_ready_; } mem;
  int intr_flag[1];
} *___processor_state;
typedef struct { int processor_count; struct processor *processors; } *___virtual_machine_state;
static struct { int processor_count; struct processor *processors; } vm;
static struct { int setup_state; } global;
static atomic_int *users;
static atomic_int completed, started;
#define ___GSTATE (&global)
#define ___P(args, old) args
#define ___PSD ___processor_state ___ps,
#define ___PSV ___ps,
#define ___PSDKR
#define ___PSGET
#define ___PSP ___ps,
#define ___HIDDEN static
#define ___VMSTATE_FROM_PSTATE(ps) ((___virtual_machine_state)&vm)
#define ___PROCESSOR_ID(ps, vms) ((ps)->id)
#define ___PSTATE_FROM_PROCESSOR_ID(id, vms) (&(vms)->processors[id])
#define ___FIX(value) (value)
#define ___NO_ERR 0
#define ___INTR_SYNC_OP 0
#define ___ACTLOG_BEGIN_PS(a, b)
#define ___ACTLOG_END_PS()
#define ___CPU_RELAX() sched_yield()
#define ___SHARED_MEMORY_BARRIER() __sync_synchronize()
#define ___MUTEX_LOCK(lock) pthread_mutex_lock(&(lock))
#define ___MUTEX_UNLOCK(lock) pthread_mutex_unlock(&(lock))
#define ___CONDVAR_WAIT(cond, lock) pthread_cond_wait(&(cond), &(lock))
#define ___CONDVAR_SIGNAL(cond) pthread_cond_signal(&(cond))
#define heap_chunks_to_scan_lock ___ps->mem.lock
static void die(void) { puts("scan_barrier_quiescence invalid=1"); exit(1); }
static void destroy_scan_lock(___processor_state ps) {
  if (atomic_load(&users[ps->id]) || pthread_mutex_destroy(&ps->mem.lock)) die();
}
#define ___SPINLOCK_DESTROY(lock) destroy_scan_lock(___ps)
static void free_still_objs(___processor_state ps) { (void)ps; }
static void cleanup_rc(___processor_state ps) { (void)ps; }
#include "scan-cleanup.inc"
#include "sync-tree.inc"
static void ___throw_error(___processor_state ps, ___SCMOBJ err) { (void)ps; (void)err; die(); }
static void execute_sync_op(___processor_state ps, ___sync_op_struct *op) {
  if (op->op == OP_GARBAGE_COLLECT) {
    int peer = (ps->id + 1) % vm.processor_count;
    pthread_mutex_lock(&vm.processors[peer].mem.lock);
    atomic_fetch_add(&users[peer], 1);
    atomic_fetch_add(&started, 1);
    if (ps->id == 0) {
      while (atomic_load(&started) < vm.processor_count) sched_yield();
#ifdef NEGATIVE_SKIP_QUIESCENCE
      ___cleanup_mem_pstate(&vm.processors[1]);
      die();
#endif
    } else {
      while (atomic_load(&started) < vm.processor_count) sched_yield();
      for (int i = 0; i < 1000; ++i) sched_yield();
    }
    atomic_fetch_sub(&users[peer], 1);
    pthread_mutex_unlock(&vm.processors[peer].mem.lock);
    atomic_fetch_add(&completed, 1);
  } else if (op->op == OP_VM_RESIZE) {
    if (atomic_load(&completed) != vm.processor_count) die();
    for (int i = 0; i < vm.processor_count; ++i)
      if (atomic_load(&users[i])) die();
    ___cleanup_mem_pstate(ps);
    ___cleanup_mem_pstate(ps);
    if (ps->mem.heap_chunks_to_scan_lock_ready_) die();
  } else die();
}
#include "sync-loop.inc"
static void *run(void *arg) {
  ___processor_state ps = arg;
  ___sync_op_struct gc = { .op = OP_GARBAGE_COLLECT, .arg = {1, 0} };
  ___sync_op_struct retire = { .op = OP_VM_RESIZE, .arg = {0, 0} };
  execute_sync_op_loop(ps, &gc, 1);
  execute_sync_op_loop(ps, &retire, 1);
  return NULL;
}
int main(void) {
  long capacity = sysconf(_SC_NPROCESSORS_ONLN);
  pthread_t *threads;
  if (capacity < 2 || capacity > 65536) return 2;
  vm.processor_count = (int)capacity;
  vm.processors = calloc((size_t)capacity, sizeof(*vm.processors));
  users = calloc((size_t)capacity, sizeof(*users));
  threads = calloc((size_t)capacity, sizeof(*threads));
  if (!vm.processors || !users || !threads) return 2;
  for (int i = 0; i < capacity; ++i) {
    struct processor *ps = &vm.processors[i];
    ps->id = i;
    ps->sync_id0 = ps->sync_id1 = ps->sync_id2 = SYNC_WAITING;
    if (pthread_mutex_init(&ps->sync_mut, NULL) || pthread_cond_init(&ps->sync_cv, NULL) ||
        pthread_mutex_init(&ps->mem.lock, NULL)) return 2;
    ps->mem.heap_chunks_to_scan_lock_ready_ = 1;
  }
  for (int i = 0; i < capacity; ++i)
    if (pthread_create(&threads[i], NULL, run, &vm.processors[i])) return 2;
  for (int i = 0; i < capacity; ++i)
    if (pthread_join(threads[i], NULL)) return 2;
  for (int i = 0; i < capacity; ++i) {
    if (atomic_load(&users[i])) die();
    if (pthread_cond_destroy(&vm.processors[i].sync_cv) ||
        pthread_mutex_destroy(&vm.processors[i].sync_mut)) return 2;
  }
  free(threads); free(users); free(vm.processors);
  puts("scan_barrier_quiescence invalid=0");
  return 0;
}
