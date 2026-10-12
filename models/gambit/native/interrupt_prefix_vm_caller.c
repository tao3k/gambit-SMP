/* Actual VM constructor; injected callees model retained resource contracts. */
#include <stdio.h>
#include <string.h>
typedef int ___SCMOBJ;
typedef int ___BOOL;
typedef struct processor {
  int memory_live, procedural_interrupts_ready, interrupt_live;
  int sync_resources_ready, sync_live;
} processor;
typedef struct vm {
  int processor_count;
  struct { int target_processor_count_; } mem;
  int log_live, os_live, memory_live, failure;
  processor slots[2];
} *___virtual_machine_state;
typedef processor *___processor_state;
static struct { struct vm vmstate0; } global;
static int invalid;
#define ___GSTATE (&global)
#define ___P(args, old) args
#define ___EXP_FUNC(type, name) type name
#define ___FIX(value) (value)
#define ___NO_ERR 0
#define ___MAX_PROCESSORS 2
#define ___PSTATE_FROM_PROCESSOR_ID(id, vm) (&(vm)->slots[id])
static void setup_vm_scmobj_vmstate(___virtual_machine_state vm) {
  if (vm->processor_count || vm->mem.target_processor_count_ != 1) ++invalid;
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
  if (!vm->memory_live || vm->processor_count) ++invalid;
  if (vm == &global.vmstate0) {
    if (!ps->procedural_interrupts_ready || !ps->interrupt_live) ++invalid;
  } else {
    if (ps->procedural_interrupts_ready || ps->interrupt_live) ++invalid;
    ps->procedural_interrupts_ready = ps->interrupt_live = 1;
  }
  if (vm->failure == 3) return 3;
  ps->memory_live = 1;
#ifndef ___SINGLE_THREADED_VMS
  ps->sync_resources_ready = ps->sync_live = 1;
#endif
  return 0;
}
static int ___publish_mem_vmstate(___virtual_machine_state vm) {
  if (!vm->slots[0].memory_live || vm->processor_count) ++invalid;
  if (vm->failure == 4) return 4;
  vm->processor_count = 1;
  return 0;
}
static void cleanup_sync_op_pstate(___processor_state ps) {
  if (!ps->sync_resources_ready || !ps->sync_live) ++invalid;
  ps->sync_resources_ready = ps->sync_live = 0;
}
static void cleanup_interrupt_resources_pstate(___processor_state ps) {
  if (ps->procedural_interrupts_ready) {
    if (!ps->interrupt_live) ++invalid;
    ps->procedural_interrupts_ready = ps->interrupt_live = 0;
  }
}
static void cleanup_failed_pstate(___processor_state ps, ___virtual_machine_state vm,
                                  ___BOOL os_mem_ready) {
  (void)vm;
  if (!os_mem_ready || !ps->memory_live || ps->sync_live) ++invalid;
  ps->memory_live = 0;
}
static void ___abort_mem_vmstate(___virtual_machine_state vm) {
  if (!vm->memory_live || vm->slots[0].memory_live || vm->processor_count) ++invalid;
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
      if (!context)
        vm->slots[0].procedural_interrupts_ready = vm->slots[0].interrupt_live = 1;
      int result = ___setup_vmstate(vm);
      if (result != failure) ++invalid;
      if (!context && (!vm->slots[0].procedural_interrupts_ready ||
                       !vm->slots[0].interrupt_live)) ++invalid;
      if (failure) {
        if (vm->processor_count || vm->log_live || vm->os_live || vm->memory_live ||
            vm->slots[0].memory_live || vm->slots[0].sync_live) ++invalid;
        if (context && (vm->slots[0].procedural_interrupts_ready ||
                        vm->slots[0].interrupt_live)) ++invalid;
      } else if (vm->processor_count != 1 || !vm->slots[0].memory_live ||
                 !vm->memory_live || !vm->log_live || !vm->os_live ||
                 !vm->slots[0].procedural_interrupts_ready) ++invalid;
      ++checks;
    }
  }
  printf("{\"checks\":%d,\"invalid\":%d}\n", checks, invalid);
  return invalid ? 1 : 0;
}
