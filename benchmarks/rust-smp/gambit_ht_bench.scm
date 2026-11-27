;;; High-Throughput & Tail-Latency (P50/P95/P99/P99.9/Max) SMP Benchmark Suite
;;; 1:1 matched against benchmarks/rust-smp/src/main.rs (Rayon + Tokio).
;;;
;;; Workloads:
;;;   1. ht_concurrent_kv_ycsb  — 80% read / 20% write sharded concurrent table ((gambit concurrent))
;;;   2. ht_mpmc_pipeline       — Multi-stage lock-free MPMC queue pipeline ((gambit concurrent))
;;;   3. ht_graph_bfs_churn     — Large live old-gen graph traversal + dynamic edge churn
;;;   4. ht_workstealing_dag    — Irregular skewed task DAG work-stealing ((gambit concurrent) ws-deque)

(import (srfi 230)
        (gambit concurrent))

;;; ---------------------------------------------------------------------------
;;; High-resolution microsecond timer & percentile statistics
;;; ---------------------------------------------------------------------------

(define (now-us)
  (* (##current-time-point) 1000000.0))

(define (quicksort-f64! vec lo hi)
  (when (< lo hi)
    (let* ((pivot (f64vector-ref vec (quotient (+ lo hi) 2)))
           (i lo)
           (j hi))
      (let loop ()
        (let loop-i ()
          (when (< (f64vector-ref vec i) pivot)
            (set! i (+ i 1))
            (loop-i)))
        (let loop-j ()
          (when (> (f64vector-ref vec j) pivot)
            (set! j (- j 1))
            (loop-j)))
        (when (<= i j)
          (let ((tmp (f64vector-ref vec i)))
            (f64vector-set! vec i (f64vector-ref vec j))
            (f64vector-set! vec j tmp)
            (set! i (+ i 1))
            (set! j (- j 1))
            (loop))))
      (when (< lo j) (quicksort-f64! vec lo j))
      (when (< i hi) (quicksort-f64! vec i hi)))))

(define (percentile-f64 sorted-vec q)
  (let* ((n (f64vector-length sorted-vec))
         (idx (max 0 (min (- n 1) (inexact->exact (ceiling (* q n)))))))
    (f64vector-ref sorted-vec (max 0 (- idx 1)))))

(define (merge-latencies vec-of-f64)
  (let* ((n-w (vector-length vec-of-f64))
         (total (let loop ((i 0) (acc 0))
                  (if (= i n-w) acc
                      (loop (+ i 1) (+ acc (f64vector-length (vector-ref vec-of-f64 i)))))))
         (out (make-f64vector total 0.0)))
    (let loop ((i 0) (pos 0))
      (if (= i n-w)
          out
          (let* ((v (vector-ref vec-of-f64 i))
                 (len (f64vector-length v)))
            (let inner ((k 0))
              (when (< k len)
                (f64vector-set! out (+ pos k) (f64vector-ref v k))
                (inner (+ k 1))))
            (loop (+ i 1) (+ pos len)))))))

(define (emit-ht-result name workers total-ops work-real gc-count gc-real lats-vec)
  (let* ((merged (merge-latencies lats-vec))
         (n (f64vector-length merged)))
    (when (> n 1) (quicksort-f64! merged 0 (- n 1)))
    (let ((p50 (if (> n 0) (percentile-f64 merged 0.50) 0.0))
          (p95 (if (> n 0) (percentile-f64 merged 0.95) 0.0))
          (p99 (if (> n 0) (percentile-f64 merged 0.99) 0.0))
          (p999 (if (> n 0) (percentile-f64 merged 0.999) 0.0))
          (mx (if (> n 0) (f64vector-ref merged (- n 1)) 0.0))
          (ops-s (if (> work-real 0.0) (/ total-ops work-real) 0.0)))
      (println "HT_RESULT name=" name
               " workers=" workers
               " ops=" total-ops
               " samples=" n
               " work_real=" work-real
               " ops_per_sec=" ops-s
               " p50_us=" p50
               " p95_us=" p95
               " p99_us=" p99
               " p999_us=" p999
               " max_us=" mx
               " gcs=" gc-count
               " gc_real=" gc-real))))

;;; ---------------------------------------------------------------------------
;;; 1. ht_concurrent_kv_ycsb — 80% Read / 20% Write Concurrent Table
;;; ---------------------------------------------------------------------------

(define (run-ht-kv-ycsb workers)
  (let* ((keyspace 8192)
         (batches-per-worker 160)
         (batch-ops 256)
         ;; 4096 buckets -> average load factor ~2.0, matching Rust HashMap
         (tbl (make-concurrent-table 4096))
         (lats (make-vector workers #f)))
    ;; Pre-populate keyspace
    (let init ((k 0))
      (when (< k keyspace)
        (concurrent-table-set! tbl k (vector k 0 (make-vector 8 k)))
        (init (+ k 1))))
    (##gc)
    (let* ((s0 (##process-statistics))
           (t0 (##current-time-point))
           (threads
            (let spawn ((w 0) (acc '()))
              (if (= w workers)
                  acc
                  (spawn (+ w 1)
                         (cons
                          (thread-start!
                           (make-thread
                            (lambda ()
                              (let ((wlat (make-f64vector batches-per-worker 0.0))
                                    (seed (+ (* w 1103515245) 12345))
                                    (checksum 0))
                                (let bloop ((b 0))
                                  (when (< b batches-per-worker)
                                    (let ((bt0 (now-us)))
                                      (let oloop ((o 0))
                                        (when (< o batch-ops)
                                          (set! seed (bitwise-and (+ (* seed 1664525) 1013904223) #x7fffffff))
                                          (let ((key (bitwise-and seed (- keyspace 1)))
                                                (op-kind (modulo (arithmetic-shift seed -16) 5)))
                                            (if (= op-kind 0)
                                                ;; 20% write with fresh heap payload
                                                (concurrent-table-set!
                                                 tbl key (vector key (+ b o) (make-vector 8 key)))
                                                ;; 80% wait-free read
                                                (let ((v (concurrent-table-ref tbl key #f)))
                                                  (when v
                                                    (set! checksum (+ checksum (vector-ref v 0)))))))
                                          (oloop (+ o 1))))
                                      (f64vector-set! wlat b (- (now-us) bt0)))
                                    (bloop (+ b 1))))
                                (vector-set! lats w wlat)
                                checksum))))
                          acc)))))
           (total-cs (let join-all ((ts threads) (acc 0))
                       (if (null? ts) acc
                           (join-all (cdr ts) (+ acc (thread-join! (car ts)))))))
           (work-real (- (##current-time-point) t0))
           (s1 (##process-statistics))
           (gcs (inexact->exact (round (- (f64vector-ref s1 6) (f64vector-ref s0 6)))))
           (gc-real (- (f64vector-ref s1 5) (f64vector-ref s0 5))))
      (when (= total-cs -1) (error "impossible"))
      (emit-ht-result "ht_concurrent_kv_ycsb"
                      workers
                      (* workers batches-per-worker batch-ops)
                      work-real gcs gc-real lats))))

;;; ---------------------------------------------------------------------------
;;; 2. ht_mpmc_pipeline — Multi-Stage Lock-Free MPMC Queue Pipeline
;;; ---------------------------------------------------------------------------

(define (run-ht-mpmc-pipeline workers)
  (let* ((half (max 1 (quotient workers 2)))
         (batches-per-prod 250)
         (batch-msgs 64)
         (msgs-per-prod (* batches-per-prod batch-msgs))
         (total-msgs (* half msgs-per-prod))
         (q1 (make-lf-queue))
         (q2 (make-lf-queue))
         (consumed (make-atomic-fxbox 0))
         (lats (make-vector half #f)))
    (##gc)
    (let* ((s0 (##process-statistics))
           (t0 (##current-time-point))
           ;; Stage 2 transformers (pull from q1, allocate transformed record, push to q2)
           (transformers
            (let spawn ((i 0) (acc '()))
              (if (= i half)
                  acc
                  (spawn (+ i 1)
                         (cons
                          (thread-start!
                           (make-thread
                            (lambda ()
                                  (let loop ((done 0) (spins 0))
                                    (when (< done msgs-per-prod)
                                      (call-with-values
                                          (lambda () (lf-queue-try-dequeue! q1))
                                        (lambda (ok? item)
                                          (if ok?
                                              (let* ((id (vector-ref item 0))
                                                     (ts (vector-ref item 1))
                                                     (out (vector (+ id 1) ts (make-vector 4 id))))
                                                (lf-queue-enqueue! q2 out)
                                                (loop (+ done 1) 0))
                                              (if (< spins 32)
                                                  (loop done (+ spins 1))
                                                  (begin
                                                    (thread-yield!)
                                                    (loop done 0)))))))))))
                          acc)))))
           ;; Stage 3 consumers (drain q2 and measure end-to-end batch latency)
           (consumers
            (let spawn ((i 0) (acc '()))
              (if (= i half)
                  acc
                  (spawn (+ i 1)
                         (cons
                          (thread-start!
                           (make-thread
                            (lambda ()
                              (let ((wlat (make-f64vector batches-per-prod 0.0))
                                    (b 0)
                                    (in-batch 0)
                                    (batch-max 0.0)
                                    (cs 0))
                                (let loop ((done 0) (spins 0))
                                  (when (< done msgs-per-prod)
                                    (call-with-values
                                        (lambda () (lf-queue-try-dequeue! q2))
                                      (lambda (ok? item)
                                        (if ok?
                                            (let* ((dt (- (now-us) (vector-ref item 1))))
                                              (when (> dt batch-max) (set! batch-max dt))
                                              (set! cs (+ cs (vector-ref item 0)))
                                              (set! in-batch (+ in-batch 1))
                                              (when (= in-batch batch-msgs)
                                                (f64vector-set! wlat b batch-max)
                                                (set! b (+ b 1))
                                                (set! in-batch 0)
                                                (set! batch-max 0.0))
                                              (atomic-fxbox+/fetch! consumed 1 (memory-order relaxed))
                                              (loop (+ done 1) 0))
                                            (if (< spins 32)
                                                (loop done (+ spins 1))
                                                (begin
                                                  (thread-yield!)
                                                  (loop done 0))))))))
                                (vector-set! lats i wlat)
                                cs))))
                          acc)))))
           ;; Stage 1 producers (stamp now-us and push to q1)
           (producers
            (let spawn ((i 0) (acc '()))
              (if (= i half)
                  acc
                  (spawn (+ i 1)
                         (cons
                          (thread-start!
                           (make-thread
                            (lambda ()
                              (let bloop ((b 0))
                                (when (< b batches-per-prod)
                                  (let ((ts (now-us)))
                                    (let mloop ((m 0))
                                      (when (< m batch-msgs)
                                        (lf-queue-enqueue! q1 (vector (+ (* i msgs-per-prod) (* b batch-msgs) m) ts))
                                        (mloop (+ m 1)))))
                                  (bloop (+ b 1)))))))
                          acc)))))
           (_p (for-each thread-join! producers))
           (_t (for-each thread-join! transformers))
           (_c (for-each thread-join! consumers))
           (work-real (- (##current-time-point) t0))
           (s1 (##process-statistics))
           (gcs (inexact->exact (round (- (f64vector-ref s1 6) (f64vector-ref s0 6)))))
           (gc-real (- (f64vector-ref s1 5) (f64vector-ref s0 5))))
      (when (not (= (atomic-fxbox-ref consumed (memory-order acquire)) total-msgs))
        (error "mpmc count mismatch"))
      (emit-ht-result "ht_mpmc_pipeline"
                      workers total-msgs work-real gcs gc-real lats))))

;;; ---------------------------------------------------------------------------
;;; 3. ht_graph_bfs_churn — Large Live Old-Gen Graph Traversal + Dynamic Churn
;;; ---------------------------------------------------------------------------

(define (make-graph-node id n-nodes)
  (let ((edges (make-vector 8 0))
        (payload (make-vector 8 id)))
    (let loop ((e 0))
      (when (< e 8)
        (vector-set! edges e (bitwise-and (+ (* id 31) (* e 997) 17) (- n-nodes 1)))
        (loop (+ e 1))))
    (vector id edges payload)))

(define (run-ht-graph-bfs-churn workers)
  (let* ((n-nodes 32768)
         (graph (make-vector n-nodes #f))
         (waves-per-worker 128)
         (nodes-per-wave 256)
         (lats (make-vector workers #f)))
    ;; Build persistent old-gen live graph (~32768 nodes x 8 edges = 262,144 edges)
    (let init ((i 0))
      (when (< i n-nodes)
        (vector-set! graph i (make-graph-node i n-nodes))
        (init (+ i 1))))
    (##gc)
    (let* ((s0 (##process-statistics))
           (t0 (##current-time-point))
           (threads
            (let spawn ((w 0) (acc '()))
              (if (= w workers)
                  acc
                  (spawn (+ w 1)
                         (cons
                          (thread-start!
                           (make-thread
                            (lambda ()
                              (let ((wlat (make-f64vector waves-per-worker 0.0))
                                    (stride (quotient n-nodes workers))
                                    (base (* w (quotient n-nodes workers)))
                                    (acc-sum 0))
                                (let wloop ((wv 0))
                                  (when (< wv waves-per-worker)
                                    (let ((wt0 (now-us)))
                                      (let nloop ((k 0))
                                        (when (< k nodes-per-wave)
                                          (let* ((idx (bitwise-and (+ base (* wv 64) k) (- n-nodes 1)))
                                                 (node (vector-ref graph idx))
                                                 (edges (vector-ref node 1)))
                                            ;; Traverse 8 outgoing edges
                                            (let eloop ((e 0))
                                              (when (< e 8)
                                                (let* ((nbr-idx (vector-ref edges e))
                                                       (nbr (vector-ref graph nbr-idx)))
                                                  (set! acc-sum (+ acc-sum (vector-ref nbr 0))))
                                                (eloop (+ e 1))))
                                            ;; 12.5% dynamic node/edge replacement (old-gen write barrier + churn)
                                            (when (= (bitwise-and k 7) 0)
                                              (vector-set! graph idx (make-graph-node (+ idx wv) n-nodes))))
                                          (nloop (+ k 1))))
                                      (f64vector-set! wlat wv (- (now-us) wt0)))
                                    (wloop (+ wv 1))))
                                (vector-set! lats w wlat)
                                acc-sum))))
                          acc)))))
           (total-cs (let join-all ((ts threads) (acc 0))
                       (if (null? ts) acc
                           (join-all (cdr ts) (+ acc (thread-join! (car ts)))))))
           (work-real (- (##current-time-point) t0))
           (s1 (##process-statistics))
           (gcs (inexact->exact (round (- (f64vector-ref s1 6) (f64vector-ref s0 6)))))
           (gc-real (- (f64vector-ref s1 5) (f64vector-ref s0 5))))
      (when (= total-cs -1) (error "impossible"))
      (emit-ht-result "ht_graph_bfs_churn"
                      workers
                      (* workers waves-per-worker nodes-per-wave 8)
                      work-real gcs gc-real lats))))

;;; ---------------------------------------------------------------------------
;;; 4. ht_workstealing_dag — Irregular Skewed Task DAG Work-Stealing
;;; ---------------------------------------------------------------------------

(define (dag-task-work id)
  ;; Small heap-allocating irregular work unit
  (let* ((n (+ 8 (bitwise-and id 31)))
         (v (make-vector n id)))
    (let loop ((i 0) (acc 0))
      (if (= i n)
          acc
          (loop (+ i 1) (+ acc (vector-ref v i)))))))

(define (run-ht-workstealing-dag workers)
  (let* ((waves 128)
         (tasks-per-wave 512)
         (total-tasks (* waves tasks-per-wave))
         (deques (let loop ((i 0) (v (make-vector workers #f)))
                   (if (= i workers) v
                       (begin (vector-set! v i (make-ws-deque 2048))
                              (loop (+ i 1) v)))))
         (done-ctr (make-atomic-fxbox 0))
         (wave-gate (make-atomic-fxbox 0))
         (lats (make-vector 1 (make-f64vector waves 0.0))))
    (##gc)
    (let* ((s0 (##process-statistics))
           (t0 (##current-time-point))
           ;; Workers 1..workers-1 steal from worker 0's bursty Chase-Lev deque
           (stealers
            (let spawn ((w 1) (acc '()))
              (if (= w workers)
                  acc
                  (spawn (+ w 1)
                         (cons
                          (thread-start!
                           (make-thread
                            (lambda ()
                              (let ((cs 0))
                                (let loop ((spins 0))
                                  (let ((g (atomic-fxbox-ref wave-gate (memory-order acquire))))
                                    (when (>= g 0)
                                      (call-with-values
                                          (lambda () (ws-deque-try-steal! (vector-ref deques 0)))
                                        (lambda (ok? task)
                                          (if ok?
                                              (begin
                                                (set! cs (+ cs (dag-task-work task)))
                                                (atomic-fxbox+/fetch! done-ctr 1 (memory-order release))
                                                (loop 0))
                                              (if (< spins 32)
                                                  (loop (+ spins 1))
                                                  (begin
                                                    (thread-yield!)
                                                    (loop 0)))))))))
                                cs))))
                          acc)))))
           ;; Owner (worker 0) pushes skewed bursts each wave and helps pop locally
           (owner-cs
            (let ((q0 (vector-ref deques 0))
                  (wlat (vector-ref lats 0))
                  (cs 0))
              (let wloop ((wv 0))
                (when (< wv waves)
                  (let ((wt0 (now-us))
                        (target (* (+ wv 1) tasks-per-wave)))
                    (let push ((k 0))
                      (when (< k tasks-per-wave)
                        (ws-deque-push! q0 (+ (* wv tasks-per-wave) k))
                        (push (+ k 1))))
                    ;; Owner pops locally until deque empty, then waits for stealers
                    (let drain ()
                      (call-with-values
                          (lambda () (ws-deque-try-pop! q0))
                        (lambda (ok? task)
                          (when ok?
                            (set! cs (+ cs (dag-task-work task)))
                            (atomic-fxbox+/fetch! done-ctr 1 (memory-order release))
                            (drain)))))
                    (let wait ()
                      (when (< (atomic-fxbox-ref done-ctr (memory-order acquire)) target)
                        (thread-yield!)
                        (wait)))
                    (f64vector-set! wlat wv (- (now-us) wt0)))
                  (wloop (+ wv 1))))
              (atomic-fxbox-set! wave-gate -1 (memory-order release))
              cs))
           (_s (for-each thread-join! stealers))
           (work-real (- (##current-time-point) t0))
           (s1 (##process-statistics))
           (gcs (inexact->exact (round (- (f64vector-ref s1 6) (f64vector-ref s0 6)))))
           (gc-real (- (f64vector-ref s1 5) (f64vector-ref s0 5))))
      (when (= owner-cs -1) (error "impossible"))
      (emit-ht-result "ht_workstealing_dag"
                      workers total-tasks work-real gcs gc-real lats))))

;;; ---------------------------------------------------------------------------
;;; Entrypoint: gsi ... gambit_ht_bench.o1 <workload|all> <workers>
;;; ---------------------------------------------------------------------------

(let* ((env-target (getenv "HT_TARGET" #f))
       (env-workers (getenv "HT_WORKERS" #f))
       (args (command-line))
       (target (or env-target (if (>= (length args) 2) (list-ref args 1) "all")))
       (workers (if env-workers (string->number env-workers)
                    (if (>= (length args) 3) (string->number (list-ref args 2)) 12))))
  (when (or (string=? target "all") (string=? target "ht_concurrent_kv_ycsb"))
    (run-ht-kv-ycsb workers))
  (when (or (string=? target "all") (string=? target "ht_mpmc_pipeline"))
    (run-ht-mpmc-pipeline workers))
  (when (or (string=? target "all") (string=? target "ht_graph_bfs_churn"))
    (run-ht-graph-bfs-churn workers))
  (when (or (string=? target "all") (string=? target "ht_workstealing_dag"))
    (run-ht-workstealing-dag workers))
  (exit 0))
