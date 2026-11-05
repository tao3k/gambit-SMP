;;; Same width and depth as the population that flushed the started row.
;;; Not original acceptance and not (go 15 5000). File ports are fully
;;; buffered, so this program force-outputs the sleep-returned line
;;; before any join and before the statistics call. The primordial
;;; sleeps 20 seconds. A missing line means that force-output did not
;;; run. The 3600-second acceptance window is unchanged.

(declare (standard-bindings) (block))

(define (busy-sleep n)
  (if (> n 0) (busy-sleep (- n 1)) #f))

(define (short-delay)
  (busy-sleep 6000))

(define (tfib n)
  (short-delay)
  (if (< n 2)
      1
      (let* ((x (thread-start! (make-thread (lambda () (tfib (- n 2))))))
             (y (tfib (- n 1))))
        (+ (thread-join! x) y))))

(define width 5000)
(define depth 15)

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
  (display "# schema tfib-sleep-flush.v1" port)
  (newline port)
  (display "# times-are-rounded-microseconds completions-are-roots-whose-tfib-returned" port)
  (newline port)
  (display "# slots user sys real gc-user gc-sys gc-real nb-gcs bytes-allocated fixed-constant call-alloc minflt majflt completions" port)
  (newline port)
  (display "# sleep-returned is force-output before any join and before statistics" port)
  (newline port)
  (display "# no root join in this fixture" port)
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
            (write-row port 'started started (count-done))
            (force-output port)
            (thread-sleep! 20)
            (display "sleep-returned" port)
            (newline port)
            (force-output port)
            (display "completions " port)
            (write (count-done) port)
            (newline port)
            (force-output port)
            (let ((slept (##process-statistics)))
              (write-row port 'slept slept (count-done))
              (force-output port)))))))

(call-with-output-file "tfib-sleep-flush.txt" emit)
(println "SLEEP-RETURNED")
