#include <stdio.h>
#include <stdlib.h>

typedef long ___SCMOBJ;
typedef struct processor { int unused; } *___processor_state;
typedef struct vm {
  int processor_count;
  struct processor processor;
} *___virtual_machine_state;
static struct {
  int setup_state;
  struct vm vmstate0;
} state;

#define ___GSTATE (&state)
#define ___PSTATE (&state.vmstate0.processor)
#define ___EXP_FUNC(result,name) result name
#define ___PVOID (void)
#define ___PSP
#define ___FAL 0
#define ___SINGLE_VM
#define ___PSTATE_FROM_PROCESSOR_ID(i,vms) (&(vms)->processor)

static int injected_error;
static int resize_calls;
static int global_releases;
static int unsafe_releases;
static int unjoined;

static void ___cleanup_all_interrupt_handling(void) {}
static void cleanup_interrupt_resources_pstate(___processor_state ps) { (void)ps; }
static void cleanup_os_and_mem(void) { global_releases++; }
static ___SCMOBJ ___current_vm_resize(___SCMOBJ thunk, int target) {
  (void)thunk;
  if (target != 1) abort();
  resize_calls++;
  state.vmstate0.processor_count = 1;
  unjoined = injected_error != 0;
  return injected_error;
}
static void ___cleanup_pstate(___processor_state ps) {
  (void)ps;
  if (unjoined) unsafe_releases++;
}
static void ___cleanup_vmstate(___virtual_machine_state vm) {
  (void)vm;
  if (unjoined) unsafe_releases++;
}

// This include is the exact locked ___cleanup definition, not a rewritten body.
#include "cleanup-source.inc"

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  injected_error = atoi(argv[1]);
  state.setup_state = 1;
  state.vmstate0.processor_count = 2;
  ___cleanup();
  printf("{\"resizeError\":%d,\"resizeCalls\":%d,\"unjoined\":%d,"
         "\"unsafeReleases\":%d,\"setupState\":%d}\n",
         injected_error, resize_calls, unjoined, unsafe_releases, state.setup_state);
  return 0;
}
