/* Frozen RC domain is the source; the explicit worker owns copying. */
___HIDDEN ___BOOL mark_rc(___collector_worker *work, ___processor_state executor,
                          ___rc_domain *source, ___UWORD epoch)
{
  ___rc_header *h;
  ___RC_LOCK(source);
  if (source->phase != ___RC_FROZEN || source->task.scan_leases != 1 ||
      source->task.origin.source.rc != source ||
      !root_task_matches(&source->task,___ROOT_RC,executor,epoch) || source->task.state != ___ROOT_CLAIMED)
    { ___RC_UNLOCK(source); return 0; }
  source->task.state=___ROOT_SCANNING;
#ifdef ENABLE_CONSISTENCY_CHECKS
  if (work != 0) reference_location = IN_RC;
#endif
  h=source->head.next;
  while (h != &source->head)
    {
      ___rc_header *next=h->next;
      mark_array (work, &h->data, 1);
      mark_array (work, ___CAST(___SCMOBJ*,h+1), h->root_count);
      h=next;
    }
  source->task.state=___ROOT_SCANNED;
  ___RC_UNLOCK(source);
  return 1;
}

___BOOL ___root_task_scan(___rc_domain *source, ___processor_state executor,
                         ___collector_worker *work, ___UWORD epoch)
{
  if (source == 0 || !root_scan_executor(executor,work)) return 0;
  return mark_rc (work,executor,source,epoch);
}

#define UNMARKED_MOVABLE(obj) \
((unmarked_typ = ___HD_TYP((unmarked_body=___BODY0(obj))[-1])) == ___MOVABLE0)

#define UNMARKED_STILL(obj) \
(unmarked_typ == ___STILL && \
 unmarked_body[___STILL_MARK - ___STILL_BODY] == -1)

#define UNMARKED(obj) \
(UNMARKED_MOVABLE(obj) || UNMARKED_STILL(obj))


/* End internal memory fragment. */
