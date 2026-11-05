#line 7191 ___MEM_SOURCE_FILE
___HIDDEN void mark_processor_scmobj
   ___P((___collector_worker *work, ___execution_context *context),
        (work, context)
___collector_worker *work;
___execution_context *context;)
{
  ___processor_state ___ps = work->carrier;

#ifdef ENABLE_CONSISTENCY_CHECKS
  reference_location = IN_PROCESSOR_SCMOBJ;
#endif

  mark_array (work, ___BODY0_AS(___CONTEXT_PROCESSOR_SCMOBJ(context),___tSUBTYPED),
              ___PROCESSOR_SIZE);
}


___HIDDEN void mark_vm_scmobj
   ___P((___collector_worker *work),
        (work)
___collector_worker *work;)
{
  ___processor_state ___ps = work->carrier;
  ___virtual_machine_state ___vms = work->vm;

#ifdef ENABLE_CONSISTENCY_CHECKS
  reference_location = IN_VM_SCMOBJ;
#endif

  mark_array (work, ___BODY0_AS(___VM_SCMOBJ(___vms),___tSUBTYPED),
              ___VM_SIZE);
  mark_array (work, &___vms->resize.thunk, 1);
  {
    int i;
    /* All origins are frozen by the old collective. Registry lifetime is the
     * VM's, not participant_count or a caller C frame. Never skip a retained
     * slot because its origin is absent or its operation has failed. */
    for (i=0; i<___MAX_PROCESSORS; i++)
      mark_array (work, &___vms->resize_requests[i].thunk, 1);
  }

}


___HIDDEN void mark_global_variables
   ___P((___collector_worker *work),
        (work)
___collector_worker *work;)
{
  ___processor_state ___ps = work->carrier;
  ___virtual_machine_state ___vms = work->vm;
  int id = work->id; /* id of this processor */

#ifdef ENABLE_CONSISTENCY_CHECKS
  reference_location = IN_GLOBAL_VAR;
#endif

  /*
   * Mark a portion of the global variables.
   */

#ifdef ___SINGLE_VM

  {
    int np = ___vms->gc_round.worker_count;
    int lo = (id * ___GLO_SUBLIST_COUNT) / np;
    int hi = ((id+1) * ___GLO_SUBLIST_COUNT) / np;

    while (lo < hi)
      {
        ___glo_sublist_struct *sl = &___GSTATE->mem.glo_list.sublist[lo];
        ___glo_struct *glo = sl->head;

        while (glo != 0)
          {
#ifdef ___DEBUG_GARBAGE_COLLECT_globals
            print_global_var_name (glo);
            ___printf ("\n");
#endif
            mark_array (work, &___GLOCELL(glo->val), 1);
            glo = glo->next;
          }

        lo++;
      }
  }

#else

  {
    int n = ___GSTATE->mem.glo_list.count;
    int np = ___vms->gc_round.worker_count;
    int lo = (id * n) / np;
    int hi = ((id+1) * n) / np;

    mark_array (work, work->vm->glos+lo,
                hi-lo);
  }

#endif
}


___HIDDEN void mark_symkey_tables
   ___P((___collector_worker *work),
        (work)
___collector_worker *work;)
{
  ___processor_state ___ps = work->carrier;

#ifdef ENABLE_CONSISTENCY_CHECKS
  reference_location = IN_SYMKEY_TABLE;
#endif

  mark_array (work, &___GSTATE->symbol_table, 1);
  mark_array (work, &___GSTATE->keyword_table, 1);
}


___HIDDEN void require_gc_phase
   ___P((___gc_participant *participant, ___gc_participant_phase expected),
        (participant, expected)
___gc_participant *participant;
___gc_participant_phase expected;)
{
  if (participant->phase != expected)
    {
      static char *msgs[] = { "Invalid GC participant phase", NULL };
      ___fatal_error (msgs);
    }
}


___HIDDEN void require_gc_worker_phase (___collector_worker *work,
                                      ___gc_worker_phase expected)
{
  if (work->phase != expected)
    {
      static char *msgs[] = { "Invalid GC worker phase", NULL };
      ___fatal_error (msgs);
    }
}

___HIDDEN void mark_execution_roots
   ___P((___collector_worker *work, ___gc_root_task *task),
        (work, task)
___collector_worker *work;
___gc_root_task *task;)
{
  ___processor_state ___ps = work->carrier;
  ___execution_context *context = task->origin->context;

  /* The collective published this complete root origin before any worker
   * started scanning.  The worker owns copying work, not these root slots. */
  ___GC_ROOT_CONTROL(work); /* default has no code or storage */
  mark_continuation (work, context);
  mark_array (work, context->r, sizeof(context->r)/sizeof(*context->r));
  mark_array (work, context->saved, sizeof(context->saved)/sizeof(*context->saved));
  mark_array (work, context->type_cache,
              sizeof(context->type_cache)/sizeof(*context->type_cache));
  mark_array (work, &context->startup_thunk, 1);
  mark_array (work, &context->entry_marker, 1);
  mark_processor_scmobj (work, context);
  mark_rc (work, context);
}


/* End internal memory fragment. */
