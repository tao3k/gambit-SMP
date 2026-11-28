;;; Real public FFI frames reject global teardown after a closed VM prefix.
;;; No interposition, injected failures, private frame counters or fake progress.
(c-declare #<<c-end
#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <limits.h>
#include <time.h>
#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS)
#error Multiple threaded VMs required
#endif
extern ___SCMOBJ ___cleanup_checked ___PVOID;
extern ___SCMOBJ ___cleanup_owned_vmstate ___P((___virtual_machine_state), ());
extern int cleanup_admission_callback(int reject);
struct worker { _Atomic(___virtual_machine_state) vm; int accepted; };
static struct worker *workers;
static int count;
static _Thread_local int child;
static _Atomic int ready, selected, completed, passed;
static _Atomic(___virtual_machine_state) busy_vm;
static void pause_fixture(void) {
  const struct timespec delay = {0, 1000000};
  nanosleep(&delay, NULL);
}
static int gates_open(void) {
  ___virtual_machine_state root = &___GSTATE->vmstate0, vm = root;
  int seen = 0;
  do {
    if (__atomic_load_n(&vm->sfun_admission_gate, __ATOMIC_ACQUIRE) != 0) return 0;
    ++seen; vm = vm->next;
  } while (vm != root);
  return seen == count + 1 && ___GSTATE->setup_state == 1;
}
static int reject_cleanup(void) {
  ___SCMOBJ err = ___cleanup_checked();
  return err == ___FIX(___INVALID_OP_ERR) && gates_open();
}
static void *worker_main(void *argument) {
  struct worker *w = argument;
  ___virtual_machine_state vm = calloc(1, sizeof(*vm));
  ___processor_state ps;
  ___SCMOBJ module, thunk, err;
  if (!vm) _Exit(80);
  child = 1;
  module = ___GSTATE->vmstate0.main_module_ref;
  thunk = ___VECTORELEM(___VECTORELEM(___VECTORELEM(___GSTATE->program_descr, 0), 0),
                        ___MODULE_DESCR_THUNK);
  if (___HD_TYP(___HEADER(module)) != ___PERM || ___HD_TYP(___HEADER(thunk)) != ___PERM)
    _Exit(81);
  if (___GSTATE->___setup_vmstate(vm) != ___FIX(___NO_ERR)) _Exit(82);
  ps = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
  if (___GSTATE->___thread_init_from_self(&ps->os_thread) != ___FIX(___NO_ERR)) _Exit(83);
  ___SET_REAL_PSTATE(ps);
  vm->main_module_ref = module;
  atomic_store(&w->vm, vm);
  atomic_fetch_add(&ready, 1);
  while (!atomic_load(&selected)) pause_fixture();
  err = ___GSTATE->___run(___PSA(ps) thunk);
  if (err != ___FIX(___NO_ERR)) _Exit(84);
  // Keep list membership stable until every post-rollback callback has returned.
  while (atomic_load(&passed) != count * count) pause_fixture();
  if (___cleanup_owned_vmstate(vm) != ___FIX(___NO_ERR)) _Exit(85);
  w->accepted = 1;
  ___SET_REAL_PSTATE(NULL);
  free(vm);
  return NULL;
}
static int run_child(void) {
  ___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___PSTATE);
  int round;
  for (round = 1; round <= count; ++round) {
    while (atomic_load(&selected) < round) pause_fixture();
    if (vm == atomic_load(&busy_vm)) {
      if (cleanup_admission_callback(1) != 42) return 0;
      atomic_store(&completed, round);
    } else {
      while (atomic_load(&completed) < round) pause_fixture();
    }
    if (cleanup_admission_callback(0) != 42) return 0;
    atomic_fetch_add(&passed, 1);
  }
  return 1;
}
static int start(void) {
  const char *capacity = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = capacity ? strtol(capacity, &end, 10) : 0;
  pthread_t *threads;
  int i;
  if (!capacity || *end || cpu < 4 || cpu > INT_MAX) return 0;
  count = (int)cpu - 2;
  threads = calloc(count, sizeof(*threads));
  workers = calloc(count, sizeof(*workers));
  if (!threads || !workers) _Exit(86);
  for (i = 0; i < count; ++i)
    if (pthread_create(&threads[i], NULL, worker_main, &workers[i])) _Exit(87);
  while (atomic_load(&ready) != count) pause_fixture();
  // Exercise every child position: varying closed prefix and untouched suffix.
  {
    ___virtual_machine_state vm = ___GSTATE->vmstate0.next;
    for (i = 1; i <= count; ++i) {
      atomic_store(&busy_vm, vm);
      atomic_store(&selected, i);
      while (atomic_load(&passed) != i * count) pause_fixture();
      // Do not traverse the list after the final round releases owner cleanup.
      if (i < count) vm = vm->next;
    }
  }
  for (i = 0; i < count; ++i)
    if (pthread_join(threads[i], NULL) || !workers[i].accepted) _Exit(88);
  if (___GSTATE->vmstate0.next != &___GSTATE->vmstate0) _Exit(89);
  free(threads); free(workers);
  return atomic_load(&completed) == count && atomic_load(&passed) == count * count;
}
c-end
)
(define (require ok message) (if (not ok) (error message)))
(c-define (cleanup-admission-callback reject) (int) int
  "cleanup_admission_callback" ""
  (let ((root (make-vector 128 1042)))
    (if (= reject 1)
        (require ((c-lambda () bool "reject_cleanup"))
                 "busy cleanup did not restore every closed admission gate"))
    (##gc)
    (require (= (vector-ref root 127) 1042) "rollback lost a callback root")
    42))
(if (= ((c-lambda () int "___return(child);")) 0)
    (begin
      (require ((c-lambda () bool "start")) "cleanup rollback topology failed")
      (display "CLEANUP-ADMISSION-ROLLBACK:PASS\n"))
    (require ((c-lambda () bool "run_child")) "post-rollback FFI reentry failed"))
