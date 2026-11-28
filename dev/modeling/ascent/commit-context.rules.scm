;; Input schema for the existing relational commit policy. Per-REV facts are
;; data passed to the native session, never executable DSL generated in Cache.
(relation clue (id document claim kind owner source))
(relation factor (id document name value))
(relation binding (name value))
