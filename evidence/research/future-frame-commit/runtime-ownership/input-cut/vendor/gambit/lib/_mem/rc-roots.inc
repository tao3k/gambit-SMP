#line 4356 ___MEM_SOURCE_FILE
___HIDDEN void mark_rc
   ___P((___collector_worker *work, ___execution_context *context),
        (work, context)
___collector_worker *work;
___execution_context *context;)
{
  ___processor_state ___ps = work->carrier;
  ___rc_header *h;

  ___SPINLOCK_LOCK(context->mem.rc_gate_);
  if (!context->mem.rc_closed_)
    {
      ___SPINLOCK_UNLOCK(context->mem.rc_gate_);
      rc_custody_error ("RC root task requires a closed context domain");
    }
  h = context->mem.rc_head_.next;

#ifdef ENABLE_CONSISTENCY_CHECKS
  reference_location = IN_RC;
#endif

  while (h != &context->mem.rc_head_)
    {
      ___rc_header *next = h->next;
      mark_array (work, &h->data, 1);
      mark_array (work, ___CAST(___SCMOBJ*,h+1), h->root_count);
      h = next;
    }
  ___SPINLOCK_UNLOCK(context->mem.rc_gate_);
}


#define UNMARKED_MOVABLE(obj) \
((unmarked_typ = ___HD_TYP((unmarked_body=___BODY0(obj))[-1])) == ___MOVABLE0)

#define UNMARKED_STILL(obj) \
(unmarked_typ == ___STILL && \
 unmarked_body[___STILL_MARK - ___STILL_BODY] == -1)

#define UNMARKED(obj) \
(UNMARKED_MOVABLE(obj) || UNMARKED_STILL(obj))


/* End internal memory fragment. */
