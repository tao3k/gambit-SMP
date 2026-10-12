(include "../#.scm")

(cond-expand
 (enable-smp
  (define (check-ended-new-owner exceptional?)
    (let* ((gate (make-mutex))
           (request (make-mutex))
           (target (make-thread
                    (lambda ()
                      (mutex-lock! gate)
                      (mutex-unlock! gate)
                      (if exceptional? (raise 'target-error) 'target-done))))
           (caller (make-thread
                    (lambda ()
                      (with-exception-catcher
                       (lambda (error)
                         (if (abandoned-mutex-exception? error)
                             'abandoned
                             (raise error)))
                       (lambda ()
                         (mutex-lock! request #f target)
                         'unexpected-success))))))
      (mutex-lock! gate)
      (mutex-lock! request)
      (thread-start! target)
      (thread-start! caller)
      ;; The target cannot end before this caller is queued on the request.
      (let await-queue ()
        (let ((state (thread-state caller)))
          (if (and (thread-state-waiting? state)
                   (eq? request (thread-state-waiting-for state)))
              (test-assert #t)
              (begin (thread-yield!) (await-queue)))))
      (mutex-unlock! gate)
      (if exceptional?
          (test-error uncaught-exception? (thread-join! target))
          (test-equal 'target-done (thread-join! target)))
      ;; Previous owner releases normally; only the requested new owner ended.
      (mutex-unlock! request)
      (test-eq 'abandoned (thread-join! caller))
      (test-eq 'abandoned (mutex-state request))))

  (check-ended-new-owner #f)
  (check-ended-new-owner #t))
 (else
  (error "SMP required for queued mutex owner transfer fixture")))
