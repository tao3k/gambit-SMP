      ___MUTEX_LOCK(scan_termination_mutex);

      /* Recheck every queue before relinquishing active-scanner ownership. */
      for (i=np-1; i>=0; i--)
        {
          ___processor_state ps = ___PSTATE_FROM_PROCESSOR_ID(i,___vms);
          int pending;

          ___SPINLOCK_LOCK(ps->mem.heap_chunks_to_scan_lock_);
          pending = ps->mem.heap_chunks_to_scan_head_ !=
                    ps->mem.heap_chunks_to_scan_tail_;
          ___SPINLOCK_UNLOCK(ps->mem.heap_chunks_to_scan_lock_);

          if (pending)
            {
              ___MUTEX_UNLOCK(scan_termination_mutex);
              goto continue_local_scan;
            }
        }

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