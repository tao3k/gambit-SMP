;; Three production wait protocols share one forced GC, for two complete epochs.
;; Five role placements are controls; total runtime CPUs are host-selected.
(c-declare #<<end-of-code
#include <stdio.h>
static int cohort_flags[8] = {0, 0, 0, 0, 0, 0, 0, 0};
end-of-code
)
(define announce!
  (c-lambda (int) void
    "__atomic_store_n(&cohort_flags[___arg1], 1, __ATOMIC_RELEASE);"))
(define announced?
  (c-lambda (int) bool
    "___return(__atomic_load_n(&cohort_flags[___arg1], __ATOMIC_ACQUIRE) != 0);"))
(define reset-flags!
  (c-lambda () void
    "int i; for (i=0; i<8; i++) __atomic_store_n(&cohort_flags[i], 0, __ATOMIC_RELEASE);"))
(define trace-gc!
  (c-lambda () void
    "fputs(\"TRACE:gc-wait-cohort:gc-request\\n\", stderr); fflush(stderr);"))
(define population (##current-vm-processor-count))
(if (< population 6) (error "requires six simultaneous protocol roles"))
(define object-address
  (c-lambda (scheme-object) unsigned-long-long
    "___return((unsigned long long)___arg1);"))
(define (await! flag)
  (declare (not interrupts-enabled))
  (let loop () (if (not (announced? flag)) (loop))))
(define (epoch)
  (declare (not interrupts-enabled))
  (##thread-migrate-to! 0)
  (reset-flags!)
  (let* ((owner-processor (##processor 0))
         (yield-processor (##processor 3))
         (schedule-processor (##processor 4))
         (queued (make-thread (lambda () 'queued-returned)))
         (thread-waiter
          (make-thread
           (lambda ()
             (declare (not interrupts-enabled))
             (let ((self (current-thread)))
               (##primitive-lock! self 1 9)
               (announce! 0)
               (##lock-processor-with-sync-participation! owner-processor)
               (##primitive-unlock! owner-processor 1 9)
               (##primitive-unlock! self 1 9)
               'thread-waiter-returned))))
         (thread-reader
          (make-thread
           (lambda ()
             (declare (not interrupts-enabled))
             (await! 0)
             (announce! 1)
             (thread-state thread-waiter)
             'thread-reader-returned)))
         (processor-waiter
          (make-thread
           (lambda ()
             (declare (not interrupts-enabled))
             (announce! 2)
             (await! 4)
             (announce! 5)
             (thread-yield!)
             'processor-waiter-returned)))
         (retry-waiter
          (make-thread
           (lambda ()
             (declare (not interrupts-enabled))
             (announce! 3)
             (await! 4)
             (announce! 6)
             (thread-yield!)
             'retry-waiter-returned)))
         (threads (list thread-waiter thread-reader processor-waiter retry-waiter queued)))
    (##thread-pin! thread-waiter (##processor 1))
    (##thread-pin! thread-reader (##processor 2))
    (##thread-pin! processor-waiter yield-processor)
    (##thread-pin! retry-waiter schedule-processor)
    (##thread-pin! queued schedule-processor)
    (thread-start! processor-waiter)
    (thread-start! retry-waiter)
    (await! 2)
    (await! 3)
    ;; The pinned scheduler cannot run the queued head before this lock.
    (thread-start! queued)
    (##primitive-lock! queued 1 9)
    (##primitive-lock! owner-processor 1 9)
    (##primitive-lock! yield-processor 1 9)
    (thread-start! thread-waiter)
    (thread-start! thread-reader)
    (announce! 4)
    (for-each await! '(0 1 5 6))
    (trace-gc!)
    (##gc)
    (##primitive-unlock! yield-processor 1 9)
    (##primitive-unlock! owner-processor 1 9)
    (##primitive-unlock! queued 1 9)
    (let ((results (map thread-join! threads)))
      (if (not (equal? results '(thread-waiter-returned thread-reader-returned
                                processor-waiter-returned retry-waiter-returned queued-returned)))
          (error "cohort results changed" results)))))
(define (run-root-cohort)
  (declare (not interrupts-enabled))
  (##thread-migrate-to! 0)
  (reset-flags!)
  (let* ((held (make-thread (lambda () 'never-started)))
         (before (object-address held))
         (waiter (make-thread
                  (lambda ()
                    (declare (not interrupts-enabled))
                    (announce! 7)
                    (##lock-scheduler-object-with-sync-participation! held)
                    (##primitive-unlock! held 1 9)
                    'root-waiter-returned))))
    (##thread-pin! waiter (##processor 5))
    (##primitive-lock! held 1 9)
    (thread-start! waiter)
    (await! 7)
    ;; The same helper argument remains parked through both cohorts.
    (epoch)
    (epoch)
    (##primitive-unlock! held 1 9)
    (if (not (eq? (thread-join! waiter) 'root-waiter-returned))
        (error "root waiter result changed"))
    (if (= before (object-address held))
        (error "root cohort observed no target relocation"))))
(run-root-cohort)
(display "NATIVE-OK:gc_root_cohort_composition\n")
