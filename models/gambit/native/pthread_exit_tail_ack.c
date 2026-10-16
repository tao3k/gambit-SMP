/* POSIX ordering control, not a Gambit RC/GC regression or join fault hook. */
#define _POSIX_C_SOURCE 200809L
#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <time.h>
#define ___PVOID (void)
#include "gambit-thread-exit.c"

struct owner {
  _Atomic int pre_exit_ack, release, destructor_done, root_value;
  int copied_root;
};
static pthread_key_t key;
static void pause_owner(void)
{
  const struct timespec delay = {0, 1000000};
  nanosleep(&delay, NULL);
}
static void destructor(void *value)
{
  struct owner *owner = value;
  atomic_store(&owner->root_value, 2);
  atomic_store(&owner->destructor_done, 1);
}
static void *worker(void *value)
{
  struct owner *owner = value;
  if (pthread_setspecific(key, owner)) abort();
  atomic_store(&owner->root_value, 1);
  atomic_store(&owner->pre_exit_ack, 1);
  while (!atomic_load(&owner->release)) pause_owner();
  ___thread_exit();
  abort();
}
int main(int argc, char **argv)
{
  char *end;
  const char *capacity = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  long cpu = capacity ? strtol(capacity, &end, 10) : 0;
  int unsafe, i, count, launched = 0, violated = 0;
  pthread_t *threads;
  struct owner *owners;
  if (!capacity || *end || cpu < 1 || cpu > INT_MAX || argc != 2)
    return 2;
  unsafe = (int)strtol(argv[1], &end, 10);
  if (*end || (unsafe != 0 && unsafe != 1)) return 2;
  count = cpu > 1 ? (int)cpu - 1 : 1;
  threads = calloc((size_t)count, sizeof(*threads));
  owners = calloc((size_t)count, sizeof(*owners));
  if (!threads || !owners || pthread_key_create(&key, destructor)) return 2;
  for (i = 0; i < count; ++i)
    {
      if (pthread_create(&threads[i], NULL, worker, &owners[i])) break;
      ++launched;
    }
  for (i = 0; i < launched; ++i)
    {
      while (!atomic_load(&owners[i].pre_exit_ack)) pause_owner();
      if (atomic_load(&owners[i].destructor_done)) abort();
      if (unsafe) owners[i].copied_root = atomic_load(&owners[i].root_value);
      atomic_store(&owners[i].release, 1);
    }
  for (i = 0; i < launched; ++i)
    {
      if (pthread_join(threads[i], NULL)) abort();
      if (!atomic_load(&owners[i].destructor_done)) abort();
      if (!unsafe) owners[i].copied_root = atomic_load(&owners[i].root_value);
      if (owners[i].copied_root != 2) ++violated;
    }
  if (pthread_key_delete(key)) abort();
  free(owners);
  free(threads);
  if (launched != count) return 2;
  if (unsafe)
    {
      if (violated != count) return 2;
      puts("PRE-EXIT-ACK:EXPECTED-VIOLATION");
      return 1;
    }
  if (violated) return 2;
  puts("JOINED-EXIT-TAIL:PASS");
  return 0;
}
