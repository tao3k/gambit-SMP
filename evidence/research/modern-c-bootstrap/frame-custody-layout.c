/* Structural cost only: no throughput, peak RSS or runtime qualification. */
#include <stdio.h>
#include "gambit.h"
#include "mem.h"
int main(void) {
  printf("{\"wordBytes\":%zu,\"maxProcessors\":%d,\"ledgerBytes\":%zu,\"slotBytes\":%zu,\"contextBytes\":%zu,\"workerBytes\":%zu,\"carrierStrideBytes\":%zu,\"vmBytes\":%zu,\"sectionWords\":%d,\"fudgeWords\":%d,\"biggestMovableWords\":%d,\"subtypedTag\":%d,\"vectorTag\":%d}\n",
    sizeof(___WORD),___MAX_PROCESSORS,sizeof(___vm_resize_ledger),sizeof(___vm_resize_slot),
    sizeof(___execution_context),sizeof(___collector_worker),sizeof(___aligned_processor_state_struct),
    sizeof(struct ___virtual_machine_state_struct),___MSECTION_SIZE,___MSECTION_FUDGE,___MSECTION_BIGGEST,___tSUBTYPED,___tVECTOR);
  fprintf(stderr,"%zu %zu %zu\n", (size_t)___msection_scan_words(___MSECTION_SIZE)*___WS,
    (size_t)___MSECTION_SIZE*___WS, (size_t)___sizeof_msection(___MSECTION_SIZE));
  return 0;

}
