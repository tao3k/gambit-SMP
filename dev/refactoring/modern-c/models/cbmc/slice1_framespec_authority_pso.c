/* CBMC --mm pso Weak-Memory Contract Harness for Slice 1:
 *   Unified FrameSpec / PointId Authority (OFD Fixup Publication + Cohort Pinning)
 *
 * Mirrors:
 *   - lib/setup.c: setup_module_fixup (OFD bind -> release-publish module)
 *   - include/_gambit/module_generation.h.in: ___frame_is_unresolved_ofd /
 *       ___decode_frame_descriptor_checked
 *   - lib/os_dyn.c: ___dyn_cohort_pin / ___dyn_cohort_unpin / cleanup_dynamic_load
 *
 * Verification commands:
 *   cbmc --mm pso -DUSE_GUARD=1 slice1_framespec_authority_pso.c  (MUST PASS)
 *   cbmc --mm pso -DUSE_GUARD=0 slice1_framespec_authority_pso.c  (MUST FAIL / kill mutant)
 */

#include <assert.h>
#include <stdint.h>

#ifndef USE_GUARD
#define USE_GUARD 1
#endif

/* Bit-identical to include/_gambit/module_generation.h.in */
#define KIND_WIDTH 2
#define IFD_FS_WIDTH 5
#define RETN 1
#define RETI 2
#define MAKE_IFD(k, fs, link, gcmap) \
  (((uint64_t)(gcmap) << (2 * IFD_FS_WIDTH + KIND_WIDTH)) | \
   ((uint64_t)(link) << (IFD_FS_WIDTH + KIND_WIDTH)) | \
   ((uint64_t)(fs) << KIND_WIDTH) | (uint64_t)(k))
#define UNRESOLVED_OFD(k) MAKE_IFD((k), 0, 0, 0)
#define IS_IFD(x) ((x) & 3ULL)
#define IS_UNRESOLVED_OFD(x) \
  (IS_IFD(x) && (((x) >> KIND_WIDTH) == 0ULL))

/* Simulated module OFD table and return-label descriptor slot */
static uint64_t ofd_table_header = 0; /* 0 = uninitialized, >0 = bound OFD header */
static uint64_t lbl_descr = UNRESOLVED_OFD(RETI);
static int module_published = 0;

/* Simulated dynamic .o1 metadata lifetime and cohort pin count */
static int cohort_pin_count = 0;
static int metadata_alive = 1;
static int reader_saw_unresolved = 0;
static int reader_saw_freed_metadata = 0;

static void loader_setup_and_publish(void) {
  /* 1. Populate aligned OFD entry and bind lbl_descr to non-IFD bound handle */
  ofd_table_header = (1ULL << 16) | (24ULL << 2) | RETI;
  lbl_descr = 0x10000ULL; /* aligned pointer (low 2 bits == 0, non-IFD) */

#if USE_GUARD
  /* Release fence before publishing module to peer processors */
  __CPROVER_fence("WWfence", "RWfence");
#endif
  module_published = 1;
}

static void mutator_capture_and_scan(void) {
  int pub = module_published;
#if USE_GUARD
  __CPROVER_fence("RRfence", "RWfence");
#endif
  if (pub) {
    /* Pin dynamic .o1 cohort before capturing continuation / scanning */
    int pinned = 0;
    __CPROVER_atomic_begin();
    if (metadata_alive) {
      cohort_pin_count++;
      pinned = 1;
    }
    __CPROVER_atomic_end();

    if (pinned) {
      uint64_t d = lbl_descr;
      if (IS_UNRESOLVED_OFD(d)) {
        reader_saw_unresolved = 1;
      }
      if (!IS_IFD(d)) {
        if (!metadata_alive || ofd_table_header == 0) {
          reader_saw_freed_metadata = 1;
        }
      }
      __CPROVER_atomic_begin();
      cohort_pin_count--;
      __CPROVER_atomic_end();
    }
  }
}

static void unloader_try_dlclose(void) {
#if USE_GUARD
  /* Refuse unload while any captured continuation cohort pin is held */
  __CPROVER_atomic_begin();
  if (cohort_pin_count == 0) {
    metadata_alive = 0;
  }
  __CPROVER_atomic_end();
#else
  /* Buggy mutant: unloads dynamic .o1 metadata without checking cohort_pin_count */
  metadata_alive = 0;
#endif
}

int main(void) {
  /* Verify valid zero-map inline IFD (fs=8, link=7, gcmap=0) is NOT misclassified
   * as an unresolved OFD sentinel, while UNRESOLVED_OFD(RETN/RETI) IS caught! */
  uint64_t valid_zero_map = MAKE_IFD(RETN, 8, 7, 0);
  assert(!IS_UNRESOLVED_OFD(valid_zero_map));
  assert(IS_UNRESOLVED_OFD(UNRESOLVED_OFD(RETN)));
  assert(IS_UNRESOLVED_OFD(UNRESOLVED_OFD(RETI)));

  __CPROVER_ASYNC_1: loader_setup_and_publish();
  __CPROVER_ASYNC_2: mutator_capture_and_scan();
  unloader_try_dlclose();

  assert(!reader_saw_unresolved);
  assert(!reader_saw_freed_metadata);
  return 0;
}
