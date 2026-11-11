;;; POSIX/FFI only. No handler replacement, interposition, debugger, or
;;; live-resource destruction. Terminal seal is explicitly untested.
;;; Registry close/open/replay below are research controls, not upstream API.
(c-declare #<<c-end
#include <pthread.h>
#include <signal.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdatomic.h>
#include <time.h>
#include <limits.h>
#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS) || defined(___OS_WIN32)
#error Multiple threaded POSIX VMs required
#endif
/* Research controls for this fixture, not the upstream official API. */
extern void ___vm_registry_close(void);
extern void ___vm_registry_open(void);
extern void ___vm_registry_replay(void);
extern void ___raise_interrupt(int);
static _Atomic int ready_round, go_round, done_round, handles_ready;
static ___thread *worker_base;
static _Atomic int *self_join_err;
static void tick(void) {
  const struct timespec delay = {0, 1000000};
  nanosleep(&delay, NULL);
}
static int deadline_passed(const struct timespec *start) {
  struct timespec now;
  if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) return 1;
  if (now.tv_sec - start->tv_sec > 5) return 1;
  if (now.tv_sec - start->tv_sec == 5 && now.tv_nsec >= start->tv_nsec)
    return 1;
  return 0;
}
static int wait_eq(_Atomic int *cell, int expected) {
  struct timespec start;
  if (clock_gettime(CLOCK_MONOTONIC, &start) != 0) return 0;
  while (atomic_load(cell) != expected) {
    if (deadline_passed(&start)) return 0;
    tick();
  }
  return 1;
}
static int wait_neq(_Atomic int *cell, int unwanted) {
  struct timespec start;
  if (clock_gettime(CLOCK_MONOTONIC, &start) != 0) return 0;
  while (atomic_load(cell) == unwanted) {
    if (deadline_passed(&start)) return 0;
    tick();
  }
  return 1;
}
static ___WORD user_flag(___virtual_machine_state vm) {
  return ___PSTATE_FROM_PROCESSOR_ID(0, vm)->intr_flag[___INTR_USER];
}
static void clear_user(___virtual_machine_state vm) {
  ___PSTATE_FROM_PROCESSOR_ID(0, vm)->intr_flag[___INTR_USER] = ___FIX(0);
}
static void *foreign_main(void *ignored) {
  sigset_t blocked, suspend_mask;
  int round;
  (void)ignored;
  sigemptyset(&blocked);
  sigaddset(&blocked, SIGINT);
  if (pthread_sigmask(SIG_BLOCK, &blocked, NULL) != 0) _Exit(89);
  sigfillset(&suspend_mask);
  sigdelset(&suspend_mask, SIGINT);
  for (round = 1; round <= 2; ++round) {
    atomic_store(&ready_round, round);
    if (!wait_eq(&go_round, round)) _Exit(90);
    sigsuspend(&suspend_mask);
    atomic_store(&done_round, round);
  }
  return NULL;
}
static void worker_start(___thread *self) {
  int index = (int)(self - worker_base);
  ___SCMOBJ err;
  if (!wait_eq(&handles_ready, 1)) _Exit(87);
  err = ___GSTATE->___thread_join(self);
  atomic_store(&self_join_err[index],
               err == ___FIX(___ERRNO_ERR(EDEADLK)) ? EDEADLK : -2);
}
static int signal_round(pthread_t foreign, int round) {
  if (!wait_eq(&ready_round, round)) return 0;
  if (pthread_kill(foreign, SIGINT) != 0) return 0;
  atomic_store(&go_round, round);
  return wait_eq(&done_round, round);
}
static int check(void) {
  const char *value = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = value ? strtol(value, &end, 10) : 0;
  ___virtual_machine_state child, root = &___GSTATE->vmstate0;
  ___processor_state root_ps = ___PSTATE_FROM_PROCESSOR_ID(0, root);
  pthread_t foreign;
  ___thread *workers;
  int count, i;
  if (!value || *end || cpu < 2 || cpu > INT_MAX / 2) return 0;
  count = (int)cpu - 1;
  child = calloc(1, sizeof(*child));
  workers = calloc((size_t)count, sizeof(*workers));
  self_join_err = calloc((size_t)count, sizeof(*self_join_err));
  if (!child || !workers || !self_join_err) _Exit(71);
  if (___GSTATE->___setup_vmstate(child) != ___FIX(___NO_ERR)) _Exit(72);
  worker_base = workers;
  for (i = 0; i < count; ++i) {
    workers[i].start_fn = worker_start;
    atomic_store(&self_join_err[i], -1);
  }
  for (i = 0; i < count; ++i)
    if (___GSTATE->___thread_create(&workers[i]) != ___FIX(___NO_ERR)) _Exit(79);
  atomic_store(&handles_ready, 1);
  for (i = 0; i < count; ++i) {
    if (!wait_neq(&self_join_err[i], -1)) _Exit(88);
    if (atomic_load(&self_join_err[i]) != EDEADLK) _Exit(78);
  }
  for (i = 0; i < count; ++i)
    if (___GSTATE->___thread_join(&workers[i]) != ___FIX(___NO_ERR)) _Exit(80);
  if (pthread_create(&foreign, NULL, foreign_main, NULL)) _Exit(73);
  clear_user(root);
  clear_user(child);
  if (!signal_round(foreign, 1) || user_flag(root) == ___FIX(0) ||
      user_flag(child) != ___FIX(0)) _Exit(74);
  clear_user(root);
  ___vm_registry_close();
  if (!signal_round(foreign, 2)) _Exit(91);
  if (user_flag(child) != ___FIX(0)) _Exit(92);
  if (___GSTATE->setup_state != 1 ||
      child->processor_count != 1 || child->next == NULL ||
      !__atomic_load_n(&root_ps->os.select_abort_ready, __ATOMIC_ACQUIRE))
    _Exit(93);
  if (user_flag(root) != ___FIX(0)) {
    fputs("ROOT-SIGNAL-CLOSED-TOUCH\n", stderr);
    _Exit(75);
  }
  ___vm_registry_open();
  ___vm_registry_replay();
  if (user_flag(root) == ___FIX(0) || user_flag(child) != ___FIX(0)) _Exit(76);
  clear_user(root);
  clear_user(child);
  ___raise_interrupt(___INTR_USER);
  if (user_flag(root) == ___FIX(0) || user_flag(child) == ___FIX(0)) _Exit(86);
  clear_user(root);
  clear_user(child);
  if (pthread_join(foreign, NULL)) _Exit(77);
  ___GSTATE->___cleanup_vmstate(child);
  free(child);
  free(workers);
  free(self_join_err);
  return 1;
}
c-end
)
(if (not ((c-lambda () bool "check"))) (error "root signal retirement failed"))
(display "ROOT-SIGNAL-RETIREMENT:PASS\n")
