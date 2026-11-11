;;; Real same-VM Scheme workers, shared aliases, cyclic objects and completed GC.
(define nodes
  (map (lambda (id)
         (let ((v (vector id #f (make-string 128 #\x))))
           (vector-set! v 1 v)
           v))
       '(0 1 2 3)))
(define workers
  (map (lambda (node)
         (make-thread
          (lambda ()
            (let loop ((n 0))
              (if (= n 8) n
                  (begin
                    (##gc)
                    (if (not (and (eq? node (vector-ref node 1))
                                  (= (string-length (vector-ref node 2)) 128)))
                        (error "shared root or cycle lost" n))
                    (loop (+ n 1))))))))
       nodes))
(for-each thread-start! workers)
(define completed (apply + (map thread-join! workers)))
(if (not (= completed 32)) (error "worker collection completion lost"))
(##gc)
(for-each (lambda (node)
            (if (not (eq? node (vector-ref node 1)))
                (error "shared alias changed after join"))) nodes)
(display "SHARED-ROOTS-GC-PASS collections=33\n")
