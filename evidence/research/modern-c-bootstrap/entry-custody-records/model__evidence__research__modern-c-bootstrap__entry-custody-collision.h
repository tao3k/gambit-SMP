/* Qualification-only compile-time scheduling. Default runtime macros are no-op.
 * This header is injected into a separate mem.o, never the production profile. */
/* Preserve mem.c's actual import context before the forced header include. */
#define ___INCLUDED_FROM_MEM
#define ___VERSION 409008
#include "gambit.h"
extern int gambit_copy_test_begin(___collector_worker *);
extern ___WORD *gambit_copy_test_cell(___collector_worker *);
extern void gambit_copy_test_end(___collector_worker *);
extern void gambit_copy_test_before(___collector_worker *, ___WORD *, ___WORD);
#define ___GC_ROOT_CONTROL(work) do { \
  if(gambit_copy_test_begin(work)) mark_array(work,gambit_copy_test_cell(work),1); \
  gambit_copy_test_end(work); \
} while(0)
#define ___GC_COPY_CONTROL(work,body,head) gambit_copy_test_before(work,body,head)
