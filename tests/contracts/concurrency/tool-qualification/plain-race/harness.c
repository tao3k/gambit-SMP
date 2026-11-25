/* First-error qualification only; not a simulation of a Gambit algorithm. */
#include <pthread.h>
static int value;
static void *worker(void *unused) {
  value=value+1;
  return 0;
}
int main(void) {
  pthread_t first, second;
  pthread_create(&first,0,worker,0);
  pthread_create(&second,0,worker,0);
  pthread_join(first,0);
  pthread_join(second,0);
  return 0;
}
