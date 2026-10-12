;; Source-protocol control, not arbitrary-thread retirement acceptance.
;; Three fixed roles are placed explicitly; total processors remain host-selected.
(c-declare #<<end-of-code
#include <stdio.h>
static int lock_cycle_flags[2] = {0, 0};
end-of-code
)
(define announce!
  (c-lambda (int) void
    "__atomic_store_n(&lock_cycle_flags[___arg1], 1, __ATOMIC_RELEASE);"))
(define announced?
  (c-lambda (int) bool
    "___return(__atomic_load_n(&lock_cycle_flags[___arg1], __ATOMIC_ACQUIRE) != 0);"))
(define trace-gc!
  (c-lambda () void
    "fputs(\"TRACE:thread-processor-cycle:gc-request\\n\", stderr); fflush(stderr);"))
(define population (##current-vm-processor-count))
(if (< population 3) (error "requires three protocol roles"))
(##thread-migrate-to! 0)
(define coordinator (##processor 0))
(define waiter
  (make-thread
   (lambda ()
     (declare (not interrupts-enabled))
     (let ((self (current-thread)))
       ;; Migration already uses this lock order in the actual runtime.
       (##primitive-lock! self 1 9)
       (announce! 0)
       (##lock-processor-with-sync-participation! coordinator)
       (##primitive-unlock! coordinator 1 9)
       (##primitive-unlock! self 1 9)
       'waiter-returned))))
(define reader
  (make-thread
   (lambda ()
     (declare (not interrupts-enabled))
     (let loop () (if (not (announced? 0)) (loop)))
     (announce! 1)
     ;; This actual primitive begins by acquiring the waiter's thread lock.
     (thread-state waiter)
     'reader-returned)))
(##thread-pin! waiter (##processor 1))
(##thread-pin! reader (##processor 2))
(define (exercise)
  (declare (not interrupts-enabled))
  (##primitive-lock! coordinator 1 9)
  (thread-start! waiter)
  (thread-start! reader)
  (let loop ()
    (if (not (and (announced? 0) (announced? 1))) (loop)))
  (trace-gc!)
  (##gc)
  (##primitive-unlock! coordinator 1 9))
(exercise)
(if (not (eq? (thread-join! waiter) 'waiter-returned))
    (error "waiter result changed"))
(if (not (eq? (thread-join! reader) 'reader-returned))
    (error "reader result changed"))
(display "NATIVE-OK:thread_processor_gc_wait_cycle\n")
