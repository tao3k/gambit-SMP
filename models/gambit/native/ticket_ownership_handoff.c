/* Actual configured ticket macros; not a VM/collector qualification. */
#include "gambit.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#if defined(___SINGLE_THREADED_VMS) || defined(___USE_NO_THREAD_SYSTEM) || defined(___USE_MUTEX_FOR_SPINLOCK)
#error This test requires the threaded ticket-spinlock configuration.
#endif
#ifndef ___USE_sync_builtins
#error This test requires the GNU sync builtin configuration.
#endif
#ifndef ___TICKETLOCK_READ_CURRENT
#error The ownership-acquire source successor is required.
#endif

static ___SPINLOCK lock;
static unsigned long counter;
static unsigned long mirror;
static int broken;

static void *worker(void *unused)
{
  unsigned long i;
  (void)unused;
  for (i = 0; i < 10000; ++i)
    {
      ___SPINLOCK_LOCK(lock);
      if (mirror != counter * 3)
        broken = 1;
      ++counter;
      mirror = counter * 3;
      ___SPINLOCK_UNLOCK(lock);
    }
  return NULL;
}

int main(void)
{
  long count = sysconf(_SC_NPROCESSORS_ONLN);
  long i;
  pthread_t *threads;
  if (count < 1)
    return 2;
  threads = calloc((size_t)count, sizeof(*threads));
  if (!threads)
    return 3;
  ___SPINLOCK_INIT(lock);
  for (i = 0; i < count; ++i)
    if (pthread_create(&threads[i], NULL, worker, NULL))
      exit(4);
  for (i = 0; i < count; ++i)
    if (pthread_join(threads[i], NULL))
      exit(5);
  free(threads);
  if (broken || counter != (unsigned long)count * 10000 || mirror != counter * 3)
    return 6;
  puts("TICKET-HANDOFF-OK");
  return 0;
}
