#include "lp64.h"
#include "fits.inc"

typedef struct { struct { long max_heap; } setup_params; } global_state;
global_state global;
#define ___GSTATE (&global)
___msections *the_msections;
long occupied_words_still;
int growth_called;
int growth_request;

/* Callee summary only. The actual resize implementation is checked separately.
 * It may make no progress or partially grow; no success is assumed. */
void adjust_msections(___msections **pool,int need)
{
  int before=(*pool)->nb_sections;
  int after=nondet_int();
  growth_called=1;growth_request=need;
  ASSUME(after>=before && after<=need);
  (*pool)->nb_sections=after;
}

