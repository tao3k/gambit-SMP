;;; Eight identical busy-sleep phases, then one tfib(10), on the current gsi.
;;; No mutex-lock!. Not (go 15 5000). Not native acceptance.
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

(define (phase-delays n)
  (let loop ((i 0))
    (if (##fx< i n)
        (begin
          (short-delay)
          (loop (##fx+ i 1))))))

(define phase-count 40)

(define (emit port)
  (display "# schema tfib-gc-wall-repeat.v1" port)
  (newline port)
  (display "# times-are-rounded-microseconds other-slots-are-rounded-whole-values" port)
  (newline port)
  (display "# slots user sys real gc-user gc-sys gc-real nb-gcs bytes-allocated fixed-constant call-alloc minflt majflt latest-gc-user latest-gc-sys latest-gc-real latest-heap latest-alloc latest-live latest-movable latest-still" port)
  (newline port)
  (display "# user-includes-gc-user sys-includes-gc-sys call-alloc-is-that-statistics-call" port)
  (newline port)
  (display "# p1 through p8 are identical phases of 40 short-delays and no threads" port)
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
        (let ((rows (##make-vector 10 #f)))
          (##vector-set! rows 0 s0)
          (let loop ((k 1))
            (if (##fx< k 9)
                (begin
                  (phase-delays phase-count)
                  (##vector-set! rows k (##process-statistics))
                  (loop (##fx+ k 1)))))
          (tfib 10)
          (##vector-set! rows 9 (##process-statistics))
          (write-row port 'load (##vector-ref rows 0))
          (write-row port 'p1 (##vector-ref rows 1))
          (write-row port 'p2 (##vector-ref rows 2))
          (write-row port 'p3 (##vector-ref rows 3))
          (write-row port 'p4 (##vector-ref rows 4))
          (write-row port 'p5 (##vector-ref rows 5))
          (write-row port 'p6 (##vector-ref rows 6))
          (write-row port 'p7 (##vector-ref rows 7))
          (write-row port 'p8 (##vector-ref rows 8))
          (write-row port 'tfib-10 (##vector-ref rows 9))))))

(call-with-output-file "tfib-gc-wall-repeat.txt" emit)
(println "GC-WALL-REPEAT")
