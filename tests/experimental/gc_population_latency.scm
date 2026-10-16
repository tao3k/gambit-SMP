;;; Identical moving live-set, paired AB/BA/AB collector populations.
(c-declare #<<c-end
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
static FILE *samples;
static uint64_t gc_clock(void) {
  struct timespec ts;
  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) abort();
  return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}
static int start_samples(int population) {
  const char *capacity = getenv("GAMBIT_SMP_AVAILABLE_CPUS");
  if (!capacity || population < 2) return 0;
  samples = fopen("gc-samples.jsonl", "w");
  if (!samples) return 0;
  return fprintf(samples,
    "{\"schema\":\"native-latency-samples.v1\",\"cpuCapacity\":%d,\"groups\":[{\"population\":1,\"owners\":1,\"rounds\":120},{\"population\":%d,\"owners\":1,\"rounds\":120}]}\n",
    atoi(capacity), population) > 0;
}
static void sample_gc(int population, int round, uint64_t elapsed) {
  if (fprintf(samples,"{\"population\":%d,\"owner\":1,\"round\":%d,\"nanoseconds\":%llu}\n",
      population,round,(unsigned long long)elapsed) < 0) abort();
}
static int close_samples(void) { return fclose(samples) == 0; }
c-end
)
(define clock (c-lambda () unsigned-long-long "gc_clock"))
(define start! (c-lambda (int) bool "start_samples"))
(define sample! (c-lambda (int int unsigned-long-long) void "sample_gc"))
(define close! (c-lambda () bool "close_samples"))
(define (require ok) (if (not ok) (error "GC population control failed")))
(define (workload)
  (let ((roots (make-vector 1024)))
    (let loop ((i 0))
      (if (< i 1024)
          (begin (vector-set! roots i (make-vector 32 1042)) (loop (+ i 1)))))
    roots))
(define (check roots)
  (let outer ((i 0))
    (if (< i 1024)
        (begin
          (let ((root (vector-ref roots i)))
            (let inner ((j 0))
              (if (< j 32)
                  (begin (require (= (vector-ref root j) 1042)) (inner (+ j 1))))))
          (outer (+ i 1))))))
(define (run)
  (require (= (processor-id (current-processor)) 0))
  (let ((population (##current-vm-processor-count))
        (serial-round 0) (parallel-round 0))
    (require (start! population))
    (for-each
      (lambda (target)
        (require (= (##current-vm-resize ##startup-processor! target) 0))
        (require (= (##current-vm-processor-count) target))
        (let loop ((i 0))
          (if (< i 40)
              (let* ((roots (workload)) (before (clock)))
                (##gc)
                (let ((elapsed (- (clock) before)))
                  (check roots)
                  (sample! target (if (= target 1) serial-round parallel-round) elapsed))
                (if (= target 1)
                    (set! serial-round (+ serial-round 1))
                    (set! parallel-round (+ parallel-round 1)))
                (loop (+ i 1))))))
      (list 1 population population 1 1 population))
    (require (and (= serial-round 120) (= parallel-round 120)))
    (require (close!))))
(define owner (make-thread run))
(##thread-pin! owner (##processor 0))
(thread-start! owner)
(thread-join! owner)
(display "GC-POPULATION-LATENCY:PASS\n")
