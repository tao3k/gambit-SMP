#ifndef GAMBIT_TEST_MAP_SLOT_GC_CUTS_H
#define GAMBIT_TEST_MAP_SLOT_GC_CUTS_H

#include <stdint.h>

void map_slot_gc_frozen(void *ps, uintptr_t epoch);
void map_slot_gc_repaired(void *ps, uintptr_t epoch);

#define ___GC_SLOT_TEST_FROZEN(ps, epoch) map_slot_gc_frozen(ps, epoch)
#define ___GC_SLOT_TEST_REPAIRED(ps, epoch) map_slot_gc_repaired(ps, epoch)

#endif
