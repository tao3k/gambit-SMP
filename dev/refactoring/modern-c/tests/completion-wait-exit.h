#ifndef GAMBIT_TEST_COMPLETION_WAIT_EXIT_H
#define GAMBIT_TEST_COMPLETION_WAIT_EXIT_H

/* DEV coordination only; every allocation, cleanup, join and scan uses the
 * existing runtime. No root/domain ownership field is changed by this probe. */
#include "lifecycle.h"
#include "rc.h"
#include <stdlib.h>
extern void ___thread_set_pstate(___processor_state);
static struct {
  void *source, *target;
  ___virtual_machine_state vm;
  unsigned stage;
} wait_exit_source;

static int wait_exit_create(___processor_state ps)
{
  ___SCMOBJ value;
  if (___PROCESSOR_ID(ps,___VMSTATE_FROM_PSTATE(ps)) != 2 ||
      wait_exit_source.source || wait_exit_source.target) return 0;
  wait_exit_source.vm = ___VMSTATE_FROM_PSTATE(ps);
  wait_exit_source.source = ___alloc_rc(___PSA(ps) 0);
  if (!wait_exit_source.source) return 0;
  value = ___make_vector(ps,7,___FIX(113));
  if (___FIXNUMP(value)) return 0;
  if (!___try_set_data_rc(ps,wait_exit_source.source,value)) return 0;
  ___release_scmobj(value);
  wait_exit_source.stage = 1;
  return 1;
}
static int wait_exit_install(___processor_state ps)
{
  if (___PROCESSOR_ID(ps,wait_exit_source.vm) != 0 ||
      wait_exit_source.stage != 1) return 0;
  wait_exit_source.target = ___alloc_rc(___PSA(ps) 0);
  if (!wait_exit_source.target ||
      !___try_set_data_rc(ps,wait_exit_source.target,
                        ___data_rc(wait_exit_source.source))) return 0;
  wait_exit_source.stage = 2;
  return 1;
}
static int wait_exit_ack(___processor_state ps)
{
  if (___PROCESSOR_ID(ps,wait_exit_source.vm) != 2 ||
      wait_exit_source.stage != 2 ||
      ___data_rc(wait_exit_source.source) != ___data_rc(wait_exit_source.target) ||
      !___try_set_data_rc(ps,wait_exit_source.source,___FAL)) return 0;
  wait_exit_source.stage = 3;
  return 1;
}
static int wait_exit_stopped(void)
{
  ___rc_header *h;
  if (wait_exit_source.stage != 3 ||
      wait_exit_source.vm->processor_count != 2 ||
      !wait_exit_source.vm->lifecycle->launches[2].joined ||
      wait_exit_source.vm->lifecycle->launches[2].native_live ||
      wait_exit_source.vm->lifecycle->launches[2].uncertain ||
      !___WORD_LOAD_ACQUIRE(&wait_exit_source.vm->lifecycle->launches[2].data_closed))
    return 0;
  h = (___rc_header *)wait_exit_source.source - 1;
  if (!h->domain || h->domain->phase != ___RC_DETACHED ||
      h->domain->owner || h->data != ___FAL ||
      ___PSTATE_FROM_PROCESSOR_ID(2,wait_exit_source.vm)->mem.rc_domain_) return 0;
  ___release_rc(wait_exit_source.source);
  wait_exit_source.source = NULL;
  wait_exit_source.stage = 4;
  return 1;
}
static int wait_exit_finish(void)
{
  if (wait_exit_source.stage != 4 || !wait_exit_source.target) return 0;
  ___release_rc(wait_exit_source.target);
  wait_exit_source.target = NULL;
  wait_exit_source.stage = 5;
  return 1;
}

static struct {
  ___virtual_machine_state vm;
  void *root;
  unsigned releases, stage;
} wait_exit_vm;
static ___SCMOBJ wait_exit_release(void *payload)
{
  if (payload != &wait_exit_vm) return ___FIX(___UNKNOWN_ERR);
  ++wait_exit_vm.releases;
  return ___FIX(___NO_ERR);
}
static int wait_exit_vm_begin(___processor_state primary)
{
#ifdef ___SINGLE_VM
  return -1;
#else
  ___processor_state owner;
  ___SCMOBJ value;
  const ___SCMOBJ *borrow;
  int ok = 0;
  if (wait_exit_vm.vm) return 0;
  wait_exit_vm.vm = calloc(1,sizeof(*wait_exit_vm.vm));
  if (!wait_exit_vm.vm ||
      ___setup_vmstate(wait_exit_vm.vm) != ___FIX(___NO_ERR)) return 0;
  owner = ___PSTATE_FROM_PROCESSOR_ID(0,wait_exit_vm.vm);
  ___thread_set_pstate(owner);
  wait_exit_vm.root = ___alloc_rc(___PSA(owner) 0);
  if (!wait_exit_vm.root ||
      ___POINTER_to_SCMOBJ(owner,&wait_exit_vm,___FAL,wait_exit_release,&value,0)
        != ___FIX(___NO_ERR) ||
      !___try_set_data_rc(owner,wait_exit_vm.root,value)) goto done;
  borrow = ___borrow_rc_root(owner,wait_exit_vm.root);
  if (!borrow) goto done;
  if (___cleanup_vmstate(wait_exit_vm.vm)) goto done;
  ___return_rc_root(wait_exit_vm.root);
  /* A nonempty payload alone also refuses destruction. It never leaves this VM. */
  if (___cleanup_vmstate(wait_exit_vm.vm) ||
      wait_exit_vm.vm->lifecycle->phase != ___VM_LIVE) goto done;
  wait_exit_vm.stage = 1;
  ok = 1;
done:
  ___thread_set_pstate(primary);
  return ok;
#endif
}
static int wait_exit_vm_finish(___processor_state primary)
{
#ifdef ___SINGLE_VM
  return -1;
#else
  ___processor_state owner;
  int ok = 0;
  if (wait_exit_vm.stage != 1 || !wait_exit_vm.vm) return 0;
  owner = ___PSTATE_FROM_PROCESSOR_ID(0,wait_exit_vm.vm);
  ___thread_set_pstate(owner);
  if (!___try_set_data_rc(owner,wait_exit_vm.root,___FAL)) goto done;
  ___release_rc(wait_exit_vm.root);
  wait_exit_vm.root = NULL;
  if (!___cleanup_vmstate(wait_exit_vm.vm) || wait_exit_vm.vm->lifecycle ||
      wait_exit_vm.releases != 1 || ___cleanup_vmstate(wait_exit_vm.vm)) goto done;
  free(wait_exit_vm.vm);
  wait_exit_vm.vm = NULL;
  wait_exit_vm.stage = 2;
  ok = 1;
done:
  ___thread_set_pstate(primary);
  return ok;
#endif
}
#endif
