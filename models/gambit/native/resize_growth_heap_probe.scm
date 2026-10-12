;; Read-only caller snapshot: it cannot establish every peer's GC decision.
(##include "~~lib/_gambit#.scm")
(define heap-sections
  (c-lambda () long
    "___result = ___VMSTATE_FROM_PSTATE(___ps)->mem.the_msections_->nb_sections;"))
(define assigned-sections
  (c-lambda () long
    "___result = ___VMSTATE_FROM_PSTATE(___ps)->mem.nb_msections_assigned_;"))
(define resize-without-probe ##cvmr)
(set! ##cvmr
  (lambda (count)
    (display (list 'heap-before-resize
                   'caller (##current-processor-id)
                   'initial (##current-vm-processor-count)
                   'target count
                   'sections (heap-sections)
                   'assigned (assigned-sections)))
    (newline)
    (force-output)
    (resize-without-probe count)))
(##include "resize_still_reuse.scm")
