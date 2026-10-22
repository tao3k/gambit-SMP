;;; Darwin-only adversarial ownership-breach fixture for runtime retirement.
;;; pthread_detach of a live runtime-owned processor is not a valid-program
;;; fault and is not a portable POSIX proof. Normal mode does not detach.
;;; ADVERSARIAL BOUNDARY: pending and sticky call pthread_detach on the last
;;; runtime-owned processor. That breaches normal joinable exclusive ownership.
;;; A later Darwin EINVAL from the runtime's own join is an injected OS fault,
;;; not evidence that a correct Gambit program can fail this join, and not a
;;; general POSIX result. The detached worker stays inside a POSIX TSD
;;; destructor until release so its pthread id is not joined after expiry.
;;; This fixture never pthread_joins the detached id, never writes
;;; join_pending or pending_join_count, never interposes errno, and never
;;; installs a pause hook or debugger. Failure modes _Exit without a second
;;; join or a private cleanup. Do not return here after cleanup.

(declare (standard-bindings) (extended-bindings) (block) (not safe))

(c-declare #<<c-end
#ifndef __APPLE__
#error runtime_join_quarantine is a Darwin-only adversarial OS fault test
#endif
#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#ifndef ___cleanup_checked
extern ___SCMOBJ ___cleanup_checked(void);
#endif
#ifndef ___setup
extern ___SCMOBJ ___setup(___setup_params_struct *params);
#endif
#ifndef ___vm_registry_sealed
extern int ___vm_registry_sealed(void);
#endif

/*
 * ADVERSARIAL BOUNDARY: pending and sticky pthread_detach the last
 * runtime-owned processor. Darwin EINVAL is injected ownership corruption,
 * not a natural supported error and not a portable POSIX proof.
 * Destructor registration is only pthread_key_create plus pthread_setspecific
 * on that live processor. No pause hook, interposition, or synthetic errno.
 */

static pthread_key_t retirement_tsd_key;
static volatile int tsd_entered = 0;
static volatile int tsd_release = 0;
static volatile int tsd_returned = 0;
static volatile int join_witness = 0;
static ___virtual_machine_state witness_vm = 0;
static ___processor_state witness_target = 0;

static void fail_marker(const char *mode, const char *why)
{
  fprintf(stderr, "runtime-retirement %s FAIL %s\n", mode, why);
  fflush(stderr);
  _Exit(2);
}

static void pass_marker(const char *mode)
{
  fprintf(stdout, "RUNTIME-JOIN-QUARANTINE:%s:PASS\n", mode);
  fflush(stdout);
  _Exit(0);
}

static int deadline_reached(const struct timespec *start)
{
  struct timespec now;

  clock_gettime(CLOCK_MONOTONIC, &now);
  if (now.tv_sec - start->tv_sec > 5)
    return 1;
  if (now.tv_sec - start->tv_sec == 5 && now.tv_nsec >= start->tv_nsec)
    return 1;
  return 0;
}

static void await_flag(volatile int *flag, const char *mode, const char *why)
{
  struct timespec start;

  clock_gettime(CLOCK_MONOTONIC, &start);
  for (;;)
    {
      if (__atomic_load_n(flag, __ATOMIC_ACQUIRE) != 0)
        return;
      if (deadline_reached(&start))
        fail_marker(mode, why);
      {
        struct timespec sl;
        sl.tv_sec = 0;
        sl.tv_nsec = 1000000L;
        nanosleep(&sl, 0);
      }
    }
}

/* Bounded 5s: entered, wait release, then returned. Timeout kills the process. */
static void retirement_tsd_dtor(void *value)
{
  struct timespec start;

  (void)value;
  clock_gettime(CLOCK_MONOTONIC, &start);
  __atomic_store_n(&tsd_entered, 1, __ATOMIC_RELEASE);
  for (;;)
    {
      if (__atomic_load_n(&tsd_release, __ATOMIC_ACQUIRE) != 0)
        break;
      if (deadline_reached(&start))
        _Exit(3);
      {
        struct timespec sl;
        sl.tv_sec = 0;
        sl.tv_nsec = 1000000L;
        nanosleep(&sl, 0);
      }
    }
  __atomic_store_n(&tsd_returned, 1, __ATOMIC_RELEASE);
}

static void init_retirement_tsd_key(void)
{
  if (pthread_key_create(&retirement_tsd_key, retirement_tsd_dtor) != 0)
    fail_marker("unset", "tsd-key");
}

/* Called only from the Scheme task pinned to the last runtime processor. */
static void register_retirement_tsd(void)
{
  ___virtual_machine_state vm = &___GSTATE->vmstate0;
  ___processor_state target = ___PSTATE_FROM_PROCESSOR_ID(vm->processor_count - 1, vm);
  if (!pthread_equal(pthread_self(), target->os_thread.thread_id))
    fail_marker("unset", "tsd-wrong-runtime-thread");
  if (pthread_setspecific(retirement_tsd_key, &retirement_tsd_key) != 0)
    fail_marker("unset", "tsd-set");
}

static int host_cpu_count(void)
{
  const char *env = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = 0;
  long n;

  if (env == 0 || env[0] == 0)
    fail_marker("unset", "host-cpus");
  errno = 0;
  n = strtol(env, &end, 10);
  if (errno != 0 || end == env || *end != '\0' || n < 1)
    fail_marker("unset", "host-cpus");
  /* Reserve one actual CPU for the normal-mode native join observer. */
  n--;
  if (n > ___MAX_PROCESSORS)
    n = ___MAX_PROCESSORS;
  if (n < 2)
    fail_marker("unset", "cohort");
  return (int)n;
}

static ___processor_state last_runtime_processor(___virtual_machine_state vm)
{
  int n = vm->processor_count;
  if (n < 2)
    return 0;
  return ___PSTATE_FROM_PROCESSOR_ID(n - 1, vm);
}

static void detach_last_runtime_processor(const char *mode, ___virtual_machine_state vm)
{
  ___processor_state target = last_runtime_processor(vm);
  int rc;

  if (target == 0)
    fail_marker(mode, "no-retired-processor");
  /* Scheme task that called pthread_setspecific has already been joined. */
  rc = pthread_detach(target->os_thread.thread_id);
  if (rc != 0)
    fail_marker(mode, "pthread_detach");
}

static ___SCMOBJ resize_via_gstate(___processor_state ___ps, int target)
{
  return ___GSTATE->___current_vm_resize(___PSP ___FAL, target);
}

static void expect_pending_one(const char *mode, ___virtual_machine_state vm, ___processor_state target)
{
  ___WORD pending = __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE);
  if (pending != 1)
    fail_marker(mode, "pending-count");
  if (!target->join_pending)
    fail_marker(mode, "join-pending-flag");
}

