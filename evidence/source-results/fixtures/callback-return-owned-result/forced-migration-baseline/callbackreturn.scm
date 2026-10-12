(c-define (callback-return-value migrate collect value) (int int int) int
          "callback_return_value" ""
  (let ((payload (vector value)))
    (if (= migrate 1)
        (##thread-migrate-to! (if (= (##current-processor-id) 0) 1 0)))
    (if (= collect 1) (##gc))
    (vector-ref payload 0)))
