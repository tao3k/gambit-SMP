;; Concurrent interrupt delivery while unpinned workers repeatedly migrate.
;; This is schedule coverage, not a deterministic queued-reinsertion proof.
(define population (##current-vm-processor-count))
(if (< population 2) (error "requires parallel processors"))
(define rounds (* 8 population))
(define (migrate-and-observe target)
  (declare (not interrupts-enabled))
  (##thread-migrate-to! target)
  (##current-processor-id))
(define workers
  (map (lambda (index)
         (let ((deliveries (vector 0)))
           (cons
            (make-thread
             (lambda ()
               (do ((round 0 (+ round 1))) ((= round rounds))
                 (let* ((target (modulo (+ (##current-processor-id) 1) population))
                        (observed (migrate-and-observe target)))
                   (if (not (= target observed))
                       (error "interrupted migration returned on wrong processor"
                              index round target observed)))
                 (thread-yield!))
               (vector-ref deliveries 0)))
            deliveries)))
       (let loop ((index (- population 1)) (result '()))
         (if (< index 0) result (loop (- index 1) (cons index result))))))
(for-each (lambda (entry) (thread-start! (car entry))) workers)
(define senders
  (map (lambda (entry)
         (make-thread
          (lambda ()
            (let loop ((remaining rounds))
              (if (> remaining 0)
                  (let ((active
                         (with-exception-catcher
                          (lambda (exc)
                            (if (inactive-thread-exception? exc) #f (raise exc)))
                          (lambda ()
                            (thread-interrupt!
                             (car entry)
                             (lambda ()
                               (vector-set! (cdr entry) 0
                                            (+ 1 (vector-ref (cdr entry) 0)))))
                            #t))))
                    (if active (loop (- remaining 1)))))))))
       workers))
(for-each thread-start! senders)
(define results (map (lambda (entry) (thread-join! (car entry))) workers))
(for-each thread-join! senders)
(define delivered (apply + results))
(if (= delivered 0) (error "no concurrent interrupts delivered"))
(display (list 'workers population 'rounds rounds 'interrupts delivered))
(newline)
(##gc)
(display "NATIVE-OK:thread_migration_interrupts\n")
