/* Configured physical layout observation; not a copied structure declaration. */
#include "gambit.h"
#include <stddef.h>
#include <stdio.h>
#ifdef ___SINGLE_THREADED_VMS
#error Threaded profile required for this observation
#endif
int main(void) {
 printf("%zu %zu %zu %zu %zu %zu %zu %zu %zu %zu %zu\n",
 sizeof(___processor_state_struct),offsetof(___processor_state_struct,sync_id0),
 offsetof(___processor_state_struct,sync_op0),offsetof(___processor_state_struct,sync_id1),
 offsetof(___processor_state_struct,sync_op1),offsetof(___processor_state_struct,sync_id2),
 offsetof(___processor_state_struct,sync_op2),sizeof(((___processor_state)0)->sync_id0),
 sizeof(___sync_op_struct),offsetof(___processor_state_struct,context),offsetof(___processor_state_struct,collector));
 return 0;
}
