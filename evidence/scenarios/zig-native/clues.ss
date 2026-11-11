;;; Explicit selector: do not replace another research lane's default selection.
(define-evidence (query)
  (sources clue factor binding)
  (outputs question)
  (include clue-selection-schema)
  (relation question (claim))
  ((question C) <--
    (binding (lit "entity") E) (factor I H (lit "entity") E)
    (clue I H C _ _ _))
  ((question C) <--
    (binding (lit "claim") C) (clue I H C _ _ _)
    (factor I H (lit "entity") (lit "zig-gambit"))))
