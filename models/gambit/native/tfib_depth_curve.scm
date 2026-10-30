;;; One tree at each depth 10 through 15, on the current gsi.
;;; No mutex-lock!. Not (go 15 5000). Not 5000 roots. Not native acceptance.
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

(define (write-row port label stats result)
  (write label port)
  (write-char #\space port)
  (write (##current-vm-processor-count) port)
  (let loop ((i 0))
    (if (##fx< i 20)
        (begin
          (write-char #\space port)
          (write (slot-exact stats i) port)
          (loop (##fx+ i 1)))
        (begin
          (write-char #\space port)
          (write result port)
          (newline port)))))

(define (write-env port name)
  (display name port)
  (display "=" port)
  (let ((value (getenv name)))
    (display (if (string? value) value "absent") port))
  (newline port))

(define (heartbeat-microseconds)
  (let ((v (##make-f64vector 1 0.0)))
    (##get-heartbeat-interval! v 0)
    (##flonum->exact-int (##flround (##fl* (##f64vector-ref v 0) 1000000.0)))))

(define (quantum-microseconds)
  (##flonum->exact-int
   (##flround (##fl* (thread-quantum (current-thread)) 1000000.0))))

(define depths '(10 11 12 13 14 15))
(define expected-results '(89 144 233 377 610 987))

(define (emit port)
  (display "# schema tfib-depth-curve.v1" port)
  (newline port)
  (display "# times-are-rounded-microseconds other-slots-are-rounded-whole-values" port)
  (newline port)
  (display "# slots user sys real gc-user gc-sys gc-real nb-gcs bytes-allocated fixed-constant call-alloc minflt majflt latest-gc-user latest-gc-sys latest-gc-real latest-heap latest-alloc latest-live latest-movable latest-still result" port)
  (newline port)
  (display "# one tree per depth; not go-15-repeat-5000; not native acceptance" port)
  (newline port)
  (write-env port "GAMBIT_SMP_AVAILABLE_CPUS")
  (write-env port "GAMBIT_SMP_EXPECTED_PROCESSORS")
  (display "heartbeat-microseconds " port)
  (write (heartbeat-microseconds) port)
  (newline port)
  (display "root-quantum-microseconds " port)
  (write (quantum-microseconds) port)
  (newline port)
  (let ((s0 (##process-statistics)))
    (if (not (##fx= (##f64vector-length s0) 20))
        (begin
          (display "layout-mismatch " port)
          (write (##f64vector-length s0) port)
          (newline port)
          (force-output port)
          (exit 2))
        (let ((rows (##make-vector 7 #f))
              (results (##make-vector 6 #f)))
          (##vector-set! rows 0 s0)
          (let loop ((k 0))
            (if (##fx< k 6)
                (let ((n (list-ref depths k)))
                  (##vector-set! results k (tfib n))
                  (##vector-set! rows (##fx+ k 1) (##process-statistics))
                  (loop (##fx+ k 1)))))
          (write-row port 'load (##vector-ref rows 0) 0)
          (let loop ((k 0))
            (if (##fx< k 6)
                (begin
                  (write-row port
                             (string->symbol
                              (string-append "d" (number->string (list-ref depths k))))
                             (##vector-ref rows (##fx+ k 1))
                             (##vector-ref results k))
                  (loop (##fx+ k 1)))))
          (let loop ((k 0) (mismatch #f))
            (if (##fx< k 6)
                (loop (##fx+ k 1)
                      (or mismatch
                          (not (##fx= (##vector-ref results k)
                                      (list-ref expected-results k)))))
                (begin
                  (display "result-check " port)
                  (display (if mismatch "mismatch" "match") port)
                  (newline port))))))))

(call-with-output-file "tfib-depth-curve.txt" emit)
(println "DEPTH-CURVE")
