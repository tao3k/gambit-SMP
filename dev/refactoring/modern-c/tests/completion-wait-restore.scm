;;; DEV actual waiting-frame restoration and escaped-alias control.
(include "completion-wait-transfer.scm")
(define transfer-reader! (c-lambda (bool) void "wait_transfer.readers = ___arg1;"))
(define record-bytes (c-lambda () unsigned-int "___return(sizeof wait_transfer);"))
(define rc-header-bytes (c-lambda () unsigned-int "___return(sizeof(___rc_header));"))
(define root-slots (c-lambda () unsigned-int #<<c-end
unsigned count = 0;
if (wait_transfer.source)
  count += ((___rc_header *)wait_transfer.source - 1)->root_count + 1;
if (wait_transfer.target)
  count += ((___rc_header *)wait_transfer.target - 1)->root_count + 1;
___return(count);
c-end
))
(define frame-physical-words (c-lambda (scheme-object) unsigned-int
  "___return(___HD_WORDS(___HEADER(___arg1)) + 1);"))
(define finish-control (c-lambda () bool #<<c-end
if (wait_transfer.state != 1 || wait_transfer.cached || wait_transfer.readers)
  ___return(0);
___release_rc(wait_transfer.source);
wait_transfer.source = NULL;
++wait_transfer.source_releases;
wait_transfer.state = 4;
___return(wait_transfer.source_releases == 1 && wait_transfer.target_releases == 0);
c-end
))
(define (active-graph converted?)
  (if converted? (transfer-target) (transfer-source)))
