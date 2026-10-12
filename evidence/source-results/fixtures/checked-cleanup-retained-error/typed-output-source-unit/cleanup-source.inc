static int cleanup_phase = 0; /* 0=ready, 1=cleaning, 2=retained, 3=clean */
static ___SCMOBJ cleanup_error = ___FIX(___NO_ERR);

static ___SCMOBJ cleanup_admission_error ___PVOID
{
  if (cleanup_phase == 1)
    return ___FIX(___INVALID_OP_ERR);
  if (cleanup_phase == 2)
    return cleanup_error;
  return ___FIX(___NO_ERR);
}


___EXP_FUNC(___SCMOBJ,___cleanup_checked) ___PVOID
{
  ___processor_state ___ps;
  ___virtual_machine_state ___vms = &___GSTATE->vmstate0;
  ___SCMOBJ err = cleanup_admission_error ();

  if (err != ___FIX(___NO_ERR))
    return err;

  /*
   * Only do cleanup once after successful setup.
   */

  if (___GSTATE->setup_state != 1)
    return ___FIX(___NO_ERR);

  ___ps = ___PSTATE;
  cleanup_phase = 1;
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
      cleanup_phase = 3;
      return ___FIX(___NO_ERR);
    }

#ifndef ___SINGLE_THREADED_VMS

  /*
   * Shutdown processors of this VM except for processor 0.
   */

  err = ___current_vm_resize (___PSP ___FAL, 1);

  if (err != ___FIX(___NO_ERR))
    {
      /* A reduced population is not proof that all retired threads joined. */
      cleanup_error = err;
      cleanup_phase = 2;
      return err;
    }

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
  cleanup_phase = 3;
  return ___FIX(___NO_ERR);
}


___EXP_FUNC(void,___cleanup) ___PVOID
{
  if (___cleanup_checked () != ___FIX(___NO_ERR))
    {
      char *msgs[2];
      msgs[0] = "cleanup failed with retained runtime resources";
      msgs[1] = 0;
      ___fatal_error (msgs);
    }
}

