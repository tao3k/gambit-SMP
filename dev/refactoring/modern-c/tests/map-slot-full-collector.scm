;;; Full-collector control for logical frame and denv observations.
;;; Observations bracket GC at Scheme entry and return.
(define saved #f)
(define exit-map #f)
(define sample-count 0)
(define winds '())

(cond-expand
 (mature-slot-native-comparator
  (c-declare "#include \"mature-slot-oracle.h\"")
  (define observe-repaired-slot
    (c-lambda (scheme-object int scheme-object int scheme-object scheme-object)
              bool
              #<<end-of-c
struct mature_slot_sample before = {1, (uintptr_t)___arg1,
                                    (uintptr_t)___arg2, 0};
struct mature_slot_sample after = {1, (uintptr_t)___arg3,
                                   (uintptr_t)___arg4, (uintptr_t)___arg5};
/* Both frame references are the reloaded Scheme identities at return.
 * This full-collector control does not have the pre-copy raw word. */
___result = mature_slot_compare(before, after, 1, (uintptr_t)___arg6)
            == MATURE_SLOT_MATCH;
end-of-c
)))
 (else
  (define (observe-repaired-slot before-frame before-index after-frame
                                 after-index value expected)
    (and (eq? before-frame after-frame) (= before-index after-index)
         (eq? value expected)))))

(define (find-slot cont)
  (let next-frame ((current cont) (fuel 128))
    (if (or (not current) (= fuel 0))
        (error "map fixture root missing from captured frames"))
    (let ((frame (##continuation-frame current)))
      (let next-slot ((i 1))
        (cond
         ((> i (##frame-fs frame))
          (next-frame (##continuation-next current) (- fuel 1)))
         ((and (##frame-slot-live? frame i)
               (vector? (##frame-ref frame i)))
          (cons frame i))
         (else (next-slot (+ i 1))))))))

(cond-expand
 (mature-slot-gc-cuts
  (c-declare #<<end-of-c
#include <string.h>
#include "mem.h"
#include "map-slot-gc-cuts.h"
#include "map-slot-remembered-gc.h"
#include "mature-slot-oracle.h"
#ifdef MAP_SLOT_SELECTIVE
#include "map-slot-selective-probe.h"
#endif

/* This fixture admits exactly one p1 collection at a time. RC roots keep
 * both source objects and independently expected referents visible. */
static struct {
  ___processor_state owner;
  void *roots[4];
  int index;
  int phase;
  uintptr_t epoch;
  ___SCMOBJ old_values[2]; /* diagnostic words, never traced */
  unsigned stale_detected[2];
} map_slot_probe;

static ___SCMOBJ *map_slot_frame_slot(___SCMOBJ frame, int index)
{
  ___SIZE_TS words = ___HD_WORDS(___SUBTYPED_HEADER(frame));
  return &___BODY_AS(frame,___tFRAME)[words-___FRAME_EXTRA_SLOTS-index+1];
}

/* DEV-only layout control. Allocate the destination before reloading
 * the rooted source. The still object's initial native reference keeps
 * the initialized copy live until the caller releases it. */
static ___SCMOBJ map_slot_still_copy(___processor_state ps, ___SCMOBJ source)
{
  if (!___MEM_ALLOCATED(source))
    return ___FAL;
  ___WORD head = ___HEADER(source);
  int subtype = ___HD_SUBTYPE(head);
  if (subtype != ___sFRAME && subtype != ___sVECTOR)
    return ___FAL;
  ___SIZE_TS words = ___HD_WORDS(head);
  void *root = ___alloc_rc(___PSA(ps) 0);
  if (!root)
    return ___FAL;
  ___SCMOBJ copy = ___FAL;
  if (___try_set_data_rc(ps, root, source)) {
    copy = ___alloc_scmobj(ps, subtype, words << ___LWS);
    if (!___FIXNUMP(copy)) {
      source = ___data_rc(root);
      memcpy(___BODY0(copy), ___BODY0(source),
             words * sizeof(___WORD));
    } else
      copy = ___FAL;
  }
  ___release_rc(root);
  return copy;
}

static int map_slot_gc_matches(void)
{
  ___SCMOBJ frame = ___data_rc(map_slot_probe.roots[0]);
  ___SCMOBJ cont = ___data_rc(map_slot_probe.roots[1]);
  return ___TESTTYPE(frame, ___tFRAME) &&
         ___TESTTYPE(cont, ___tCONTINUATION) &&
         *map_slot_frame_slot(frame, map_slot_probe.index) ==
           ___data_rc(map_slot_probe.roots[2]) &&
         ___CONTINUATION_DENV_FIELD(cont) ==
           ___data_rc(map_slot_probe.roots[3]);
}

void map_slot_gc_frozen(void *ps, uintptr_t epoch)
{
#ifdef MAP_SLOT_SELECTIVE
  map_slot_selective_frozen(ps, epoch);
#endif
  if (ps != map_slot_probe.owner || map_slot_probe.phase != 0)
    return;
  map_slot_probe.epoch = epoch;
  map_slot_probe.phase = map_slot_gc_matches() ? 1 : -1;
  if (map_slot_probe.phase == 1)
    for (int i = 0; i < 2; i++)
      map_slot_probe.old_values[i] = ___data_rc(map_slot_probe.roots[i+2]);
}

void map_slot_gc_repaired(void *ps, uintptr_t epoch)
{
#ifdef MAP_SLOT_SELECTIVE
  map_slot_selective_repaired(ps, epoch);
#endif
  map_remembered_after(ps);
  if (ps != map_slot_probe.owner || map_slot_probe.phase != 1)
    return;
  map_slot_probe.phase = map_slot_probe.epoch == epoch &&
                         map_slot_gc_matches() ? 2 : -1;
  if (map_slot_probe.phase != 2)
    return;
  ___SCMOBJ frame = ___data_rc(map_slot_probe.roots[0]);
  ___SCMOBJ cont = ___data_rc(map_slot_probe.roots[1]);
  ___SCMOBJ *slots[2] = {
    map_slot_frame_slot(frame, map_slot_probe.index),
    &___CONTINUATION_DENV_FIELD(cont)
  };
  for (int i = 0; i < 2; i++) {
    ___SCMOBJ expected = ___data_rc(map_slot_probe.roots[i+2]);
    if (expected == map_slot_probe.old_values[i])
      continue;
    struct mature_slot_sample before = {
      epoch, (uintptr_t)map_slot_probe.roots[i],
      i == 0 ? (uintptr_t)map_slot_probe.index : 1,
      (uintptr_t)map_slot_probe.old_values[i]
    };
    struct mature_slot_sample after = before;
    /* The independent RC root has already been repaired. Inject and
     * undo the stale word with all participants still at the test cut. */
    *slots[i] = map_slot_probe.old_values[i];
    after.value = (uintptr_t)*slots[i];
    enum mature_slot_result result =
      mature_slot_compare(before, after, 1, (uintptr_t)expected);
    *slots[i] = expected;
    if (result != MATURE_SLOT_STALE || !map_slot_gc_matches()) {
      map_slot_probe.phase = -1;
      return;
    }
    map_slot_probe.stale_detected[i]++;
  }
}
end-of-c
)
  (define (collect-with-slot-cuts frame index cont value denv)
    (if (not ((c-lambda (scheme-object int scheme-object scheme-object scheme-object)
                       bool
                       #<<end-of-c
___SCMOBJ values[4] = {___arg1, ___arg3, ___arg4, ___arg5};
int i;
___result = 0;
if (map_slot_probe.owner == 0 &&
    ___VMSTATE_FROM_PSTATE(___ps)->processor_count == 1 &&
    ___TESTTYPE(___arg1, ___tFRAME) && ___arg2 > 0 &&
    ___arg2 <= ___HD_WORDS(___SUBTYPED_HEADER(___arg1))-___FRAME_EXTRA_SLOTS) {
  for (i = 0; i < 4; i++) {
    map_slot_probe.roots[i] = ___alloc_rc(___PSA(___ps) 0);
    if (!map_slot_probe.roots[i]) break;
    ___set_data_rc(map_slot_probe.roots[i], values[i]);
  }
  if (i == 4) {
    map_slot_probe.owner = ___ps;
    map_slot_probe.index = ___arg2;
    map_slot_probe.phase = 0;
    ___result = !___garbage_collect(___PSA(___ps) 0) &&
                map_slot_probe.phase == 2;
    map_slot_probe.owner = 0;
  }
  while (i > 0) ___release_rc(map_slot_probe.roots[--i]);
}
end-of-c
)
              frame index cont value denv))
        (error "collector slot cut was missing or disagreed with its RC root")))
  (define still-copy
    (c-lambda (scheme-object) scheme-object
              "___result = map_slot_still_copy(___ps, ___arg1);"))
  (define release-still-copy
    (c-lambda (scheme-object) scheme-object
              "___result = ___release_scmobj(___arg1);"))
  (define still-address
    (c-lambda (scheme-object) unsigned-int64
              "___result = (uintptr_t)___arg1;"))
  (define (observe-still-layout frame index denv value)
    (let ((still-frame (still-copy frame)))
      (if (not still-frame) (error "cannot allocate still frame control"))
      (dynamic-wind
       (lambda () #f)
       (lambda ()
         (let ((still-denv (still-copy denv)))
           (if (not still-denv) (error "cannot allocate still denv control"))
           (dynamic-wind
            (lambda () #f)
            (lambda ()
              (let ((frame-address (still-address still-frame))
                    (denv-address (still-address still-denv)))
                (##gc)
                (if (not (and (= frame-address (still-address still-frame))
                              (= denv-address (still-address still-denv))
                              (= (##frame-fs still-frame) (##frame-fs frame))
                              (##frame-slot-live? still-frame index)
                              (eq? (##frame-ref still-frame index) value)
                              (equal? still-denv denv)))
                    (error "still frame or denv layout differs after GC"))
                (observe-selective-slots still-frame index still-denv value)))
            (lambda () (release-still-copy still-denv)))))
       (lambda () (release-still-copy still-frame))))))
 (else
  (define (observe-still-layout frame index denv value) #f)
  (define (collect-with-slot-cuts frame index cont value denv)
    (##gc))))

(cond-expand
 (mature-slot-native-pbt
  (define self (car (command-line)))
  (define (trace-tag) 'map-slot-native)
  (include "../../../../vendor/gambit/tests/root-task-replay.scm"))
 (else #f))

(cond-expand
 (mature-slot-selective
  (define selective-control
    (c-lambda (scheme-object int scheme-object scheme-object int) bool
              #<<end-of-c
___result = ___HD_TYP(___HEADER(___arg1)) == ___STILL &&
            ___HD_TYP(___HEADER(___arg3)) == ___STILL &&
            map_slot_selective_control(___ps,
              map_slot_frame_slot(___arg1, ___arg2), &___VECTORELEM(___arg3,0),
              ___arg4, ___arg5);
end-of-c
))
  (define (observe-selective-slots frame index denv value)
    (let ((original (vector-ref denv 0)))
      (dynamic-wind
       (lambda () #f)
       (lambda ()
         (for-each
          (lambda (mode)
            (if (not (selective-control frame index denv value mode))
                (error "collector slot selection or repair failed" mode))
            (##frame-set! frame index value))
          '(0 1 4 2))
         (observe-selective-pbt frame index denv value))
       (lambda ()
         (##frame-set! frame index value)
         (vector-set! denv 0 original))))))
 (else
  (define (observe-selective-slots frame index denv value) #f)))

(cond-expand
 (mature-slot-native-pbt
  (define (observe-selective-pbt frame index denv value)
    (let ((original (vector-ref denv 0)))
      (define (check mode)
        (let ((passed (selective-control frame index denv value mode)))
          (##frame-set! frame index value)
          (vector-set! denv 0 original)
          passed))
      (define (run commands fault)
        (let loop ((rest commands) (at 0))
          (if (null? rest)
              (list 'root-task-result 'pass at)
              (let* ((mode (car rest))
                     (omitted (and (= mode 1) fault)))
                (cond
                 ((= mode -1) (loop (cdr rest) (+ at 1)))
                 ((not (check (if omitted 3 mode)))
                  (error "native remembered replay failed" mode at))
                 (omitted (list 'root-task-result 'mismatch at 'rearm 0))
                 (else (loop (cdr rest) (+ at 1))))))))
      (let ((seed 317))
        (do ((i 0 (+ i 1))) ((= i 8))
          (let generate ((n 4) (commands '(0 1 2)))
            (if (= n 0)
                (if (signature (run commands #f))
                    (error "native remembered history failed"))
                (begin
                  (set! seed (modulo (* seed 48271) 2147483647))
                  (generate (- n 1) (cons (modulo seed 3) commands)))))))
      (let ((previous trial))
        (dynamic-wind
         (lambda () (set! trial run))
         (lambda ()
           (let* ((commands '(-1 2 -1 1 0 -1))
                  (wanted '(rearm 0))
                  (minimal (shrink commands #t wanted))
                  (encoded (call-with-output-string
                            (lambda (port)
                              (write (list (trace-tag) 1 minimal #t) port))))
                  (decoded (call-with-input-string encoded read)))
             (if (not (and (equal? (signature (run commands #t)) wanted)
                           (equal? minimal '(1))
                           (one-minimal? minimal #t wanted)
                           (equal? (signature (run (caddr decoded) (cadddr decoded))) wanted)
                           (not (signature (run minimal #f)))))
                 (error "native remembered replay/shrink failed" encoded))
             (display "MAP-SLOT-NATIVE-PBT-PASS histories=8 actions=56 shrink=6-to-1\n")))
         (lambda () (set! trial previous)))))))
 (else
  (define (observe-selective-pbt frame index denv value) #f)))

(define (observe-collection)
  (let* ((denv (##continuation-denv saved))
         (before (find-slot saved))
         (value (##frame-ref (car before) (cdr before))))
    (observe-still-layout (car before) (cdr before) denv value)
    (collect-with-slot-cuts (car before) (cdr before) saved value denv)
    (let ((after (find-slot saved)))
      (if (not (and (eq? denv (##continuation-denv saved))
                    (observe-repaired-slot
                     (car before) (cdr before) (car after) (cdr after)
                     (##frame-ref (car after) (cdr after)) value)))
          (error "map frame/denv logical slot changed across full GC"))
      (set! sample-count (+ sample-count 1)))))

(define payload (vector 'map-slot-control))
(define (keep-live value thunk)
  (let ((answer (thunk)))
    (cons answer (vector-ref value 0))))

(define (run-map start)
  (call/cc (lambda (k) (set! exit-map k) (start))))

(define (map-body)
  (let ((result
         (dynamic-wind
          (lambda () (set! winds (cons 'before winds)))
          (lambda ()
            (map (lambda (x)
                   (if (= x 2)
                       (keep-live payload
                                  (lambda ()
                                    (continuation-capture
                                     (lambda (k) (set! saved k) 2))))
                       x))
                 '(1 2 3)))
          (lambda () (set! winds (cons 'after winds))))))
    (exit-map result)))

(define first (run-map map-body))
(observe-collection)
(define second (run-map (lambda () (continuation-return saved 20))))
(observe-collection)
(define third (run-map (lambda () (continuation-return saved 200))))
(if (not (and (equal? first '(1 (2 . map-slot-control) 3))
              (equal? second '(1 (20 . map-slot-control) 3))
              (equal? third '(1 (200 . map-slot-control) 3))
              (= sample-count 2)
              (equal? winds '(after before after before after before))))
    (error "map full collector control failed" first second third winds))
(display "MAP-SLOT-FULL-COLLECTOR-PASS observations=2 restores=2\n")
(cond-expand
 (mature-slot-native-comparator (display "MAP-SLOT-C23-COMPARATOR-PASS\n"))
 (else #f))
(cond-expand
 (mature-slot-gc-cuts
  (if (not ((c-lambda () bool "___result = map_slot_probe.stale_detected[0] > 0 && map_slot_probe.stale_detected[1] > 0;")))
      (error "stale-slot control never observed a moved referent"))
  (display "MAP-SLOT-GC-CUTS-PASS observations=2 stale-live-frame-and-denv=detected\n"))
 (else #f))

(cond-expand
 (mature-slot-remembered-gc
  (define remembered-gc-control
    (c-lambda (bool bool) bool
              "___result = map_remembered_gc(___ps, ___arg1, ___arg2);"))
  (for-each
   (lambda (case)
     (if (not (remembered-gc-control (cadr case) (caddr case)))
         (error "remembered-slot full collector adapter failed" (car case))))
   '((bounded #f #f) (overflow #t #f) (omitted-rearm #f #t)))
  (display "MAP-SLOT-REMEMBERED-GC-PASS bounded=1 overflow=2 rearm-without-store=both omitted-rearm=dead\n"))
 (else #f))

(cond-expand
 (mature-slot-selective
  (display "MAP-SLOT-SELECTIVE-SCAN-PASS frame-and-denv recorded-write overflow sole-edge-rearm\n"))
 (else #f))
