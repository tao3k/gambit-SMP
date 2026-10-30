;;; Native Scheme composition of the independent named suite cases. The suite
;;; owns each case's original budgets and raw receipts; failures do not skip
;;; siblings and cannot be erased by retrying inside this campaign.
(##namespace ("gambit#tests#smp#campaign#"
              root runtime out names statuses run-case write-status suite))
(define root (path-expand (getenv "GAMBIT_SMP_ROOT" ".")))
(define runtime (path-expand (getenv "GAMBIT_SMP_RUNTIME" root)))
(define out (path-expand (getenv "GAMBIT_SMP_CAMPAIGN_OUT")))
(define statuses '())
(load (path-expand "tests/smp/catalog.scm" (string-append root "/")))
(define names
  (let partition ((rows gambit#tests#smp#cases) (mailbox '()) (others '()))
    (if (null? rows) (append (reverse mailbox) (reverse others))
        (if (string=? (list-ref (car rows) 6) "gambit.smp.scheduler.mailbox")
            (partition (cdr rows) (cons (caar rows) mailbox) others)
            (partition (cdr rows) mailbox (cons (caar rows) others))))))
(define suite (path-expand "tests/smp/suite.scm" (string-append root "/")))
(define (write-status)
  (call-with-output-file (string-append out "/campaign.scm")
    (lambda (p) (write (reverse statuses) p) (newline p))))
(define (run-case name)
  (setenv "GAMBIT_SMP_CASE" name)
  (setenv "GAMBIT_SMP_OUT" (string-append out "/" name))
  (setenv "GAMBOPT" (string-append "p1,~~lib=" runtime "/lib,~~bin=" runtime "/bin,~~include=" runtime "/include"))
  (let* ((p (open-process
             (list path: "/opt/homebrew/bin/gtimeout"
                   arguments: (list "--kill-after=2s" "120s" (string-append runtime "/gsi/gsi") suite)
                   directory: root stderr-redirection: #t)))
         (reader (make-thread
                  (lambda ()
                    (call-with-output-file (string-append out "/" name ".output")
                      (lambda (log)
                        (let loop ((b (read-u8 p)))
                          (if (not (eof-object? b))
                              (begin (write-u8 b log) (loop (read-u8 p)))))))))))
    (close-output-port p) (thread-start! reader)
    (let ((status (process-status p 123 'unknown))
          (joined (thread-join! reader 2 'unknown)))
      (close-input-port p)
      (set! statuses (cons (list name status (not (eq? joined 'unknown))) statuses))
      (write-status)
      (write (car statuses)) (newline))))
(create-directory out)
(for-each run-case names)
(exit (let all ((rows statuses))
        (if (null? rows) 0
            (let ((row (car rows)))
              (if (and (number? (cadr row)) (= (cadr row) 0) (caddr row))
                  (all (cdr rows)) 1)))))
