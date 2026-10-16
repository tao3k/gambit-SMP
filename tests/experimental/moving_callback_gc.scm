;;; Official FFI return of a moving Scheme root; no C borrowing across GC.
(c-declare #<<c-end
#include <stdint.h>
extern ___SCMOBJ moving_callback_gc(void);
static uintptr_t observed_before;
static int observed_moved;
static int observed_movable;
static int observed_intact;
c-end
)
(define remember-address!
  (c-lambda (scheme-object) void
    "observed_before = (uintptr_t)___arg1; observed_movable = ___HD_TYP(___HEADER(___arg1)) <= ___MOVABLE2;"))
(c-define (moving-callback-gc) () scheme-object "moving_callback_gc" ""
  (let ((root (make-vector 32 1042)))
    (remember-address! root)
    (##gc)
    (if (not (= (vector-ref root 31) 1042)) (error "moving root corrupted"))
    root))
(define invoke
  (c-lambda () scheme-object #<<c-end
___SCMOBJ result = moving_callback_gc();
___SCMOBJ ___temp;
observed_moved = observed_before != (uintptr_t)result;
observed_intact = ___VECTORP(result) && ___INT(___VECTORLENGTH(result)) == 32;
for (int i = 0; observed_intact && i < 32; ++i)
  observed_intact = ___FIXEQ(___VECTORELEM(result, i), ___FIX(1042));
___return(result);
c-end
))
(let ((root (invoke)))
  (if (not ((c-lambda () bool "___return(observed_movable && observed_moved && observed_intact);")))
      (error "physical relocation and C payload observation required"))
  (##gc)
  (if (not (= (vector-ref root 31) 1042)) (error "returned Scheme root corrupted")))
(display "MOVING-CALLBACK-GC:PASS\n")
