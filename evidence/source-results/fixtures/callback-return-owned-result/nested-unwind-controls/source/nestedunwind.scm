(c-declare "extern int nested_inner(int fail);")

(c-define (nested-inner fail) (int) int "nested_inner" ""
  (if (= fail 1)
      ((c-lambda () void "___throw_error (___PSP ___FIX(___UNKNOWN_ERR));")))
  42)

(c-define (nested-outer migrate fail) (int int) int "nested_outer" ""
  (if (= migrate 1)
      (##thread-migrate-to! (if (= (##current-processor-id) 0) 1 0)))
  ((c-lambda (int) int "___result = nested_inner(___arg1);") fail))
