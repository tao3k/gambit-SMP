  ___ACTLOG_END_PS();

  /* Unlimited heaps keep the post-collection cursors. The recoverable
   * overflow flag otherwise becomes a Scheme heap-overflow exception. */
  if(___GSTATE->setup_params.max_heap==0 &&
     ___heap_rearm_after_collection(___ps))
    overflow=0;
  if(overflow && ___GSTATE->setup_params.max_heap!=0) {
    extern long write(int, const void *, unsigned long);
    write(2, "GC-CAP\n", 7);
  }

  REST_OBS(REST_GC_END,___ps,0,0,rc_epoch,
           ___VMSTATE_FROM_PSTATE(___ps),___ps->context->fp,overflow,
           ___COLLECTION(___vms).epoch,0,0,0,0);
#ifdef ___GAMBIT_REST_OBSERVATION
  rest_observation_emit_parent(2,___ps->context->fp,(uint64_t)rc_epoch,
    ___COLLECTION(___vms).epoch);
#endif
  return overflow;
}
