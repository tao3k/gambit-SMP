(define (hp-tail-b n acc)
  (if (= n 0) acc (hp-tail-a (- n 1) (+ acc 1))))
