/* CBMC bounded model checking harness for adaptive STW drained-fromspace OS page
 * reclamation (configure --enable-gc-fromspace-reclaim=auto|off|N + movable-sections.inc).
 * Verifies exact C pointer arithmetic, overflow resistance, page alignment, strict
 * containment inside the retired source half, zero overlap with header / destination
 * half / trailing metadata, and overflow-free adaptive RAM/LLC/max_heap threshold policy.
 */

#include <assert.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

extern uintptr_t nondet_uintptr(void);
extern size_t nondet_size(void);
extern int nondet_int(void);
extern unsigned nondet_uint(void);
extern bool nondet_bool(void);
extern void __CPROVER_assume(bool);

enum {
  MODEL_WS = 8u,
  MODEL_MSECTION_SIZE = 131072u,
  MODEL_HALF_WORDS = MODEL_MSECTION_SIZE >> 1,
  MODEL_HALF_BYTES = MODEL_HALF_WORDS * MODEL_WS,      /* 524288 = 512 KiB */
  MODEL_HEADER_BYTES = 48u,
  MODEL_META_BYTES = 65536u,
  MODEL_SECTION_BYTES = MODEL_HEADER_BYTES + 2u * MODEL_HALF_BYTES + MODEL_META_BYTES
};

static const size_t MODEL_FLOOR_MIN_BYTES = (size_t)16u * 1024u * 1024u;
static const size_t MODEL_ADAPTIVE_CAP_BYTES = (size_t)128u * 1024u * 1024u;
static const size_t MODEL_FALLBACK_CAP_BYTES = (size_t)64u * 1024u * 1024u;
static const size_t MODEL_MAX_HEAP_FLOOR_BYTES = (size_t)16u * 1024u * 1024u;

typedef struct {
  int valid;
  uintptr_t plo;
  uintptr_t phi;
} reclaim_span;

/* Exact C algorithm implemented in movable-sections.inc:release_drained_source_half */
static reclaim_span compute_reclaim_span(uintptr_t section_addr,
                                         size_t header_bytes,
                                         size_t source_offset_words,
                                         size_t page_size) {
  reclaim_span out = {0, 0, 0};
  if (page_size < 4096u || (page_size & (page_size - 1u)) != 0u)
    return out;
  if (source_offset_words != 0u && source_offset_words != MODEL_HALF_WORDS)
    return out;
  if (section_addr > UINTPTR_MAX - header_bytes)
    return out;
  uintptr_t base = section_addr + header_bytes;
  uintptr_t byte_off = source_offset_words * MODEL_WS;
  if (base > UINTPTR_MAX - byte_off)
    return out;
  uintptr_t lo = base + byte_off;
  if (lo > UINTPTR_MAX - MODEL_HALF_BYTES)
    return out;
  uintptr_t hi = lo + MODEL_HALF_BYTES;
  if (lo > UINTPTR_MAX - (page_size - 1u))
    return out;
  uintptr_t plo = (lo + (page_size - 1u)) & ~(uintptr_t)(page_size - 1u);
  uintptr_t phi = hi & ~(uintptr_t)(page_size - 1u);
  if (plo >= lo && phi <= hi && phi > plo) {
    out.valid = 1;
    out.plo = plo;
    out.phi = phi;
  }
  return out;
}

