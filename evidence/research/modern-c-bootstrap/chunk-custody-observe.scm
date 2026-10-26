(declare (standard-bindings) (extended-bindings))
(if (not (= (##current-vm-processor-count) 11))
    (error "transport observation requires eleven participants"))
(define transport-count
  (c-lambda (int) unsigned-long #<<c-end
___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___ps);
unsigned long count=0;
int i;
for(i=0;i<vm->gc_round.participant_count;i++) {
  ___collector_worker *w=&vm->collector_workers[i];
  switch (___arg1) {
  case 0: count+=w->chunks_published_; break;
  case 1: count+=w->chunks_claimed_; break;
  case 2: count+=w->chunks_completed_; break;
  case 3: count+=w->duplicate_scans; break;
  case 4: count+=(w->heap_chunks_to_scan_head_!=w->heap_chunks_to_scan_tail_); break;
  }
}
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
        (begin
          (##gc)
          (let ((p (transport-count 0)) (t (transport-count 1))
                (d (transport-count 2)) (dup (transport-count 3))
                (pending (transport-count 4)))
            (if (or (not (= p t)) (< d t) (not (= pending 0)))
                (error "transport did not drain" p t d pending))
            (loop (- n 1) (cons (list p t d dup) xs)))))))
(define total
  (let loop ((xs graph) (sum 0))
    (if (null? xs) sum (loop (cdr xs) (+ sum ((car xs)))))))
(if (not (= total 200010000)) (error "graph lost fields" total))
(display "CHUNK-CUSTODY-GRAPH-PASS observations=")
(write observations)
(newline)
