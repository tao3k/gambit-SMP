;;; Same width and depth as (go 15 5000): 5000 roots, each runs tfib(15),
;;; all started. The original program then joins in list order. This file
;;; does not perform that unbounded join. The primordial sleeps, then counts
;;; roots whose tfib has returned. A separate OS process samples the gsi pid
;;; with ps. Not native acceptance. The 3600-second acceptance window is
;;; unchanged.

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

(define (pid-text pid)
  (cond ((##fixnum? pid) (##number->string pid))
        ((number? pid) (number->string pid))
        (else #f)))

(define (start-sampler pid-string)
  (open-process
   (list path: "/bin/sh"
         arguments:
         (list "-c"
               "pid=$1; out=$2; i=0; while [ \"$i\" -lt 24 ]; do /bin/ps -p \"$pid\" -o pid=,state=,etime=,time=,rss=,vsz= >> \"$out\" 2>&1 || echo \"ps-failed $i\" >> \"$out\"; i=$((i+1)); /bin/sleep 1; done; echo DONE >> \"$out\""
               "_"
               pid-string
               "host-sample.txt")
         stdin-redirection: #f
         stdout-redirection: #f
         stderr-redirection: #f)))

(define (write-count port label n)
  (display label port)
  (display " " port)
  (write n port)
  (newline port)
  (force-output port))

(define (emit port)
  (display "# schema tfib-population-host-sample.v1" port)
  (newline port)
  (display "# completions are roots whose tfib returned" port)
  (newline port)
  (display "# no unbounded root join; host-sample.txt is ps of this pid" port)
  (newline port)
  (display "processors " port)
  (write (##current-vm-processor-count) port)
  (newline port)
  (let* ((pid (##os-getpid))
         (text (pid-text pid)))
    (display "pid " port)
    (write pid port)
    (newline port)
    (force-output port)
    (if (not text)
        (begin
          (display "pid-unusable" port)
          (newline port)
          (force-output port)
          (exit 2))
        (begin
          (call-with-output-file
           "host-sample.txt"
           (lambda (sample)
             (display "# schema tfib-population-host-sample-ps.v1" sample)
             (newline sample)
             (display "# columns pid state etime time rss vsz" sample)
             (newline sample)))
          (let* ((sampler (start-sampler text))
                 (_mark (begin
                          (display "sampler-started" port)
                          (newline port)
                          (force-output port)))
                 (threads (make-roots)))
            (for-each thread-start! threads)
            (write-count port "started" (count-done))
            (thread-sleep! 6)
            (write-count port "after-sleep" (count-done))
            (display "root0-join " port)
            (write (thread-join! (car threads) 0 'running) port)
            (newline port)
            (force-output port)
            (display "sampler-status " port)
            (write (process-status sampler) port)
            (newline port)
            (force-output port)
            (close-port sampler))))))

(call-with-output-file "tfib-population-host-sample.txt" emit)
(println "POPULATION-HOST-SAMPLE")
