(declare (standard-bindings) (extended-bindings))
(c-declare #<<c-end
#include <stdatomic.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
static _Atomic int armed,arrivals,rejected,entries;
static _Atomic ___WORD first_token;
static uintptr_t initial[2];
static int moved;
static ___WORD expected_serial;
extern ___BOOL ___garbage_collect_pstate(___processor_state,___SIZE_TS);
extern void ___throw_error(___processor_state,___SCMOBJ);
void gambit_request_control(int event,___processor_state ps,___WORD token) {
 ___virtual_machine_state vm=___VMSTATE_FROM_PSTATE(ps);
 int id=(int)___PROCESSOR_ID(ps,vm);
 const char *mode=getenv("GAMBIT_REQUEST_CASE");
 if(!atomic_load(&armed)) return;
 if(event==1) {
  ___resize_request_root *r=&vm->resize_requests[id];
  ___WORD serial=r->serial;___SCMOBJ root=r->thunk;
  if(___current_vm_resize(ps,___FAL,2)==___FIX(___UNKNOWN_ERR)&&
     r->serial==serial&&r->thunk==root&&r->state==___RESIZE_SOURCE_QUEUED)
    atomic_fetch_add(&rejected,1);
  if(mode&&strcmp(mode,"exception")==0) ___throw_error(ps,___FIX(___UNKNOWN_ERR));
  initial[id]=(uintptr_t)r->thunk;
  atomic_fetch_add(&arrivals,1);
  while(atomic_load(&arrivals)<2) ___CPU_RELAX();
 } else if(event==2) {
  ___WORD zero=0;atomic_compare_exchange_strong(&first_token,&zero,token);
  if(token==atomic_load(&first_token)) {
   if(___garbage_collect_pstate(ps,0)) abort();
   if(id==0) moved=((uintptr_t)vm->resize_requests[0].thunk!=initial[0])+
                    ((uintptr_t)vm->resize_requests[1].thunk!=initial[1]);
  }
 }
}
static int request_from_fixture(___processor_state ___ps,___SCMOBJ thunk,int target) {
 ___SCMOBJ ___err=___FIX(___NO_ERR);___SCMOBJ answer=___FIX(___UNKNOWN_ERR);
 ___BEGIN_TRY
   answer=___current_vm_resize(___ps,thunk,target);
 ___END_TRY
 return ___INT(___err==___FIX(___NO_ERR)?answer:___err);
}
c-end
)
(define request (c-lambda (scheme-object int) int "___return(request_from_fixture(___ps,___arg1,___arg2));"))
(define arm (c-lambda () void "expected_serial=___VMSTATE_FROM_PSTATE(___ps)->resize_requests[0].serial+1;atomic_store(&armed,1);"))
(define disarm (c-lambda () void "atomic_store(&armed,0);"))
(define entry-count (c-lambda () int "___return(atomic_load(&entries));"))
(define note-entry (c-lambda () void "atomic_fetch_add(&entries,1);"))
(define check (c-lambda () bool #<<c-end
___virtual_machine_state vm=___VMSTATE_FROM_PSTATE(___ps);int i;
int ok=atomic_load(&arrivals)==2&&atomic_load(&rejected)==2&&moved==2&&
       atomic_load(&first_token)%___MAX_PROCESSORS==0;
for(i=0;i<___MAX_PROCESSORS;i++)
 ok=ok&&vm->resize_requests[i].state==___RESIZE_SOURCE_IDLE&&vm->resize_requests[i].thunk==___FAL;
___return(ok);
c-end
))
(define retained? (c-lambda () bool #<<c-end
___resize_request_root *r=&___VMSTATE_FROM_PSTATE(___ps)->resize_requests[0];
___return(r->state==___RESIZE_SOURCE_RETAINED&&r->thunk!=___FAL&&r->serial==expected_serial&&atomic_load(&rejected)==1);
c-end
))
(define safety-exit (c-lambda () void "_Exit(0);"))
(define (require-test p label) (if (not p) (error label)))
(require-test (= (##current-vm-processor-count) 1) "requires p1 initial")
(require-test (= (##cvmr 2) 0) "initial two ready members")
(##thread-pin! (current-thread) (##processor 0))
(let ((mode (getenv "GAMBIT_REQUEST_CASE" "normal")))
  (define (invoke id target)
    (let ((payload (vector (+ 812300 id))))
      (request (lambda ()
                 (declare (not interrupts-enabled))
                 (require-test (= (vector-ref payload 0) (+ 812300 id)) "relocated thunk payload")
                 (note-entry)
                 (##startup-processor!)) target)))
  (arm)
  (if (equal? mode "exception")
    (begin
      (require-test (not (= (invoke 0 3) 0)) "exception lost")
      (disarm)
      (require-test (retained?) "exception erased source custody")
      (##gc)
      (require-test (retained?) "retained source not scanned")
      (require-test (not (= (request #f 2) 0)) "retained identity reused")
      (display "REQUEST-EXCEPTION-RETAINED-PASS\n") (force-output) (safety-exit))
    (let ((other (make-thread (lambda () (invoke 1 (if (equal? mode "retire") 2 4))))))
      (##thread-pin! other (##processor 1))
      (thread-start! other)
      (let ((answer (invoke 0 (if (equal? mode "retire") 1 3))))
        (require-test (if (equal? mode "retire") (not (= answer 0)) (= answer 0)) "origin zero result"))
      (require-test (= (thread-join! other) 0) "origin one result")
      (disarm)
      (require-test (check) "source relocation/drain/reentry/order contract")
      (if (not (equal? mode "retire"))
        (begin (require-test (= (##current-vm-resize-ready #f 4) 0) "new children ready") (require-test (= (entry-count) 2) "both relocated payloads entered")))
      (require-test (= (##cvmr 1) 0) "retirement after source ACK")
      (##gc)
      (display (if (equal? mode "retire") "REQUEST-PENDING-RETIRE-REJECTED-PASS\n" "REQUEST-CONCURRENT-GC-PASS moved=2\n")))))
