;;; DEV-only protocol probe plus real wide-map full-collector control.
;;; Protocol effects use fixture storage; the optional cuts observe real GC.
(c-declare "#include \"map-worker-stop-overlay.h\"")
(define worker-stop-control
  (c-lambda (bool bool bool) bool
    "___return(map_worker_stop_control(___arg1, ___arg2, ___arg3));"))

(define self (car (command-line)))
(define (trace-tag) 'map-worker-stop)
(include "../../../../vendor/gambit/tests/root-task-replay.scm")

(define (worker-stop-trial commands fault?)
  (let loop ((remaining commands) (index 0))
    (if (null? remaining)
        (list 'root-task-result 'pass index)
        (let ((command (car remaining)))
          (cond
           ((eq? command 'idle) (loop (cdr remaining) (+ index 1)))
           ((not (worker-stop-control
                  (not (eq? command 'carrier-exit))
                  (eq? command 'lost-child-reply)
                  fault?))
            (if (and fault? (eq? command 'lost-child-reply))
                (list 'root-task-result 'mismatch index 'lost-child-reply 0)
                (error "worker-stop fixture invariant" command)))
           (else (loop (cdr remaining) (+ index 1))))))))

(set! trial worker-stop-trial)
(let ((seed 317) (commands '#(idle carrier-exit lost-child-reply)))
  (do ((i 0 (+ i 1))) ((= i 8))
    (let generate ((n 7) (history '()))
      (if (= n 0)
          (if (signature (trial history #f))
              (error "seeded worker-stop history failed" history))
          (begin
            (set! seed (modulo (* seed 48271) 2147483647))
            (generate (- n 1)
                      (cons (vector-ref commands (modulo seed 3)) history)))))))

(let* ((wanted '(lost-child-reply 0))
       (history '(idle carrier-exit idle lost-child-reply idle))
       (minimal (shrink history #t wanted))
       (encoded (call-with-output-string
                 (lambda (port) (write (list (trace-tag) 1 minimal #t) port))))
       (decoded (call-with-input-string encoded read)))
  (if (not (and (equal? minimal '(lost-child-reply))
                (one-minimal? minimal #t wanted)
                (equal? (signature (trial (caddr decoded) (cadddr decoded))) wanted)
                (not (signature (trial minimal #f)))))
      (error "worker stop replay/shrink control failed" minimal)))
(display "MAP-WORKER-STOP-OVERLAY-PASS helper=delayed weak=exact-query carrier=retained\n")

(if (not (= (##current-vm-processor-count) 3))
    (error "map worker-stop control requires R=3"))
(cond-expand
 (worker-stop-gc-cuts
  (c-declare "#include \"map-worker-stop-gc-cuts.h\"\n#include \"map-worker-carrier-exit.h\"\n#include \"map-worker-retention.h\"")
  ((c-lambda () void #<<c-end
___virtual_machine_state vm = ___VMSTATE_FROM_PSTATE(___ps);
___WORD_STORE_RELEASE(&___COLLECTION(vm).requested_workers, 2);
map_worker_rounds.vm = vm;
c-end
)))
 (else #f))
(include "../../../../vendor/gambit/tests/frame-continuation-roots.scm")
(cond-expand
 (worker-stop-gc-cuts
  (define arm-cut-helper
    (c-lambda () bool "___return(map_worker_arm_helper());"))
  (define finish-cut-helper
    (c-lambda () bool "___return(map_worker_finish_helper());"))
  (define arm-weak-observer
    (c-lambda (scheme-object) bool #<<c-end
void *root = ___alloc_rc(___PSP 0);
if (root && !___try_set_data_rc(___ps, root, ___arg1)) {
  ___release_rc(root);
  root = NULL;
}
map_worker_rounds.weak_root = root;
___return(root != NULL);
c-end
))
  (define arm-sole-strong-edge
    (c-lambda (scheme-object) bool #<<c-end
/* Only the parent receives a root. The child never appears as a
 * Scheme argument or in a second managed slot. */
void *prefix = ___alloc_rc_roots(___ps, 1);
if (!prefix) ___return(0);
void *root = ___alloc_rc(___PSP 0);
if (!root) { ___release_rc(prefix); ___return(0); }
if (!___try_set_data_rc(___ps, root, ___arg1)) {
  ___release_rc(root);
  ___release_rc(prefix);
  ___return(0);
}
___WORD *hp = ___ps->context->hp;
if (___ps->mem.alloc_heap_limit_ - hp < 4) {
  ___release_rc(root);
  ___release_rc(prefix);
  ___return(0);
}
hp[0] = ___MAKE_HD_WORDS(1, ___sVECTOR);
hp[1] = ___FIX(73);
hp[2] = ___MAKE_HD_WORDS(1, ___sVECTOR);
hp[3] = ___FIX(74);
if (!___try_set_data_rc(___ps, prefix, ___VECTOR_FROM_BODY(hp+3))) {
  ___release_rc(root);
  ___release_rc(prefix);
  ___return(0);
}
___VECTORELEM(___data_rc(root), 0) = ___VECTOR_FROM_BODY(hp+1);
___ps->context->hp = hp+4;
for (unsigned i = 0; i < 2; ++i) {
  map_worker_rounds.write_bank[i].storage = malloc(sizeof(uintptr_t));
  if (!map_worker_rounds.write_bank[i].storage)
    abort();
  map_worker_rounds.bank_bytes += sizeof(uintptr_t);
}
map_worker_rounds.strong_source =
  ___PROCESSOR_ID(___ps, ___VMSTATE_FROM_PSTATE(___ps));
map_worker_rounds.strong_root = root;
map_worker_rounds.prefix_root = prefix;
___return(1);
c-end
))
  (define query-weak-receipt
    (c-lambda () bool #<<c-end
/* A collection only publishes the receipt. Recover it here without
 * re-running cleanup or republishing the actual weak task. */
___return(map_worker_rounds.weak_receipt == map_worker_rounds.last &&
          map_worker_rounds.weak_observed > map_worker_rounds.weak_queried &&
          ++map_worker_rounds.weak_queried == map_worker_rounds.weak_observed);
c-end
))
  (define disarm-weak-observer
    (c-lambda () void #<<c-end
void *root = atomic_exchange(&map_worker_rounds.weak_root, NULL);
if (root)
  ___release_rc(root);
root = atomic_exchange(&map_worker_rounds.strong_root, NULL);
if (root)
  ___release_rc(root);
if (map_worker_rounds.prefix_root) {
  ___release_rc(map_worker_rounds.prefix_root);
  map_worker_rounds.prefix_root = NULL;
}
c-end
))
  (let ((table (make-table test: eq? weak-values: #t))
        (key (vector 'strong-table-key))
        (value (box (vector 'weak-table-value))))
    (table-set! table key (unbox value))
    (if (not (arm-weak-observer (##table-get-gcht table)))
        (error "could not root weak backing for collector observation"))
    (dynamic-wind
      (lambda () #f)
      (lambda ()
        (if (not (arm-sole-strong-edge (vector #f)))
            (error "could not allocate sole strong edge"))
        (if (not (arm-cut-helper))
            (error "could not admit fixture helper before GC"))
        (##gc)
        (if (not (finish-cut-helper))
            (error "helper permit did not cross both GC cuts"))
        (display "MAP-WORKER-STOP-HELPER-CUTS-PASS held=freeze+repair stale=refused\n")
        (if (not (and (query-weak-receipt)
                      (eq? (table-ref table key #f) (unbox value))))
            (error "weak table receipt or first-round value missing"))
        ;; Drop the independent value root, with no table write.
        (set-box! value #f)
        (##gc)
        (if (not (and (query-weak-receipt)
                      (not (table-ref table key #f))
                      (= (table-length table) 0)
                      ((c-lambda () bool "___return(map_worker_rounds.strong_repaired == 2 && map_worker_rounds.transfers == 2 && map_worker_rounds.suffix_scans == 2 && map_worker_rounds.write_queries == 2);"))))
            (error "weak table was not cleaned in the next epoch")))
      disarm-weak-observer))
  (display "MAP-WORKER-STOP-STRONG-CUTS-PASS sole-edge=1 repairs=2 no-target-store=1 partial-transfers=2 suffix-scans=2 write-queries=2 missing-results=2\n")
  (display "MAP-WORKER-STOP-WEAK-CUTS-PASS publish=2 exact-query=2 no-table-store=1\n"))
 (else #f))
(cond-expand
 (worker-stop-gc-cuts
  (if (not ((c-lambda () bool #<<c-end
map_worker_rounds.vm = NULL;
___return(!map_worker_rounds.failed && !map_worker_rounds.pending &&
          map_worker_rounds.completed >= 11);
c-end
)))
      (error "R=3 W=2 GC cut sequence or non-worker RC coverage mismatch"))
  (display "MAP-WORKER-STOP-GC-CUTS-PASS source=2 executor=0 min-rounds=11\n"))
 (else #f))
(display "MAP-WORKER-STOP-FULL-GC-TOPOLOGY-PASS R=3 W=2\n")

(cond-expand
 (worker-stop-gc-cuts
  (if (member "--carrier-exit" (command-line))
      (begin
        (if (not ((c-lambda () bool "___return(map_carrier_arm_exit());")))
            (error "could not start carrier exit monitor"))
        (##gc)
        (error "collector returned after the carrier exited"))))
 (else #f))

(cond-expand
 (worker-stop-gc-cuts
  (if (or (member "--retention-budget" (command-line))
          (member "--process-readers" (command-line)))
      (begin
        (if (not ((c-lambda (scheme-object bool) bool
                     "___return(map_worker_retention_control(___ps, ___arg1, ___arg2));")
                  (vector 89)
                  (and (member "--process-readers" (command-line)) #t)))
            (error "retained capacity refusal or recovery failed"))
        (display "MAP-WORKER-RETENTION-PASS census=ran grants=unchanged physical-ledger=2-to-1 live-readers=2 lost-ack=queried recovery=full-gc\n"))))
 (else #f))

(cond-expand
 (worker-stop-gc-cuts
  (let ((probe (member "--exec-bank-probe" (command-line))))
    (if probe
        (begin
          (if (not ((c-lambda (scheme-object) bool
                      "___return(map_worker_exec_arm(___ps, ___arg1));")
                    (vector 89)))
              (error "pending owner journal failed to retain bank credit"))
          (let* ((port (open-input-process
                        (list path: (cadr probe)
                              arguments: (list "recover" (caddr probe)))))
                 (marker (read-line port))
                 (status (process-status port)))
            (close-input-port port)
            (if (or (not (= status 0))
                    (not (or (eof-object? marker) (equal? marker "EXEC-RECOVERY-UNLINK"))))
                (error "owner restart failed" status marker))
            (if (not (eof-object? marker))
                (display "EXEC-RECOVERY-UNLINK\n")))
          (if (not ((c-lambda () bool "___return(map_worker_exec_retry(___ps));")))
              (error "committed retirement failed to reopen GC admission"))
          (display "MAP-WORKER-EXEC-BANK-PASS census=ran refused=1 retry=full-gc\n")))))
 (else #f))
