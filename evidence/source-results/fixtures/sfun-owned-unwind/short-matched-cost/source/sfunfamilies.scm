(include "nestedmarker.scm")

(define (family-body migrate fail)
  (if (= migrate 1)
      (##thread-migrate-to! (if (= (##current-processor-id) 0) 1 0)))
  (if (= fail 1)
      ((c-lambda () void "___throw_error (___PSP ___FIX(___UNKNOWN_ERR));")))
  (if (= fail 2) "not-an-integer" 42))

(c-define (family-void migrate fail) (int int) void "family_void" ""
  (family-body migrate fail))

(c-define (family-object migrate fail) (int int) scheme-object "family_object" ""
  (vector (family-body migrate fail)))

(c-define (family-integer migrate fail) (int int) int "family_integer" ""
  (family-body migrate fail))
