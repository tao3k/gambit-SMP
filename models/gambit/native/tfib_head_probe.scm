;;; Same width and depth as the start-flush fixture. Not original
;;; acceptance and not (go 15 5000). force-output brackets
;;; thread-start!, then a zero-timeout thread-join! of the list head,
;;; then another force-output, all before the port closes. No
;;; statistics call. Each marker line ends with one monotonic tick
;;; from ##get-monotonic-time! so a later sample can split the gap
;;; after thread-start! returns. completions is a plain vector read.
;;; The join result is the synchronized observation of that one root.
;;; The 3600-second acceptance window is unchanged.

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

(define (write-env port name)
  (display name port)
  (display "=" port)
  (let ((value (getenv name)))
    (display (if (string? value) value "absent") port))
  (newline port))

(define mono (##make-u64vector 1))

(define (write-tick port)
  (##get-monotonic-time! mono 0)
  (write-char #\space port)
  (write (##u64vector-ref mono 0) port)
  (newline port)
  (force-output port))

(define (emit port)
  (display "# schema tfib-head-probe.v2" port)
  (newline port)
  (display "# before-roots, before-start, and after-start bracket make-roots and thread-start!" port)
  (newline port)
  (display "# each marker ends with one monotonic tick; frequency is ticks per second" port)
  (newline port)
  (display "# head-join is thread-join! of the list head with timeout 0" port)
  (newline port)
  (display "# pending means that root had not finished; a number is its result" port)
  (newline port)
  (display "# completions is an unsynchronized vector count, not the join" port)
  (newline port)
  (write-env port "GAMBIT_SMP_AVAILABLE_CPUS")
  (write-env port "GAMBIT_SMP_EXPECTED_PROCESSORS")
  (display "processors " port)
  (write (##current-vm-processor-count) port)
  (newline port)
  (force-output port)
  (let ((frequency (##make-u64vector 1)))
    (##get-monotonic-time-frequency! frequency 0)
    (display "monotonic-frequency " port)
    (write (##u64vector-ref frequency 0) port)
    (newline port)
    (force-output port))
  (display "before-roots" port)
  (write-tick port)
  (let ((threads (make-roots)))
    (display "before-start" port)
    (write-tick port)
    (for-each thread-start! threads)
    (display "after-start" port)
    (write-tick port)
    (display "completions " port)
    (write (count-done) port)
    (write-tick port)
    (display "head-join " port)
    (write (thread-join! (car threads) 0 'pending) port)
    (write-tick port)
    (display "after-join" port)
    (write-tick port)))

(call-with-output-file "tfib-head-probe.txt" emit)
(println "HEAD-PROBE")
