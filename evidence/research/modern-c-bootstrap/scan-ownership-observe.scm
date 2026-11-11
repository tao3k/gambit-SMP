(declare (standard-bindings) (extended-bindings))
(define scan-duplicates
  (c-lambda () unsigned-long #<<c-end
___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___ps);
unsigned long count=0;
int i;
for(i=0;i<vm->gc_round.participant_count;i++)
  count += vm->collector_workers[i].duplicate_scans;
___return(count);
c-end
))
(define graph
  (let loop ((n 20000) (xs '()))
    (if (= n 0) xs
        (let ((v (vector n)))
          (loop (- n 1) (cons (lambda () (vector-ref v 0)) xs))))))
(define observations
  (let loop ((n 3) (xs '()))
    (if (= n 0) (reverse xs)
        (begin (##gc) (loop (- n 1) (cons (scan-duplicates) xs))))))
(define total
  (let loop ((xs graph) (sum 0))
    (if (null? xs) sum (loop (cdr xs) (+ sum ((car xs)))))))
(if (not (= total 200010000)) (error "scan owner graph lost fields" total))
(display "SCAN-OWNERSHIP-GRAPH-PASS duplicates=")
(write observations)
(newline)
