(def loads 1)
(def (hidden x) (+ x 1))
(defrules shifted () ((_ x) (hidden x)))
(def (shared-loads) loads)
(defrules copying ()
  ((_ from to)
   (gerbil-ascent-rule
    (list (gerbil-ascent-atom to (list (gerbil-ascent-variable 'x))))
    (list (gerbil-ascent-atom from (list (gerbil-ascent-variable 'x)))))))
