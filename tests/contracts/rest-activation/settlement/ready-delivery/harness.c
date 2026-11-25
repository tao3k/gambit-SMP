/* Compile actual READY, delivery, and finish control flow. The directory pin
 * and root-view lookup are supplied interfaces, not verified here. */
typedef long ___WORD, ___SCMOBJ;
typedef unsigned long ___SIZE_T;
typedef struct { int identity; } ___rc_domain;
typedef struct {
  ___rc_domain *domain;
  long refcount, root_borrows;
  ___SIZE_T root_count;
} ___rc_header;
typedef struct {
  ___SCMOBJ *roots;
  ___WORD rest_epoch;
  int rest_phase, rest_delivered;
} ___activation_record;
struct context { ___WORD *hp; };
struct processor { struct context *context; struct { ___rc_domain *rc_domain_; } mem; };
typedef struct processor *___processor_state;
#define ___CAST(t,x) ((t)(x))
#define ___FIX(x) ((x)*4L)
#define ___FAL (-1L)
#define REST_OBS(...) ((void)0)
#define ___RC_LOCK(d) ((void)(d))
#define ___RC_UNLOCK(d) ((void)(d))
#define CHECK(p,n) __CPROVER_assert((p),(n))
#include "status.inc"
static struct { ___rc_header header; ___SCMOBJ roots[2]; } storage;
static ___rc_domain domain, foreign;
static struct context context;
static struct processor processor;
static ___activation_record record;
static int view_open, writer_open;
static enum ___rest_status pin_status;
static int cleanup_count;
static unsigned ___rest_ready_claims, ___rest_internal_entries;
static int nondet_int(void);
static enum ___rest_status rest_with_pin(___processor_state ps, ___activation_record *r,
                                         ___WORD attempt, ___WORD epoch, int *index)
{
  (void)ps; (void)r; (void)attempt; (void)epoch;
  if (pin_status==___REST_OK) *index=0;
  return pin_status;
}
static void rest_unpin(___processor_state ps, int index, ___WORD epoch)
{ (void)ps; (void)index; (void)epoch; }
static int rest_view_open(___processor_state ps, ___activation_record *r,
                          ___WORD attempt, ___WORD epoch, ___WORD *count)
{ (void)ps; (void)r; (void)attempt; (void)epoch; *count=2; return view_open; }
static int root_writer_open(___processor_state ps) { (void)ps; return writer_open; }
static enum ___rest_status ___rest_activation_cleanup(___processor_state ps,
                                                       ___activation_record *r,
                                                       ___WORD attempt, ___WORD epoch)
{ (void)ps; (void)r; (void)attempt; (void)epoch; ++cleanup_count; return ___REST_OK; }
#include "ready.inc"
#include "delivery.inc"
#include "finish.inc"

static void setup(int fault)
{
  processor.context=&context;
  processor.mem.rc_domain_=&domain;
  storage.header=(___rc_header){&domain,1,1,2};
  /* Runtime layout is one header immediately followed by root words. */
  record=(___activation_record){(___SCMOBJ *)(&storage.header+1),7,___REST_INSTALLED,0};
  view_open=writer_open=1;
  pin_status=___REST_OK;
  if (fault==1) pin_status=___REST_RETRY;
  if (fault==2) view_open=0;
  if (fault==3) writer_open=0;
  if (fault==4) record.rest_epoch=8;
  if (fault==5) storage.header.root_borrows=0;
  if (fault==6) storage.header.domain=&foreign;
  if (fault==7) storage.header.root_count=1;
  if (fault==8) record.rest_phase=___REST_PUBLISHING;
  if (fault==9) { record.rest_phase=___REST_READY; record.rest_delivered=1; }
  if (fault==10) storage.header.refcount=0;
}

void check_delivery(void)
{
  int fault=nondet_int();
  __CPROVER_assume(fault>=0 && fault<=10);
  setup(fault);
  ___SCMOBJ result=___rest_finish_refusal(&processor,&record,7,42,0);
  CHECK(cleanup_count==1,"settlement.one-cleanup");
  if (fault==0) {
    CHECK(result==42 && ___rest_ready_claims==1 && ___rest_internal_entries==1,"settlement.ready-and-deliver-once");
    CHECK(___rest_resume_delivery(&processor,&record,7,___FIX(1),0,0,0)==___REST_DUPLICATE,
          "settlement.replay-refused");
    CHECK(___rest_internal_entries==1,"settlement.replay-does-not-deliver");
  } else {
    CHECK(result==0 && ___rest_internal_entries==0,"settlement.failing-prerequisite-no-delivery");
    CHECK(___rest_ready_claims==0 && storage.roots[1]==0,"settlement.failing-prerequisite-no-ready-write");
  }
}

void check_grant_is_not_delivery(void)
{
  /* Capacity was granted, but it supplies no root-writer guarantee. */
  setup(3);
  CHECK(___rest_finish_refusal(&processor,&record,7,42,0)!=0,"control.grant-does-not-discharge-writer");
}

void check_ready_is_not_delivery(void)
{
  setup(0);
  CHECK(___rest_claim_ready(&processor,&record,___FIX(1),7,42)==___REST_OK,
        "settlement.ready-control-reaches-ready");
  /* Explicit environment transition, not a proved native interleaving. */
  writer_open=0;
  ___SCMOBJ result=-9;
  enum ___rest_status status=___rest_resume_delivery(&processor,&record,7,___FIX(1),0,0,&result);
  CHECK(status==___REST_LOST && result==-9 && record.rest_phase==___REST_READY &&
        !record.rest_delivered && ___rest_internal_entries==0,
        "settlement.closed-writer-after-ready-preserves-delivery");
}