(define (wait-cell? x)
  (and (vector? x) (= (vector-length x) 2) (eq? (vector-ref x 0) 'wait-cell)))
(define (wait-frame-slot k)
  (let frames ((p k) (fuel 256))
    (if (or (not p) (= fuel 0)) (error "missing actual waiting cell"))
    (let ((frame (##continuation-frame p)) (fs (##continuation-fs p))
          (link (##continuation-link p)))
      (let slots ((i 1))
        (cond ((> i fs) (frames (##continuation-next p) (- fuel 1)))
              ((and (not (= i link)) (##continuation-slot-live? p i)
                    (wait-cell? (##frame-ref frame i)))
               (vector frame i (##frame-ref frame i)))
              (else (slots (+ i 1))))))))
(define (frame-cost k)
  (let frames ((p k) (fuel 256) (seen '()) (n 0) (slots 0) (words 0))
    (if (not p) (list n slots words)
        (begin
          (ensure (> fuel 0) "finite frame cost chain")
          (let* ((frame (##continuation-frame p)) (fs (##continuation-fs p))
                 (link (##continuation-link p))
                 (live (let loop ((i 1) (count 0))
                         (if (> i fs) count
                             (loop (+ i 1) (+ count
                               (if (and (not (= i link))
                                        (##continuation-slot-live? p i)) 1 0)))))))
            (frames (##continuation-next p) (- fuel 1) (cons frame seen)
                    (+ n (if (memq frame seen) 0 1))
                    (+ slots (if (memq frame seen) 0 live))
                    (+ words (if (memq frame seen) 0 (frame-physical-words frame)))))))))

(define (restore-wait-case converted?)
  (let ((controller (current-thread)) (m (make-mutex))
        (gate (make-mutex)) (cv (make-condition-variable)) (released #f)
        (escape #f) (callbacks 0) (completed 0) (winds '())
        (bytes (make-f64vector 2 0.0)))
    (mutex-lock! m #f #f)
    (let ((worker
           (thread-start!
            (make-thread
             (lambda () (mutex-lock! m) (set! completed (+ completed 1))
                        (mutex-unlock! m))))))
      (let await ()
        (if (not (thread-state-waiting? (thread-state worker)))
            (begin (thread-yield!) (await))))
      (##thread-intr! worker #t
       (lambda ()
         (set! callbacks (+ callbacks 1))
         (dynamic-wind
          (lambda () (set! winds (cons 'before winds)))
          (lambda ()
            (let* ((cell (vector 'wait-cell 7))
                   (answer (continuation-capture
                            (lambda (k) (thread-send controller k) 'initial))))
              (if (eq? answer 'initial)
                  (begin
                    (mutex-lock! gate)
                    (let wait ()
                      (if (not released)
                          (begin (mutex-unlock! gate cv) (mutex-lock! gate) (wait))))
                    (mutex-unlock! gate))
                  ;; Exit before the old physical scheduler registration path.
                  ;; This is a real user multi-shot restore, not a retry/query.
                  (escape (list answer (vector-ref cell 1))))))
          (lambda () (set! winds (cons 'after winds))))))
      (let* ((k (thread-receive))
             (ignore (##get-bytes-allocated! bytes 0))
             (generation (transfer-init (if converted? k (vector 'generic-target k)))))
        (ensure (> generation 0) "wait-frame source root")
        (set! k #f)
        (transfer-cache! #t)
        (if converted?
            (begin
              (ensure (transfer-prepare (vector 'generic-target (transfer-source))) "wait-frame target")
              (ensure (= -1 (transfer-commit generation #t)) "wait-frame lost commit")
              (ensure (= 2 (transfer-query generation)) "wait-frame commit query")))
        (let ((peak-root-slots (root-slots)))
          (##gc)
          (if converted?
              (begin
                (ensure (= -1 (transfer-ack generation #t)) "wait-frame lost ACK")
                (ensure (= 3 (transfer-query generation)) "wait-frame ACK query")))
          (transfer-reader! #t)
          (mutex-lock! gate)
          (set! released #t)
          (condition-variable-broadcast! cv)
          (mutex-unlock! gate)
          (mutex-unlock! m)
          (thread-join! worker)
          (transfer-cache! #f)
          (ensure (and (= callbacks 1) (= completed 1)) "capturing owner ended exactly once")
          (if converted?
              (ensure (not (transfer-retire generation #f)) "escaped reader outlives owner"))
          (##gc)
          (let* ((slot (wait-frame-slot (vector-ref (active-graph converted?) 1)))
                 (frame (vector-ref slot 0)) (index (vector-ref slot 1))
                 (old-alias (vector-ref slot 2)) (replacement (vector 'wait-cell 9))
                 (before (frame-cost (vector-ref (active-graph converted?) 1))))
            ;; Real reflective frame write. The old escaped value is independent
            ;; from the replaced captured slot and must remain the original cell.
            (##frame-set! frame index replacement)
            (ensure (and (= (vector-ref old-alias 1) 7)
                         (eq? (##frame-ref frame index) replacement)) "reflective replacement alias")
            (##gc)
            (let ((first (call/cc (lambda (out)
                                   (set! escape out)
                                   (continuation-return (vector-ref (active-graph converted?) 1) 20)))))
              (ensure (equal? first '(20 9)) "first actual wait continuation restore"))
            (##gc)
            (ensure (eq? (##frame-ref frame index) replacement) "escaped frame repaired")
            (vector-set! replacement 1 11)
            (let ((second (call/cc (lambda (out)
                                    (set! escape out)
                                    (continuation-return (vector-ref (active-graph converted?) 1) 200)))))
              (ensure (equal? second '(200 11)) "second actual wait continuation restore"))
            (ensure (and (= (vector-ref old-alias 1) 7)
                         (= callbacks 1) (= completed 1)
                         (equal? winds '(after before after before after before)))
                    "restore must not re-enqueue/execute original worker or lose winding")
            (let ((after (frame-cost (vector-ref (active-graph converted?) 1))))
              (##get-bytes-allocated! bytes 1)
              (write (list 'COMPLETION-WAIT-RESTORE-COST (if converted? 'converted 'control)
                           'record-bytes (record-bytes) 'rc-header-bytes (rc-header-bytes)
                           'peak-root-slots peak-root-slots 'retained-root-slots (root-slots)
                           'before before 'after after
                           'allocated-bytes (- (f64vector-ref bytes 1) (f64vector-ref bytes 0))
                           'static-entries 0 'eliminated-closures 0)) (newline)))
          (transfer-reader! #f)
          (ensure (if converted? (transfer-retire generation #f) (finish-control))
                  "post-shot reader settlement"))))))
(restore-wait-case #f)
(restore-wait-case #t)

;; Ordinary wait completion is separate from the escaped-graph controls above.
;; This runs the existing scheduler and wait code, not the proposed S lowering.
;; The RC record/pin remains DEV-owned; no production conversion is claimed.
(define normal-wait-topology?
  (c-lambda () bool #<<c-end
___root_round *round = ___ROOT_UNION(___VMSTATE_FROM_PSTATE(___ps));
___return(round->participants == 3 && round->collection.worker_count == 2);
c-end
))
(define (await-normal-mutex-wait worker mutex)
  (let loop ()
    (let ((state (thread-state worker)))
      (if (not (and (thread-state-waiting? state)
                    (eq? (thread-state-waiting-for state) mutex)))
          (begin (thread-yield!) (loop))))))

(define (normal-wait-trial commands fault?)
  (let* ((mutex (make-mutex))
         (counts (vector 0 0 0 0)) ; before, after, returns, services
         (payload (vector 'normal-wait-payload 0))
         (worker #f) (generation #f) (held-target #f)
         (state 1) (ended? #f) (pinned? #t) (failure #f) (index 0))
    (define (check-target)
      (if (< state 4)
          (let ((target (transfer-target)))
            (ensure (and (or (not pinned?) (eq? target held-target))
                         (eq? (vector-ref (vector-ref target 1) 0)
                              'normal-wait-payload)
                         (= (vector-ref (vector-ref target 1) 1)
                            (if ended? 1 0)))
                    "normal wait repaired target and result"))))
    (define (finish-owner)
      (mutex-unlock! mutex)
      (ensure (eq? (thread-join! worker) 'normal-wait-returned)
              "normal wait natural Thread return")
      (ensure (and (= (vector-ref counts 0) 1)
                   (= (vector-ref counts 1) 1)
                   (= (vector-ref counts 2) 1))
              "normal wait return and exact winding")
      (set! worker #f)
      (set! ended? #t))
    (define (invalid action)
      (set! failure (list 'root-task-result 'invalid index action)))
    (mutex-lock! mutex)
    ;; The worker closes over its own payload binding. Clearing the controller's
    ;; binding below does not change that value or depend on a raw C address.
    (set! worker
      (let ((value payload))
        (thread-start!
         (make-thread
          (lambda ()
            (dynamic-wind
             (lambda () (vector-set! counts 0 (+ 1 (vector-ref counts 0))))
             (lambda ()
               (ensure (eq? (mutex-lock! mutex) #t) "normal wait grant")
               (ensure (eq? (mutex-state mutex) (current-thread))
                       "normal wait actual owner")
               ;; This marker is after the actual production wait returns.
               (vector-set! counts 2 (+ 1 (vector-ref counts 2)))
               (vector-set! value 1 1)
               (mutex-unlock! mutex)
               'normal-wait-returned)
             (lambda () (vector-set! counts 1 (+ 1 (vector-ref counts 1))))))))))
    (await-normal-mutex-wait worker mutex)
    (set! generation (transfer-init (vector 'normal-wait-source payload)))
    (ensure (> generation 0) "normal wait source RC")
    (ensure (transfer-prepare
             (vector 'normal-wait-target (vector-ref (transfer-source) 1)))
            "normal wait target RC")
    (set! payload #f)
    (set! held-target (transfer-target))
    (transfer-reader! #t)
    (let loop ((remaining commands))
      (if (and (pair? remaining) (not failure))
          (let ((action (car remaining)))
            (case action
              ((idle) #f)
              ((service)
               (if ended?
                   (invalid action)
                   (begin
                     (ensure
                      (eq? (thread-interrupt!
                            worker
                            (lambda ()
                              (vector-set! counts 3 (+ 1 (vector-ref counts 3)))
                              (##gc)
                              (ensure (normal-wait-topology?)
                                      "service GC actual R=3 W=2")
                              'normal-service-returned))
                           'normal-service-returned)
                      "normal wait service completed")
                     ;; Controller still owns the mutex. Seeing this specific
                     ;; wait again after completed service witnesses rearm, not
                     ;; a nested completion-mutex wait or a terminal grant.
                     (await-normal-mutex-wait worker mutex))))
              ((collect)
               (##gc)
               (ensure (normal-wait-topology?) "normal wait GC actual R=3 W=2")
               (check-target))
              ((commit)
               (if (= state 1)
                   (begin
                     (ensure (= -1 (transfer-commit generation #t))
                             "normal wait lost commit return")
                     (set! state 2))
                   (invalid action)))
              ((ack)
               (if (= state 2)
                   (begin
                     (ensure (= -1 (transfer-ack generation #t))
                             "normal wait lost ACK return")
                     (set! state 3))
                   (invalid action)))
              ((query)
               (ensure (= state (transfer-query generation))
                       "normal wait same-key status query"))
              ((owner-return)
               (if (and (= state 3) (not ended?))
                   (finish-owner)
                   (invalid action)))
              ((unpin)
               (if (and ended? pinned?)
                   (begin (set! held-target #f)
                          (transfer-reader! #f) (set! pinned? #f))
                   (invalid action)))
              ((retire)
               (if (and ended? (= state 3))
                   (let ((actual (transfer-retire generation fault?))
                         (expected (not pinned?)))
                     (if actual (set! state 4))
                     (if (not (eq? actual expected))
                         (set! failure
                           (list 'root-task-result 'mismatch index
                                 'normal-wait-early-retire 0))))
                   (invalid action)))
              (else (invalid action)))
            (set! index (+ index 1))
            (loop (cdr remaining)))))
    ;; Cleanup is not part of the accepted history. It settles all actual roots
    ;; and the real worker even when shrinking deletes a required predecessor.
    (if (= state 1)
        (begin (ensure (= 2 (transfer-commit generation #f)) "cleanup commit")
               (set! state 2)))
    (if (= state 2)
        (begin (ensure (= 3 (transfer-ack generation #f)) "cleanup ACK")
               (set! state 3)))
    (if (not ended?) (finish-owner))
    (set! held-target #f)
    (transfer-reader! #f)
    (ensure (transfer-retire generation #f) "normal wait cleanup retire")
    (ensure (transfer-releases) "normal wait exactly-once RC release")
    (if failure failure (list 'root-task-result 'pass index))))

(let ((saved-trial trial) (seed 317))
  ;; In-process replay preserves the already asserted R=3 and requested W=2;
  ;; the root-task driver's generic -:p1 subprocess is deliberately not used.
  (set! trial normal-wait-trial)
  (do ((i 0 (+ i 1))) ((= i 8))
    (let* ((ignored (set! seed (modulo (* seed 48271) 2147483647)))
           (services (modulo seed 3))
           (prefix (let loop ((n services) (xs '()))
                     (if (= n 0) xs (loop (- n 1) (cons 'service xs)))))
           (commands (append prefix
                      '(collect commit query ack collect owner-return
                        collect query retire unpin collect retire)))
           (encoded (call-with-output-string
                      (lambda (p)
                        (write (list 'normal-wait 1 '(3 2) commands #f) p))))
           (decoded (call-with-input-string encoded read))
           (outcome (trial (list-ref decoded 3) (list-ref decoded 4))))
      (ensure (and (equal? (list-ref decoded 2) '(3 2))
                   (eq? (cadr outcome) 'pass))
              "normal wait topology-bound native replay")
      (write (list 'COMPLETION-WAIT-NORMAL-REPLAY decoded outcome))
      (newline)))
  (let* ((history '(idle service collect commit query ack owner-return
                        collect query retire idle))
         (wanted '(normal-wait-early-retire 0))
         (minimal (shrink history #t wanted)))
    (ensure (and (equal? minimal '(commit ack owner-return retire))
                 (one-minimal? minimal #t wanted)
                 (equal? (signature (trial minimal #t)) wanted)
                 (eq? (cadr (trial minimal #f)) 'pass)
                 (eq? (cadr (trial '(ack owner-return retire) #f)) 'invalid))
            "normal wait reader negative shrink and invalid-history guard")
    (write (list 'COMPLETION-WAIT-NORMAL-SHRINK minimal))
    (newline))
  (set! trial saved-trial))
(display "COMPLETION-WAIT-NORMAL-PASS histories=8 topology=3/2 service=0..2 return=natural winding=exact post-ACK-exit=GC reader=retained RC-release=once production-conversion=absent\n")
(display "COMPLETION-WAIT-RESTORE-PASS control+converted shots=2-each owner=ended reflective-slot=replaced old-alias=preserved winding=exact physical-completions=1-each\n")
