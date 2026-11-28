___BOOL ___try_set_data_rc(___processor_state ps, void *ptr, ___SCMOBJ value)
{
  ___rc_header *h;
  ___rc_domain *d;
  if (ptr == 0 || ps == 0 || ps != ___PSTATE) return 0;
  h=___CAST(___rc_header*,ptr)-1; d=h->domain;
  if (d == 0 || d != ps->mem.rc_domain_) return 0;
  ___RC_LOCK(d);
  if (d->owner != ps || d->phase != ___RC_OPEN || h->refcount <= 0)
    { ___RC_UNLOCK(d); return 0; }
  h->data=value;
  ___RC_UNLOCK(d);
  return 1;
}
