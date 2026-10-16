(c-declare #<<c-end
#if defined(___SINGLE_VM) || defined(___SINGLE_THREADED_VMS)
#error This regression requires the default multiple threaded VM profile
#endif
c-end
)

(define resize-rejected?
  (c-lambda (int) bool
    "___return(___GSTATE->___current_vm_resize (___PSP ___FAL, ___arg1) == ___FIX(___INVALID_OP_ERR));"))

(define (require condition message)
  (if (not condition) (error message)))

(let ((before (##current-vm-processor-count)))
  (require (resize-rejected? -1) "negative resize was not rejected")
  (require (= before (##current-vm-processor-count)) "negative resize changed population")
  (require (resize-rejected? 0) "zero resize was not rejected")
  (require (= before (##current-vm-processor-count)) "zero resize changed population")
  (##current-vm-resize ##startup-processor! before)
  (require (= before (##current-vm-processor-count)) "valid resize failed after rejection")
  (display "FOREIGN-ORIGIN-RESIZE-BOUNDARY:PASS\n"))
