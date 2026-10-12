(##include "~~lib/_gambit#.scm")
(c-declare "static void *retirement_rc_slot = 0;")
(define rc-create!
  (c-lambda (scheme-object) bool #<<end-of-code
if (retirement_rc_slot != 0) {
  ___result = 0;
} else {
  retirement_rc_slot = ___EXT(___alloc_rc) (___PSP sizeof(long));
  if (retirement_rc_slot != 0)
    ___EXT(___set_data_rc) (retirement_rc_slot, ___arg1);
  ___result = retirement_rc_slot != 0;
}
end-of-code
))
(define rc-local?
  (c-lambda () bool #<<end-of-code
___rc_header *head = &___ps->mem.rc_head_;
___rc_header *node = head->next;
___rc_header *wanted = ((___rc_header*)retirement_rc_slot) - 1;
___result = 0;
while (node != head) {
  if (node->prev->next != node || node->next->prev != node) break;
  if (node == wanted) { ___result = 1; break; }
  node = node->next;
}
end-of-code
))
(define rc-value
  (c-lambda () scheme-object
    "___result = ___EXT(___data_rc) (retirement_rc_slot);"))
(define rc-count
  (c-lambda () int
    "___result = ___EXT(___refcount_rc) (retirement_rc_slot);"))
(define rc-release!
  (c-lambda () void
    "___EXT(___release_rc) (retirement_rc_slot); retirement_rc_slot = 0;"))
(define population (##current-vm-processor-count))
(if (< population 2) (error "requires parallel processors"))
(define victim (- population 1))
(##thread-pin! (current-thread) (##processor 0))
(define worker
  (make-thread
   (lambda ()
     (if (not (rc-create! (vector 'rc-root (make-vector 64 victim))))
         (error "RC allocation"))
     (if (not (rc-local?)) (error "donor RC ownership"))
     (##current-processor-id))))
(##thread-pin! worker (##processor victim))
(thread-start! worker)
(if (not (= victim (thread-join! worker))) (error "RC allocation processor"))
(if (rc-local?) (error "premature RC owner transfer"))
(##cvmr victim)
(if (not (= victim (##current-vm-processor-count))) (error "RC shrink membership"))
(if (not (rc-local?)) (error "retained RC list missing live block"))
(##gc)
(if (not (equal? (rc-value) (vector 'rc-root (make-vector 64 victim))))
    (error "RC data root lost after GC"))
(if (not (= 1 (rc-count))) (error "RC refcount changed during transfer"))
(rc-release!)
(display "NATIVE-OK:resize_rc_survival\n")
