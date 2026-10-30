;;; Same width and depth as (go 15 5000). The prefix through the started
;;; row matches the in-band sample that flushed load and started. There is
;;; no polling loop and no second statistics call after that flush. The
;;; primordial then sleeps. A child process samples this pid with ps for
;;; the whole interval, including after the flush. Not native acceptance.
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

(define (pid-text pid)
  (cond ((##fixnum? pid) (##number->string pid))
        ((number? pid) (number->string pid))
        (else #f)))

(define (start-sampler pid-string)
  (open-process
   (list path: "/bin/sh"
         arguments:
         (list "-c"
               "pid=$1; out=$2; i=0; while [ \"$i\" -lt 12 ]; do /bin/ps -p \"$pid\" -o pid=,state=,etime=,time=,rss=,vsz= >> \"$out\" 2>&1 || echo \"ps-failed $i\" >> \"$out\"; if [ $((i % 4)) -eq 0 ]; then echo \"MACH-BEGIN $i\" >> \"$out\"; /bin/ps -M -p \"$pid\" >> \"$out\" 2>&1 || echo \"ps-m-failed $i\" >> \"$out\"; echo \"MACH-END $i\" >> \"$out\"; fi; i=$((i+1)); /bin/sleep 1; done; echo DONE >> \"$out\""
               "_"
               pid-string
               "host-sample.txt")
         stdin-redirection: #f
         stdout-redirection: #f
         stderr-redirection: #f)))

(define (emit port)
  (display "# schema tfib-population-after-start.v1" port)
  (newline port)
  (display "# times-are-rounded-microseconds completions-are-roots-whose-tfib-returned" port)
  (newline port)
  (display "# slots user sys real gc-user gc-sys gc-real nb-gcs bytes-allocated fixed-constant call-alloc minflt majflt completions" port)
  (newline port)
  (display "# host-sample.txt is ps of this pid and continues if this file stops" port)
  (newline port)
  (display "# no unbounded root join and no statistics call after the started row" port)
  (newline port)
  (write-env port "GAMBIT_SMP_AVAILABLE_CPUS")
  (write-env port "GAMBIT_SMP_EXPECTED_PROCESSORS")
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
             (display "# schema tfib-population-after-start-ps.v1" sample)
             (newline sample)
             (display "# process columns pid state etime time rss vsz" sample)
             (newline sample)
             (display "# MACH blocks are ps -M thread state, not stack samples" sample)
             (newline sample)))
          (let ((sampler (start-sampler text))
                (s0 (##process-statistics)))
            (display "sampler-started" port)
            (newline port)
            (force-output port)
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
                    (thread-sleep! 3)
                    (display "after-sleep " port)
                    (write (count-done) port)
                    (newline port)
                    (display "root0-join " port)
                    (write (thread-join! (car threads) 0 'running) port)
                    (newline port)
                    (force-output port)
                    (display "sampler-status " port)
                    (write (process-status sampler) port)
                    (newline port)
                    (force-output port)
                    (close-port sampler)))))))))

(call-with-output-file "tfib-population-after-start.txt" emit)
(println "POPULATION-AFTER-START")
