(include "../#.scm")

(cond-expand
 (enable-smp
  (define thunk-calls 0)
  (define (unexpected-thunk)
    (set! thunk-calls (+ thunk-calls 1)))

  ;; Registration itself must reject an owner that has already terminated.
  (define ended (thread-start! (make-thread (lambda () 'done))))
  (test-equal 'done (thread-join! ended))
  (test-error abandoned-mutex-exception?
              (##thread-intr! ended #f unexpected-thunk))

  (define (check-registered-owner exceptional?)
    (let* ((gate (make-mutex))
           (request (make-mutex unexpected-thunk))
           (target (make-thread
                    (lambda ()
                      (mutex-lock! gate)
                      (mutex-unlock! gate)
                      (if exceptional? (raise 'ended-error) 'ended-normal)))))
      (mutex-lock! gate)
      (thread-start! target)
      (mutex-specific-set! request target)
      ;; Gate prevents termination until the request has target ownership.
      (test-assert (mutex-lock! request #f target))
      (test-eq target (mutex-state request))
      (mutex-unlock! gate)
      (if exceptional?
          (test-error uncaught-exception? (thread-join! target))
          (test-equal 'ended-normal (thread-join! target)))
      (test-eq 'abandoned (mutex-state request))
      (##thread-intr-propagate! (vector '() request))
      (let ((acquired? (##primitive-trylock! target 1 9)))
        (test-assert acquired?)
        (if acquired? (##primitive-unlock! target 1 9)))
      (test-error abandoned-mutex-exception? (mutex-lock! request))
      (test-eq (current-thread) (mutex-state request))
      (mutex-unlock! request)
      (test-assert (mutex-lock! request))
      (mutex-unlock! request)))

  (check-registered-owner #f)
  (check-registered-owner #t)
  (test-equal 0 thunk-calls))
 (else
  (error "SMP required for ended interrupt result lifecycle fixture")))
