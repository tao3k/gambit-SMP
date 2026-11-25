;;; Native process/device regression. Keep six processors and the full roster.
;;; Completed handles stay reachable while later children exit; GC and final
;;; close exercise status ownership independently of the SIGCHLD delivery time.
(define (check expected actual)
  (if (not (= expected actual))
      (error "child status mismatch" expected actual)))
(define (run-child code)
  (let ((p (open-input-process
            (list path: "/bin/sh"
                  arguments: (list "-c" (string-append "exit " (number->string code)))))))
    (check (* code 256) (process-status p))
    p))
(define workers
  (map (lambda (owner)
         (make-thread
          (lambda ()
            (let loop ((i 0) (retained '()))
              (if (= i 16)
                  (for-each close-input-port retained)
                  (let ((p (run-child (modulo (+ owner i) 8))))
                    (if (zero? (modulo i 4)) (##gc))
                    (loop (+ i 1) (cons p retained))))))))
       '(0 1 2 3 4 5)))
(for-each thread-start! workers)
(for-each thread-join! workers)
(define refused
  (with-exception-catcher
   (lambda (e)
     (if (no-such-file-or-directory-exception? e) #t (raise e)))
   (lambda ()
     (open-input-process (list path: "/this-program-does-not-exist"))
     #f)))
(if (not refused) (error "missing executable was accepted"))
(##gc)
(display "DARWIN-CHILD-STATUS-OK 96\n")
