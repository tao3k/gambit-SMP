;; The default association selects one named review from ordinary bindings.
;; Callers can supply a selector that emits several explicit operand groups.
(define-evidence (make-research-request)
  (sources binding)
  (outputs research_review research_operand)
  (relation binding (name value))
  (relation research_review (id kind))
  (relation research_operand (id name value))
  ((research_review (lit "request") Kind) <-- (binding (lit "review") Kind))
  ((research_operand (lit "request") Name Value) <--
    (research_review (lit "request") _) (binding Name Value)
    (if (Name) (not (equal? Name "review")))))
