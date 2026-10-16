;;; Positive native control: RC roots survive successful processor retirement.
(c-declare #<<c-end
#include <stdlib.h>
static void *held[___MAX_PROCESSORS];
static ___SCMOBJ original[___MAX_PROCESSORS];
static int held_count;
static int retain_root(___processor_state ___ps, ___SCMOBJ value)
{
  int id = ___PROCESSOR_ID(___ps, ___VMSTATE_FROM_PSTATE(___ps));
  int type = ___HD_TYP(___HEADER(value));
  if (id <= 0 || id >= ___MAX_PROCESSORS || held[id] != NULL ||
      (type != ___MOVABLE0 && type != ___MOVABLE1))
    return 0;
  held[id] = ___EXT(___alloc_rc)(___PSP 1);
  if (!held[id]) return 0;
  ___EXT(___set_data_rc)(held[id], value);
  original[id] = value; /* Unregistered address observation, not a GC root. */
  return 1;
}
static int root_moved(int id)
{
  return held[id] && ___EXT(___data_rc)(held[id]) != original[id];
}
static ___SCMOBJ root_value(int id)
{
  return held[id] ? ___EXT(___data_rc)(held[id]) : ___FAL;
}
static void release_roots(void)
{
  int i;
  for (i = 1; i < ___MAX_PROCESSORS; ++i)
    if (held[i])
      {
        ___EXT(___release_rc)(held[i]);
        held[i] = NULL;
        original[i] = ___FAL;
        ++held_count;
      }
}
c-end
)
(define retain! (c-lambda (scheme-object) bool "___return(retain_root(___PSTATE, ___arg1));"))
(define moved? (c-lambda (int) bool "root_moved"))
(define retained (c-lambda (int) scheme-object "root_value"))
(define release! (c-lambda () void "release_roots"))
(define released-count (c-lambda () int "___return(held_count);"))
(define (require value message) (if (not value) (error message)))
(define (run-control)
  (require (= (processor-id (current-processor)) 0) "root owner must actually run on P0")
  (let* ((population (##current-vm-processor-count))
         (workers
          (let loop ((index 1))
            (if (= index population) '()
                (let ((worker
                       (make-thread
                        (lambda ()
                          (require (= (processor-id (current-processor)) index) "wrong donor processor")
                          (require (retain! (make-vector 32 (+ 1000 index))) "RC root allocation failed")
                          #t))))
                  (##thread-pin! worker (##processor index))
                  (thread-start! worker)
                  (cons worker (loop (+ index 1))))))))
    (require (> population 1) "multiple processors required")
    (for-each (lambda (worker) (require (eq? (thread-join! worker) #t) "donor task incomplete")) workers)
    (require (equal? (##current-vm-resize ##startup-processor! 1) 0) "successful retirement required")
    (##gc)
    (let loop ((index 1))
      (if (< index population)
          (begin
            (require (moved? index) "registered root did not relocate")
            (let ((value (retained index)))
              (require (and (vector? value) (= (vector-length value) 32)
                            (= (vector-ref value 31) (+ 1000 index))) "retired RC payload corrupted"))
            (loop (+ index 1)))))
    (release!)
    (require (= (released-count) (- population 1)) "RC handle release count mismatch")))
(define owner (make-thread run-control))
(##thread-pin! owner (##processor 0))
(thread-start! owner)
(thread-join! owner)
(display "RETIRED-RC-ROOT-SURVIVAL:PASS\n")
