;;; Same-owner lifecycle probe.
;;; Success requires the errno ___thread_join actually returned while the
;;; worker was still joinable, then a later ___thread_join of 0 by that owner.
;;; A shrink that joins on the first call is not that contract. EINVAL is not
;;; still-joinable. No detach and no errno interposition.

(declare (standard-bindings) (extended-bindings) (block))

(c-declare #<<c-end
int ___lifecycle_join_os_errno(void);
c-end
)

(define os-errno
  (c-lambda () int "___lifecycle_join_os_errno"))

(let* ((before (##current-vm-processor-count))
       (first (##current-vm-resize ##startup-processor! 1))
       (mid (##current-vm-processor-count))
       (reopen (##current-vm-resize ##startup-processor! before))
       (after (##current-vm-processor-count))
       (errno (os-errno)))
  (if (and (##fx> before 1)
           (##fx= mid 1)
           (##fx= reopen 0)
           (##fx= after before)
           (##fx> errno 0)
           (##not (##fx= errno 22)))
      (begin
        (display "LIFECYCLE-JOIN:OS-JOIN-ERROR ")
        (display errno)
        (newline)
        (display "LIFECYCLE-JOIN:SAME-OWNER-JOIN 0\n")
        (display "LIFECYCLE-JOIN:STILL-JOINABLE-THEN-SUCCESS\n"))
      (begin
        (display "LIFECYCLE-JOIN:NO-STILL-JOINABLE-ERROR\n")
        (write (list before first mid reopen after errno))
        (newline)
        (exit 2))))
