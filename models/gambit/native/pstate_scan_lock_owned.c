/* Actual locked memory setup/cleanup bodies, with returning primitive contracts. */
#include <stdio.h>
#include <string.h>
typedef int ___SCMOBJ;
typedef int ___BOOL;
typedef long ___WORD;
typedef void ___msection;
typedef struct processor {
  struct {
    int heap_chunks_to_scan_lock_ready_, tospace_offset_;
    struct { int initialized, live; } lock;
  } mem;
  ___WORD *stack_start, *stack_break;
} *___processor_state;
typedef struct vm { struct processor p0; } *___virtual_machine_state;
static struct vm vm;
static int fail_log, fail_lock, invalid, log_live, prepare_calls, destroy_calls;
static ___WORD stack[16], *alloc_stack_start, *alloc_stack_ptr, *alloc_heap_start, *alloc_heap_ptr;
static long msection_free_list, words_prev_msections, stack_msection, heap_msection;
static long still_objs, words_still_objs, words_still_objs_deferred;
static double bytes_allocated_minus_occupied;
static long nonexecutable_wills, executable_wills;
static int tospace_offset;
#define ___P(args, old) args
#define ___FIX(x) (x)
#define ___NO_ERR 0
#define ___UNKNOWN_ERR -1
#define ___VMSTATE_FROM_PSTATE(ps) (&vm)
#define ___PSTATE_FROM_PROCESSOR_ID(id, vms) (&(vms)->p0)
#define ___CAST(type, value) ((type)(value))
#define ___TAG(a, b) ((a) + (b))
#define ___EXECUTABLE_WILL 1
#define ___FIRST_BREAK_FRAME_SPACE 1
#define ___BREAK_FRAME_NEXT 0
#define ___FIRST_BREAK_FRAME_STACK_MSECTION 1
#define ___END_OF_CONT_MARKER 0
#define ___FP_ADJFP(ptr, count) ((ptr) += (count));
#define ___FP_SET_STK(ptr, offset, value) ((void)(ptr), (void)(offset), (void)(value));
#define heap_chunks_to_scan_lock ___ps->mem.lock
static int setup_log(___processor_state ps) {
  (void)ps;
  if (fail_log) return -2;
  if (log_live) ++invalid;
  log_live = 1;
  return 0;
}
static void cleanup_log(___processor_state ps) {
  (void)ps;
  if (!log_live) ++invalid;
  log_live = 0;
}
#define ___setup_actlog_pstate setup_log
#define ___cleanup_actlog_pstate cleanup_log
static int initialize_lock(___processor_state ps, int can_fail, int os_resource) {
  if (ps->mem.lock.initialized) ++invalid;
  if (can_fail && fail_lock) return 0;
  ps->mem.lock.initialized = 1;
  ps->mem.lock.live = os_resource;
  return 1;
}
static void destroy_lock(___processor_state ps) {
  ++destroy_calls;
  if (!ps->mem.lock.initialized) ++invalid;
  ps->mem.lock.initialized = ps->mem.lock.live = 0;
}
#if defined(MODE_MUTEX)
#define ___USE_POSIX_THREAD_SYSTEM
#define ___USE_MUTEX_FOR_SPINLOCK
#define ___SPINLOCK_INIT(lock) initialize_lock(___ps, 1, 1)
#elif defined(MODE_VOID)
static void initialize_void(___processor_state ps) { (void)initialize_lock(ps, 0, 1); }
#define ___USE_MUTEX_FOR_SPINLOCK
#define ___SPINLOCK_INIT(lock) initialize_void(___ps)
#else
#define ___USE_POSIX_THREAD_SYSTEM
#define ___SPINLOCK_INIT(lock) initialize_lock(___ps, 0, 0)
#endif
#define ___SPINLOCK_DESTROY(lock) destroy_lock(___ps)
static void next_stack_msection(___processor_state ps) { (void)ps; alloc_stack_start = stack; }
static void next_heap_msection(___processor_state ps) { (void)ps; alloc_heap_start = stack; }
static void setup_rc(___processor_state ps) { (void)ps; }
static void free_still_objs(___processor_state ps) { (void)ps; }
static void cleanup_rc(___processor_state ps) { (void)ps; }
static void prepare_mem_pstate(___processor_state ps) {
  ++prepare_calls;
#ifndef ___SINGLE_THREADED_VMS
  if (!ps->mem.lock.initialized) ++invalid;
#else
  (void)ps;
#endif
}
#include "pstate-memory-setup.inc"
#include "pstate-memory-cleanup.inc"
int main(void) {
  int checks = 0;
  for (fail_log = 0; fail_log <= 1; ++fail_log)
    for (fail_lock = 0; fail_lock <= 1; ++fail_lock) {
      int generation;
      memset(&vm, 0, sizeof(vm));
      log_live = 0;
      for (generation = 0; generation < 2; ++generation) {
        int expected = fail_log ? -2 : 0;
        int before = destroy_calls;
        ___SCMOBJ result;
        prepare_calls = 0;
#if defined(MODE_MUTEX) && !defined(___SINGLE_THREADED_VMS)
        if (!fail_log && fail_lock) expected = -1;
#endif
        result = ___setup_mem_pstate(&vm.p0);
        if (result != expected) ++invalid;
        if (expected) {
          if (log_live || prepare_calls || vm.p0.mem.lock.live ||
              vm.p0.mem.heap_chunks_to_scan_lock_ready_ || destroy_calls != before) ++invalid;
        } else {
          if (!log_live || prepare_calls != 1) ++invalid;
          /* The projected callees do not prove the real caller's quiescence. */
          ___cleanup_mem_pstate(&vm.p0);
          ___cleanup_mem_pstate(&vm.p0);
#ifndef ___SINGLE_THREADED_VMS
          if (destroy_calls != before + 1 || vm.p0.mem.lock.initialized ||
              vm.p0.mem.lock.live || vm.p0.mem.heap_chunks_to_scan_lock_ready_) ++invalid;
#else
          if (destroy_calls != before) ++invalid;
#endif
          cleanup_log(&vm.p0);
        }
        ++checks;
      }
    }
  printf("pstate_scan_lock_owned checks=%d invalid=%d\n", checks, invalid != 0);
  return invalid ? 1 : 0;
}
