;;; Interpreted delay sample for the current numeric-host gsi.
;;; Not (go 15 5000). Not native acceptance.
;;; Slot order is ##process-statistics in this producer's lib/_kernel.scm.

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

(define time-slots '(0 1 2 3 4 5 12 13 14))

(define (slot-exact stats i)
  (let ((x (##f64vector-ref stats i)))
    (if (memv i time-slots)
        (##flonum->exact-int (##flround (##fl* x 1000000.0)))
        (##flonum->exact-int (##flround x)))))

(define (write-row port label stats)
  (write label port)
  (write-char #\space port)
  (write (##current-vm-processor-count) port)
  (let loop ((i 0))
    (if (##fx< i 20)
        (begin
          (write-char #\space port)
          (write (slot-exact stats i) port)
          (loop (##fx+ i 1)))
        (newline port))))

(define (write-env port name)
  (display name port)
  (display "=" port)
  (let ((value (getenv name)))
    (display (if (string? value) value "absent") port))
  (newline port))

(define (emit port)
  (display "# schema tfib-delay-sample.v1" port)
  (newline port)
  (display "# times-are-rounded-microseconds other-slots-are-rounded-whole-values" port)
  (newline port)
  (display "# slots user sys real gc-user gc-sys gc-real nb-gcs bytes-allocated fixed-constant call-alloc minflt majflt latest-gc-user latest-gc-sys latest-gc-real latest-heap latest-alloc latest-live latest-movable latest-still" port)
  (newline port)
  (display "# user-includes-gc-user sys-includes-gc-sys call-alloc-is-that-statistics-call" port)
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
        (begin
          (short-delay)
          (let ((s1 (##process-statistics)))
            (let loop ((i 0))
              (if (##fx< i 200)
                  (begin
                    (short-delay)
                    (loop (##fx+ i 1)))))
            (let ((s2 (##process-statistics)))
              (tfib 10)
              (let ((s3 (##process-statistics)))
                (write-row port 'load s0)
                (write-row port 'one-delay s1)
                (write-row port 'repeat-200 s2)
                (write-row port 'tfib-10 s3))))))))

(call-with-output-file "tfib-delay-sample.txt" emit)
(println "TFIB-DELAY-SAMPLE")
