#line 676 ___MEM_SOURCE_FILE
/*---------------------------------------------------------------------------*/

/* Allocation of reference counted blocks of memory. */

___HIDDEN void rc_custody_error (char *message)
{
  char *messages[] = { message, 0 };
  ___fatal_error (messages);
}

___HIDDEN void setup_rc
   ___P((___processor_state ___ps),
        (___ps)
___processor_state ___ps;)
{
  ___SPINLOCK_INIT(___ps->context->mem.rc_gate_);
  ___ps->context->mem.rc_closed_ = 0;
  ___ps->context->mem.rc_root_borrows_ = 0;
  rc_head.prev = &rc_head;
  rc_head.next = &rc_head;
  rc_head.refcount = 1;
  rc_head.data = ___FAL;
  rc_head.domain = &___ps->context->mem;
  rc_head.root_count = 0;
}

/* A borrow pins the cell, not a GC participant. Closing writers must never
 * wait for borrowers: the collector updates these cells while they wait. */
___HIDDEN void close_rc_roots (___processor_state ps)
{
  ___SPINLOCK_LOCK(ps->context->mem.rc_gate_);
  ps->context->mem.rc_closed_ = 1;
  ___SPINLOCK_UNLOCK(ps->context->mem.rc_gate_);
}

___HIDDEN void reopen_rc_roots (___processor_state ps)
{
  ___SPINLOCK_LOCK(ps->context->mem.rc_gate_);
  ps->context->mem.rc_closed_ = 0;
  ___SPINLOCK_UNLOCK(ps->context->mem.rc_gate_);
}

___BOOL ___rc_entry_open (___processor_state ps)
{
  ___BOOL open;
  if (ps == 0 || ps != ___PSTATE ||
      ___VMSTATE_FROM_PSTATE(ps)->gc_participants[
        ___PROCESSOR_ID(ps,___VMSTATE_FROM_PSTATE(ps))].phase != ___GC_RUNNING)
    return 0;
  ___SPINLOCK_LOCK(ps->context->mem.rc_gate_);
  open = !ps->context->mem.rc_closed_;
  ___SPINLOCK_UNLOCK(ps->context->mem.rc_gate_);
  return open;
}

___HIDDEN void cleanup_rc
   ___P((___processor_state ___ps),
        (___ps)
___processor_state ___ps;)
{
  ___rc_header *h;

  ___SPINLOCK_LOCK(___ps->context->mem.rc_gate_);
  if (___ps->context->mem.rc_root_borrows_ != 0)
    {
      ___SPINLOCK_UNLOCK(___ps->context->mem.rc_gate_);
      rc_custody_error ("RC root borrow still owned at context cleanup");
    }
  ___ps->context->mem.rc_closed_ = 1;
  h = rc_head.next;

  rc_head.prev = &rc_head;
  rc_head.next = &rc_head;
  ___SPINLOCK_UNLOCK(___ps->context->mem.rc_gate_);

  while (h != &rc_head)
    {
      ___rc_header *next = h->next;
      ___FREE_MEM(h);
      h = next;
    }
  ___SPINLOCK_DESTROY(___ps->context->mem.rc_gate_);
}

/* Teardown must reject outstanding borrows before foreign destructors can
 * invalidate a still object referenced by a retained root cell. */
___HIDDEN void prepare_rc_cleanup (___processor_state ps)
{
  close_rc_roots(ps);
  ___SPINLOCK_LOCK(ps->context->mem.rc_gate_);
  if (ps->context->mem.rc_root_borrows_ != 0)
    {
      ___SPINLOCK_UNLOCK(ps->context->mem.rc_gate_);
      rc_custody_error ("RC root borrow prevents context teardown");
    }
  ___SPINLOCK_UNLOCK(ps->context->mem.rc_gate_);
}


