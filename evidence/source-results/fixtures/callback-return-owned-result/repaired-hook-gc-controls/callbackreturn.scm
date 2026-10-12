(c-define (callback-return-value migrate collect value) (int int int) int
          "callback_return_value" ""
  (let ((payload (vector value)))
    (if (= migrate 1)
        (##thread-migrate-to! (if (= (##current-processor-id) 0) 1 0)))
    (if (= collect 1) (##gc))
    (vector-ref payload 0)))

(c-define (callback-return-string migrate collect) (int int) char-string
          "callback_return_string" ""
  (##c-return-on-other-processor-hook-set!
   (lambda (id)
     (##thread-migrate-to! id)
     (if (= collect 1) (##gc))))
  (let ((payload (make-string 4096 #\x)))
    (if (= migrate 1)
        (##thread-migrate-to! (if (= (##current-processor-id) 0) 1 0)))
    payload))
