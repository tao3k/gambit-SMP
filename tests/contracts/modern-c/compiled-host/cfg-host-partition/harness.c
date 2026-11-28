/*
 * CBMC C Contract Harness: Flag-Driven & CFG-Adaptive Contiguous Host Partitioning
 * + Indexed Physical-Host Entry Fixup (`___USES_INDEXED_HOST_ENTRIES`).
 *
 * Models:
 *   - vendor/gambit/include/_gambit/stack_operations.h.in:189-245
 *   - vendor/gambit/lib/setup.c:2140-2165
 *   - vendor/gambit/gsc/_t-c-1.scm:targ-plan-cfg-hosts (cfg-host-limit flag,
 *     compactness-adaptive base target, max-comp domination, O(sqrt(N)) max hosts,
 *     and 4*sum(b_h^2) <= 3*N^2 quadratic cost-benefit acceptance gate)
 */

#include <assert.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __CPROVER__
unsigned int nondet_uint(void);
int nondet_int(void);
bool nondet_bool(void);
void __CPROVER_assume(bool);
#else
static unsigned int nondet_uint(void) { return 0; }
static int nondet_int(void) { return 0; }
static bool nondet_bool(void) { return false; }
static void __CPROVER_assume(bool c) { (void)c; }
#endif

#define NUM_HOSTS 3
#define NUM_LABELS 4
#define ERR_INCOMPAT (-1)
#define NO_ERR 0

typedef struct {
  int host_id;
  uintptr_t hlbl_val;
} label_entry_t;

static const uintptr_t hlbl_host0[3] = { 1, 0x1001u, 0 };
static const uintptr_t hlbl_host1[3] = { 1, 0x2001u, 0 };
static const uintptr_t hlbl_host2[4] = { 2, 0x3001u, 0x3002u, 0 };

static const uintptr_t *query_host_hlbl(int host_id, uintptr_t *ctx_pc) {
  uintptr_t saved_pc = *ctx_pc;
  *ctx_pc = 0;
  const uintptr_t *tbl = NULL;
  if (host_id == 0) tbl = hlbl_host0;
  else if (host_id == 1) tbl = hlbl_host1;
  else if (host_id == 2) tbl = hlbl_host2;
  *ctx_pc = saved_pc;
  return tbl;
}

static int fixup_indexed_module(label_entry_t *lbls, size_t n, uintptr_t *ctx_pc) {
  int current_host = -2;
  const uintptr_t *hlbl_ptr = NULL;
  for (size_t i = 0; i < n; i++) {
    if (lbls[i].host_id != current_host) {
      current_host = lbls[i].host_id;
      if (current_host < 0 || current_host >= NUM_HOSTS) {
        return ERR_INCOMPAT;
      }
      hlbl_ptr = query_host_hlbl(current_host, ctx_pc);
    }
    uintptr_t index = lbls[i].hlbl_val;
    if (hlbl_ptr == NULL || index == 0 || index > hlbl_ptr[0] || hlbl_ptr[index] == 0) {
      return ERR_INCOMPAT;
    }
    lbls[i].hlbl_val = hlbl_ptr[index];
  }
  return NO_ERR;
}

static uintptr_t dispatch_jumpfast(int current_host, const label_entry_t *dest, int *trampoline_used) {
  if (dest->host_id != current_host) {
    *trampoline_used = 1;
    return dest->hlbl_val;
  }
  *trampoline_used = 0;
  return dest->hlbl_val;
}

/* Exact model of gsc/_t-c-1.scm adaptive CFG host target & cost-benefit gate */
static unsigned int adaptive_base_target(int limit, int compactness) {
  if (limit > 0) return (unsigned int)limit;
  int c = (compactness < 0) ? 0 : ((compactness > 9) ? 9 : compactness);
  return (unsigned int)(448 - 32 * c);
}