___EXP_FUNC(void*,___alloc_rc_no_register)
   ___P((___SIZE_T bytes),
        (bytes)
___SIZE_T bytes;)
{
  ___rc_header *h;
  if (bytes > ~___CAST(___SIZE_T,0) - sizeof (___rc_header))
    return 0;
  h = ___CAST(___rc_header*, ___ALLOC_MEM(bytes + sizeof (___rc_header)));

  if (h != 0)
    {
      h->refcount = 1;
      h->data = ___FAL;
      h->prev = h;
      h->next = h;
      h->domain = 0;
      h->root_count = 0;

      return ___CAST(void*,h+1);
    }

  return 0;
}


___EXP_FUNC(void*,___register_rc)
   ___P((___PSD
         void *ptr),
        (___PSV
         ptr)
___PSDKR
void *ptr;)
{
  ___PSGET
  ___rc_header *h;
  ___rc_header *head;
  ___rc_header *tail;
  if (ptr == 0 || ___ps == 0) return 0;
  h = ___CAST(___rc_header*, ptr) - 1;
  if (h->domain != 0)
    return h->domain == &___ps->context->mem ? ptr : 0;
  head = &rc_head;
  ___SPINLOCK_LOCK(___ps->context->mem.rc_gate_);
  if (___ps->context->mem.rc_closed_)
    {
      ___SPINLOCK_UNLOCK(___ps->context->mem.rc_gate_);
      return 0; /* Unregistered allocation remains caller-owned. */
    }
  tail = head->prev;

  h->prev = tail;
  h->next = head;
  head->prev = h;
  tail->next = h;
  h->domain = &___ps->context->mem;
  ___SPINLOCK_UNLOCK(___ps->context->mem.rc_gate_);
  return ptr;
}


___EXP_FUNC(void*,___alloc_rc)
   ___P((___PSD
         ___SIZE_T bytes),
        (___PSV
         bytes)
___PSDKR
___SIZE_T bytes;)
{
  ___PSGET
  void *ptr = ___alloc_rc_no_register (bytes);

  if (ptr != 0 && ___register_rc (___PSP ptr) == 0)
    {
      ___FREE_MEM(___CAST(___rc_header*,ptr)-1);
      return 0;
    }

  return ptr;
}


___HIDDEN ___BOOL release_rc_locked (___rc_header *h)
{
  if (--h->refcount != 0) return 0;
  h->next->prev = h->prev;
  h->prev->next = h->next;
  return 1;
}

___EXP_FUNC(void,___release_rc)
   ___P((void *ptr),
        (ptr)
void *ptr;)
{
  if (ptr != 0)
    {
      ___rc_header *h = ___CAST(___rc_header*,ptr) - 1;

      ___BOOL reclaim;
      if (h->domain != 0) ___SPINLOCK_LOCK(h->domain->rc_gate_);
      reclaim = release_rc_locked (h);
      if (h->domain != 0) ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
      if (reclaim) ___FREE_MEM(h);
    }
}


___EXP_FUNC(void,___addref_rc)
   ___P((void *ptr),
        (ptr)
void *ptr;)
{
  if (ptr != 0)
    {
      ___rc_header *h = ___CAST(___rc_header*,ptr) - 1;
      if (h->domain != 0) ___SPINLOCK_LOCK(h->domain->rc_gate_);
      if (h->refcount == ___MAX_FIX)
        {
          if (h->domain != 0) ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
          rc_custody_error ("RC reference count exhausted");
        }
      h->refcount++;
      if (h->domain != 0) ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
    }
}


___EXP_FUNC(___WORD,___refcount_rc)
   ___P((void *ptr),
        (ptr)
void *ptr;)
{
  ___rc_header *h = ___CAST(___rc_header*,ptr) - 1;
  ___WORD count;
  if (h->domain != 0) ___SPINLOCK_LOCK(h->domain->rc_gate_);
  count = h->refcount;
  if (h->domain != 0) ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
  return count;
}