/* Exact C algorithm implemented in movable-sections.inc:msection_adaptive_reclaim_min_sections */
static size_t compute_adaptive_reclaim_threshold(int configured,
                                                 size_t phys_mem_bytes,
                                                 size_t cpu_count,
                                                 size_t min_heap_bytes,
                                                 size_t max_heap_bytes) {
  if (configured < 0)
    return SIZE_MAX;
  if (configured > 0)
    return (size_t)configured;

  size_t eff_cpus = (cpu_count > 0u) ? cpu_count : 1u;
  size_t cache_floor = (min_heap_bytes <= SIZE_MAX / 4u) ? (min_heap_bytes * 4u) : SIZE_MAX;
  if (cache_floor < MODEL_FLOOR_MIN_BYTES)
    cache_floor = MODEL_FLOOR_MIN_BYTES;

  size_t target_bytes;
  if (phys_mem_bytes > 0u) {
    size_t ram_share = (eff_cpus <= SIZE_MAX / 64u) ? (phys_mem_bytes / (64u * eff_cpus)) : 0u;
    target_bytes = (ram_share > cache_floor) ? ram_share : cache_floor;
    if (target_bytes > MODEL_ADAPTIVE_CAP_BYTES)
      target_bytes = MODEL_ADAPTIVE_CAP_BYTES;
  } else {
    target_bytes = (cache_floor < MODEL_FALLBACK_CAP_BYTES) ? cache_floor : MODEL_FALLBACK_CAP_BYTES;
  }

  if (max_heap_bytes > 0u) {
    size_t cap_share = max_heap_bytes / 4u;
    if (cap_share < MODEL_MAX_HEAP_FLOOR_BYTES)
      cap_share = MODEL_MAX_HEAP_FLOOR_BYTES;
    if (cap_share < target_bytes)
      target_bytes = cap_share;
  }

  size_t min_sec = (target_bytes + (MODEL_HALF_BYTES - 1u)) / MODEL_HALF_BYTES;
  return (min_sec > 0u) ? min_sec : 1u;
}

static bool spans_overlap(uintptr_t a_lo, uintptr_t a_hi,
                          uintptr_t b_lo, uintptr_t b_hi) {
  return a_lo < b_hi && b_lo < a_hi;
}

static bool admit_fromspace_reclaim(bool draining,
                                    bool all_drained,
                                    unsigned source_pins,
                                    bool custom_alloc,
                                    int nb_sections,
                                    int configured,
                                    size_t phys_mem_bytes,
                                    size_t cpu_count,
                                    size_t min_heap_bytes,
                                    size_t max_heap_bytes) {
  size_t thr = compute_adaptive_reclaim_threshold(
      configured, phys_mem_bytes, cpu_count, min_heap_bytes, max_heap_bytes);
  return draining && all_drained && (source_pins == 0u) &&
         !custom_alloc && (nb_sections > 0) && ((size_t)nb_sections >= thr);
}

