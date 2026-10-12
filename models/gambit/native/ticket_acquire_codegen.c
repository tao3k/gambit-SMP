/* Code-generation inspection only; no native scheduling or GC acceptance. */
#include "gambit.h"

#if defined(___SINGLE_THREADED_VMS) || defined(___USE_NO_THREAD_SYSTEM) || defined(___USE_MUTEX_FOR_SPINLOCK)
#error This inspection requires the threaded ticket-spinlock configuration.
#endif
#ifndef ___USE_sync_builtins
#error This inspection requires the GNU sync builtin configuration.
#endif

___WORD *ticket_cursor_read(___SPINLOCK *lock, ___WORD **cursor)
{
  ___WORD *value;
  ___SPINLOCK_LOCK(*lock);
  value = *cursor;
  ___SPINLOCK_UNLOCK(*lock);
  return value;
}

___WORD *ticket_cursor_read_after_barrier(___SPINLOCK *lock, ___WORD **cursor)
{
  ___WORD *value;
  ___SPINLOCK_LOCK(*lock);
  ___SHARED_MEMORY_BARRIER();
  value = *cursor;
  ___SPINLOCK_UNLOCK(*lock);
  return value;
}
