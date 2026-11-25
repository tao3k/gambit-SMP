;;; DEV overlay: actual blocking wait/cached dispatcher, native RC graph transfer.
;;; The static S emitter and scheduler conversion remain unimplemented.
(include "map-worker-stop.scm")
(c-declare "#include <limits.h>\n#include \"completion-wait-transfer.h\"")
(define transfer-init (c-lambda (scheme-object) int
  "___return(wait_transfer_init(___ps, ___arg1));"))
(define transfer-prepare (c-lambda (scheme-object) bool
  "___return(wait_transfer_prepare(___ps, ___arg1));"))
(define transfer-commit (c-lambda (int bool) int
  "___return(wait_transfer_commit(___arg1, ___arg2));"))
(define transfer-query (c-lambda (int) int
  "___return(wait_transfer_query(___arg1));"))
(define transfer-ack (c-lambda (int bool) int
  "___return(wait_transfer_ack(___arg1, ___arg2));"))
(define transfer-retire (c-lambda (int bool) bool
  "___return(wait_transfer_retire(___arg1, ___arg2));"))
(define transfer-cache! (c-lambda (bool) void
  "wait_transfer.cached = ___arg1;"))
(define transfer-source (c-lambda () scheme-object
  "___return(wait_transfer.source ? ___data_rc(wait_transfer.source) : ___FAL);"))
(define transfer-target (c-lambda () scheme-object
  "___return(wait_transfer.target ? ___data_rc(wait_transfer.target) : ___FAL);"))
(define transfer-releases (c-lambda () bool
  "___return(wait_transfer.source_releases == 1 && wait_transfer.target_releases == 1);"))
(define (ensure value message) (if (not value) (error message)))

;; A thread is physically queued on M. Its interrupt callback executes after
;; thread-resume-execution! has cached the old resume action. Keep that callback
;; suspended while the controller transfers a captured root graph across GC.
(let ((m (make-mutex)) (entered (make-mutex)) (cv (make-condition-variable))
      (controller (current-thread)) (release #f) (callbacks 0) (completions 0))
  (mutex-lock! m #f #f)
  (let ((worker (make-thread
                 (lambda ()
                   (mutex-lock! m)
                   (set! completions (+ completions 1))
                   (mutex-unlock! m)))))
    (thread-start! worker)
    (let await ()
      (if (not (thread-state-waiting? (thread-state worker)))
          (begin (thread-yield!) (await))))
    (##thread-intr!
     worker #t
     (lambda ()
       (set! callbacks (+ callbacks 1))
       (continuation-capture
        (lambda (k)
          (thread-send controller k)))
       (mutex-lock! entered)
       (condition-variable-broadcast! cv)
       (let wait ()
         (if (not release)
             (begin (mutex-unlock! entered cv) (mutex-lock! entered) (wait))))
       (mutex-unlock! entered)))
    (let ((generation (transfer-init (thread-receive))))
      (ensure (> generation 0) "source root registration")
      (transfer-cache! #t)
      ;; The target representation shares the actual captured continuation.
      ;; Moving values are reloaded from the registered RC home after GC.
      (ensure (transfer-prepare (vector 'generic-target (transfer-source)))
              "target prepare")
      (ensure (= -1 (transfer-commit generation #t)) "lost commit return")
      (ensure (= 2 (transfer-query generation)) "commit query")
      (##gc)
      (ensure (continuation? (vector-ref (transfer-target) 1)) "target root repaired")
      (ensure (= -1 (transfer-ack generation #t)) "lost ACK return")
      (ensure (= 3 (transfer-query generation)) "ACK query")
      (ensure (= 3 (transfer-ack generation #f)) "duplicate ACK")
      (ensure (= -2 (transfer-query (- generation 1))) "stale query")
      (##gc)
      (ensure (continuation? (vector-ref (transfer-target) 1)) "post-ACK next-round root")
      (ensure (not (transfer-retire generation #f)) "cached action must retain record")
      (mutex-lock! entered)
      (set! release #t)
      (condition-variable-broadcast! cv)
      (mutex-unlock! entered)
      (mutex-unlock! m)
      (thread-join! worker)
      (ensure (and (= callbacks 1) (= completions 1)) "one original wait completion")
      (transfer-cache! #f)
      (ensure (transfer-retire generation #f) "last-reader retirement")
      (ensure (transfer-retire generation #f) "duplicate retirement")
      (ensure (transfer-releases) "exactly-once source and target release"))))
(display "COMPLETION-WAIT-NATIVE-OVERLAY-PASS actual-wait=1 cached-callback=1 lost-commit=queried lost-ack=queried full-gc=2 release=once\n")

;; Reuse the existing replay/shrink driver; every trial touches actual RC roots.
(define (transfer-trial commands fault?)
  (let ((g (transfer-init (vector 'replay))))
    (ensure (> g 0) "replay source")
    (ensure (transfer-prepare (vector 'generic)) "replay target")
    (transfer-cache! #t)
    (let loop ((xs commands) (index 0) (model 1) (failure #f))
      (if (null? xs)
          (begin
            ;; Settle this trial's actual native roots before the next history.
            (if (not (= (transfer-query g) 4))
                (begin (transfer-commit g #f) (transfer-ack g #f)))
            (transfer-cache! #f)
            (ensure (transfer-retire g #f) "trial settlement")
            (ensure (transfer-releases) "trial exactly-once release")
            (if failure failure (list 'root-task-result 'pass index)))
          (let* ((action (car xs))
                 (expected
                  (case action
                    ((idle) 0)
                    ((commit) (if (or (= model 1) (= model 2)) -1 0))
                    ((query) model)
                    ((ack) (if (or (= model 2) (= model 3)) -1 0))
                    ((retire) #f)
                    (else (error "unknown transfer action" action))))
                 (actual
                  (case action
                    ((idle) 0)
                    ((commit) (transfer-commit g #t))
                    ((query) (transfer-query g))
                    ((ack) (transfer-ack g #t))
                    ((retire) (transfer-retire g fault?))))
                 (next (cond ((and (eq? action 'commit) (= model 1)) 2)
                             ((and (eq? action 'ack) (= model 2)) 3)
                             (else model))))
            (loop (cdr xs) (+ index 1) next
                  (or failure
                      (and (not (equal? actual expected))
                           (list 'root-task-result 'mismatch index
                                 (if (eq? action 'retire) 'early-retire 'state-result) 0)))))))))
(set! trial transfer-trial)
(let ((seed 317) (choices '#(idle commit query ack retire)))
  (do ((i 0 (+ i 1))) ((= i 8))
    (let generate ((n 7) (history '()))
      (if (= n 0)
          (ensure (not (signature (trial history #f))) "seeded RC transfer history")
          (begin
            (set! seed (modulo (* seed 48271) 2147483647))
            (generate (- n 1) (cons (vector-ref choices (modulo seed (vector-length choices))) history)))))))
(let* ((wanted '(early-retire 0)) (history '(idle commit query ack idle retire idle))
       (minimal (shrink history #t wanted))
       (encoded (call-with-output-string
                 (lambda (p) (write (list 'completion-wait 1 minimal #t) p))))
       (decoded (call-with-input-string encoded read)))
  (ensure (and (equal? minimal '(commit ack retire))
               (one-minimal? minimal #t wanted)
               (equal? (signature (trial (caddr decoded) (cadddr decoded))) wanted)
               (not (signature (trial minimal #f))))
          "actual RC replay/shrink"))
(display "COMPLETION-WAIT-NATIVE-PBT-PASS histories=8 actions=56 replay=round-trip shrink=7-to-3 cached-reader-negative=detected\n")
