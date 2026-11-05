#line 7348 ___MEM_SOURCE_FILE
___HIDDEN void mark_reachable_from_marked
   ___P((___collector_worker *work),
        (work)
___collector_worker *work;)
{
  ___processor_state ___ps = work->carrier;

#ifndef ___SINGLE_THREADED_VMS

  ___virtual_machine_state ___vms = work->vm;
  ___VOLATILE ___WORD *workers_count = &scan_workers_count[traverse_weak_refs];
  int np = ___vms->gc_round.worker_count;
  int id = work->id; /* id of this processor */
  int i;

 continue_local_scan:

#endif

  do
    {
      scan_still_objs_to_scan (work);
      scan_movable_objs_to_scan (work);
    } while (___CAST(___WORD*,still_objs_to_scan) != 0);

#ifndef ___SINGLE_THREADED_VMS

#define ___GC_SCAN_STEAL_WORK_CYCLES 1000

  for (;;)
    {
      /* Try stealing a queued chunk from another processor */

      for (i = (np-1) * ___GC_SCAN_STEAL_WORK_CYCLES - 1; i>=0; i--)
        {
          ___collector_worker *victim = &___vms->collector_workers[(id + 1 + i%(np-1)) % np];
          ___WORD *ptr = take_heap_chunk(work,victim);

          if (ptr != 0)
            {
              scan_complete_heap_chunk (work, ptr, 3);
              goto continue_local_scan;
            }
        }

      /* Signal being idle and wait for more work or termination */

      ___MUTEX_LOCK(scan_termination_mutex);

      if (--(*workers_count) == 0)
        {
          /* Scan has terminated */

          for (i=np-1; i>=0; i--)
            ___CONDVAR_SIGNAL(scan_termination_condvar);

          ___MUTEX_UNLOCK(scan_termination_mutex);

          break;
        }
      else
        {
          /* Other processors are still actively scanning chunks */

          ___ACTLOG_BEGIN_PS(gc_wait,lightgray);
          ___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex);
          ___ACTLOG_END_PS();

          if (*workers_count == 0)
            {
              ___MUTEX_UNLOCK(scan_termination_mutex);
              break;
            }

          (*workers_count)++;

          ___MUTEX_UNLOCK(scan_termination_mutex);
        }
    }

#endif
}


___HIDDEN void collect_root_tasks (___collector_worker *work,
                                 ___gc_root_phase phase)
{
  ___virtual_machine_state vm = work->vm;
  int i, count = vm->gc_round.participant_count;
  ___WORD owner = work->id+4;
  for (i=0; i<count; i++)
    {
      ___gc_root_task *task = &vm->gc_root_tasks[(work->id+1+i)%count];
      ___execution_context *context = task->origin->context;
      if (!___gc_root_task_claim(task,vm->gc_round.epoch,phase,owner))
        continue;
      switch (phase)
        {
        case ___GC_ROOT_PREPARE:
          setup_still_objs_to_scan(work,context);
          context->mem.words_still_objs_ += context->mem.words_still_objs_deferred_;
          context->mem.words_still_objs_deferred_ = 0;
          break;
        case ___GC_ROOT_STRONG:
          mark_execution_roots(work,task);
          break;
        case ___GC_ROOT_WEAK:
          process_wills(work,context);
          break;
        case ___GC_ROOT_CLEANUP:
          { static char *msgs[] = { "Cleanup requires host-domain authority", NULL };
            ___fatal_error(msgs); }
          break;
        }
      if (!___gc_root_task_finish(task,vm->gc_round.epoch,phase,owner))
        {
          static char *msgs[] = { "GC root phase completion lost owner", NULL };
          ___fatal_error(msgs);
        }
    }
}

/* Host-domain service is not a collector worker. Every stopped carrier
 * executes this once, including those excluded from the W-worker census.
 * Unknown foreign release effects retain their original native-thread owner. */
___HIDDEN void cleanup_root_domain (___processor_state ___ps)
{
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___ps);
  int id = ___PROCESSOR_ID(___ps,vm);
  ___gc_root_task *task = &vm->gc_root_tasks[id];
  ___WORD owner = 4+___MAX_PROCESSORS+id;
  if (task->origin->context != ___ps->context ||
      !vm->gc_participants[id].resume.restored ||
      !___gc_root_task_claim(task,vm->gc_round.epoch,___GC_ROOT_CLEANUP,owner))
    {
      static char *msgs[] = { "GC cleanup lacks restored host root domain", NULL };
      ___fatal_error(msgs);
    }
  vm->gc_participants[id].phase = ___GC_OWNER_CLEANUP;
  free_unmarked_still_objs(___ps);
  vm->gc_participants[id].phase = ___GC_ROOTS_FROZEN;
  if (!___gc_root_task_finish(task,vm->gc_round.epoch,___GC_ROOT_CLEANUP,owner))
    {
      static char *msgs[] = { "GC cleanup lost host-domain custody", NULL };
      ___fatal_error(msgs);
    }
}


