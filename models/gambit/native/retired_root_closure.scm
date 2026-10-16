;;; RC and independently referenced still roots across successful retirement.
(c-declare #<<c-end
#include <stdlib.h>
static void *held[___MAX_PROCESSORS];
static ___SCMOBJ still[___MAX_PROCESSORS];
static ___SCMOBJ previous[___MAX_PROCESSORS];
static int rc_released, still_released;
static int allocate_still(___processor_state ___ps, int id)
{
  if (id <= 0 || id >= ___MAX_PROCESSORS || still[id] != 0) return 0;
  /* Immediate arguments obey ___make_pair's nonmovable input contract. */
  still[id] = ___EXT(___make_pair)(___ps, ___FIX(id), ___FAL);
  if (___FIXNUMP(still[id])) { still[id] = 0; return 0; }
  return ___HD_TYP(___HEADER(still[id])) == ___STILL;
}
static int retain(___processor_state ___ps, ___SCMOBJ value)
{
  int id = ___PROCESSOR_ID(___ps, ___VMSTATE_FROM_PSTATE(___ps));
  int type = ___HD_TYP(___HEADER(value));
  if (id <= 0 || id >= ___MAX_PROCESSORS || !still[id] || held[id] ||
      (type != ___MOVABLE0 && type != ___MOVABLE1)) return 0;
  held[id] = ___EXT(___alloc_rc)(___PSP 1);
  if (!held[id]) return 0;
  ___EXT(___set_data_rc)(held[id], value);
  /* No allocating call between the input and publication in the still root. */
  ___CDR_FIELD(still[id]) = value;
  previous[id] = value; /* Address observation only, not a registered root. */
  return 1;
}
static ___SCMOBJ payload(int id) { return ___CDR(still[id]); }
static int roots_agree(int id)
{
  return held[id] && ___EXT(___data_rc)(held[id]) == payload(id) &&
    ___CAR(still[id]) == ___FIX(id) && payload(id) != previous[id];
}
static void release_rc(void)
{
  int i;
  for (i = 1; i < ___MAX_PROCESSORS; ++i)
    if (held[i])
      {
        previous[i] = payload(i);
        ___EXT(___release_rc)(held[i]);
        held[i] = NULL;
        ++rc_released;
      }
}
static int still_moved(int id) { return payload(id) != previous[id]; }
static void release_still(void)
{
  int i;
  for (i = 1; i < ___MAX_PROCESSORS; ++i)
    if (still[i])
      {
        ___EXT(___release_scmobj)(still[i]);
        still[i] = 0;
        previous[i] = ___FAL;
        ++still_released;
      }
}
c-end
)
(define allocate! (c-lambda (int) bool "___return(allocate_still(___PSTATE, ___arg1));"))
(define retain! (c-lambda (scheme-object) bool "___return(retain(___PSTATE, ___arg1));"))
(define agree? (c-lambda (int) bool "roots_agree"))
(define value (c-lambda (int) scheme-object "payload"))
(define moved? (c-lambda (int) bool "still_moved"))
(define release-rc! (c-lambda () void "release_rc"))
(define release-still! (c-lambda () void "release_still"))
(define released? (c-lambda (int) bool "___return(rc_released == ___arg1 && still_released == ___arg1);"))
(define (require ok message) (if (not ok) (error message)))
(define (check-payload id)
  (let ((v (value id)))
    (require (and (vector? v) (= (vector-length v) 32)
                  (= (vector-ref v 31) (+ 1000 id))) "still closure payload corrupted")))
(define (run-control)
  (require (= (processor-id (current-processor)) 0) "owner must run on P0")
  (let* ((population (##current-vm-processor-count))
         (workers
          (let loop ((id 1))
            (if (= id population) '()
                (let ((worker (make-thread
                               (lambda ()
                                 (require (= (processor-id (current-processor)) id) "wrong donor")
                                 (require (allocate! id) "still allocation failed")
                                 (require (retain! (make-vector 32 (+ 1000 id))) "RC allocation failed")
                                 #t))))
                  (##thread-pin! worker (##processor id))
                  (thread-start! worker)
                  (cons worker (loop (+ id 1))))))))
    (require (> population 1) "multiple processors required")
    (for-each (lambda (worker) (require (eq? (thread-join! worker) #t) "worker incomplete")) workers)
    (require (equal? (##current-vm-resize ##startup-processor! 1) 0) "successful retirement required")
    (##gc)
    (let loop ((id 1))
      (if (< id population)
          (begin (require (agree? id) "RC/still relocation disagreement")
                 (check-payload id) (loop (+ id 1)))))
    (release-rc!)
    ;; No Scheme-held payload and no RC handle: only the still refcount is live.
    (##gc)
    (let loop ((id 1))
      (if (< id population)
          (begin (require (moved? id) "still-only child did not relocate")
                 (check-payload id) (loop (+ id 1)))))
    (release-still!)
    (require (released? (- population 1)) "root release count mismatch")
    (##gc)))
(define owner (make-thread run-control))
(##thread-pin! owner (##processor 0))
(thread-start! owner)
(thread-join! owner)
(display "RETIRED-ROOT-CLOSURE:PASS\n")
