/* Reuse real Darwin worker controls, not their old caller expectations. */
static void ___fatal_error(char **messages);
#define main old_cleanup_observer_main
#include "cleanup_real_pthread_join.c"
#undef main

static void ___fatal_error(char **messages) {
  if (!messages[0] || messages[1] || cleanup_phase != 2 ||
      unsafe_releases || global_releases || !live_at_failed_join)
    _Exit(74);
  printf("{\"fatal\":true,\"retained\":true,\"unsafeReleaseCalls\":0}\n");
  fflush(stdout);
  /* Match the fatal-error contract: this fixture substitutes process exit. */
  _Exit(73);
}

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  int mode = atoi(argv[1]);
  if (mode < 0 || mode > 3) return 2;
  int detached = mode & 1;
  int legacy = mode >= 2;
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
  ___SCMOBJ result;
  if (legacy) {
    ___cleanup();
    if (detached) return 75;
    result = ___FIX(___NO_ERR);
  } else result = ___cleanup_checked();
  ___SCMOBJ repeated = ___cleanup_checked();
  ___SCMOBJ admission = cleanup_admission_error();
  int invalid = result != ___FIX(___ERRNO_ERR(detached ? EINVAL : 0)) ||
    repeated != result || admission != result || resize_calls != 1 ||
    unsafe_releases != 0 || global_releases != !detached ||
    cleanup_phase != (detached ? 2 : 3) ||
    live_at_failed_join != detached;
  check(pthread_mutex_lock(&mutex));
  release_worker = 1;
  check(pthread_cond_broadcast(&condition));
  while (!done) check(pthread_cond_wait(&condition, &mutex));
  check(pthread_mutex_unlock(&mutex));
  printf("{\"mode\":%d,\"joinError\":%d,\"resizeCalls\":%d,"
    "\"unsafeReleaseCalls\":%d,\"globalReleaseCalls\":%d,"
    "\"phase\":%d,\"repeatedSame\":%d,\"setupGuardSame\":%d,\"invalid\":%d}\n",
    mode, ___ERRNO_FROM_ERR_CODE(result), resize_calls, unsafe_releases,
    global_releases, cleanup_phase, repeated == result, admission == result, invalid);
  return invalid ? 1 : 0;
}
