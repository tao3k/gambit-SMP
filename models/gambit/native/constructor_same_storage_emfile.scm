;;; Standard POSIX resource failure; no symbol replacement or runtime hooks.
(c-declare #<<c-end
#include <pthread.h>
#include <stdatomic.h>
#include <sys/resource.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <time.h>
#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS) || defined(___OS_WIN32)
#error Multiple threaded POSIX VMs required
#endif
static _Thread_local int owner;
static int count, rounds;
static _Atomic int ready, begin_failure, failed, restored, retried;
struct worker { int id, accepted; ___virtual_machine_state vm; };
static void wait_tick(void) {
  const struct timespec delay = {0, 1000000};
  nanosleep(&delay, NULL);
}
static int rollback_empty(___virtual_machine_state vm) {
  ___processor_state ps = ___PSTATE_FROM_PROCESSOR_ID(0, vm);
  return vm->processor_count == 0 && vm->mem.target_processor_count_ == 1 &&
    vm->next == NULL && vm->prev == NULL && vm->glos == NULL &&
    vm->mem.the_msections_ == NULL && !ps->procedural_interrupts_ready &&
    !ps->sync_resources_ready &&
    !__atomic_load_n(&ps->os.select_abort_ready, __ATOMIC_ACQUIRE) &&
    ps->os.select_abort.reading_fd == -1 && ps->os.select_abort.writing_fd == -1 &&
    ps->os.fdset.size == 0 && ps->os.fdset.readfds == NULL &&
    ps->os.fdset.writefds == NULL && ps->os.fdset.exceptfds == NULL;
}
static void *worker_main(void *argument) {
  struct worker *w = argument;
  ___virtual_machine_state original = w->vm;
  ___processor_state ps;
  ___SCMOBJ module, thunk, err;
  owner = w->id;
  atomic_fetch_add(&ready, 1);
  while (!atomic_load(&begin_failure)) wait_tick();
  err = ___GSTATE->___setup_vmstate(w->vm);
  if (err != ___FIX(___ERRNO_ERR(EMFILE)) || !rollback_empty(w->vm)) {
    fprintf(stderr, "constructor error=%ld expected=%ld empty=%d\n",
      (long)___INT(err), (long)___ERRNO_ERR(EMFILE), rollback_empty(w->vm));
    _Exit(81);
  }
  atomic_fetch_add(&failed, 1);
  while (!atomic_load(&restored)) wait_tick();
  // No free, memset, fresh allocation or pointer swap between these two calls.
  if (w->vm != original || !rollback_empty(w->vm)) _Exit(82);
  err = ___GSTATE->___setup_vmstate(w->vm);
  if (err != ___FIX(___NO_ERR) || w->vm->processor_count != 1) _Exit(83);
  atomic_fetch_add(&retried, 1);
  ps = ___PSTATE_FROM_PROCESSOR_ID(0, w->vm);
  if (___GSTATE->___thread_init_from_self(&ps->os_thread) != ___FIX(___NO_ERR)) _Exit(84);
  ___SET_REAL_PSTATE(ps);
  module = ___GSTATE->vmstate0.main_module_ref;
  thunk = ___VECTORELEM(___VECTORELEM(___VECTORELEM(___GSTATE->program_descr, 0), 0),
                        ___MODULE_DESCR_THUNK);
  if (___HD_TYP(___HEADER(module)) != ___PERM || ___HD_TYP(___HEADER(thunk)) != ___PERM)
    _Exit(85);
  w->vm->main_module_ref = module;
  err = ___GSTATE->___run(___PSA(ps) thunk);
  if (err != ___FIX(___NO_ERR) || w->vm->processor_count != 1 ||
      __atomic_load_n(&w->vm->pending_join_count, __ATOMIC_ACQUIRE) != 0) _Exit(86);
  ___GSTATE->___cleanup_vmstate(w->vm);
  ___SET_REAL_PSTATE(NULL);
  free(w->vm);
  w->accepted = 1;
  return NULL;
}
static int start(void) {
  const char *capacity = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = capacity ? strtol(capacity, &end, 10) : 0;
  struct rlimit original, limited, observed;
  struct worker *workers;
  pthread_t *threads;
  int *owned_fds, used = 0, fd, i, probe[2];
  if (!capacity || *end || cpu < 2 || cpu > INT_MAX - 8) return 0;
  count = (int)cpu - 1;
  rounds = (int)cpu;
  workers = calloc(count, sizeof(*workers));
  threads = calloc(count, sizeof(*threads));
  owned_fds = calloc((size_t)cpu + 8, sizeof(*owned_fds));
  if (!workers || !threads || !owned_fds) _Exit(87);
  // Host thread creation and VM storage allocation precede the resource limit.
  for (i = 0; i < count; ++i) {
    workers[i].id = i + 1;
    workers[i].vm = calloc(1, sizeof(*workers[i].vm));
    if (!workers[i].vm || pthread_create(&threads[i], NULL, worker_main, &workers[i])) _Exit(88);
  }
  while (atomic_load(&ready) != count) wait_tick();
  if (getrlimit(RLIMIT_NOFILE, &original)) _Exit(89);
  limited = original;
  if (limited.rlim_cur > (rlim_t)cpu + 8) limited.rlim_cur = (rlim_t)cpu + 8;
  // The hard limit and the parent process are never changed.
  if (setrlimit(RLIMIT_NOFILE, &limited)) _Exit(90);
  while ((fd = open("/dev/null", O_RDONLY)) >= 0) {
    if (used >= cpu + 8) _Exit(91);
    owned_fds[used++] = fd;
  }
  if (errno != EMFILE || pipe(probe) != -1 || errno != EMFILE) _Exit(92);
  atomic_store(&begin_failure, 1);
  while (atomic_load(&failed) != count) wait_tick();
  for (i = 0; i < used; ++i) if (close(owned_fds[i])) _Exit(93);
  if (setrlimit(RLIMIT_NOFILE, &original) || getrlimit(RLIMIT_NOFILE, &observed) ||
      observed.rlim_cur != original.rlim_cur || observed.rlim_max != original.rlim_max) _Exit(94);
  if (pipe(probe) || close(probe[0]) || close(probe[1])) _Exit(95);
  if (___GSTATE->setup_state != 1 ||
      ___GSTATE->vmstate0.next != &___GSTATE->vmstate0) _Exit(96);
  atomic_store(&restored, 1);
  for (i = 0; i < count; ++i)
    if (pthread_join(threads[i], NULL) || !workers[i].accepted) _Exit(97);
  if (atomic_load(&failed) != count || atomic_load(&retried) != count ||
      ___GSTATE->vmstate0.next != &___GSTATE->vmstate0) _Exit(98);
  free(owned_fds); free(threads); free(workers);
  return 1;
}
c-end
)
(define (require ok message) (if (not ok) (error message)))
(define owner ((c-lambda () int "___return(owner);")))
(define rounds ((c-lambda () int "___return(rounds);")))
(if (= owner 0)
    (begin
      (require ((c-lambda () bool "start")) "constructor same-storage retry failed")
      (display "CONSTRUCTOR-SAME-STORAGE-EMFILE:PASS\n"))
    (let loop ((remaining rounds))
      (if (> remaining 0)
          (let ((root (make-vector 256 owner)))
            (##gc)
            (require (= (vector-ref root 255) owner) "retried VM root corrupted")
            (loop (- remaining 1))))))
