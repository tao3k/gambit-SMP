/* Actual VM caller; resource primitives and P0 callee are failure-injected. */
#include <stdio.h>
#include <string.h>
typedef int ___SCMOBJ;
typedef int ___BOOL;
typedef struct resource { int live; } resource;
typedef struct processor {
  int memory_live, owned_interrupt;
  resource sync_cv, sync_mut;
} processor;
typedef struct vm {
  int processor_count;
  struct { int target_processor_count_; } mem;
  int log_live, os_live, memory_live, failure;
  processor p0;
} *___virtual_machine_state;
typedef processor *___processor_state;
static struct { struct vm vmstate0; } global;
static int invalid;
#define ___GSTATE (&global)
#define ___P(args, old) args
#define ___EXP_FUNC(type, name) type name
#define ___FIX(value) (value)
#define ___NO_ERR 0
#define ___PSTATE_FROM_PROCESSOR_ID(id, vm) (&(vm)->p0)
static void release(resource *r) {
  if (!r->live) ++invalid;
  r->live = 0;
}
#define ___CONDVAR_DESTROY(r) release(&(r))
#define ___MUTEX_DESTROY(r) release(&(r))
static void setup_vm_scmobj_vmstate(___virtual_machine_state vm) {
  if (vm->processor_count != 0 || vm->mem.target_processor_count_ != 1) ++invalid;
}
static int ___setup_actlog_vmstate(___virtual_machine_state vm) {
  if (vm->failure == 1) return 1;
  vm->log_live = 1;
  return 0;
}
static void ___abort_actlog_vmstate(___virtual_machine_state vm) {
  if (!vm->log_live || vm->memory_live || vm->os_live) ++invalid;
  vm->log_live = 0;
}
static int setup_os_and_mem_vmstate(___virtual_machine_state vm) {
  if (vm->failure == 2) return 2;
  vm->os_live = vm->memory_live = 1;
  return 0;
}
static int ___setup_pstate(___processor_state ps, ___virtual_machine_state vm) {
  if (!vm->memory_live || vm->processor_count != 0) ++invalid;
  if (vm->failure == 3) return 3; /* Callee already unwound its owned prefix. */
  ps->memory_live = 1;
  ps->owned_interrupt = vm != &global.vmstate0;
#ifndef ___SINGLE_THREADED_VMS
  ps->sync_cv.live = ps->sync_mut.live = 1;
#endif
  return 0;
}
static int ___publish_mem_vmstate(___virtual_machine_state vm) {
  if (!vm->p0.memory_live || vm->processor_count != 0) ++invalid;
  if (vm->failure == 4) return 4;
  vm->processor_count = 1;
  return 0;
}
static void cleanup_failed_pstate(___processor_state ps, ___virtual_machine_state vm,
                                  ___BOOL os_mem_ready) {
  if (!os_mem_ready || !ps->memory_live) ++invalid;
#ifndef ___SINGLE_THREADED_VMS
  if (ps->sync_mut.live || ps->sync_cv.live) ++invalid;
#endif
  ps->memory_live = 0;
  if (vm != &global.vmstate0) ps->owned_interrupt = 0;
}
static void ___abort_mem_vmstate(___virtual_machine_state vm) {
  if (!vm->memory_live || vm->p0.memory_live || vm->processor_count != 0) ++invalid;
  vm->memory_live = 0;
}
static void ___cleanup_os_vmstate(___virtual_machine_state vm) {
  if (!vm->os_live || vm->memory_live) ++invalid;
  vm->os_live = 0;
}
#include "vm-constructor-source.inc"
int main(void) {
  int checks = 0;
  struct vm other;
  for (int context = 0; context < 2; ++context) {
    for (int failure = 0; failure < 5; ++failure) {
      struct vm *vm = context ? &other : &global.vmstate0;
      memset(vm, 0, sizeof *vm);
      vm->failure = failure;
      int result = ___setup_vmstate(vm);
      if (result != failure) ++invalid;
      if (failure) {
        if (vm->processor_count || vm->log_live || vm->os_live || vm->memory_live ||
            vm->p0.memory_live || vm->p0.sync_cv.live || vm->p0.sync_mut.live ||
            vm->p0.owned_interrupt) ++invalid;
      } else {
        if (vm->processor_count != 1 || !vm->p0.memory_live || !vm->memory_live ||
            !vm->log_live || !vm->os_live) ++invalid;
      }
      ++checks;
    }
  }
  printf("{\"checks\":%d,\"invalid\":%d}\n", checks, invalid);
  return invalid ? 1 : 0;
}
