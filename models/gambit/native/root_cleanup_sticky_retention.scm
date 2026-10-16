(c-declare #<<c-end
#include <pthread.h>
#include <stdatomic.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS)
#error This fixture requires multiple threaded VMs
#endif
static _Atomic int armed, injected;
static int (*real_join)(pthread_t, void **);
int pthread_join(pthread_t thread, void **result)
{
  if (!real_join)
    real_join = (int (*)(pthread_t, void **))dlsym(RTLD_NEXT, "pthread_join");
  if (!real_join || real_join == pthread_join) _Exit(80);
  if (atomic_exchange(&armed, 0))
    { atomic_fetch_add(&injected, 1); return EINVAL; }
  return real_join(thread, result);
}
static int capacity(void)
{
  const char *value = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  char *end = NULL;
  long cpu = value ? strtol(value, &end, 10) : 0;
  if (!value || *end || cpu < 3 || cpu > INT_MAX) _Exit(81);
  if (cpu - 1 > ___MAX_PROCESSORS) _Exit(82);
  return (int)(cpu - 1);
}
static void retain_root(void)
{
  ___virtual_machine_state vm = &___GSTATE->vmstate0;
  ___processor_state ps = ___PSTATE;
  ___SCMOBJ module = vm->main_module_ref;
  ___SCMOBJ expected = ___FIX(___ERRNO_ERR(EINVAL));
  ___setup_params_struct parameters;
  if (ps != ___PSTATE_FROM_PROCESSOR_ID(0, vm) ||
      vm->processor_count < 2 || ___GSTATE->setup_state != 1)
    {
      fprintf(stderr, "root admission p0=%d processors=%d setup=%d\n",
              ps == ___PSTATE_FROM_PROCESSOR_ID(0, vm), vm->processor_count,
              ___GSTATE->setup_state);
      _Exit(83);
    }
  atomic_store(&armed, 1);
  if (___cleanup_checked() != expected || atomic_load(&injected) != 1 ||
      vm->processor_count != 1 || ___GSTATE->setup_state != 2 ||
      __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE) != 1) _Exit(84);
  if (___cleanup_checked() != expected || ___cleanup_checked() != expected ||
      atomic_load(&injected) != 1 || vm->main_module_ref != module ||
      ___PSTATE != ps) _Exit(85);
  ___setup_params_reset(&parameters);
  parameters.version = ___VERSION;
  if (___setup(&parameters) != expected || atomic_load(&injected) != 1 ||
      ___GSTATE->setup_state != 2 || vm->processor_count != 1 ||
      vm->main_module_ref != module ||
      __atomic_load_n(&vm->pending_join_count, __ATOMIC_ACQUIRE) != 1) _Exit(86);
  /* Retained failure forbids normal cleanup/unload; the OS reclaims this process.
     This exit qualifies the retention assertions, not successful runtime teardown. */
  if (fputs("ROOT-STICKY-RETENTION:PASS\n", stdout) < 0 || fflush(stdout)) _Exit(87);
  _Exit(0);
}
c-end
)
(define processors ((c-lambda () int "capacity")))
(##current-vm-resize ##startup-processor! processors)
(let ((threads
       (let loop ((index 0))
         (if (= index processors) '()
             (let ((thread
                    (make-thread
                     (lambda ()
                       (if (not (= (processor-id (current-processor)) index))
                           (error "processor ownership mismatch"))
                       (let ((root (make-vector 256 index)))
                         (##gc)
                         (if (not (= (vector-ref root 255) index))
                             (error "root corruption")))
                       #t))))
               (##thread-pin! thread (##processor index))
               (thread-start! thread)
               (cons thread (loop (+ index 1))))))))
  (for-each (lambda (thread)
              (if (not (eq? (thread-join! thread) #t))
                  (error "worker incomplete"))) threads))
(let ((retainer (make-thread (lambda () ((c-lambda () void "retain_root"))))))
  (##thread-pin! retainer (##processor 0))
  (thread-start! retainer)
  (thread-join! retainer)
  (error "retained-root observer must terminate its process"))
