/* DEV diagnostic overlay. Compile the retained setup.c unchanged, except for
   observing its name lookup result. This is not a runtime implementation or
   a performance subject; libc logging may change scheduling. */
#include <string.h>
#define ___subprocedure_parent_name test_environment_parent_name
#include "setup.c"
#undef ___subprocedure_parent_name
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdatomic.h>
#include <dlfcn.h>

___SCMOBJ ___subprocedure_parent_name (___SCMOBJ proc)
{
  ___SCMOBJ name = test_environment_parent_name (proc);
  static _Atomic unsigned observations;
  if (name == ___FAL &&
      atomic_fetch_add_explicit (&observations, 1, memory_order_relaxed) < 64)
    {
#ifdef ___SUPPORT_LOWLEVEL_EXEC
      if (___LOWLEVEL_LABEL(proc))
        fprintf (stderr, "ENVIRONMENT-CODE-IDENTITY unnamed lowlevel\n");
      else
#endif
        {
          ___SCMOBJ intro = ___subprocedure_parent_intro (proc);
          void *host = (void *) ___LABEL_HOST_GET(proc);
          Dl_info image;
          int found = dladdr (host, &image);
          fprintf (stderr,
                   "ENVIRONMENT-CODE-IDENTITY unnamed proc=%" PRIxPTR
                   " intro=%" PRIxPTR " id=%ld return=%d host=%p symbol=%s\n",
                   (uintptr_t) proc, (uintptr_t) intro,
                   (long) ___INT(___subprocedure_id (proc)),
                   !!___TESTSUBTYPETAG(proc, ___sRETURN), host,
                   found && image.dli_sname ? image.dli_sname : "UNKNOWN");
        }
    }
  return name;
}
