;;;============================================================================
;;; Phase C1 Frontier Continuation & Algebraic Effect Benchmark (p1 / p12)
;;; Measures ops/s and real P50 / P95 / P99 batch latencies across:
;;;   1. Koka Tail-Resumptive `perform` (zero-capture fast path)
;;;   2. Delimited One-Shot `perform` / `resume` (SRFI 226 + SRFI 230 CAS)
;;;   3. Direct-Style `make-generator` / `yield`
;;;   4. Multi-Shot `resume-multishot` (lazy ONE_SHOT_LIVE -> MULTISHOT_COW)
;;;============================================================================

(##demand-module gambit/effect)
(##demand-module srfi/226)
(##demand-module srfi/230)
(import (gambit effect))
(import (srfi 226))
(import (srfi 230))

(define-effect bench-ask)
(define-effect bench-step)
(define-effect bench-choose)

(define (now-us)
  (inexact->exact (round (* (real-time) 1000000.0))))

(define (vector-sort-fx! v)
  (let ((n (vector-length v)))
    (let loop ((i 1))
      (if (fx< i n)
          (let ((key (vector-ref v i)))
            (let inner ((j (fx- i 1)))
              (if (and (fx>= j 0) (fx> (vector-ref v j) key))
                  (begin
                    (vector-set! v (fx+ j 1) (vector-ref v j))
                    (inner (fx- j 1)))
                  (vector-set! v (fx+ j 1) key)))
            (loop (fx+ i 1)))))))

(define (percentile sorted-v p)
  (let* ((n (vector-length sorted-v))
         (idx (min (fx- n 1) (inexact->exact (floor (* p n))))))
    (vector-ref sorted-v idx)))

(define (run-bench name workers batches batch-size worker-fn)
  (let* ((samples (make-vector (fx* workers batches) 0))
         (t0 (now-us))
         (threads
          (let loop ((w 0) (acc '()))
            (if (fx= w workers)
                acc
                (loop (fx+ w 1)
                      (cons
                       (thread-start!
                        (make-thread
                         (lambda ()
                           (let ((base (fx* w batches)))
                             (let bloop ((b 0))
                               (if (fx< b batches)
                                   (let ((bt0 (now-us)))
                                     (worker-fn batch-size)
                                     (vector-set! samples (fx+ base b) (fx- (now-us) bt0))
                                     (bloop (fx+ b 1)))))))))
                       acc))))))
    (for-each thread-join! threads)
    (let* ((elapsed-us (max 1 (fx- (now-us) t0)))
           (total-ops (* workers batches batch-size))
           (ops-per-sec (inexact->exact (round (/ (* total-ops 1000000.0) elapsed-us)))))
      (vector-sort-fx! samples)
      (display name) (display " | w=") (display workers)
      (display " | ops/s=") (display ops-per-sec)
      (display " | P50=") (display (percentile samples 0.50)) (display "us")
      (display " | P95=") (display (percentile samples 0.95)) (display "us")
      (display " | P99=") (display (percentile samples 0.99)) (display "us")
      (display " | Max=") (display (percentile samples 1.00)) (display "us")
      (newline))))

(define workers
  (let ((env (getenv "C1_WORKERS" "1")))
    (or (string->number env) 1)))

;; 1. Koka Tail-Resumptive Fast Path
(run-bench
 "effect_tail_resumptive"
 workers 200 1000
 (lambda (n)
   (with-handler
     ((tail: bench-ask () 1))
     (let loop ((i 0) (acc 0))
       (if (fx< i n)
           (loop (fx+ i 1) (fx+ acc (perform bench-ask)))
           acc)))))

;; 2. Suspending One-Shot Effect (perform + resume)
(run-bench
 "effect_oneshot_suspend"
 workers 100 100
 (lambda (n)
   (with-handler
     ((bench-step (k x) (resume k (fx+ x 1))))
     (let loop ((i 0) (acc 0))
       (if (fx< i n)
           (loop (fx+ i 1) (perform bench-step acc))
           acc)))))

;; 3. Direct-Style Generator (make-generator / yield)
(run-bench
 "effect_generator_yield"
 workers 100 100
 (lambda (n)
   (let ((g (make-generator
             (lambda ()
               (let loop ((i 0))
                 (if (fx< i n)
                     (begin (perform yield i) (loop (fx+ i 1)))))))))
     (let loop ((acc 0))
       (let ((v (g)))
         (if (eof-object? v) acc (loop (fx+ acc v))))))))

;; 4. Multi-Shot Lazy Promotion (resume-multishot)
(run-bench
 "effect_multishot_cow"
 workers 100 20
 (lambda (n)
   (let loop ((i 0) (acc 0))
     (if (fx< i n)
         (let ((res
                (with-handler
                  ((bench-choose (k)
                     (fx+ (resume-multishot k 1)
                          (resume-multishot k 2))))
                  (let ((a (perform bench-choose))
                        (b (perform bench-choose)))
                    (fx+ a b)))))
           (loop (fx+ i 1) (fx+ acc res)))
         acc))))

(exit 0)
