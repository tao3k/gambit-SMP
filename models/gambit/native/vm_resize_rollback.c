/* Source-function unit: stubs inject setup failure, not a complete runtime. */
#include <stdio.h>
#include <stdlib.h>
typedef long ___SCMOBJ;
typedef long ___WORD;
typedef struct processor *___processor_state;
typedef struct vm *___virtual_machine_state;
typedef struct { void (*start_fn)(void); void *data_ptr; long data_scmobj; } ___thread;
struct processor { int id; struct vm *vm; ___thread os_thread; };
struct sections { int nb_sections; };
struct vm {
  int processor_count;
  struct { int target_processor_count_; struct sections *the_msections_;
           int nb_msections_assigned_; } mem;
};
typedef struct { int op; long arg[2]; } ___sync_op_struct;
static struct processor states[4];
static int failure, prepared, bad_cleanup;
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
static int ___garbage_collect_pstate(___processor_state ps, int words) { (void)ps; (void)words; return 0; }
static long ___setup_pstate(___processor_state ps, ___virtual_machine_state vm) {
  (void)vm;
  if (ps->id == failure) return 42;
  prepared |= 1 << ps->id;
  return 0;
}
static void ___cleanup_pstate(___processor_state ps) {
  printf("CLEANUP %d\n", ps->id);
  if (!(prepared & (1 << ps->id))) ++bad_cleanup;
  prepared &= ~(1 << ps->id);
}
static void barrier_sync_op(___processor_state ps, ___sync_op_struct *op) {
  ps->vm->processor_count = (int)op->arg[0];
}
static void start_processor_execution(void) {}
static int ___thread_create(___thread *thread) { (void)thread; return 0; }
static void ___thread_join(___thread *thread) { (void)thread; }
static void ___thread_exit(void) { abort(); }
static void ___fatal_error(char **messages) { (void)messages; abort(); }
#include "resize-source.inc"
int main(int argc, char **argv) {
  if (argc != 2) return 2;
  failure = atoi(argv[1]);
  struct sections sections = {100};
  struct vm vm = {1, {1, &sections, 2}};
  prepared = 1;
  for (int i = 0; i < 4; ++i) { states[i].id = i; states[i].vm = &vm; }
  long result = ___vm_resize_pstate(&states[0], 0, 4);
  printf("RESULT %ld PREPARED %d ACTIVE %d TARGET %d INVALID %d\n",
         result, prepared, vm.processor_count, vm.mem.target_processor_count_, bad_cleanup);
  int ok = failure == 0
    ? result == 0 && prepared == 15 && vm.processor_count == 4 && vm.mem.target_processor_count_ == 4
    : result == 42 && prepared == 1 && vm.processor_count == 1 && vm.mem.target_processor_count_ == 1;
  if (!ok || bad_cleanup) return 1;
  puts("SOURCE-UNIT-OK");
  return 0;
}
