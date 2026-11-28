/* Transport regression: compile the maintained recorder verbatim. This does
 * not implement or qualify Gambit's allocator, GC, or rest algorithms. */
#define ___GAMBIT_REST_OBSERVATION 1
#include "rest-observation.h"
/* Some recorder state is only used by the allocator and handler fragments. */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
#include "_mem/rest-observation.inc"
#pragma GCC diagnostic pop
#include <pthread.h>
#include <stdio.h>
#define ___PSTATE ((void*)7)
#define ___LWS 3
#define ___LF 2
#define ___HTB 3
#define ___MOVABLE0 1
#define ___sPAIR 0
#define ___PAIR_SIZE 2
#ifdef REST_NATIVE_TEST_UNOBSERVED_MACROS
#undef ___GAMBIT_REST_OBSERVATION
#endif
#include "_gambit/language.h.in"
#include "_gambit/object_access.h.in"
#include "_gambit/stack_operations.h.in"

static void *writer(void *raw)
{
  uint64_t actor=(uintptr_t)raw, i;
  for (i=0;i<100;i++)
    ___rest_observation_emit(REST_STORE,actor,0,0,0,actor,i,0,0,0,0,0,0);
  return 0;
}

static void *check_unbound_carrier(void *actor)
{
  return rest_observation_attempt_record(actor) || rest_observation_attempt_id(actor)
         ? actor : NULL;
}

int main(int argc, char **argv)
{
  pthread_t a,b;
  if (argc!=3) return 2;
  if (!strcmp(argv[2],"carrier")) {
    uint64_t actor=0, record=0;
    void *other;
    if (setenv("GAMBIT_REST_OBSERVATION",argv[1],1) ||
        !___rest_observation_open(NULL) || !___rest_observation_case(7)) return 7;
    rest_observation_set_case_hold(1);
    rest_observation_case_enter();
    rest_observation_chain_bind(&record,19);
    /* The rest activation sets the protocol attempt separately from its epoch. */
    rest_observation_protocol_attempt=11;
    if (pthread_create(&a,NULL,check_unbound_carrier,&actor) ||
        pthread_join(a,&other) || other) return 8;
    REST_OBS(REST_SECTION_VIEW,&actor,rest_observation_attempt_record(&actor),
             rest_observation_attempt_id(&actor),rest_observation_chain_attempt,0,0,0,0,0,0,0,0);
    rest_observation_chain_bind(NULL,0);
    if (rest_observation_attempt_id(&actor) || rest_observation_attempt_record(&actor)) return 9;
    rest_observation_case_leave();
    if (rest_observation_current_case()!=7) return 10;
    rest_observation_set_case_hold(0);
    rest_observation_case_enter();
    rest_observation_case_leave();
    if (rest_observation_current_case()) return 10;
    rest_observation_finish();
    return 0;
  }
  if (!___rest_observation_open(argv[1]) || !___rest_observation_case(1)) return 2;
  if (!strcmp(argv[2],"delivery")) {
    uint64_t actor=0, other=0, record=0;
    if (___rest_observation_body(&actor)) return 12;
    rest_observation_case_enter();
    rest_observation_ready_result=19;
    ___rest_observation_delivered(&actor,&record,11,19);
    rest_observation_case_leave();
    if (___rest_observation_body(&other) || !___rest_observation_body(&actor) ||
        !___rest_observation_body(&actor)) return 13;
    return !(___rest_observation_case_end() && ___rest_observation_close());
  }
  if (!strcmp(argv[2],"macros")) {
    uint64_t stack[8]={0}, heap[8]={0};
    uint64_t *fp=stack+8, *___hp=heap, popped;
    ___FP_PUSH(fp,11)
    ___FP_ADJFP(fp,1)
    ___FP_SET_STK(fp,1,22)
    popped=___FP_POP(fp);
    ___BEGIN_ALLOC_PAIR();
    ___ADD_PAIR_ELEM(0,33);
    ___ADD_PAIR_ELEM(1,44);
    ___END_ALLOC_PAIR();
    if (fp!=stack+7 || popped!=0 || stack[7]!=11 || stack[5]!=22 ||
        ___hp!=heap+3 || heap[1]!=33 || heap[2]!=44) return 6;
    return !(___rest_observation_case_end() && ___rest_observation_close());
  }
  if (!strcmp(argv[2],"crash")) {
    REST_OBS(REST_PREFLIGHT,1,0,0,0,3,0,0,1,0,0,0,0);
    _exit(70); /* no close: the committed prefix must survive */
  }
  if (pthread_create(&a,0,writer,(void*)1) || pthread_create(&b,0,writer,(void*)2)) return 3;
  if (pthread_join(a,0) || pthread_join(b,0)) return 4;
  if (!___rest_observation_case_end() || !___rest_observation_close()) return 5;
  return 0;
}
