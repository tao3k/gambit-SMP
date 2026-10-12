/* Darwin implementation diagnostic, not a portable POSIX invalid-handle test. */
#ifndef __APPLE__
#error This fixture requires the Darwin detached-thread join failure contract.
#endif
#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

typedef long ___SCMOBJ;
typedef struct { pthread_t thread_id; } ___thread;
typedef struct processor { int unused; } *___processor_state;
typedef struct vm {
  int processor_count;
  struct processor processor;
} *___virtual_machine_state;
static struct { int setup_state; struct vm vmstate0; } state;

#define ___P(args, old) args
#define ___PVOID (void)
#define ___EXP_FUNC(result, name) result name
#define ___GSTATE (&state)
#define ___PSTATE (&state.vmstate0.processor)
#define ___PSTATE_FROM_PROCESSOR_ID(i, vms) (&(vms)->processor)
#define ___PSP
#define ___FAL 0
#define ___SINGLE_VM
#define ___USE_POSIX_THREAD_SYSTEM
#define ___CAST(type, value) ((type)(value))
#define ___MASK(type, bits) (((type)1 << (bits)) - 1)
/* Tagging is abstracted; error encoding comes from the locked header. */
#define ___FIX(value) (value)
#include "error-source.inc"
#include "join-source.inc"

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t condition = PTHREAD_COND_INITIALIZER;
static int ready, release_worker, done;
static int resize_calls, unsafe_releases, global_releases, unjoined;
static int live_at_failed_join;
static ___SCMOBJ join_result;
static ___thread target;

static void check(int error) { if (error) abort(); }
static void *worker(void *unused) {
  (void)unused;
  check(pthread_mutex_lock(&mutex));
  ready = 1;
  check(pthread_cond_broadcast(&condition));
  while (!release_worker) check(pthread_cond_wait(&condition, &mutex));
  done = 1;
  check(pthread_cond_broadcast(&condition));
  check(pthread_mutex_unlock(&mutex));
  return NULL;
}
static void ___cleanup_all_interrupt_handling(void) {}
static void cleanup_interrupt_resources_pstate(___processor_state ps) { (void)ps; }
static void cleanup_os_and_mem(void) { global_releases++; }
static ___SCMOBJ ___current_vm_resize(___SCMOBJ thunk, int count) {
  (void)thunk;
  if (count != 1) abort();
  resize_calls++;
  state.vmstate0.processor_count = 1;
  join_result = ___thread_join(&target);
  unjoined = join_result != ___FIX(___NO_ERR);
  check(pthread_mutex_lock(&mutex));
  live_at_failed_join = unjoined && ready && !done && !release_worker;
  check(pthread_mutex_unlock(&mutex));
  return join_result;
}
static void ___cleanup_pstate(___processor_state ps) {
  (void)ps;
  unsafe_releases += unjoined;
}
static void ___cleanup_vmstate(___virtual_machine_state vms) {
  (void)vms;
  unsafe_releases += unjoined;
}
#include "cleanup-source.inc"

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  int detached = atoi(argv[1]);
  if (detached != 0 && detached != 1) return 2;
  pthread_attr_t attributes;
  check(pthread_attr_init(&attributes));
  check(pthread_attr_setdetachstate(&attributes,
    detached ? PTHREAD_CREATE_DETACHED : PTHREAD_CREATE_JOINABLE));
  check(pthread_create(&target.thread_id, &attributes, worker, NULL));
  check(pthread_attr_destroy(&attributes));
  check(pthread_mutex_lock(&mutex));
  while (!ready) check(pthread_cond_wait(&condition, &mutex));
  if (!detached) {
    release_worker = 1;
    check(pthread_cond_broadcast(&condition));
  }
  check(pthread_mutex_unlock(&mutex));
  state.setup_state = 1;
  state.vmstate0.processor_count = 2;
  errno = EDOM;
  ___cleanup();
  int ambient_after = errno;
  check(pthread_mutex_lock(&mutex));
  release_worker = 1;
  check(pthread_cond_broadcast(&condition));
  while (!done) check(pthread_cond_wait(&condition, &mutex));
  check(pthread_mutex_unlock(&mutex));
  /* Shared fixture storage stays static until process exit; no false join. */
  int encoded = ___ERRNO_FROM_ERR_CODE(join_result);
  int invalid = resize_calls != 1 || state.setup_state != 2 ||
    encoded != (detached ? EINVAL : 0) ||
    live_at_failed_join != detached || unsafe_releases != 2 * detached ||
    global_releases != 1;
  printf("{\"detached\":%d,\"joinError\":%d,\"ambientErrno\":%d,"
    "\"liveAtFailedJoin\":%d,\"unsafeReleaseCalls\":%d,"
    "\"globalReleaseCalls\":%d,\"invalid\":%d}\n",
    detached, encoded, ambient_after, live_at_failed_join,
    unsafe_releases, global_releases, invalid);
  return invalid ? 1 : 0;
}
