#include <stdio.h>

/* Branch controls, not a Linux/Clang runtime or memory-ordering test. */
#ifdef TEST_NON_DARWIN
#undef __APPLE__
#endif
#ifdef TEST_CLANG_BRANCH
#define __clang__ 1
#endif
#ifdef TEST_SINGLE_THREADED
#define ___SINGLE_THREADED_VMS
#endif

static int locks;
static int unlocks;
static int barriers;
#define ___SPINLOCK_LOCK(lock) (++locks)
#define ___SPINLOCK_UNLOCK(lock) (++unlocks)
#define ___SHARED_MEMORY_BARRIER() (++barriers)
#include "allocator-locks.inc"

int main(void)
{
  ALLOC_MEM_LOCK();
  ALLOC_MEM_UNLOCK();
  MISC_MEM_LOCK();
  MISC_MEM_UNLOCK();
  if (locks != EXPECT_LOCKS || unlocks != EXPECT_LOCKS || barriers != EXPECT_BARRIERS)
    return 1;
  puts("ALLOC-SCOPE-OK");
  return 0;
}