static unsigned int bounded_isqrt(unsigned int n) {
  if (n < 2u) return n;
  unsigned int lo = 1u, hi = (n < 65535u) ? n : 65535u, ans = 1u;
  for (int iter = 0; iter < 16 && lo <= hi; iter++) {
    unsigned int mid = lo + (hi - lo) / 2u;
    if (mid <= n / mid) {
      ans = mid;
      lo = mid + 1u;
    } else {
      hi = mid - 1u;
    }
  }
  return ans;
}

static unsigned int adaptive_host_target(int limit, int compactness,
                                         unsigned int count) {
  unsigned int base = adaptive_base_target(limit, compactness);
  unsigned int sq = bounded_isqrt(count);
  unsigned int max_hosts = (sq > 2u) ? sq : 2u;
  unsigned int ceil_share = (count + max_hosts - 1u) / max_hosts;
  return (base > ceil_share) ? base : ceil_share;
}

static unsigned int effective_opt_host_limit(unsigned int mod_limit, int host_flag) {
  if (host_flag >= 0) return (unsigned int)host_flag;
  if (mod_limit == 0u) return 0u;
  unsigned int derived = mod_limit / 8u;
  return (derived >= 1u) ? derived : 1u;
}

static bool host_uses_unopt_attrs(unsigned int host_labels, unsigned int mod_labels,
                                  unsigned int mod_limit, int host_flag) {
  bool mod_exceeded = (mod_limit > 0u) && (mod_labels > mod_limit);
  unsigned int hlim = effective_opt_host_limit(mod_limit, host_flag);
  bool host_exceeded = (hlim > 0u) && (host_labels > hlim);
  return mod_exceeded || host_exceeded;
}

static bool cost_benefit_gate(uint64_t sum_sq, uint64_t count) {
  return (4u * sum_sq) <= (3u * count * count);
}

