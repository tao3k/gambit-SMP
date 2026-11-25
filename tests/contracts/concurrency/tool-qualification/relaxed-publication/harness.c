/* Tool qualification control only; no Gambit algorithm is simulated. */
#include <pthread.h>
#include <stdatomic.h>
#include <assert.h>
static atomic_int payload;
static atomic_int ready;
static void *publisher(void *unused) {
  atomic_store_explicit(&payload,42,memory_order_relaxed);
  atomic_store_explicit(&ready,1,memory_order_relaxed);
  return 0;
}
static void *reader(void *unused) {
  if (atomic_load_explicit(&ready,memory_order_relaxed)) {
    int seen=atomic_load_explicit(&payload,memory_order_relaxed);
    assert(seen == 42);
  }
  return 0;
}
int main(void) {
  pthread_t first, second;
  pthread_create(&first,0,publisher,0);
  pthread_create(&second,0,reader,0);
  pthread_join(first,0);
  pthread_join(second,0);
  return 0;
}
