___EXP_FUNC(void,___cleanup) ___PVOID
{
  ___processor_state ___ps = ___PSTATE;
  ___virtual_machine_state ___vms = &___GSTATE->vmstate0;

  /*
   * Only do cleanup once after successful setup.
   */

  if (___GSTATE->setup_state != 1)
    return;

  ___GSTATE->setup_state = 2;

  ___cleanup_all_interrupt_handling ();

  if (___vms->processor_count == 0)
    {
      /* VM setup already unwound its private prefix, not this global prefix. */
      cleanup_interrupt_resources_pstate (___PSTATE_FROM_PROCESSOR_ID(0,___vms));
#ifndef ___SINGLE_VM
      ___MUTEX_DESTROY(___GSTATE->vm_list_mut);
#endif
      cleanup_os_and_mem ();
      return;
    }

#ifndef ___SINGLE_THREADED_VMS

  /*
   * Shutdown processors of this VM except for processor 0.
   */

  ___current_vm_resize (___PSP ___FAL, 1);

#endif

  ___cleanup_pstate (___ps);

#ifdef ___SINGLE_VM

  ___cleanup_vmstate (&___GSTATE->vmstate0);

#else

  ___MUTEX_LOCK(___GSTATE->vm_list_mut);

  do
    {
      ___vms = ___vms->prev;
      ___cleanup_vmstate (___vms);
    }
  while (___vms != &___GSTATE->vmstate0);

  ___MUTEX_DESTROY(___GSTATE->vm_list_mut);

#endif

  cleanup_interrupt_resources_pstate (___PSTATE_FROM_PROCESSOR_ID(0,&___GSTATE->vmstate0));
  cleanup_os_and_mem ();
}

