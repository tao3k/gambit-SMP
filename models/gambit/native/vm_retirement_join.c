/* Actual resize caller, injected join outcome and synchronous population op. */
#include <stdio.h>
#include <stdlib.h>
typedef long ___SCMOBJ;
typedef long ___WORD;
typedef struct processor *___processor_state;
typedef struct vm *___virtual_machine_state;
typedef struct { void (*start_fn)(void); void *data_ptr; long data_scmobj; int id; } ___thread;
struct processor { int id; struct vm *vm; ___thread os_thread; };
struct sections { int nb_sections; };
struct vm {
  int processor_count;
  struct { int target_processor_count_; struct sections *the_msections_;
           int nb_msections_assigned_; } mem;
};
typedef struct { int op; long arg[2]; } ___sync_op_struct;
static struct processor states[2];
static int join_failure, joins, retired_live = 1;
#define ___P(args, old) args
#define ___FIX(x) (x)
#define ___NO_ERR 0
#define ___HEAP_OVERFLOW_ERR 70
#define ___VMSTATE_FROM_PSTATE(ps) ((ps)->vm)
#define ___PROCESSOR_ID(ps, vm) ((ps)->id)
#define ___PSTATE_FROM_PROCESSOR_ID(id, vm) (&states[(id)])
#define ___MIN_NB_MSECTIONS_PER_PROCESSOR 2
#define ___CAST(type, value) ((type)(value))
#define OP_SET_PROCESSOR_COUNT 1
#define BARRIER() ((void)0)
#define ___PSP ___ps,
static int ___garbage_collect_pstate(___processor_state ps, int words) {
  (void)ps; (void)words; return 0;
}
static long ___setup_pstate(___processor_state ps, ___virtual_machine_state vm) {
  (void)ps; (void)vm; return 0;
}
static void ___cleanup_pstate(___processor_state ps) { (void)ps; }
static void barrier_sync_op(___processor_state ps, ___sync_op_struct *op) {
  ps->vm->processor_count = (int)op->arg[0];
}
static void start_processor_execution(void) {}
static int ___thread_create(___thread *thread) { (void)thread; return 0; }
static long ___thread_join(___thread *thread) {
  if (thread->id != 1) abort();
  ++joins;
  if (join_failure) return 42;
  retired_live = 0;
  return 0;
}
static void ___thread_exit(void) { abort(); }
static void ___fatal_error(char **messages) { (void)messages; abort(); }
#include "resize-source.inc"
int main(int argc, char **argv) {
  if (argc != 2) return 2;
  join_failure = atoi(argv[1]);
  if (join_failure != 0 && join_failure != 1) return 2;
  struct sections sections = {100};
  struct vm vm = {2, {2, &sections, 4}};
  for (int i = 0; i < 2; ++i) {
    states[i].id = i; states[i].vm = &vm; states[i].os_thread.id = i;
  }
  long result = ___vm_resize_pstate(&states[0], 0, 1);
  int invalid = joins != 1 || vm.processor_count != 1 ||
    (result == 0 && retired_live);
  printf("{\"result\":%ld,\"published\":%d,\"retiredLive\":%d,\"joins\":%d,\"invalid\":%d}\n",
         result, vm.processor_count, retired_live, joins, invalid);
  return invalid ? 1 : 0;
}