static void release_and_await_returned(const char *mode)
{
  __atomic_store_n(&tsd_release, 1, __ATOMIC_RELEASE);
  await_flag(&tsd_returned, mode, "tsd-returned");
}

static void *normal_join_helper(void *unused)
{
  struct timespec start;
  ___WORD pending;

  (void)unused;
  await_flag(&tsd_entered, "normal", "tsd-entered");
  /* P0 is inside the real join until this helper releases the destructor. */
  clock_gettime(CLOCK_MONOTONIC, &start);
  for (;;)
    {
      pending = __atomic_load_n(&witness_vm->pending_join_count, __ATOMIC_ACQUIRE);
      if (pending > 0 && witness_target->join_pending)
        break;
      if (deadline_reached(&start))
        fail_marker("normal", "witness");
      {
        struct timespec sl;
        sl.tv_sec = 0;
        sl.tv_nsec = 1000000L;
        nanosleep(&sl, 0);
      }
    }
  __atomic_store_n(&join_witness, 1, __ATOMIC_RELEASE);
  __atomic_store_n(&tsd_release, 1, __ATOMIC_RELEASE);
  return 0;
}

void runtime_retirement_quarantine_main(void)
{
  const char *mode = getenv("RUNTIME_RETIREMENT_MODE");
  ___virtual_machine_state vm = &___GSTATE->vmstate0;
  ___processor_state ___ps = ___PSTATE;
  ___processor_state target;
  ___processor_state root_ps;
  ___setup_params_struct saved;
  ___setup_params_struct copy;
  unsigned char params_bytes[sizeof(___setup_params_struct)];
  unsigned char abort_bytes[sizeof root_ps->os.select_abort];
  void *abort_addr = 0;
  int ready_before = 0;
  size_t abort_sz = 0;
  int count_before;
  int sealed_before;
  ___SCMOBJ err;
  ___SCMOBJ again;
  ___SCMOBJ setup_err;
  ___WORD pending_after;

  if (mode == 0)
    fail_marker("unset", "mode");
  if (vm->processor_count < 2)
    fail_marker(mode, "cohort");

  root_ps = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
  abort_sz = sizeof root_ps->os.select_abort;
  memcpy(abort_bytes, &root_ps->os.select_abort, abort_sz);
  abort_addr = &root_ps->os.select_abort;
  ready_before = __atomic_load_n(&root_ps->os.select_abort_ready, __ATOMIC_ACQUIRE);

  if (strcmp(mode, "normal") == 0)
    {
      pthread_t helper;

      target = last_runtime_processor(vm);
      if (target == 0)
        fail_marker(mode, "no-retired-processor");
      witness_vm = vm;
      witness_target = target;
      if (pthread_create(&helper, 0, normal_join_helper, 0) != 0)
        fail_marker(mode, "helper-create");
      err = ___current_vm_resize(___PSP ___FAL, 1);
      if (pthread_join(helper, 0) != 0)
        fail_marker(mode, "helper-join");
      if (__atomic_load_n(&join_witness, __ATOMIC_ACQUIRE) == 0)
        fail_marker(mode, "witness");
      await_flag(&tsd_returned, mode, "tsd-returned");
      if (err != ___FIX(___NO_ERR))
        fail_marker(mode, "shrink");
      if (__atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE) != 0)
        fail_marker(mode, "pending");
      /* Helper has finished. Global cleanup is next. Do not return to Scheme. */
      err = ___cleanup_checked();
      if (err != ___FIX(___NO_ERR))
        fail_marker(mode, "cleanup");
      pass_marker(mode);
    }

  target = last_runtime_processor(vm);
  if (strcmp(mode, "pending") == 0)
    {
      int grow_to = vm->processor_count;
      detach_last_runtime_processor(mode, vm);
      err = resize_via_gstate(___ps, 1);
      if (err != ___FIX(___ERRNO_ERR(EINVAL)))
        fail_marker(mode, "einval");
      await_flag(&tsd_entered, mode, "tsd-entered");
      expect_pending_one(mode, vm, target);
      if (___GSTATE->setup_state != 1)
        fail_marker(mode, "setup-state");
      again = resize_via_gstate(___ps, grow_to);
      if (again == ___FIX(___NO_ERR))
        fail_marker(mode, "grow");
      if (___GSTATE->setup_state != 1)
        fail_marker(mode, "setup-state-after-grow");
      expect_pending_one(mode, vm, target);
      /* No second join of the detached id and no private cleanup. */
      release_and_await_returned(mode);
      pass_marker(mode);
    }

  if (strcmp(mode, "sticky") == 0)
    {
      saved = ___GSTATE->setup_params;
      memcpy(params_bytes, &___GSTATE->setup_params, sizeof params_bytes);
      detach_last_runtime_processor(mode, vm);
      target = last_runtime_processor(vm);
      err = ___cleanup_checked();
      if (err != ___FIX(___ERRNO_ERR(EINVAL)))
        fail_marker(mode, "einval");
      await_flag(&tsd_entered, mode, "tsd-entered");
      expect_pending_one(mode, vm, target);
      if (___GSTATE->setup_state != 2)
        fail_marker(mode, "setup-state");
      if (&root_ps->os.select_abort != abort_addr)
        fail_marker(mode, "select-abort");
      if (memcmp(&root_ps->os.select_abort, abort_bytes, abort_sz) != 0)
        fail_marker(mode, "select-abort");
      if (__atomic_load_n(&root_ps->os.select_abort_ready, __ATOMIC_ACQUIRE) != ready_before)
        fail_marker(mode, "select-abort-ready");
      count_before = (int)__atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE);
      sealed_before = ___vm_registry_sealed();
      if (!sealed_before)
        fail_marker(mode, "seal");
      again = ___cleanup_checked();
      copy = saved;
      setup_err = ___setup(&copy);
      pending_after = __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE);
      if (again != err || setup_err != err)
        fail_marker(mode, "same-error");
      if (pending_after != count_before || !target->join_pending)
        fail_marker(mode, "pending-changed");
      if (___vm_registry_sealed() != sealed_before)
        fail_marker(mode, "seal-changed");
      if (&root_ps->os.select_abort != abort_addr)
        fail_marker(mode, "select-abort-changed");
      if (memcmp(&root_ps->os.select_abort, abort_bytes, abort_sz) != 0)
        fail_marker(mode, "select-abort-changed");
      if (__atomic_load_n(&root_ps->os.select_abort_ready, __ATOMIC_ACQUIRE) != ready_before)
        fail_marker(mode, "select-abort-ready-changed");
      if (memcmp(&___GSTATE->setup_params, params_bytes, sizeof params_bytes) != 0)
        fail_marker(mode, "setup-params");
      if (___GSTATE->setup_state != 2)
        fail_marker(mode, "setup-state-changed");
      release_and_await_returned(mode);
      pass_marker(mode);
    }

  fail_marker(mode, "unknown-mode");
}
c-end
)

(define host-cpus
  (c-lambda () int
    "___return(host_cpu_count());"))

(define processors (host-cpus))
(##thread-pin! (current-thread) (##processor 0))
;; Key exists before the cohort grows. Registration is a later pinned task.
((c-lambda () void "init_retirement_tsd_key"))
(##current-vm-resize ##startup-processor! processors)
(let ((worker (make-thread
               (lambda ()
                 ((c-lambda () void "register_retirement_tsd"))))))
  ;; Publish the pin before the task starts; pinning the current task need not migrate immediately.
  (##thread-pin! worker (##processor (- processors 1)))
  (thread-start! worker)
  (thread-join! worker))
((c-lambda () void "runtime_retirement_quarantine_main"))
(error "returned to Scheme after runtime retirement")
