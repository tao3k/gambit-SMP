;;; Same width and depth as the start-flush fixture. Not original
;;; acceptance and not (go 15 5000). thread-start! is bracketed by
;;; force-output. The primordial then sleeps 10 seconds and
;;; force-outputs the completion count before any join and before
;;; any statistics call. The 3600-second acceptance window is unchanged.

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

(define (emit port)
  (display "# schema tfib-after-start-flush.v1" port)
  (newline port)
  (display "# after-sleep-completions is force-output after thread-sleep! of 10 seconds" port)
  (newline port)
  (display "# no statistics call and no root join in this fixture" port)
  (newline port)
  (write-env port "GAMBIT_SMP_AVAILABLE_CPUS")
  (write-env port "GAMBIT_SMP_EXPECTED_PROCESSORS")
  (display "processors " port)
  (write (##current-vm-processor-count) port)
  (newline port)
  (force-output port)
  (let ((threads (make-roots)))
    (display "before-start" port)
    (newline port)
    (force-output port)
    (for-each thread-start! threads)
    (display "after-start" port)
    (newline port)
    (force-output port)
    (display "completions-at-start " port)
    (write (count-done) port)
    (newline port)
    (force-output port)
    (thread-sleep! 10)
    (display "after-sleep-completions " port)
    (write (count-done) port)
    (newline port)
    (force-output port)))

(call-with-output-file "tfib-after-start-flush.txt" emit)
(println "AFTER-START-FLUSH")