int main(void) {
  /* 1. Positive contract: compiler-emitted 3-host contiguous partition */
  label_entry_t lbls[NUM_LABELS] = {
    { 0, 1 }, { 1, 1 }, { 2, 1 }, { 2, 2 }
  };
  uintptr_t pc = 0xCAFEu;
  int rc = fixup_indexed_module(lbls, NUM_LABELS, &pc);
  assert(rc == NO_ERR);
  assert(pc == 0xCAFEu);
  assert(lbls[0].hlbl_val == 0x1001u);
  assert(lbls[1].hlbl_val == 0x2001u);
  assert(lbls[2].hlbl_val == 0x3001u);
  assert(lbls[3].hlbl_val == 0x3002u);

  /* 2. Observational equivalence of ___JUMPFAST across all (cur_host, dest) pairs */
  unsigned int cur_host = nondet_uint();
  unsigned int dest_idx = nondet_uint();
  if (cur_host < NUM_HOSTS && dest_idx < NUM_LABELS) {
    int tramp = -1;
    uintptr_t landed = dispatch_jumpfast((int)cur_host, &lbls[dest_idx], &tramp);
    assert(landed == lbls[dest_idx].hlbl_val);
    assert(tramp == ((lbls[dest_idx].host_id != (int)cur_host) ? 1 : 0));
  }

  /* 3. Negative contracts on setup.c fixup */
  label_entry_t bad_zero[1] = { { 0, 0 } };
  assert(fixup_indexed_module(bad_zero, 1, &pc) == ERR_INCOMPAT);
  label_entry_t bad_oob[1] = { { 2, 3 } };
  assert(fixup_indexed_module(bad_oob, 1, &pc) == ERR_INCOMPAT);
  label_entry_t bad_host[1] = { { -1, 1 } };
  assert(fixup_indexed_module(bad_host, 1, &pc) == ERR_INCOMPAT);

  unsigned int bad_h = nondet_uint();
  unsigned int bad_s = nondet_uint();
  if (bad_h < NUM_HOSTS && bad_s <= 6) {
    uintptr_t max_c = (bad_h == 2) ? 2u : 1u;
    label_entry_t probe[1] = { { (int)bad_h, (uintptr_t)bad_s } };
    int prc = fixup_indexed_module(probe, 1, &pc);
    if (bad_s == 0 || bad_s > max_c) {
      assert(prc == ERR_INCOMPAT);
    } else {
      assert(prc == NO_ERR);
      assert(probe[0].hlbl_val != 0);
    }
  }

  /* 4. Adaptive CFG target & cost-benefit gate symbolic verification */
  int limit = nondet_int();
  int comp = nondet_int();
  unsigned int count = nondet_uint();
  unsigned int max_comp = nondet_uint();
  __CPROVER_assume(limit >= -1 && limit <= 4096);
  __CPROVER_assume(comp >= -5 && comp <= 15);
  __CPROVER_assume(count >= 4u && count <= 65536u);
  __CPROVER_assume(max_comp >= 1u && max_comp <= count);

  bool forced = nondet_bool();
  bool allowed = forced || (limit != 0);
  if (limit == 0 && !forced) {
    assert(!allowed);
  }
  if (limit < 0) {
    unsigned int base = adaptive_base_target(limit, comp);
    assert(base >= 160u && base <= 448u);
  } else if (limit > 0) {
    assert(adaptive_base_target(limit, comp) == (unsigned int)limit);
  }
  unsigned int tgt = adaptive_host_target(limit, comp, count);
  assert(tgt >= adaptive_base_target(limit, comp));

  /* Oversized component isolation strictly beats sibling amalgamation */
  uint64_t M = (uint64_t)max_comp;
  uint64_t s1 = 160u, s2 = 160u;
  uint64_t iso_sq = M * M + s1 * s1 + s2 * s2;
  uint64_t mrg_sq = (M + s1) * (M + s1) + s2 * s2;
  uint64_t sib_sq = M * M + (s1 + s2) * (s1 + s2);
  assert(iso_sq < mrg_sq);
  assert(iso_sq < sib_sq);

  /* Per-host GCC optimization gate symbolic verification (--enable-optimized-host-limit) */
  unsigned int mod_limit = nondet_uint();
  int host_flag = nondet_int();
  unsigned int mod_labels = nondet_uint();
  unsigned int host_labels = nondet_uint();
  __CPROVER_assume(mod_limit <= 20000u);
  __CPROVER_assume(host_flag >= -1 && host_flag <= 4096);
  __CPROVER_assume(mod_labels <= 30000u);
  __CPROVER_assume(host_labels <= mod_labels);

  unsigned int eff_hlim = effective_opt_host_limit(mod_limit, host_flag);
  if (host_flag == 0) {
    assert(eff_hlim == 0u);
  } else if (host_flag < 0 && mod_limit == 0u) {
    assert(eff_hlim == 0u);
  } else if (host_flag < 0 && mod_limit > 0u) {
    assert(eff_hlim >= 1u && eff_hlim <= mod_limit);
  }
  bool unopt = host_uses_unopt_attrs(host_labels, mod_labels, mod_limit, host_flag);
  if ((mod_limit == 0u || mod_labels <= mod_limit) &&
      (eff_hlim == 0u || host_labels <= eff_hlim)) {
    assert(!unopt);
  }
  if (eff_hlim > 0u && host_labels > eff_hlim) {
    assert(unopt);
  }
  /* Concrete eval~0.c check: mod=5726 <= 6000, monster host=2140 > 750, normal host=160 <= 750 */
  assert(host_uses_unopt_attrs(2140u, 5726u, 6000u, -1));
  assert(!host_uses_unopt_attrs(160u, 5726u, 6000u, -1));
  assert(!host_uses_unopt_attrs(2140u, 5726u, 6000u, 0));

  /* Skewed split (90%/10%) rejected; balanced split (50%/50%) accepted */
  assert(!cost_benefit_gate(90u * 90u + 10u * 10u, 100u));
  assert(cost_benefit_gate(50u * 50u + 50u * 50u, 100u));

  return 0;
}
