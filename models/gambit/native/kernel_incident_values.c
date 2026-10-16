/* Classify captured values using the exact configured runtime tag/error ABI. */
#include "gambit.h"
#include <errno.h>
#include <stdio.h>

_Static_assert(sizeof(___SCMOBJ) == 8, "the observed incident uses 64-bit values");
_Static_assert(___ABSENT == (___SCMOBJ)-44, "captured return value is ABSENT");
_Static_assert(___FIX(___ERRNO_ERR(EINTR)) ==
               (___SCMOBJ)0xffffffff0a000020ULL,
               "captured C result is the configured EINTR error");

int main(void)
{
  if ((___SCMOBJ)-44 - 9 != (___SCMOBJ)-53)
    return 1;
  puts("INCIDENT-VALUES-ABSENT-EINTR-OK");
  return 0;
}
