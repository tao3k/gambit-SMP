(def (hidden x) (+ x 100))
(def (answer) 1)
(def (rebind) (set! answer (lambda () 3)) #t)
(def (left-value) (shifted 2))