___HIDDEN void advance_root_tasks (___virtual_machine_state vm,
                                  ___gc_root_phase completed)
{
  int i;
  /* Called by the sole round coordinator after the phase barrier. Strong and
   * weak descendants have also drained before those barriers are crossed. */
  for (i=0; i<vm->gc_round.participant_count; i++)
    if (!___gc_root_task_advance(&vm->gc_root_tasks[i],vm->gc_round.epoch,completed))
      {
        static char *msgs[] = { "GC root phase advance lacks drain", NULL };
        ___fatal_error(msgs);
      }
}

___HIDDEN void garbage_collect_setup_phase
   ___P((___collector_worker *work),
        (work)
___collector_worker *work;)
{
  ___processor_state ___ps = work->carrier;
  ___virtual_machine_state ___vms = work->vm;

#ifdef ENABLE_GC_ACTLOG_PHASES
  ___ACTLOG_BEGIN_PS(setup_phase,_);
#endif

#ifdef ENABLE_GC_TRACE_PHASES
  if (work->id == 0)
    ___printf ("garbage_collect_setup_phase\n");
#endif

  collect_root_tasks(work,___GC_ROOT_PREPARE);

#ifdef ENABLE_GC_ACTLOG_PHASES
  ___ACTLOG_END_PS();
#endif
}


___HIDDEN void garbage_collect_mark_strong_phase
   ___P((___collector_worker *work),
        (work)
___collector_worker *work;)
{
  ___processor_state ___ps = work->carrier;
  ___virtual_machine_state ___vms = work->vm;

#ifdef ENABLE_GC_ACTLOG_PHASES
  ___ACTLOG_BEGIN_PS(mark_strong_phase,_);
#endif

#ifdef ENABLE_GC_TRACE_PHASES
  if (work->id == 0)
    ___printf ("garbage_collect_mark_strong_phase\n");
#endif

#ifdef ENABLE_CONSISTENCY_CHECKS
  if (___DEBUG_SETTINGS_LEVEL(___GSTATE->setup_params.debug_settings) >= 1)
    {
      stack_fudge_used = 0;
      heap_fudge_used = 0;
    }
#endif

  /* maintain list of GC hash tables reached by GC */

  reached_gc_hash_tables = 0;

  traverse_weak_refs = 0; /* don't traverse weak references in this phase */

  if (work->id == 0)
    {
      mark_vm_scmobj (work);
      mark_symkey_tables (work);
    }

  mark_global_variables (work);

  collect_root_tasks(work,___GC_ROOT_STRONG);

  mark_reachable_from_marked (work);
  work->phase = ___GC_WORKER_STRONG_COMPLETE;

#ifdef ENABLE_GC_ACTLOG_PHASES
  ___ACTLOG_END_PS();
#endif
}


___HIDDEN void garbage_collect_mark_weak_phase
   ___P((___collector_worker *work),
        (work)
___collector_worker *work;)
{
  ___processor_state ___ps = work->carrier;
  ___virtual_machine_state ___vms = work->vm;

  require_gc_worker_phase (work, ___GC_WORKER_STRONG_COMPLETE);

  /*
   * At this point all of the objects accessible from the roots
   * without having to traverse a weak reference have been scanned
   * by the GC.
   */

#ifdef ENABLE_GC_ACTLOG_PHASES
  ___ACTLOG_BEGIN_PS(mark_weak_phase,_);
#endif

#ifdef ENABLE_GC_TRACE_PHASES
  if (work->id == 0)
    ___printf ("garbage_collect_mark_weak_phase\n");
#endif

  traverse_weak_refs = 1; /* traverse weak references in this phase */

  collect_root_tasks(work,___GC_ROOT_WEAK);

  mark_reachable_from_marked (work);

  if (work->copy_request.state != 0 || work->copy_begin_ != 0 || work->tail_cell_ != 0 ||
      work->tail_started_ != work->tail_completed_ ||
      work->copy_reserved_words_-work->copy_cancelled_words_ !=
        work->copied_words+work->copy_padding_words_)
    {
      static char *msgs[] = { "GC unfinished copy or Tail custody", NULL };
      ___fatal_error(msgs);
    }

  work->phase = ___GC_WORKER_WEAK_COMPLETE;

#ifdef ENABLE_GC_ACTLOG_PHASES
  ___ACTLOG_END_PS();
#endif
}


