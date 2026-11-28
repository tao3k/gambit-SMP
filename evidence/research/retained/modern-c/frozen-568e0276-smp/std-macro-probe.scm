(define probe-start (cpu-time))
(define probe-phase 'entry)
(define probe-lookup 0)
(define probe-samples 0)
(define probe-sampled-cpu 0.)
(define probe-match 0)
(define (probe-report mark)
  (write (list 'gsc-phase mark probe-phase (- (cpu-time) probe-start)
               probe-lookup probe-samples probe-sampled-cpu probe-match))
  (newline)
  (force-output))

(define original-env-lookup c#env-lookup)
(set! c#env-lookup
      (lambda (env name stop? receive)
        (set! probe-lookup (+ probe-lookup 1))
        (if (= (bitwise-and probe-lookup 4095) 0) (probe-report 'lookup-checkpoint))
        (if (= (bitwise-and probe-lookup 127) 0)
            (let ((start (cpu-time)))
              (original-env-lookup
               env name stop?
               (lambda (found-env canonical binding)
                 (set! probe-samples (+ probe-samples 1))
                 (set! probe-sampled-cpu (+ probe-sampled-cpu (- (cpu-time) start)))
                 (receive found-env canonical binding))))
            (original-env-lookup env name stop? receive))))

;; The same-module direct calls remain unobserved by these wrappers.
(define original-match c#match)
(set! c#match
      (lambda (head size source env)
        (set! probe-match (+ probe-match 1))
        (original-match head size source env)))

(define original-parse c#parse-program)
(set! c#parse-program
      (lambda (program env module-ref receive)
        (set! probe-phase 'parse)
        (probe-report 'begin)
        (original-parse program env module-ref
                        (lambda args
                          (probe-report 'parsed)
                          (set! probe-phase 'after-parse)
                          (apply receive args)))))

(probe-report 'installed)
(define (probe-macro? name)
  (let ((text (symbol->string name)))
    (or (member name '(identity macro-define-macros-from-unicode-files
                               macro-define-unicode-tables))
        (and (> (string-length text) 1)
             (let loop ((i (- (string-length text) 1)))
               (cond ((< i 0) #f)
                     ((char=? (string-ref text i) #\#)
                      (member (substring text (+ i 1) (string-length text))
                              '("macro-define-macros-from-unicode-files"
                                "macro-define-unicode-tables")))
                     (else (loop (- i 1)))))))))
(define original-env-macro c#env-macro)
(set! c#env-macro
      (lambda (env name descr)
        (if (probe-macro? name)
            (let ((expand (c#**macro-descr-expander descr)))
              (original-env-macro
               env name
               (c#**make-macro-descr
                (c#**macro-descr-def-syntax? descr)
                (c#**macro-descr-size descr)
                (lambda args
                  (probe-report (list 'macro-enter name))
                  (let ((result (apply expand args)))
                    (probe-report (list 'macro-exit name))
                    result))
                (c#**macro-descr-expander-src descr))))
            (original-env-macro env name descr))))