___EXP_FUNC(___SCMOBJ,___data_rc)
   ___P((void *ptr),
        (ptr)
void *ptr;)
{
  ___rc_header *h = ___CAST(___rc_header*,ptr) - 1;
  ___SCMOBJ data;
  if (h->domain != 0) ___SPINLOCK_LOCK(h->domain->rc_gate_);
  data = h->data;
  if (h->domain != 0) ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
  return data; /* Snapshot only; use a root borrow across allocating calls. */
}


___EXP_FUNC(___BOOL,___set_data_rc)
   ___P((void *ptr,
         ___SCMOBJ val),
        (ptr,
         val)
void *ptr;
___SCMOBJ val;)
{
  ___rc_header *h;
  ___processor_state ps = ___PSTATE;
  if (ptr == 0 || ps == 0) return 0;
  h = ___CAST(___rc_header*,ptr) - 1;
  if (h->domain != &ps->context->mem) return 0;
  ___SPINLOCK_LOCK(h->domain->rc_gate_);
  if (h->domain->rc_closed_)
    {
      ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
      return 0;
    }
  h->data = val;
  ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
  return 1;
}

___SCMOBJ *___borrow_rc_root (___processor_state ps, void *ptr)
{
  ___rc_header *h;
  if (ptr == 0 || !___rc_entry_open(ps)) return 0;
  h = ___CAST(___rc_header*,ptr)-1;
  if (h->domain != &ps->context->mem) return 0;
  ___SPINLOCK_LOCK(h->domain->rc_gate_);
  if (h->domain->rc_closed_ || h->refcount == ___MAX_FIX ||
      h->domain->rc_root_borrows_ == ___MAX_FIX)
    {
      ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
      return 0;
    }
  h->refcount++;
  h->domain->rc_root_borrows_++;
  ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
  return &h->data;
}

void ___return_rc_root (void *ptr)
{
  ___rc_header *h = ___CAST(___rc_header*,ptr)-1;
  ___BOOL reclaim;
  ___SPINLOCK_LOCK(h->domain->rc_gate_);
  if (h->domain->rc_root_borrows_ <= 0)
    {
      ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
      rc_custody_error ("RC root borrow returned without custody");
    }
  h->domain->rc_root_borrows_--;
  reclaim = release_rc_locked(h);
  ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
  if (reclaim) ___FREE_MEM(h);
}

/* Non-collecting construction: publish count only with initialized cells.
 * One native flag byte per argument follows the scanned span. */
void *___alloc_rc_roots (___processor_state ps, ___SIZE_TS count)
{
  ___processor_state ___ps = ps;
  void *ptr;
  ___rc_header *h;
  ___SIZE_TS i;
  if (!___rc_entry_open(ps) || count < 2 || count > ___MAX_NB_ARGS+2)
    return 0;
  ptr = ___alloc_rc(___PSP count*(sizeof(___SCMOBJ)+1));
  if (!ptr) return 0;
  h = ___CAST(___rc_header*,ptr)-1;
  ___SPINLOCK_LOCK(h->domain->rc_gate_);
  for (i=0; i<count; i++) ___CAST(___SCMOBJ*,ptr)[i] = ___FAL;
  memset(___CAST(___SCMOBJ*,ptr)+count,0,count);
  h->root_count = count;
  ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
  return ptr;
}

___BOOL ___store_rc_root (___processor_state ps, void *ptr,
                         ___SIZE_TS index, ___SCMOBJ value)
{
  ___rc_header *h;
  if (!ptr || !___rc_entry_open(ps)) return 0;
  h = ___CAST(___rc_header*,ptr)-1;
  if (h->domain != &ps->context->mem || index<0 || index>=h->root_count) return 0;
  ___SPINLOCK_LOCK(h->domain->rc_gate_);
  if (h->domain->rc_closed_)
    { ___SPINLOCK_UNLOCK(h->domain->rc_gate_); return 0; }
  ___CAST(___SCMOBJ*,ptr)[index] = value;
  ___SPINLOCK_UNLOCK(h->domain->rc_gate_);
  return 1;
}


/* End internal memory fragment. */
