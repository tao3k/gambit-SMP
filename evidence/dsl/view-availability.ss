;;; Host byte observations describe provenance, not the unavailable domain facts.
(define-evidence (make-view-availability)
  (sources unavailable)
  (outputs clue factor link)
  (relation unavailable (id digest claim view path ref expected observed reason))
  (relation clue (id digest claim polarity role source))
  (relation factor (id digest name value))
  (relation link (claim target label id digest))
  ((clue I D C (lit "counter") (lit "observation") Path) <--
    (unavailable I D C _ Path _ _ _ _))
  ((factor I D (lit "evidence-state") (lit "provenance-unavailable")) <--
    (unavailable I D _ _ _ _ _ _ _))
  ((factor I D (lit "view-id") V) <-- (unavailable I D _ V _ _ _ _ _))
  ((factor I D (lit "reference-path") R) <-- (unavailable I D _ _ _ R _ _ _))
  ((factor I D (lit "expected-sha256") E) <-- (unavailable I D _ _ _ _ E _ _))
  ((factor I D (lit "observed-sha256") A) <-- (unavailable I D _ _ _ _ _ A _))
  ((factor I D (lit "unavailable-reason") R) <-- (unavailable I D _ _ _ _ _ _ R)))
