;;; Same (go 15 5000) body: 5000 roots, each runs tfib(15), all started,
;;; then the original would join in list order. This file does not perform
;;; that unbounded join. Each root stores 1 in its own vector slot when
;;; tfib returns. The primordial sleeps and records process statistics.
;;; Not native acceptance.

(declare (standard-bindings) (block))

(define (busy-sleep n) (if (> n 0) (busy-sleep (- n 1)) #f))

(define (short-delay) (busy-sleep 6000))

(define (tfib n)
  (short-delay)
  (if (< n 2)
      1
      (let* ((x (thread-start! (make-thread (lambda () (tfib (- n 2))))))
             (y (tfib (- n 1))))
        (+ (thread-join! x) y))))

(define width 5000)
(define depth 15)
(define observe-seconds 90)

(define done (##make-vector width 0))

(define (count-done)
  (let loop ((i 0) (n 0))
    (if (##fx< i width)
        (loop (##fx+ i 1)
              (if (##fx= (##vector-ref done i) 1)
                  (##fx+ n 1)
                  n))
        n)))

(define (make-roots)
  (let loop ((i (##fx- width 1)) (threads '()))
    (if (##fx< i 0)
        threads
        (let ((index i))
          (loop (##fx- i 1)
                (cons (make-thread
                       (lambda ()
                         (let ((answer (tfib depth)))
                           (##vector-set! done index 1)
                           answer)))
                      threads))))))

(define time-slots '(0 1 2 3 4 5))

(define (slot-exact stats i)
  (let ((x (##f64vector-ref stats i)))
    (if (memv i time-slots)
        (##flonum->exact-int (##flround (##fl* x 1000000.0)))
        (##flonum->exact-int (##flround x)))))

(define (write-row port label stats completions)
  (write label port)
  (write-char #\space port)
  (write (##current-vm-processor-count) port)
  (let loop ((i 0))
    (if (##fx< i 12)
        (begin
          (write-char #\space port)
          (write (slot-exact stats i) port)
          (loop (##fx+ i 1)))
        (begin
          (write-char #\space port)
          (write completions port)
          (newline port)))))

(define (write-env port name)
  (display name port)
  (display "=" port)
  (let ((value (getenv name)))
    (display (if (string? value) value "absent") port))
  (newline port))

(define (emit port)
  (display "# schema tfib-population-wait.v1" port)
  (newline port)
  (display "# times-are-rounded-microseconds completions-are-roots-whose-tfib-returned" port)
  (newline port)
  (display "# slots user sys real gc-user gc-sys gc-real nb-gcs bytes-allocated fixed-constant call-alloc minflt majflt completions" port)
  (newline port)
  (display "# 5000 roots of depth 15 started together; no unbounded root join" port)
  (newline port)
  (write-env port "GAMBIT_SMP_AVAILABLE_CPUS")
  (write-env port "GAMBIT_SMP_EXPECTED_PROCESSORS")
  (let ((s0 (##process-statistics)))
    (if (not (##fx= (##f64vector-length s0) 20))
        (begin
          (display "layout-mismatch " port)
          (write (##f64vector-length s0) port)
          (newline port)
          (force-output port)
          (exit 2))
        (let ((threads (make-roots)))
          (write-row port 'load s0 0)
          (force-output port)
          (for-each thread-start! threads)
          (let ((started (##process-statistics)))
            (write-row port 'started started  (count-done))
            (force-output port)
            (let ((origin (##f64vector-ref started 2)))
              (let loop ((k 0))
                (let* ((stats (##process-statistics))
                       (completed (count-done))
                       (elapsed (##fl- (##f64vector-ref stats 2) origin)))
                  (write-row port
                             (string->symbol
                              (string-append "s" (number->string k)))
                             stats
                             completed)
                  (force-output port)
                  (if (and (##fx< completed width)
                           (##fl< elapsed (exact->inexact observe-seconds)))
                      (begin
                        (thread-sleep! 2)
                        (loop (##fx+ k 1)))))))
            (let ((probe (thread-join! (car threads) 0 'running)))
              (display "root0-join " port)
              (write probe port)
              (newline port)
              (write-row port 'probe (##process-statistics) (count-done))
              (force-output port)))))))

(call-with-output-file "tfib-population-wait.txt" emit)
(println "POPULATION-WAIT")
