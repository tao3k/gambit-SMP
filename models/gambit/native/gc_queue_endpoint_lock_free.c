#include <stdint.h>

_Static_assert(__GCC_ATOMIC_POINTER_LOCK_FREE == 2, "pointer atomics must be lock-free");
_Static_assert(__atomic_always_lock_free(sizeof(void *), 0), "no hidden atomic helper");

volatile uintptr_t *queue_endpoint_load(volatile uintptr_t * volatile *endpoint)
{
  return __atomic_load_n(endpoint, __ATOMIC_RELAXED);
}

void queue_endpoint_store(volatile uintptr_t * volatile *endpoint, volatile uintptr_t *value)
{
  __atomic_store_n(endpoint, value, __ATOMIC_RELAXED);
}
