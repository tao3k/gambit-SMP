___SCMOBJ ___setup_actlog_vmstate
   ___P((___virtual_machine_state ___vms),
        (___vms)
___virtual_machine_state ___vms;)
{
#ifdef ___ACTIVITY_LOG

  ___actlog_activity *ptr =
    ___CAST(___actlog_activity*,
            ___ALLOC_MEM(sizeof (___actlog_activity) *
                         ___MAX_NB_ACTLOG_ACTIVITIES));

  if (ptr == NULL)
    return ___FIX(___HEAP_OVERFLOW_ERR);

#ifdef ___USE_POSIX_THREAD_SYSTEM
  if (!___MUTEX_INIT(___vms->actlog.mut))
    {
      ___FREE_MEM(ptr);
      return ___FIX(___UNKNOWN_ERR);
    }
#else
  ___MUTEX_INIT(___vms->actlog.mut);
#endif
  ___vms->actlog.activities = ptr;
  ___vms->actlog.nb_activities = 0;
  ___vms->actlog.auto_dump = 1;
  ___vms->actlog.max_processor_count = ___vms->processor_count;

#endif

  return ___FIX(___NO_ERR);
}


void ___abort_actlog_vmstate
   ___P((___virtual_machine_state ___vms),
        (___vms)
___virtual_machine_state ___vms;)
{
#ifdef ___ACTIVITY_LOG

  /* Only successfully initialized, quiescent VM log resources are owned. */
  if (___vms->actlog.activities != NULL)
    {
      ___FREE_MEM(___vms->actlog.activities);
      ___vms->actlog.activities = NULL;
    }
  ___MUTEX_DESTROY(___vms->actlog.mut);
  ___vms->actlog.nb_activities = 0;
  ___vms->actlog.auto_dump = 0;

#endif
}


