(declare (standard-bindings) (extended-bindings))
(c-declare #<<c-end
#include <dlfcn.h>
#include <stdlib.h>
#include <stdatomic.h>
static _Atomic int entry_count;
static int resize_test_arm_fn(int c,int j,int a) {
  void (*fn)(int,int,int)=dlsym(RTLD_DEFAULT,"resize_test_arm");
  if(!fn) return 0;fn(c,j,a);return 1;
}
static int resize_test_counter(int kind) {
  int (*fn)(int)=dlsym(RTLD_DEFAULT,"resize_test_count");
  return fn ? fn(kind) : -1;
}
c-end
)
(define arm (c-lambda (int int int) int "resize_test_arm_fn"))
(define fault-count (c-lambda (int) int "resize_test_counter"))
(define note-entry (c-lambda () void "atomic_fetch_add(&entry_count,1);"))
(define entries (c-lambda () int "___return(atomic_load(&entry_count));"))
(define hold-start (c-lambda (int) void "((void (*)(int))dlsym(RTLD_DEFAULT,\"resize_test_hold_start\"))(___arg1);"))
(define phase (c-lambda () int "___return(___VMSTATE_FROM_PSTATE(___ps)->resize.phase);"))
(define capacity (c-lambda () int "___return(___VMSTATE_FROM_PSTATE(___ps)->mem.the_msections_->nb_sections);"))
(define assigned (c-lambda () int "___return(___VMSTATE_FROM_PSTATE(___ps)->mem.nb_msections_assigned_);"))
(define base-capacity (c-lambda () int "___return(___VMSTATE_FROM_PSTATE(___ps)->resize.base_capacity);"))
(define base-assigned (c-lambda () int "___return(___VMSTATE_FROM_PSTATE(___ps)->resize.base_assigned);"))
(define retained-root? (c-lambda () bool "___return(___VMSTATE_FROM_PSTATE(___ps)->resize.thunk!=___FAL);"))
(define retained-phase? (c-lambda () bool "___return(___VMSTATE_FROM_PSTATE(___ps)->resize.phase==___RESIZE_RETAINED);"))
(define retained-reinit-rejected? (c-lambda () bool #<<c-end
___virtual_machine_state vms = ___VMSTATE_FROM_PSTATE(___ps);
___SCMOBJ root = vms->resize.thunk;
___WORD generation = vms->resize.generation;
___cleanup();
if (___GSTATE->setup_state != 3) { ___return(0); }
___SCMOBJ err = ___setup(&___GSTATE->setup_params);
___return(err != ___FIX(___NO_ERR) && ___GSTATE->setup_state == 3 &&
          vms->resize.phase == ___RESIZE_RETAINED &&
          vms->resize.thunk == root && vms->resize.generation == generation);
c-end
))
(define isolated? (c-lambda () bool "___return(___VMSTATE_FROM_PSTATE(___ps)->resize.abort_isolated);"))
(define collections (c-lambda () double "___return(___VMSTATE_FROM_PSTATE(___ps)->mem.nb_gcs_);"))
(define end-control (c-lambda () void "_Exit(0);"))
(define (require-test p label) (if (not p) (error label)))
(define dump-entry-state (c-lambda (int) void #<<c-end
___virtual_machine_state vm=___VMSTATE_FROM_PSTATE(___ps);
int i;
fprintf(stderr,"ENTRY-STATE expected=%d observed=%d generation=%ld members=%d phase=%d\n",___arg1,atomic_load(&entry_count),(long)vm->resize.generation,vm->processor_count,vm->resize.phase);
for(i=0;i<3;i++) {
 ___processor_state p=___PSTATE_FROM_PROCESSOR_ID(i,vm);
 fprintf(stderr,"ENTRY-SLOT id=%d phase=%d permit=%d thunk=%d marker=%d sync=%d,%d,%d\n",i,vm->resize.slots[i].phase,vm->resize.slots[i].entry,p->context->startup_thunk!=___FAL,p->context->entry_marker!=___FAL,p->sync_id0,p->sync_id1,p->sync_id2);
}
c-end
))
(define (await-entry n)

  (let loop ((i 0))
    (cond ((= (entries) n) #t)
          ((> i 10000) (begin (dump-entry-state n) (error "startup entries did not complete" n (entries))))
          (else (thread-yield!) (loop (+ i 1))))))
(define (request n)
  ;; Fresh closure and payload must survive the pre-grant collection, entry
  ;; synchronization and marker allocation. Each child records actual entry.
  (let ((payload (vector 314159)))
    (##current-vm-resize
      (lambda ()
        (declare (not interrupts-enabled))
        (if (not (= (vector-ref payload 0) 314159)) (error "startup closure root"))
        (note-entry)
        (##startup-processor!))
      n)))
(require-test (= (##current-vm-processor-count) 1) "fixture requires p1 initial population")
(let ((mode (getenv "GAMBIT_VM_RESIZE_FAULT_CASE" "none")))
  (cond
    ((equal? mode "allocation")
     (require-test (= (arm 0 0 2) 1) "fault adapter unavailable")
     (require-test (not (= (request 11) 0)) "partial reservation accepted")
     (require-test (= (fault-count 2) 2) "second physical allocation not reached")
     (require-test (= (capacity) (base-capacity)) "partial capacity not refunded")
     (require-test (= (assigned) (base-assigned)) "assigned regions changed on failed grant")
     (require-test (= (phase) 0) "known allocation failure not closed"))
    ((or (equal? mode "create") (equal? mode "unknown"))
     (require-test (= (arm 2 (if (equal? mode "unknown") 1 0) 0) 1) "fault adapter unavailable")
     (if (equal? mode "unknown") (hold-start 1))
     (require-test (not (= (request 3) 0)) "pthread error with errno zero accepted")
     (require-test (= (fault-count 0) 2) "partial creation not reached")
     (require-test (= (entries) 0) "unpublished child entered Scheme")
     (if (equal? mode "unknown")
       (begin
         (require-test (retained-phase?) "unknown join lost quarantine")
         (require-test (retained-root?) "unknown join lost request root")
         (require-test (isolated?) "abort writer domain not isolated")
         (let loop () (if (= (fault-count 3) 0) (begin (thread-yield!) (loop))))
         (require-test (= (assigned) (base-assigned)) "empty grants not detached")
         (let ((before (collections))) (##gc) (##gc) (##gc)
           (require-test (>= (- (collections) before) 3) "healthy VM GC blocked by unknown join"))
         (require-test (= (fault-count 3) 1) "held native thread escaped during healthy GC")
         (require-test (retained-root?) "isolated GC lost request root")
         (hold-start 0)
         (let loop () (if (not (= (fault-count 3) 0)) (begin (thread-yield!) (loop))))
         (require-test (not (= (request 3) 0)) "unknown transaction reused")
         (require-test (retained-reinit-rejected?) "retained cleanup/setup erased custody")
         (display "RESIZE-UNKNOWN-ISOLATED-GC-PASS\n")
         (force-output)
         ;; A deliberately unjoinable test process cannot claim clean runtime
         ;; shutdown. This explicit end is a safety control only.
         (end-control))
       (begin
         (require-test (= (capacity) (base-capacity)) "create rollback capacity")
         (require-test (= (assigned) (base-assigned)) "create rollback assigned")
         (require-test (= (phase) 0) "known creation failure not closed")))))
  (require-test (= (##current-vm-processor-count) 1) "failed request published members")
  (if (not (equal? mode "none")) (arm 0 0 0))
  (let repeat ((round 0))
  (require-test (= (request 3) 0) "growth retry failed")
  (await-entry (+ (* round 4) 2))
  (require-test (= (##current-vm-processor-count) 3) "successful count mismatch")
  (##gc)
  (require-test (= (##cvmr 1) 0) "retirement admission failed")
  (require-test (= (##current-vm-processor-count) 1) "shrink count mismatch")
  (##gc)
  (require-test (= (request 3) 0) "slot generation reuse failed")
  (await-entry (+ (* round 4) 4))
  (require-test (= (##cvmr 1) 0) "second retirement failed")
  (##gc)
    (if (< round 39) (repeat (+ round 1))))
  (display "RESIZE-TRANSACTION-PASS\n"))
