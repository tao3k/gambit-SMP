(c-declare #<<end-of-code
static unsigned long long callback_raw_before = 0;
unsigned long long callback_payload_before(void) { return callback_raw_before; }
end-of-code
)
(define remember-address!
  (c-lambda (scheme-object) void
    "callback_raw_before = (unsigned long long)___arg1;"))

(c-define (callback-return-relocation migrate collect) (int int) scheme-object
          "callback_return_relocation" ""
  (##c-return-on-other-processor-hook-set!
   (lambda (id)
     (##thread-migrate-to! id)
     (if (= collect 1) (##gc))))
  (let ((payload (make-vector 32 42)))
    (remember-address! payload)
    (if (= migrate 1)
        (##thread-migrate-to! (if (= (##current-processor-id) 0) 1 0)))
    payload))
