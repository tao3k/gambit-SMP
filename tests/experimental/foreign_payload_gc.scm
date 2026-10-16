;;; Pending actual compiled candidate qualification; not an interpreted mock.
;;; This exercises stable C payload ownership, NOT concurrent movable pointers.
(c-declare "
#include <stdlib.h>
struct gc_payload { unsigned long value; };
static struct gc_payload *payload_new(void) {
  struct gc_payload *p = malloc(sizeof(*p));
  if (p) p->value = 0;
  return p;
}
static unsigned long payload_get(struct gc_payload *p) { return p->value; }
static void payload_set(struct gc_payload *p, unsigned long v) { p->value = v; }
static void payload_free(struct gc_payload *p) { free(p); }
")
(c-define-type gc-payload (pointer (struct "gc_payload")))
(define new-payload (c-lambda () gc-payload "payload_new"))
(define get-payload (c-lambda (gc-payload) unsigned-long "payload_get"))
(define set-payload! (c-lambda (gc-payload unsigned-long) void "payload_set"))
(define free-payload! (c-lambda (gc-payload) void "payload_free"))
(define payload (new-payload))
(if (not payload) (error "payload allocation failed"))
(let loop ((i 0))
  (if (< i 32)
      (begin
        (set-payload! payload i)
        (let ((roots (vector payload (make-vector 4096 i))))
          (##gc)
          (if (not (= (get-payload (vector-ref roots 0)) i))
              (error "foreign payload changed across GC")))
        (loop (+ i 1)))))
(free-payload! payload)
(set! payload #f)
(display "FOREIGN-PAYLOAD-GC-OK\n")
