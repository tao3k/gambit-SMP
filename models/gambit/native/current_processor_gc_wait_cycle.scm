;; A production thread-yield! processor wait, not retirement acceptance.
;; Two protocol roles are fixed; the runtime population is host-selected.
(c-declare #<<end-of-code
#include <stdio.h>
static int current_processor_cycle_flags[3] = {0, 0, 0};
end-of-code
)
(define announce!
  (c-lambda (int) void
    "__atomic_store_n(&current_processor_cycle_flags[___arg1], 1, __ATOMIC_RELEASE);"))
(define announced?
  (c-lambda (int) bool
    "___return(__atomic_load_n(&current_processor_cycle_flags[___arg1], __ATOMIC_ACQUIRE) != 0);"))
(define trace-gc!
  (c-lambda () void
    "fputs(\"TRACE:current-processor-cycle:gc-request\\n\", stderr); fflush(stderr);"))
(define population (##current-vm-processor-count))
(if (< population 2) (error "requires two protocol roles"))
(##thread-migrate-to! 0)
(define target (##processor 1))
(define waiter
  (make-thread
   (lambda ()
     (declare (not interrupts-enabled))
     (announce! 0)
     (let loop () (if (not (announced? 1)) (loop)))
     (announce! 2)
     ;; This actual primitive locks its thread, then its current processor.
     (thread-yield!)
     'waiter-returned)))
(##thread-pin! waiter target)
(define (exercise)
  (declare (not interrupts-enabled))
  (thread-start! waiter)
  (let loop () (if (not (announced? 0)) (loop)))
  (##primitive-lock! target 1 9)
  (announce! 1)
  (let loop () (if (not (announced? 2)) (loop)))
  (trace-gc!)
  (##gc)
  (##primitive-unlock! target 1 9))
(exercise)
(if (not (eq? (thread-join! waiter) 'waiter-returned))
    (error "waiter result changed"))
(display "NATIVE-OK:current_processor_gc_wait_cycle\n")
