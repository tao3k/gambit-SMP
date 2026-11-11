;;; Separate observer control, never a replacement for original stress files.
(if (not (smp-gc-datagram-allocation-control 10000)) (exit 71))
(let loop ((n 20))
  (if (> n 0)
      (begin
        (make-vector 100000 n)
        (##gc)
        (loop (- n 1)))))
