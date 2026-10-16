;;; SOURCE-REVIEW-REJECTED, NOT A NATIVE FAILURE RECEIPT:
;;; Legacy ___cleanup is fatal on busy rejection; the post-call checks below
;;; cannot qualify normal return. Kept intact as the rejected test contract.
;;; Use foreign_origin_frame_roundtrip.scm for the frame-only successor.
;;; Successor protocol: busy retirement preserves a real C frame, then retries.
;;; The historical successful-shrink roundtrip remains unchanged as a DENY.
(c-declare "extern int foreign_origin_lease_roundtrip(int target, int busy);")
(define (require ok message) (if (not ok) (error message)))
(define cleanup-public (c-lambda () void "___cleanup"))
(c-define (foreign-origin-lease-roundtrip target busy) (int int) int
  "foreign_origin_lease_roundtrip" ""
  (let* ((root (make-vector 32 1042))
         (population (##current-vm-processor-count))
         (result (##current-vm-resize ##startup-processor! target)))
    (if (= busy 1)
        (begin
          (require (not (= result 0)) "live removed-origin C frame was retired")
          (require (= (##current-vm-processor-count) population) "busy resize mutated population"))
        (begin
          (require (= result 0) "retained-origin callback blocked unrelated retirement")
          (require (= (##current-vm-processor-count) target) "retained-origin shrink incomplete")))
    (##gc)
    (require (= (vector-ref root 31) 1042) "callback root corrupted")
    (let ((before-cleanup (##current-vm-processor-count)))
      (cleanup-public)
      (require (= (##current-vm-processor-count) before-cleanup) "busy public cleanup mutated VM"))
    (##gc)
    (require (= (vector-ref root 31) 1042) "busy cleanup destroyed callback root")
    42))
(define invoke (c-lambda (int int) int "foreign_origin_lease_roundtrip"))
(define (run-worker origin busy)
  (let ((worker (make-thread
                 (lambda ()
                   (require (= (processor-id (current-processor)) origin) "wrong native-frame origin")
                   (let ((result (invoke 1 busy)))
                     (require (= result 42) "C callback failed to return")
                     result)))))
    (##thread-pin! worker (##processor origin))
    (thread-start! worker)
    (require (= (thread-join! worker) 42) "native C parent or Scheme join did not complete")))
(define (run-control)
  (require (= (processor-id (current-processor)) 0) "owner must run on P0")
  (let ((population (##current-vm-processor-count)))
    (require (> population 1) "host-managed multiple processors required")
    (run-worker (- population 1) 1)
    (require (= (##current-vm-processor-count) population) "removed-origin busy changed topology")
    (run-worker 0 0)
    (require (= (##current-vm-processor-count) 1) "retained-origin callback did not shrink VM")
    (require (= (##current-vm-resize ##startup-processor! 1) 0) "post-C-return retry stayed busy")
    (##gc)))
(define owner (make-thread run-control))
(##thread-pin! owner (##processor 0))
(thread-start! owner)
(thread-join! owner)
(display "FOREIGN-ORIGIN-LEASE:PASS\n")
