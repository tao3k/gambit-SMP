;; Inspect source forms with the native reader, not a parenthesis scanner.
(with-exception-catcher
 (lambda (e) (display-exception e (current-error-port)) (exit 70))
 (lambda ()
   (call-with-input-file
    branch-source-path
    (lambda (port)
      (let* ((form (read port)) (clauses (cdr form)))
        (if (not (and (eq? (car form) 'cond-expand)
                      (= (length clauses) 2)
                      (equal? (map car clauses) '(enable-smp else))
                      (eof-object? (read port))))
            (error "unexpected scheduler branch structure"))
        (for-each
         (lambda (clause)
           (let ((definitions
                  (let scan ((forms (cdr clause)) (count 0))
                    (if (null? forms)
                        count
                        (let ((x (car forms)))
                          (scan
                           (cdr forms)
                           (+ count
                              (if (and (pair? x)
                                       (eq? (car x) 'define-prim)
                                       (pair? (cdr x))
                                       (pair? (cadr x))
                                       (eq? (caadr x) '##thread-check-devices!))
                                  1 0))))))))
             (write (list 'scheduler-clause (car clause)
                          'thread-check-devices-definitions definitions))
             (newline)
             (if (not (= definitions 1))
                 (error "scheduler definition not uniquely scoped"))))
         clauses))))
   (display "BRANCH-SCOPE-PASS\n")
   (exit 0)))
