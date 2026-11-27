;;;============================================================================
;;; Phase C4-A: Paired 1:1 Gambit (gambit fiber) / (gambit effect) vs Rust Tokio
;;; 12-Core High-Order Benchmark Suite
;;;
;;; Workloads (exact 1:1 parameters with benchmarks/rust-smp/src/main.rs):
;;;   1. ht_effect_pingpong    : 12 pairs x 150 batches x 100 bounded-ch (cap=16) rounds
;;;   2. ht_generator_stream   : 12 lanes x 150 batches x 200 bounded-ch (cap=32) items
;;;   3. ht_fiber_fanout_100k  : 100 structured nurseries x 1000 yielding fibers = 100,000
;;;   4. lexa_cap_tail_12c     : 12 workers x 200 batches x 1000 O(1) Lexa perform-cap ops
;;;============================================================================

(import (gambit fiber))
(import (gambit effect))
(import (srfi 230))

(c-declare "#include <sys/resource.h>")
(define get-peak-rss-mib
  (c-lambda () double
    "struct rusage r; getrusage(RUSAGE_SELF, &r);
#ifdef __APPLE__
     ___return((double)r.ru_maxrss / (1024.0 * 1024.0));
#else
     ___return((double)r.ru_maxrss / 1024.0);
#endif"))

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

(define (report-result name workers total-ops elapsed-us samples s0 s1)
  (vector-sort-fx! samples)
  (let* ((ops-s (inexact->exact (round (/ (* total-ops 1000000.0) (max 1 elapsed-us)))))
         (gcs (inexact->exact (round (- (f64vector-ref s1 6) (f64vector-ref s0 6)))))
         (gc-ms (inexact->exact (round (* 1000.0 (- (f64vector-ref s1 5) (f64vector-ref s0 5))))))
         (rss (/ (round (* 10.0 (get-peak-rss-mib))) 10.0)))
    (display "[GAMBIT] ") (display name)
    (display " | w=") (display workers)
    (display " | work=") (display (/ (round (/ elapsed-us 100.0)) 10000.0)) (display "s")
    (display " | ops/s=") (display ops-s)
    (display " | p50=") (display (percentile samples 0.50)) (display "us")
    (display " | p95=") (display (percentile samples 0.95)) (display "us")
    (display " | p99=") (display (percentile samples 0.99)) (display "us")
    (display " | p99.9=") (display (percentile samples 0.999)) (display "us")
    (display " | max=") (display (percentile samples 1.00)) (display "us")
    (display " | gcs=") (display gcs)
    (display " | gc_ms=") (display gc-ms)
    (display " | rss=") (display rss) (display "MiB")
    (newline)))

(define workers
  (let ((env (getenv "FIBER_WORKERS" "12")))
    (or (string->number env) 12)))

;;;----------------------------------------------------------------------------
;;; 1. ht_effect_pingpong (1:1 match with Rust Tokio mpsc::channel(16))

(define (bench-ht-effect-pingpong w)
  (let* ((pairs (max 1 w))
         (batches 150)
         (rounds 100)
         (total-rounds (fx* batches rounds))
         (samples (make-vector (fx* pairs batches) 0))
         (s0 (##process-statistics))
         (t0 (now-us)))
    (run-fibers
     (lambda ()
       (with-nursery
        (lambda (n)
          (let ploop ((p 0))
            (if (fx< p pairs)
                (begin
                  (fiber-spawn
                   (lambda ()
                     (let ((c1 (make-fiber-channel 16))
                           (c2 (make-fiber-channel 16))
                           (base (fx* p batches)))
                       (with-nursery
                        (lambda (pn)
                          (fiber-spawn
                           (lambda ()
                             (let rloop ((i 0))
                               (if (fx< i total-rounds)
                                   (let ((v (fiber-recv! c1)))
                                     (fiber-send! c2 (fx+ v 1))
                                     (rloop (fx+ i 1))))))
                           pn)
                          (fiber-spawn
                           (lambda ()
                             (let bloop ((b 0) (acc 0))
                               (if (fx< b batches)
                                   (let ((bt0 (now-us)))
                                     (let iloop ((r 0) (a acc))
                                       (if (fx< r rounds)
                                           (begin
                                             (fiber-send! c1 (fx+ p r))
                                             (iloop (fx+ r 1) (fx+ a (fiber-recv! c2))))
                                           (begin
                                             (vector-set! samples (fx+ base b) (fx- (now-us) bt0))
                                             (bloop (fx+ b 1) a))))))))
                           pn)))))
                   n)
                  (ploop (fx+ p 1))))))))
     workers: w)
    (let ((elapsed (fx- (now-us) t0))
          (s1 (##process-statistics)))
      (report-result "ht_effect_pingpong" w (* pairs total-rounds) elapsed samples s0 s1))))

;;;----------------------------------------------------------------------------
;;; 2. ht_generator_stream (1:1 match with Rust Tokio mpsc::channel(32))

(define (bench-ht-generator-stream w)
  (let* ((lanes (max 1 w))
         (batches 150)
         (items 200)
         (total-items (fx* batches items))
         (samples (make-vector (fx* lanes batches) 0))
         (s0 (##process-statistics))
         (t0 (now-us)))
    (run-fibers
     (lambda ()
       (with-nursery
        (lambda (n)
          (let lloop ((lane 0))
            (if (fx< lane lanes)
                (begin
                  (fiber-spawn
                   (lambda ()
                     (let ((ch (make-fiber-channel 32))
                           (base (fx* lane batches)))
                       (with-nursery
                        (lambda (ln)
                          (fiber-spawn
                           (lambda ()
                             (let ploop ((i 0))
                               (if (fx< i total-items)
                                   (begin
                                     (fiber-send! ch (fx+ lane i))
                                     (ploop (fx+ i 1))))))
                           ln)
                          (fiber-spawn
                           (lambda ()
                             (let bloop ((b 0) (acc 0))
                               (if (fx< b batches)
                                   (let ((bt0 (now-us)))
                                     (let iloop ((i 0) (a acc))
                                       (if (fx< i items)
                                           (iloop (fx+ i 1) (fx+ a (fiber-recv! ch)))
                                           (begin
                                             (vector-set! samples (fx+ base b) (fx- (now-us) bt0))
                                             (bloop (fx+ b 1) a))))))))
                           ln)))))
                   n)
                  (lloop (fx+ lane 1))))))))
     workers: w)
    (let ((elapsed (fx- (now-us) t0))
          (s1 (##process-statistics)))
      (report-result "ht_generator_stream" w (* lanes total-items) elapsed samples s0 s1))))

;;;----------------------------------------------------------------------------
;;; 3. ht_fiber_fanout_100k (100 nurseries x 1000 yielding fibers = 100,000)

(define (bench-ht-fiber-fanout-100k w)
  (let* ((nurseries 100)
         (per-nursery 1000)
         (completed (make-atomic-fxbox 0))
         (samples (make-vector nurseries 0))
         (s0 (##process-statistics))
         (t0 (now-us)))
    (run-fibers
     (lambda ()
       (let nloop ((ni 0))
         (if (fx< ni nurseries)
             (let ((bt0 (now-us)))
               (with-nursery
                (lambda (n)
                  (let floop ((fi 0))
                    (if (fx< fi per-nursery)
                        (begin
                          (fiber-spawn
                           (lambda ()
                             (fiber-yield)
                             (atomic-fxbox+/fetch! completed 1))
                           n)
                          (floop (fx+ fi 1)))))))
               (vector-set! samples ni (fx- (now-us) bt0))
               (nloop (fx+ ni 1))))))
     workers: w)
    (let ((elapsed (fx- (now-us) t0))
          (s1 (##process-statistics)))
      (if (not (fx= (atomic-fxbox-ref completed) (fx* nurseries per-nursery)))
          (error "fanout count mismatch" (atomic-fxbox-ref completed)))
      (report-result "ht_fiber_fanout_100k" w (* nurseries per-nursery) elapsed samples s0 s1))))

;;;----------------------------------------------------------------------------
;;; 4. lexa_cap_tail_12c (Lexa OOPSLA '24 O(1) Lexical Capability Fast Path)

(define (bench-lexa-cap-tail w)
  (let* ((batches 200)
         (batch-size 1000)
         (samples (make-vector (fx* w batches) 0))
         (s0 (##process-statistics))
         (t0 (now-us))
         (threads
          (let loop ((i 0) (acc '()))
            (if (fx= i w)
                acc
                (loop (fx+ i 1)
                      (cons
                       (thread-start!
                        (make-thread
                         (lambda ()
                           (let ((base (fx* i batches)))
                             (with-capability-handler add-cap
                               (tail: (x) (fx+ x 1))
                               (let bloop ((b 0))
                                 (if (fx< b batches)
                                     (let ((bt0 (now-us)))
                                       (let iloop ((k 0) (a 0))
                                         (if (fx< k batch-size)
                                             (iloop (fx+ k 1) (perform-cap add-cap a))
                                             a))
                                       (vector-set! samples (fx+ base b) (fx- (now-us) bt0))
                                       (bloop (fx+ b 1))))))))))
                       acc))))))
    (for-each thread-join! threads)
    (let ((elapsed (fx- (now-us) t0))
          (s1 (##process-statistics)))
      (report-result "lexa_cap_tail" w (* w batches batch-size) elapsed samples s0 s1))))

;; Run all 4 paired benchmarks
(bench-ht-effect-pingpong workers)
(bench-ht-generator-stream workers)
(bench-ht-fiber-fanout-100k workers)
(bench-lexa-cap-tail workers)
(exit 0)
