;;; Mailbox publication shares Scheme values; no isolated Erlang heap assumed.
(define receiver (current-thread))
(define sender
  (make-thread
   (lambda ()
     (let loop ((i 0))
       (if (= i 64) i
           (let ((message (vector i (list i (+ i 1)))))
             (if (= (modulo i 8) 0) (##gc))
             (thread-send receiver message)
             (loop (+ i 1))))))))
(thread-start! sender)
(let loop ((i 0))
  (if (< i 64)
      (let ((message (thread-receive 5 'timeout)))
        (if (eq? message 'timeout) (error "mailbox failed to make progress" i))
        (if (= (modulo i 8) 0) (##gc))
        (if (not (and (= (vector-ref message 0) i)
                      (equal? (vector-ref message 1) (list i (+ i 1)))))
            (error "mailbox root or publication order lost" i message))
        (loop (+ i 1)))))
(if (not (= (thread-join! sender) 64)) (error "sender did not complete"))
(display "MAILBOX-ROOTS-PASS messages=64\n")
