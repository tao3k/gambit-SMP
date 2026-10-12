#define ___PSTATE_MEM(var) ___ps->mem.var
#define ___VMSTATE_MEM(var) ___VMSTATE_FROM_PSTATE(___ps)->mem.var
#define alloc_heap_ptr          ___PSTATE_MEM(alloc_heap_ptr_)
#define alloc_heap_chunk_start  ___PSTATE_MEM(alloc_heap_chunk_start_)
#define heap_chunks_to_scan_lock ___PSTATE_MEM(heap_chunks_to_scan_lock_)
#define heap_chunks_to_scan_head ___PSTATE_MEM(heap_chunks_to_scan_head_)
#define heap_chunks_to_scan_tail ___PSTATE_MEM(heap_chunks_to_scan_tail_)
#define scan_ptr                ___PSTATE_MEM(scan_ptr_)
#define scan_termination_mutex  ___VMSTATE_MEM(scan_termination_mutex_)
#define scan_termination_condvar ___VMSTATE_MEM(scan_termination_condvar_)
#define NULL_CHUNK_LINK ___TAG(0, ___FORW)
___HIDDEN void end_heap_chunk
   ___P((___processor_state ___ps),
        (___ps)
___processor_state ___ps;)
{
  /*
   * Add the end of chunk marker.
   *
   * This is done even when the chunk is empty, in case the chunk is
   * currently being scanned.
   */

  *alloc_heap_ptr++ = NULL_CHUNK_LINK; /* leave space for next chunk's link */

  if (alloc_heap_ptr != alloc_heap_chunk_start &&
      !(scan_ptr >= alloc_heap_chunk_start && scan_ptr < alloc_heap_ptr))
    {
      /*
       * The chunk being ended is not empty and it isn't currently
       * being scanned, so add it to the heap chunk FIFO and wake any
       * idle processor.
       */

      ___WORD *new_tail = alloc_heap_chunk_start-1;

#ifndef ___SINGLE_THREADED_VMS
      ___SPINLOCK_LOCK(heap_chunks_to_scan_lock);
#endif

      *heap_chunks_to_scan_tail = ___TAG(new_tail, ___FORW);

      /*
       * A memory barrier is needed to ensure that the content of the
       * chunk, including the end of chunk and the link to the chunk,
       * is visible to other processors.
       */

      ___SHARED_MEMORY_BARRIER();

      heap_chunks_to_scan_tail = new_tail;

      /*
       * A memory barrier is needed to ensure that the new tail of the
       * heap chunk FIFO are visible to other processors.  This can't
       * be combined with the previous memory barrier because the
       * ordering is important (as soon as the modification of
       * heap_chunks_to_scan_tail is observed by another processor, it
       * may attempt to read the content of the chunk).
       */

      ___SHARED_MEMORY_BARRIER();

#ifndef ___SINGLE_THREADED_VMS
      ___SPINLOCK_UNLOCK(heap_chunks_to_scan_lock);
      /* Match wait registration without nesting the queue lock under M. */
      ___MUTEX_LOCK(scan_termination_mutex);
      ___CONDVAR_SIGNAL(scan_termination_condvar);
      ___MUTEX_UNLOCK(scan_termination_mutex);
#endif
    }
}


