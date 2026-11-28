;;; SMP control: dynamic structure type stays reachable only as field 0 of the
;;; object returned to the caller. Forced ##gc calls are counted. This probe
;;; does not report whether a collection moved any object.

(declare (standard-bindings) (extended-bindings) (block) (not safe))

(define worker-count 6)
(define rounds 12)
(define batch 128)
(define stress-iters 8192)
(define stress-keep 64)

(define (fail msg)
  (display msg)
  (newline)
  (##exit 1))

(define (assert-true ok msg)
  (if (not ok)
      (fail msg)))

(define (make-rooted-object expected)
  ;; Only the object is returned. The type dies as a local after the return,
  ;; so a precise collector must keep it via the object's type field.
  (let ((type (##structure ##type-type
                           (gensym 'probe)
                           'root-probe
                           26
                           #f
                           '#(payload 0 #f))))
    (let ((obj (##make-structure type 2)))
      (##unchecked-structure-set! obj expected 1 #f #f)
      obj)))

(define (payload obj)
  (##unchecked-structure-ref obj 1 #f #f))

(define (payload-is? obj expected)
  (##equal? (payload obj) expected))

(define (type-ok? obj)
  (let ((t (##structure-type obj)))
    (and (##type? t)
         (##eq? (##type-name t) 'root-probe))))

(define (check-object obj expected)
  (assert-true (payload-is? obj expected) "payload mismatch")
  (assert-true (type-ok? obj) "type descriptor missing or renamed")
  ;; Well-formed object, deliberately wrong expected value. Rejection must
  ;; come from the predicate, not from a bad pointer.
  (assert-true (not (payload-is? obj '##wrong-root-probe-payload))
               "negative control accepted a wrong payload"))

(define (exercise-write obj)
  (let ((port (##open-output-string)))
    (##write (##cons obj 'write-exercise) port)
    (##get-output-string port)))

(define (force-gc n)
  (##gc)
  (##fx+ n 1))

(define (fill-batch expected)
  (let ((v (##make-vector batch #f)))
    (let loop ((i 0))
      (if (##fx< i batch)
          (begin
            (##vector-set! v i (make-rooted-object expected))
            (loop (##fx+ i 1)))
          v))))

(define (check-batch v expected)
  (let loop ((i 0))
    (if (##fx< i batch)
        (begin
          (check-object (##vector-ref v i) expected)
          (loop (##fx+ i 1))))))

(define (stress-index slot)
  ;; 8192 is an exact multiple of 64, so each slot's last writer is known.
  (##fx+ slot (##fx* stress-keep (##fx- (##fxquotient stress-iters stress-keep) 1))))

(define (stress-make id gcs)
  (let ((v (##make-vector stress-keep #f)))
    (let loop ((i 0) (gcs gcs))
      (if (##fx< i stress-iters)
          (let ((gcs (if (##fx= (##fxmodulo i 1024) 1023)
                         (force-gc gcs)
                         gcs)))
            (##vector-set! v
                           (##fxmodulo i stress-keep)
                           (make-rooted-object (##cons 'stress (##cons id i))))
            (loop (##fx+ i 1) gcs))
          (let check ((j 0) (gcs gcs))
            (if (##fx< j stress-keep)
                (begin
                  (check-object (##vector-ref v j)
                                (##cons 'stress (##cons id (stress-index j))))
                  (check (##fx+ j 1) gcs))
                gcs))))))

(define (worker-body id)
  (let loop ((r 0) (gcs 0) (live #f))
    (if (##fx< r rounds)
        (let* ((expected (##cons id r))
               (v (fill-batch expected))
               (gcs (force-gc gcs)))
          (check-batch v expected)
          (loop (##fx+ r 1) gcs v))
        (let ((gcs (stress-make id gcs)))
          (exercise-write (##vector-ref live 0))
          (display "worker ")
          (write id)
          (display " complete")
          (newline)
          gcs))))

(define (start-workers)
  (let loop ((i 0) (acc '()))
    (if (##fx< i worker-count)
        (loop (##fx+ i 1)
              (##cons (thread-start!
                       (make-thread
                        (lambda () (worker-body i))
                        (##string-append "root-probe-" (##number->string i))))
                      acc))
        acc)))

(define (join-workers threads)
  (let loop ((ts threads) (total 0))
    (if (##null? ts)
        total
        (loop (##cdr ts)
              (##fx+ total (thread-join! (##car ts)))))))

(display "processors ")
(write (##current-vm-processor-count))
(newline)

(let ((forced (join-workers (start-workers))))
  (display "forced-gc-calls ")
  (write forced)
  (newline))
