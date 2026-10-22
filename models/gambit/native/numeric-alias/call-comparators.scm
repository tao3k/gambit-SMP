;; Keep the original numeric expressions and assertions, including source locations.
;; Change only harness-comparator specialization, not numeric primitive inlining.
(declare (not inline-primitives ##eqv? ##eq? ##equal?))
(include "unit-tests/03-number/_num.scm")
