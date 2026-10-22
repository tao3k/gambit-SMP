;;; Public-API probe for the SMP exit/mutex lock order.
;;; One thread exits while it owns a mutex. Peers call mutex-lock! with
;;; that thread as the owner. An abandoned-mutex exception is a completed
;;; lock, not a failure. This runtime waits by mutex-unlock! on the
;;; condition variable. This is not (go 15 5000) and not acceptance.

(declare (standard-bindings) (block))

(define peer-count 4)
(define rounds 40)

(define (one-round)
  (let ((mutex (make-mutex))
        (gate (make-condition-variable))
        (gate-mutex (make-mutex))
        (ready (vector #f))
        (holder (vector #f)))
    (let ((owner
           (make-thread
            (lambda ()
              (mutex-lock! mutex)
              (mutex-lock! gate-mutex)
              (vector-set! ready 0 #t)
              (condition-variable-broadcast! gate)
              (mutex-unlock! gate-mutex)))))
      (vector-set! holder 0 owner)
      (let loop ((i 0) (peers '()))
        (if (< i peer-count)
            (loop
             (+ i 1)
             (cons
              (thread-start!
               (make-thread
                (lambda ()
                  (mutex-lock! gate-mutex)
                  (if (not (vector-ref ready 0))
                      (mutex-unlock! gate-mutex gate))
                  (mutex-unlock! gate-mutex)
                  (with-exception-catcher
                   (lambda (exc)
                     (if (abandoned-mutex-exception? exc)
                         #t
                         (raise exc)))
                   (lambda ()
                     (mutex-lock! mutex #f (vector-ref holder 0))
                     #t)))))
              peers))
            (begin
              (thread-start! owner)
              (let join-peers ((rest peers))
                (if (pair? rest)
                    (begin
                      (thread-join! (car rest))
                      (join-peers (cdr rest)))))
              (thread-join! owner)))))))

(let loop ((i 0))
  (if (< i rounds)
      (begin
        (one-round)
        (loop (+ i 1)))))

(display "LOCK-ORDER-EXIT-PASS")
(newline)
(force-output)
