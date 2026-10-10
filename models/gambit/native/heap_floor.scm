;; Exercise resize under the selected runtime's ordinary heap configuration.
(for-each
  (lambda (processors)
    (##cvmr processors)
    (if (not (= processors (##current-vm-processor-count)))
        (error "processor resize failed" processors)))
  '(1 2 4))
(display "NATIVE-OK:heap_floor\n")