___HIDDEN void garbage_collect_cleanup_phase
   ___P((___collector_worker *work),
        (work)
___collector_worker *work;)
{
  ___processor_state ___ps = work->carrier;
  ___virtual_machine_state ___vms = work->vm;

  require_gc_worker_phase (work, ___GC_WORKER_WEAK_COMPLETE);

#ifdef ENABLE_GC_ACTLOG_PHASES
  ___ACTLOG_BEGIN_PS(cleanup_phase,_);
#endif

#ifdef ENABLE_GC_TRACE_PHASES
  if (work->id == 0)
    ___printf ("garbage_collect_cleanup_phase\n");
#endif

  process_gc_hash_tables (work);

  work->phase = ___GC_WORKER_COMPLETE;

#ifdef ENABLE_GC_ACTLOG_PHASES
  ___ACTLOG_END_PS();
#endif
}


___BOOL ___garbage_collect_pstate
   ___P((___processor_state ___ps,
         ___SIZE_TS requested_words_still),
        (___ps,
         requested_words_still)
___processor_state ___ps;
___SIZE_TS requested_words_still;)
{
  ___virtual_machine_state ___vms = ___VMSTATE_FROM_PSTATE(___ps);
  ___BOOL overflow;
  int id = ___PROCESSOR_ID(___ps,___vms);
  /* Deliberately permute executor assignment every population. Root origin id
   * and physical barrier membership remain independent of worker id. */
  int worker_id = (id+1) % ___vms->processor_count;
  int active_worker;
  ___collector_worker *work = &___vms->collector_workers[worker_id];
  ___gc_participant *participant = &___vms->gc_participants[id];
  ___F64 user_time_start, sys_time_start, real_time_start;
  ___F64 user_time_end, sys_time_end, real_time_end;
  ___F64 user_time, sys_time, real_time;

  /* A failed/unknown native join cannot justify moving or reclaiming the
   * quarantined contexts, their roots, or their physical grant. */
  if (___vms->resize.phase != ___RESIZE_IDLE &&
      ___vms->resize.phase != ___RESIZE_REQUESTED &&
      !(___vms->resize.phase == ___RESIZE_RETAINED &&
        ___vms->resize.abort_isolated))
    return 1;

  require_gc_phase (participant, ___GC_RUNNING);
  if (work->vm != ___vms || work->id != worker_id ||
      work->phase != ___GC_WORKER_IDLE)
    {
      static char *msgs[] = { "Invalid collector executor admission", NULL };
      ___fatal_error (msgs);
    }

/* The physical collective supplies the existing allocator/logging adapter.
 * It does not supply work identity or participant phase authority. */
work->carrier = ___ps;
work->reserve = 0; /* inactive host services carry no arena authority */
___ps->collector = work;

___ACTLOG_BEGIN_PS(gc,red);


  /* Start measuring GC statistics */

  if (___PROCESSOR_ID(___ps,___vms) == 0)
    {
#ifdef ENABLE_GC_TRACE_PHASES
      ___printf ("----------------------------------------- GC START #%d\n", ___CAST(int,nb_gcs)+1);
#endif
      ___process_times (&user_time_start, &sys_time_start, &real_time_start);
    }

  /* Print debugging info */

#ifdef ___DEBUG_GARBAGE_COLLECT

  {
    int p;
    int np = ___vms->processor_count;
    for (p=0; p<np; p++)
      {
        if (___PROCESSOR_ID(___ps,___vms) == p)
          {
            ___printf ("processor #%d\n", p);
            ___printf ("heap_size          = %d\n", heap_size);
            ___printf ("tospace_offset     = %d\n", ___ps->context->mem.tospace_offset_);
            ___printf ("___ps->context->stack_start = %p\n", ___ps->context->stack_start);
            ___printf ("___ps->context->stack_break = %p\n", ___ps->context->stack_break);
            ___printf ("___ps->context->fp          = %p\n", ___ps->context->fp);
            ___printf ("___ps->context->stack_limit = %p\n", ___ps->context->stack_limit);
            ___printf ("___ps->context->heap_limit  = %p\n", ___ps->context->heap_limit);
            ___printf ("___ps->context->hp          = %p\n", ___ps->context->hp);
          }
        BARRIER();
      }
  }

#endif


  /* Recover processor's stack and heap pointers */

  alloc_stack_ptr = ___ps->context->fp;
  alloc_heap_ptr  = ___ps->context->hp;


  /* Keep track of bytes allocated by this processor */

  bytes_allocated_minus_occupied += bytes_occupied(___ps);

  close_rc_roots (___ps);
  participant->context = ___ps->context;
  participant->phase = ___GC_ROOTS_FROZEN;
  if (id == 0)
    {
      ___vms->gc_round.participant_count = ___vms->processor_count;
      ___vms->gc_round.overflow = 0;
    }

  BARRIER();


  /* Setup the stacks and heaps of all the processors */

  if (id == 0) setup_stack_heap_vmstate(___vms);
  BARRIER(); /* actual W and every grant published after complete R freeze */
  active_worker = worker_id < ___vms->gc_round.worker_count;
  if (active_worker) work->phase = ___GC_WORKER_PREPARED;
  if (active_worker) garbage_collect_setup_phase(work);

  BARRIER();
  if (id == 0) advance_root_tasks(___vms,___GC_ROOT_PREPARE);
  BARRIER();


  /* Mark the objects that are reachable strongly */

  if (active_worker) garbage_collect_mark_strong_phase(work);

  BARRIER();
  if (id == 0) advance_root_tasks(___vms,___GC_ROOT_STRONG);
  BARRIER();


  /* Mark the objects that are reachable weakly */

  if (active_worker) garbage_collect_mark_weak_phase(work);

  BARRIER();
  if (id == 0) advance_root_tasks(___vms,___GC_ROOT_WEAK);
  BARRIER();


  /* All W copy executors and all R frozen root views crossed the same
   * physical drain. W tails credit W distinct recipients; R-W other domains
   * resume in the bounded bottom of their reserved stack section. */
  if (active_worker)
    {
      if (participant->resume.source_worker != worker_id ||
          scan_ptr != work->arena.cursor || work->active_scan_chunk_ ||
          work->copy_request.state || work->copy_begin_ || work->tail_cell_ ||
          !___gc_arena_handoff(&work->arena,&participant->resume,
                              ___vms->gc_round.epoch))
        {
          static char *msgs[] = { "GC copy/resume handoff lacks drained ownership", NULL };
          ___fatal_error(msgs);
        }
    }
  else if (!___gc_resume_without_arena(&participant->resume,___vms->gc_round.epoch))
    {
      static char *msgs[] = { "GC host resume lacks independent interval", NULL };
      ___fatal_error(msgs);
    }
  move_continuation(___ps);
  participant->resume.restored = 1;
  BARRIER(); /* every R active stack restored before any native cleanup */

  /* Worker-owned hash-table descendants and owner-affine still cleanup have
   * different authorities and completion domains. Both drain before resize. */
  if (active_worker) garbage_collect_cleanup_phase(work);
  cleanup_root_domain(___ps);

  BARRIER();


  /* Resize heap */

  if (___PROCESSOR_ID(___ps,___vms) == 0)
    ___vms->gc_round.overflow = resize_heap (___vms, requested_words_still);

  BARRIER();


  /* Consume the public outcome before the final acknowledgement barrier.
   * A subsequent collective must not overwrite an unconsumed result. */
  overflow = ___vms->gc_round.overflow;

  /* Guarantee heap fudge */

  if (alloc_heap_ptr > alloc_heap_limit - ___MSECTION_FUDGE)
    next_heap_msection (___ps);


  /* Keep track of bytes allocated by this processor */

  bytes_allocated_minus_occupied -= bytes_occupied(___ps);


  /* Finalize measuring GC statistics */

  if (___PROCESSOR_ID(___ps,___vms) == 0)
    {
      ___process_times (&user_time_end, &sys_time_end, &real_time_end);

      user_time = user_time_end - user_time_start;
      sys_time = sys_time_end - sys_time_start;
      real_time = real_time_end - real_time_start;

      nb_gcs = nb_gcs + 1.0;
      gc_user_time += user_time;
      gc_sys_time += sys_time;
      gc_real_time += real_time;

      latest_gc_user_time = user_time;
      latest_gc_sys_time = sys_time;
      latest_gc_real_time = real_time;

      ___raise_interrupt_pstate (___ps, ___INTR_GC); /* raise gc interrupt */

#ifdef ENABLE_GC_TRACE_PHASES
      ___printf ("----------------------------------------- GC END #%d\n", ___CAST(int,nb_gcs));
#endif
    }

  /* Prepare to continue executing program */

  prepare_mem_pstate (___ps);

  if (!___gc_origin_thaw(&___vms->gc_root_tasks[id],___vms->gc_round.epoch))
    {
      static char *msgs[] = { "GC resume lacks completed root task", NULL };
      ___fatal_error(msgs);
    }


  ___ACTLOG_END_PS();

  if (active_worker)
    {
      require_gc_worker_phase(work,___GC_WORKER_COMPLETE);
      work->phase = ___GC_WORKER_IDLE;
    }
  participant->phase = ___GC_RUNNING;
  BARRIER(); /* no worker may retain a stopped root view past this cut */
  reopen_rc_roots (___ps);
  return overflow;
}


/* End internal memory fragment. */
