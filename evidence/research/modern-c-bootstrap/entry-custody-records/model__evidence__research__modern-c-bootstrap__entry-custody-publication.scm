(declare (standard-bindings) (extended-bindings))
(c-declare #<<c-end
#include <stdatomic.h>
static _Atomic int hold=1;
static _Atomic int effects;
c-end
)
(define held-entry (c-lambda () void "while(atomic_load(&hold)) ___CPU_RELAX(); atomic_fetch_add(&effects,1);"))
(define release-entry (c-lambda () void "atomic_store(&hold,0);"))
(define effects-count (c-lambda () int "___return(atomic_load(&effects));"))
(define ready-count (c-lambda () int #<<c-end
___virtual_machine_state vm=___VMSTATE_FROM_PSTATE(___ps);int i;int n=0;
for(i=1;i<vm->processor_count;i++) n+=(___startup_load(&vm->resize.slots[i])==___STARTUP_READY);
___return(n);
c-end
))
(define (require-test p label) (if (not p) (error label)))
(require-test (= (##current-vm-processor-count) 1) "requires p1")
(require-test (= (##current-vm-resize
                  (lambda () (declare (not interrupts-enabled))
                    (held-entry) (##startup-processor!)) 3) 0) "publication failed")
;; Real actors cannot acknowledge while the explicit native control is held.
;; Keep the old 10000-yield count; it cannot manufacture an entry receipt.
(let loop ((n 0)) (if (< n 10000) (begin (thread-yield!) (loop (+ n 1)))))
(require-test (= (ready-count) 0) "publication fabricated READY")
(require-test (= (effects-count) 0) "held entry escaped")
(release-entry)
(require-test (= (##current-vm-resize-ready ##startup-processor! 3) 0) "ready join failed")
(require-test (= (effects-count) 2) "entry effects lost")
(require-test (= (ready-count) 2) "ready receipt lost")
(##gc)
(require-test (= (##cvmr 1) 0) "ready retirement failed")
(##gc)
(display "STARTUP-PUBLICATION-NOT-READY-PASS\n")
