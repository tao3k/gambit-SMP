;; Force a locked run-queue head while production scheduling retries.
;; Two fixed roles are scheduling controls, not a host CPU limit.
(c-declare #<<end-of-code
#include <stdio.h>
static int scheduler_cycle_flags[3] = {0, 0, 0};
end-of-code
)
(define announce!
  (c-lambda (int) void
    "__atomic_store_n(&scheduler_cycle_flags[___arg1], 1, __ATOMIC_RELEASE);"))
(define announced?
  (c-lambda (int) bool
    "___return(__atomic_load_n(&scheduler_cycle_flags[___arg1], __ATOMIC_ACQUIRE) != 0);"))
(define trace-gc!
  (c-lambda () void
    "fputs(\"TRACE:scheduler-retry-cycle:gc-request\\n\", stderr); fflush(stderr);"))
(define population (##current-vm-processor-count))
(if (< population 2) (error "requires two protocol roles"))
(##thread-migrate-to! 0)
(define target-processor (##processor 1))
(define queued (make-thread (lambda () 'queued-returned)))
(define scheduler
  (make-thread
   (lambda ()
     (declare (not interrupts-enabled))
     (announce! 0)
     (let loop () (if (not (announced? 1)) (loop)))
     (announce! 2)
     (thread-yield!)
     'scheduler-returned)))
(##thread-pin! queued target-processor)
(##thread-pin! scheduler target-processor)
(define (exercise)
  (declare (not interrupts-enabled))
  (thread-start! scheduler)
  (let loop () (if (not (announced? 0)) (loop)))
  ;; The pinned scheduler is still running without interrupt callbacks, so
  ;; queued cannot run between publication and this controlled acquisition.
  (thread-start! queued)
  (##primitive-lock! queued 1 9)
  (announce! 1)
  (let loop () (if (not (announced? 2)) (loop)))
  (trace-gc!)
  (##gc)
  (##primitive-unlock! queued 1 9))
(exercise)
(if (not (eq? (thread-join! queued) 'queued-returned))
    (error "queued result changed"))
(if (not (eq? (thread-join! scheduler) 'scheduler-returned))
    (error "scheduler result changed"))
(display "NATIVE-OK:scheduler_retry_gc_wait_cycle\n")
