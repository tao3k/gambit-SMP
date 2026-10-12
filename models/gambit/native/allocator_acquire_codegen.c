/* Configured-header code generation, not executed allocation/GC admission. */
#include "gambit.h"
#if defined(___SINGLE_THREADED_VMS) || defined(___USE_NO_THREAD_SYSTEM) || defined(___USE_MUTEX_FOR_SPINLOCK)
#error Threaded ticket lock configuration required
#endif
#ifndef ___USE_sync_builtins
#error GNU sync builtin configuration required
#endif
#define alloc_mem_lock (*lock)
#include "allocator-lock-source.inc"

___WORD *allocator_cursor_read(___SPINLOCK *lock, ___WORD **cursor)
{
  ___WORD *value;
  ALLOC_MEM_LOCK();
  value = *cursor;
  ALLOC_MEM_UNLOCK();
  return value;
}
