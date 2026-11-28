/* Family 11 (11/12: gerbil) CBMC Contract:
 * Verifies C-level ABI seal fingerprint matching between the sealed Gambit
 * producer (gsi, gsc, libgambit.a, gambit.h, SMP capability mask) and each
 * downstream Gerbil stage artifact.
 */
#include <stdint.h>

#define CHECK(p, n) __CPROVER_assert((p), (n))
extern uint64_t nondet_u64(void);
extern int nondet_int(void);

#define GERBIL_STAGES 8

typedef struct {
  uint64_t gsi_fp;
  uint64_t gsc_fp;
  uint64_t lib_fp;
  uint64_t hdr_fp;
  uint32_t cap_mask;    /* bit0: multiple_threaded_vms, bit1: multiple_vms, bit2: smp */
  uint32_t export_mask; /* bit0: group_demand_enter, bit1: group_demand_commit, bit2: primitive_ref, bit3: publish_raw_stack_span */
} abi_seal;

static int seals_equal(const abi_seal *a, const abi_seal *b) {
  return a->gsi_fp == b->gsi_fp &&
         a->gsc_fp == b->gsc_fp &&
         a->lib_fp == b->lib_fp &&
         a->hdr_fp == b->hdr_fp &&
         a->cap_mask == b->cap_mask &&
         a->export_mask == b->export_mask;
}

static int admit_gerbil_chain(const abi_seal *producer, const abi_seal stages[GERBIL_STAGES],
                              const int passed[GERBIL_STAGES]) {
  if ((producer->cap_mask & 7u) != 7u)
    return 0;
  if ((producer->export_mask & 15u) != 15u)
    return 0;
  for (int i = 0; i < GERBIL_STAGES; ++i) {
    if (!passed[i] || !seals_equal(producer, &stages[i]))
      return 0;
  }
  return 1;
}

int main(void) {
  abi_seal prod;
  prod.gsi_fp = nondet_u64();
  prod.gsc_fp = nondet_u64();
  prod.lib_fp = nondet_u64();
  prod.hdr_fp = nondet_u64();
  prod.cap_mask = 7u;
  prod.export_mask = 15u;

  abi_seal stages[GERBIL_STAGES];
  int passed[GERBIL_STAGES];
  for (int i = 0; i < GERBIL_STAGES; ++i) {
    stages[i] = prod;
    passed[i] = 1;
  }

  /* 1. Uniform matching 8-stage chain with complete 4-way dynamic ABI closure admitted */
  CHECK(admit_gerbil_chain(&prod, stages, passed) == 1, "f11.uniform-seal-admitted");

  /* 2. Single drifted stage header/ABI fingerprint rejected */
  int drift_stage = nondet_int();
  __CPROVER_assume(drift_stage >= 0 && drift_stage < GERBIL_STAGES);
  stages[drift_stage].hdr_fp ^= 1ULL;
  CHECK(admit_gerbil_chain(&prod, stages, passed) == 0, "f11.mixed-abi-stage-rejected");
  stages[drift_stage].hdr_fp = prod.hdr_fp;

  /* 3. Partial stage omission rejected */
  passed[GERBIL_STAGES - 1] = 0;
  CHECK(admit_gerbil_chain(&prod, stages, passed) == 0, "f11.partial-stage-rejected");

  /* 4. Non-SMP capability profile rejected for SMP acceptance */
  passed[GERBIL_STAGES - 1] = 1;
  prod.cap_mask = 3u;
  CHECK(admit_gerbil_chain(&prod, stages, passed) == 0, "f11.non-smp-profile-rejected");
  prod.cap_mask = 7u;

  /* 5. Missing dynamic .o1 export (e.g. ___publish_raw_stack_span bit3) rejected */
  prod.export_mask = 7u;
  for (int i = 0; i < GERBIL_STAGES; ++i)
    stages[i].export_mask = 7u;
  CHECK(admit_gerbil_chain(&prod, stages, passed) == 0, "f11.unexported-dynamic-symbol-rejected");

  return 0;
}
