#include "gambit.h"

/* Compile-only ABI/context diagnostic; never called as a runtime fixture. */
___SCMOBJ marker_context_probe(___global_state gs, ___processor_state ps,
                             ___SCMOBJ *marker, ___SCMOBJ proc)
{
  return ___sfun_frame_marker(gs, ps, marker, proc);
}

void marker_void_wrapper_probe(___global_state ___local_gstate, ___SCMOBJ proc)
{
  ___BEGIN_SFUN_VOID(proc)
  ___SFUN_ERROR_VOID
  ___END_SFUN_VOID
}

void marker_scmobj_wrapper_probe(___global_state ___local_gstate, ___SCMOBJ proc)
{
  ___BEGIN_SFUN_SCMOBJ(proc)
  ___SFUN_ERROR_SCMOBJ
  ___END_SFUN_SCMOBJ
}

void marker_generic_wrapper_probe(___global_state ___local_gstate, ___SCMOBJ proc)
{
  ___BEGIN_SFUN(proc,)
  ___SFUN_ERROR
  ;
  ___END_SFUN
}
