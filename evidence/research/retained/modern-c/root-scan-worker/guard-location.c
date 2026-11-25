/* Actual configured types distinguish execution roots from allocator limits. */
#include "gambit.h"
___WORD *guard_location(___processor_state ps)
{
#ifdef UNQUALIFIED_CONTEXT_LIMIT
  return ps->context->heap_limit;
#else
  return ps->heap_limit;
#endif
}
