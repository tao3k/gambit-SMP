(declare (standard-bindings) (extended-bindings))
(c-declare #<<c-end
#include <stdatomic.h>
#include <stdint.h>
static _Atomic int enabled,arrivals,finished;
static ___WORD target;
static ___WORD cells[2];
static uintptr_t starts[2],ends[2],after[2];
static ___SIZE_TS cancellations[2],copies[2],cancelBase[2],copyBase[2];
static int worker_id(___collector_worker *w) {
 return (int)___PROCESSOR_ID(w->carrier,___VMSTATE_FROM_PSTATE(w->carrier));
}
int gambit_copy_test_begin(___collector_worker *w) {
 int id=worker_id(w);
 if(!atomic_load(&enabled)||id>=2) return 0;
 cells[id]=target;return 1;
}
___WORD *gambit_copy_test_cell(___collector_worker *w) {return &cells[worker_id(w)];}
void gambit_copy_test_before(___collector_worker *w,___WORD *body,___WORD head) {
 int id=worker_id(w);(void)head;
 if(!atomic_load(&enabled)||id>=2||body!=___BODY0(target)) return;
 starts[id]=(uintptr_t)w->copy_begin_;ends[id]=(uintptr_t)w->copy_past_;
 cancelBase[id]=w->copy_cancelled_words_;copyBase[id]=w->copied_words;
 atomic_fetch_add(&arrivals,1);
 while(atomic_load(&arrivals)<2) ___CPU_RELAX();
}
void gambit_copy_test_end(___collector_worker *w) {
 int id=worker_id(w);
 if(!atomic_load(&enabled))return;
 if(id<2) {
  cancellations[id]=w->copy_cancelled_words_-cancelBase[id];
  copies[id]=w->copied_words-copyBase[id];
  after[id]=(uintptr_t)w->context->mem.alloc_heap_ptr_;
  atomic_fetch_add(&finished,1);
 }
 while(atomic_load(&finished)<2) ___CPU_RELAX();
}
c-end
)
(define install-target (c-lambda (scheme-object) void "target=___arg1;atomic_store(&enabled,1);"))
(define verify-copy (c-lambda () bool #<<c-end
int i;int valid=atomic_load(&arrivals)==2&&atomic_load(&finished)==2;
atomic_store(&enabled,0);
valid=valid&&(ends[0]<=starts[1]||ends[1]<=starts[0]);
valid=valid&&cells[0]==cells[1]&&cancellations[0]+cancellations[1]==4&&copies[0]+copies[1]==4;
for(i=0;i<2;i++) {
 valid=valid&&ends[i]-starts[i]==4*sizeof(___WORD);
 if(cancellations[i]) valid=valid&&cancellations[i]==4&&copies[i]==0&&after[i]==starts[i];
 else valid=valid&&copies[i]==4;
}
valid=valid&&___BODY0(cells[0])[0]==___FIX(1234567)&&___BODY0(cells[0])[1]==___FIX(99)&&___BODY0(cells[0])[2]==___FIX(42);
___return(valid);
c-end
))
(if (not (= (##current-vm-processor-count) 11)) (error "collision requires p11"))
;; No Scheme global retains this value. The test root adapter registers two
;; disjoint cells before ordinary execution-root scanning in the same round.
(install-target (vector 1234567 99 42))
(##gc)
(if (not (verify-copy)) (error "real forwarding/refund conservation failed"))
(display "COPY-CAS-REFUND-PASS arrivals=2 cancelled=4 copied=4\n")