int main(void) {
  /* 1. Symbolic msection layout with arbitrary non-wrapping address and page size */
  size_t ps_sel = nondet_size();
  __CPROVER_assume(ps_sel <= 2u);
  size_t ps = (ps_sel == 0u) ? 4096u : ((ps_sel == 1u) ? 16384u : 65536u);

  uintptr_t sec_addr = nondet_uintptr();
  __CPROVER_assume((sec_addr & 7u) == 0u);
  __CPROVER_assume(sec_addr <= UINTPTR_MAX - MODEL_SECTION_BYTES - ps);

  size_t dest_off = nondet_bool() ? 0u : MODEL_HALF_WORDS;
  size_t src_off = MODEL_HALF_WORDS - dest_off;

  reclaim_span r = compute_reclaim_span(sec_addr, MODEL_HEADER_BYTES, src_off, ps);
  assert(r.valid == 1);

  uintptr_t base = sec_addr + MODEL_HEADER_BYTES;
  uintptr_t src_lo = base + src_off * MODEL_WS;
  uintptr_t src_hi = src_lo + MODEL_HALF_BYTES;
  uintptr_t dst_lo = base + dest_off * MODEL_WS;
  uintptr_t dst_hi = dst_lo + MODEL_HALF_BYTES;
  uintptr_t meta_lo = base + 2u * MODEL_HALF_BYTES;
  uintptr_t meta_hi = meta_lo + MODEL_META_BYTES;

  assert((r.plo % ps) == 0u);
  assert((r.phi % ps) == 0u);
  assert(((r.phi - r.plo) % ps) == 0u);
  assert(r.plo >= src_lo);
  assert(r.phi <= src_hi);
  assert(r.phi > r.plo);
  assert(!spans_overlap(r.plo, r.phi, sec_addr, base));
  assert(!spans_overlap(r.plo, r.phi, dst_lo, dst_hi));
  assert(!spans_overlap(r.plo, r.phi, meta_lo, meta_hi));
  assert((r.phi - r.plo) >= (MODEL_HALF_BYTES - 2u * ps));

  /* 2. Boundary overflow resistance near UINTPTR_MAX */
  reclaim_span wrap = compute_reclaim_span(UINTPTR_MAX - 1024u, MODEL_HEADER_BYTES, 0u, 16384u);
  assert(wrap.valid == 0);

  /* 3. Concrete multi-machine CPU+RAM adaptive calibration checks */
  const size_t GiB = (size_t)1024u * 1024u * 1024u;
  const size_t MiB = (size_t)1024u * 1024u;
  assert(compute_adaptive_reclaim_threshold(0, 12u * GiB, 12u, 4u * MiB, 0u) == 32u);
  assert(compute_adaptive_reclaim_threshold(0, 32u * GiB, 12u, 4u * MiB, 0u) == 86u);
  assert(compute_adaptive_reclaim_threshold(0, 16u * GiB, 4u, 4u * MiB, 0u) == 128u);
  assert(compute_adaptive_reclaim_threshold(0, 64u * GiB, 16u, 4u * MiB, 0u) == 128u);
  assert(compute_adaptive_reclaim_threshold(0, 256u * GiB, 4u, 8u * MiB, 0u) == 256u);
  assert(compute_adaptive_reclaim_threshold(0, 256u * GiB, 4u, 8u * MiB, 256u * MiB) == 128u);
  assert(compute_adaptive_reclaim_threshold(-1, 32u * GiB, 12u, 4u * MiB, 0u) == SIZE_MAX);
  assert(compute_adaptive_reclaim_threshold(200, 32u * GiB, 12u, 4u * MiB, 0u) == 200u);

  /* Explicit SIZE_MAX overflow-guard checks on cpu_count and min_heap_bytes */
  assert(compute_adaptive_reclaim_threshold(0, 32u * GiB, SIZE_MAX, 4u * MiB, 0u) == 32u);
  assert(compute_adaptive_reclaim_threshold(0, 32u * GiB, 12u, SIZE_MAX, 0u) == 256u);

  /* 4. Full symbolic overflow-freedom & gating across realistic CPU counts & arbitrary RAM/min/max_heap */
  int configured = nondet_int();
  size_t phys_mem = nondet_size();
  size_t cpu_sel = nondet_size();
  __CPROVER_assume(cpu_sel <= 6u);
  size_t cpu_table[7] = { 0u, 1u, 4u, 12u, 16u, 64u, 1024u };
  size_t cpu_count = cpu_table[cpu_sel];
  size_t min_heap = nondet_size();
  size_t max_heap = nondet_size();
  size_t thr = compute_adaptive_reclaim_threshold(configured, phys_mem, cpu_count, min_heap, max_heap);
  if (configured < 0) {
    assert(thr == SIZE_MAX);
  } else if (configured > 0) {
    assert(thr == (size_t)configured);
  } else {
    assert(thr >= (MODEL_MAX_HEAP_FLOOR_BYTES / MODEL_HALF_BYTES));
    assert(thr <= (MODEL_ADAPTIVE_CAP_BYTES / MODEL_HALF_BYTES));
  }

  bool draining = nondet_bool();
  bool all_drained = nondet_bool();
  unsigned pins = nondet_uint();
  bool custom_alloc = nondet_bool();
  int nb_sections = nondet_int();
  bool ok = admit_fromspace_reclaim(draining, all_drained, pins, custom_alloc,
                                    nb_sections, configured, phys_mem, cpu_count,
                                    min_heap, max_heap);
  if (ok) {
    assert(draining && all_drained && pins == 0u && !custom_alloc);
    assert(configured >= 0);
    assert(nb_sections > 0 && (size_t)nb_sections >= thr);
  }
  if (configured < 0 || !draining || !all_drained || pins != 0u || custom_alloc ||
      nb_sections <= 0 || (size_t)nb_sections < thr) {
    assert(!ok);
  }

  return 0;
}
