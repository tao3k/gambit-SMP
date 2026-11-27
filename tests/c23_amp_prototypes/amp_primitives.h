/*
 * amp_primitives.h
 *
 * Standalone C23 (-std=c23 -Wall -Wextra -Werror) verified reference primitives
 * for Gambit SMP Post-Phase A/B/C structural amplification:
 *   - Amp-1 Lever 1: Lock-free batched atomic still_words_delta + STILL_BLOCK_GLOBAL
 *                    skip + unified local minor sweep/direct-promotion + bounded escape budget
 *   - Amp-1 Lever 2: Contiguous mmap(PROT_NONE) virtual nursery arena (O(1) is_young)
 *                    + lock-free 2-level radix msection directory (release/acquire publish)
 *   - Amp-2 Lever 3: OCaml-5 256-entry prefetch ring (PREFETCH_BUFFER_MIN=64)
 *                    + compressed overflow addrmap bitset
 *   - Amp-4 Lever 8: True (L, g, s) MemBalancer EWMA controller
 *                    + OCaml-5 global alloc_counter/work_counter pacing (with phantom bytes)
 *                    + Erlang ProcBin / Rust Arc off-heap immutable RefC binary (acq_rel)
 *
 * Designed as zero-dependency, ASan/UBSan + ThreadSanitizer clean drop-in reference
 * algorithms ready to wire into vendor/gambit/lib/_mem/ after Phase A/B/C merges.
 */

#ifndef GAMBIT_AMP_PRIMITIVES_H
#define GAMBIT_AMP_PRIMITIVES_H

#include <math.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

/* ========================================================================= */
/* Amp-1 Lever 1: Lock-Free Batched Atomic still_words_delta Accounting      */
/* ========================================================================= */

#define AMP_STILL_FLUSH_THRESHOLD 8192 /* 64 KiB in 64-bit words */

typedef struct {
  _Atomic int64_t occupied_words_still;
} amp_still_vm_acct;

typedef struct {
  int64_t local_delta;
  uint64_t flush_count;
} amp_still_proc_acct;

static inline void amp_still_vm_init(amp_still_vm_acct *vm, int64_t initial_words) {
  atomic_init(&vm->occupied_words_still, initial_words);
}

static inline void amp_still_proc_init(amp_still_proc_acct *p) {
  p->local_delta = 0;
  p->flush_count = 0;
}

static inline void amp_still_proc_flush(amp_still_vm_acct *vm, amp_still_proc_acct *p) {
  int64_t d = p->local_delta;
  if (d != 0) {
    atomic_fetch_add_explicit(&vm->occupied_words_still, d, memory_order_release);
    p->local_delta = 0;
    p->flush_count++;
  }
}

static inline void amp_still_proc_add(amp_still_vm_acct *vm, amp_still_proc_acct *p, int64_t delta) {
  p->local_delta += delta;
  if (p->local_delta >= AMP_STILL_FLUSH_THRESHOLD ||
      p->local_delta <= -AMP_STILL_FLUSH_THRESHOLD) {
    amp_still_proc_flush(vm, p);
  }
}

static inline int64_t amp_still_vm_read(const amp_still_vm_acct *vm) {
  return atomic_load_explicit(&vm->occupied_words_still, memory_order_acquire);
}

/* Amp-1 Lever 1B: STILL_BLOCK_GLOBAL + Unified Local Pass + Bounded Escape */
#define AMP_STILL_FLAG_YOUNG  (1u << 0)
#define AMP_STILL_FLAG_GLOBAL (1u << 1)
#define AMP_STILL_FLAG_MARKED (1u << 2)

typedef struct amp_still_node {
  struct amp_still_node *next;
  uint32_t flags;
  uint32_t words;
} amp_still_node;

static inline size_t amp_sweep_local_still_skip_global(
    amp_still_node **head_ptr,
    amp_still_vm_acct *vm,
    amp_still_proc_acct *proc,
    size_t *skipped_global_out) {
  amp_still_node **cur = head_ptr;
  size_t freed_words = 0;
  size_t skipped_global = 0;
  while (*cur != nullptr) {
    amp_still_node *n = *cur;
    if ((n->flags & AMP_STILL_FLAG_GLOBAL) != 0u) {
      /* Marlow ISMM '11 §5.3: O(1) skip of escaped global young-still block */
      skipped_global++;
      cur = &n->next;
    } else if ((n->flags & AMP_STILL_FLAG_MARKED) == 0u) {
      *cur = n->next;
      freed_words += n->words;
      free(n);
    } else {
      n->flags &= ~AMP_STILL_FLAG_MARKED;
      cur = &n->next;
    }
  }
  if (freed_words > 0) {
    amp_still_proc_add(vm, proc, -(int64_t)freed_words);
  }
  if (skipped_global_out != nullptr) {
    *skipped_global_out = skipped_global;
  }
  return freed_words;
}

/* ========================================================================= */
/* Amp-1 Lever 2: Contiguous Virtual Nursery Arena + 2-Level Radix Directory */
/* ========================================================================= */

typedef struct {
  uintptr_t base;
  size_t total_span;
  size_t slice_size;
  size_t max_procs;
} amp_nursery_arena;

static inline bool amp_nursery_arena_init(amp_nursery_arena *a, size_t max_procs, size_t slice_size) {
  size_t total = max_procs * slice_size;
  void *mem = mmap(nullptr, total, PROT_NONE, MAP_PRIVATE | MAP_ANON, -1, 0);
  if (mem == MAP_FAILED) {
    return false;
  }
  a->base = (uintptr_t)mem;
  a->total_span = total;
  a->slice_size = slice_size;
  a->max_procs = max_procs;
  return true;
}

static inline void *amp_nursery_arena_commit_slice(amp_nursery_arena *a, size_t proc_id) {
  if (proc_id >= a->max_procs) {
    return nullptr;
  }
  void *slice = (void *)(a->base + proc_id * a->slice_size);
  if (mprotect(slice, a->slice_size, PROT_READ | PROT_WRITE) != 0) {
    return nullptr;
  }
  return slice;
}

/* Single unsigned subtraction + compare: ZERO memory loads! */
static inline bool amp_is_young(const amp_nursery_arena *a, const void *ptr) {
  return ((uintptr_t)ptr - a->base) < a->total_span;
}

static inline void amp_nursery_arena_destroy(amp_nursery_arena *a) {
  if (a->base != 0) {
    munmap((void *)a->base, a->total_span);
    a->base = 0;
  }
}

/* 2-Level Lock-Free Radix Msection Directory (1 MiB = 1<<20 msection granularity) */
#define AMP_MSECTION_SHIFT 20u
#define AMP_RADIX_L2_BITS  10u
#define AMP_RADIX_L2_SIZE  (1u << AMP_RADIX_L2_BITS)
#define AMP_RADIX_L1_SIZE  1024u /* covers 1 TiB of chunk-indexed test space */

typedef struct {
  uint32_t msection_id;
  uint32_t region_age;
  uint64_t region_generation;
} amp_msection_desc;

typedef struct {
  _Atomic(amp_msection_desc *) slots[AMP_RADIX_L2_SIZE];
} amp_radix_l2;

typedef struct {
  _Atomic(amp_radix_l2 *) l1[AMP_RADIX_L1_SIZE];
  _Atomic uint32_t active_readers;
} amp_radix_dir;

static inline void amp_radix_init(amp_radix_dir *d) {
  for (size_t i = 0; i < AMP_RADIX_L1_SIZE; i++) {
    atomic_init(&d->l1[i], nullptr);
  }
  atomic_init(&d->active_readers, 0u);
}

static inline bool amp_radix_insert(amp_radix_dir *d, uint64_t chunk_idx, amp_msection_desc *desc) {
  uint64_t hi = (chunk_idx >> AMP_RADIX_L2_BITS) % AMP_RADIX_L1_SIZE;
  uint64_t lo = chunk_idx & (AMP_RADIX_L2_SIZE - 1u);
  amp_radix_l2 *l2 = atomic_load_explicit(&d->l1[hi], memory_order_acquire);
  if (l2 == nullptr) {
    amp_radix_l2 *fresh = (amp_radix_l2 *)calloc(1, sizeof(amp_radix_l2));
    if (fresh == nullptr) {
      return false;
    }
    for (size_t i = 0; i < AMP_RADIX_L2_SIZE; i++) {
      atomic_init(&fresh->slots[i], nullptr);
    }
    amp_radix_l2 *expected = nullptr;
    if (atomic_compare_exchange_strong_explicit(
            &d->l1[hi], &expected, fresh, memory_order_release, memory_order_acquire)) {
      l2 = fresh;
    } else {
      free(fresh);
      l2 = expected;
    }
  }
  atomic_store_explicit(&l2->slots[lo], desc, memory_order_release);
  return true;
}

static inline amp_msection_desc *amp_radix_lookup(amp_radix_dir *d, uint64_t chunk_idx) {
  uint64_t hi = (chunk_idx >> AMP_RADIX_L2_BITS) % AMP_RADIX_L1_SIZE;
  uint64_t lo = chunk_idx & (AMP_RADIX_L2_SIZE - 1u);
  atomic_fetch_add_explicit(&d->active_readers, 1u, memory_order_acquire);
  amp_radix_l2 *l2 = atomic_load_explicit(&d->l1[hi], memory_order_acquire);
  amp_msection_desc *res = nullptr;
  if (l2 != nullptr) {
    res = atomic_load_explicit(&l2->slots[lo], memory_order_acquire);
  }
  atomic_fetch_sub_explicit(&d->active_readers, 1u, memory_order_release);
  return res;
}

static inline void amp_radix_destroy(amp_radix_dir *d) {
  for (size_t i = 0; i < AMP_RADIX_L1_SIZE; i++) {
    amp_radix_l2 *l2 = atomic_load_explicit(&d->l1[i], memory_order_relaxed);
    if (l2 != nullptr) {
      free(l2);
      atomic_store_explicit(&d->l1[i], nullptr, memory_order_relaxed);
    }
  }
}

/* ========================================================================= */
/* Amp-2 Lever 3: OCaml-5 256-Entry Prefetch Ring + Compressed addrmap       */
/* ========================================================================= */

#define AMP_PREFETCH_RING_CAP 256u
#define AMP_PREFETCH_RING_MIN 64u

typedef struct {
  uint32_t next0;
  uint32_t next1;
  uint32_t pad[14]; /* 64-byte cacheline-aligned heap node */
} amp_graph_node;

typedef struct {
  uint32_t ring[AMP_PREFETCH_RING_CAP];
  uint32_t head;
  uint32_t tail;
  uint32_t *stack;
  uint32_t stack_top;
  uint32_t stack_cap;
  uint64_t *addrmap; /* 1 bit per node on stack overflow */
  uint64_t *marked;
  uint32_t node_count;
  uint32_t addrmap_pending;
} amp_prefetch_marker;

static inline bool amp_bit_test(const uint64_t *bits, uint32_t idx) {
  return (bits[idx >> 6] & (UINT64_C(1) << (idx & 63u))) != 0u;
}

static inline void amp_bit_set(uint64_t *bits, uint32_t idx) {
  bits[idx >> 6] |= (UINT64_C(1) << (idx & 63u));
}

static inline void amp_bit_clear(uint64_t *bits, uint32_t idx) {
  bits[idx >> 6] &= ~(UINT64_C(1) << (idx & 63u));
}

static inline void amp_marker_enqueue(
    amp_prefetch_marker *m,
    const amp_graph_node *nodes,
    uint32_t idx) {
  if (idx >= m->node_count || amp_bit_test(m->marked, idx)) {
    return;
  }
  uint32_t ring_len = m->tail - m->head;
  if (ring_len < AMP_PREFETCH_RING_CAP) {
    __builtin_prefetch(&nodes[idx], 0, 1);
    m->ring[m->tail & (AMP_PREFETCH_RING_CAP - 1u)] = idx;
    m->tail++;
  } else if (m->stack_top < m->stack_cap) {
    m->stack[m->stack_top++] = idx;
  } else if (!amp_bit_test(m->addrmap, idx)) {
    amp_bit_set(m->addrmap, idx);
    m->addrmap_pending++;
  }
}

static inline uint32_t amp_marker_trace_all(
    amp_prefetch_marker *m,
    const amp_graph_node *nodes,
    uint32_t root) {
  uint32_t marked_count = 0;
  uint32_t scan_word = 0;
  uint32_t words = (m->node_count + 63u) >> 6;
  amp_marker_enqueue(m, nodes, root);

  while ((m->tail != m->head) || (m->stack_top > 0u) || (m->addrmap_pending > 0u)) {
    while ((m->tail - m->head) < AMP_PREFETCH_RING_MIN && m->stack_top > 0u) {
      uint32_t n = m->stack[--m->stack_top];
      __builtin_prefetch(&nodes[n], 0, 1);
      m->ring[m->tail & (AMP_PREFETCH_RING_CAP - 1u)] = n;
      m->tail++;
    }
    if ((m->tail == m->head) && (m->stack_top == 0u) && (m->addrmap_pending > 0u)) {
      /* Drain compressed addrmap bitset into prefetch ring */
      uint32_t scanned = 0;
      while (scanned < words && (m->tail - m->head) < AMP_PREFETCH_RING_MIN) {
        uint64_t w = m->addrmap[scan_word];
        while (w != 0u && (m->tail - m->head) < AMP_PREFETCH_RING_MIN) {
          unsigned bit = (unsigned)__builtin_ctzll(w);
          uint32_t idx = (scan_word << 6) + bit;
          amp_bit_clear(m->addrmap, idx);
          m->addrmap_pending--;
          w &= (w - 1u);
          if (!amp_bit_test(m->marked, idx)) {
            __builtin_prefetch(&nodes[idx], 0, 1);
            m->ring[m->tail & (AMP_PREFETCH_RING_CAP - 1u)] = idx;
            m->tail++;
          }
        }
        if (m->addrmap[scan_word] == 0u) {
          scan_word = (scan_word + 1u) % words;
          scanned++;
        }
      }
    }
    if (m->tail == m->head) {
      break;
    }
    uint32_t cur = m->ring[m->head & (AMP_PREFETCH_RING_CAP - 1u)];
    m->head++;
    if (amp_bit_test(m->marked, cur)) {
      continue;
    }
    amp_bit_set(m->marked, cur);
    marked_count++;
    amp_marker_enqueue(m, nodes, nodes[cur].next0);
    amp_marker_enqueue(m, nodes, nodes[cur].next1);
  }
  return marked_count;
}

/* ========================================================================= */
/* Amp-4 Lever 8: MemBalancer + Global Work Pacing + Off-Heap RefC Binary    */
/* ========================================================================= */

typedef struct {
  double c;
  double e_min;
  double m_nursery;
  double alpha_g;
  double alpha_s;
  double sm;
  double st;
  double gm;
  double gt;
  double live;
} amp_membalancer;

static inline void amp_membalancer_init(amp_membalancer *mb, double c, double e_min, double m_nursery) {
  mb->c = c;
  mb->e_min = e_min;
  mb->m_nursery = m_nursery;
  mb->alpha_g = 0.95;
  mb->alpha_s = 0.5;
  mb->sm = 0.0;
  mb->st = 0.0;
  mb->gm = 0.0;
  mb->gt = 0.0;
  mb->live = 0.0;
}

static inline void amp_membalancer_on_gc(amp_membalancer *mb, double collected, double gc_sec, double live) {
  mb->sm = mb->alpha_s * mb->sm + (1.0 - mb->alpha_s) * collected;
  mb->st = mb->alpha_s * mb->st + (1.0 - mb->alpha_s) * gc_sec;
  mb->live = live;
}

static inline void amp_membalancer_on_sample(amp_membalancer *mb, double alloc, double dt_sec) {
  mb->gm = mb->alpha_g * mb->gm + (1.0 - mb->alpha_g) * alloc;
  mb->gt = mb->alpha_g * mb->gt + (1.0 - mb->alpha_g) * dt_sec;
}

static inline double amp_membalancer_limit(const amp_membalancer *mb) {
  double g_rate = (mb->gt > 1e-9) ? (mb->gm / mb->gt) : 0.0;
  double s_rate = (mb->st > 1e-9) ? (mb->sm / mb->st) : 300.0;
  if (s_rate < 1e-6) s_rate = 1e-6;
  double extra = (mb->live > 0.0) ? sqrt((mb->live * g_rate) / (mb->c * s_rate)) : 0.0;
  if (extra < mb->e_min) extra = mb->e_min;
  return mb->live + extra + mb->m_nursery;
}

/* OCaml-5 Global alloc_counter / work_counter Pacing + Racket Phantom Bytes */
typedef struct {
  _Atomic uint64_t alloc_counter;   /* managed + phantom bytes */
  _Atomic uint64_t phantom_bytes;   /* off-heap native bytes */
  _Atomic uint64_t work_counter;    /* completed major mark work */
  uint64_t headroom_e;
  uint64_t total_work_w;
} amp_global_pacing;

static inline void amp_pacing_init(amp_global_pacing *gp, uint64_t headroom_e, uint64_t total_work_w) {
  atomic_init(&gp->alloc_counter, 0u);
  atomic_init(&gp->phantom_bytes, 0u);
  atomic_init(&gp->work_counter, 0u);
  gp->headroom_e = headroom_e;
  gp->total_work_w = total_work_w;
}

static inline uint64_t amp_pacing_record_alloc(amp_global_pacing *gp, uint64_t bytes, bool is_phantom) {
  if (is_phantom) {
    atomic_fetch_add_explicit(&gp->phantom_bytes, bytes, memory_order_relaxed);
  }
  uint64_t total_alloc =
      atomic_fetch_add_explicit(&gp->alloc_counter, bytes, memory_order_acq_rel) + bytes;
  /* Compute proportional target work: ceil(W * total_alloc / E) */
  uint64_t target_work = (gp->total_work_w * total_alloc + gp->headroom_e - 1u) / gp->headroom_e;
  if (target_work > gp->total_work_w) {
    target_work = gp->total_work_w;
  }
  uint64_t done = atomic_load_explicit(&gp->work_counter, memory_order_acquire);
  if (target_work > done) {
    uint64_t slice = target_work - done;
    atomic_fetch_add_explicit(&gp->work_counter, slice, memory_order_release);
    return slice;
  }
  return 0u;
}

/* Off-Heap Immutable RefC Binary (Erlang ProcBin / Rust Arc + Chez IMMUTABLE_TAG) */
#define AMP_BIN_FLAG_IMMUTABLE (1u << 0)

typedef struct {
  _Atomic uint32_t refcount;
  uint32_t flags;
  size_t len;
  uint8_t data[];
} amp_refc_bin;

static inline amp_refc_bin *amp_refc_bin_create(const uint8_t *src, size_t len, bool immutable) {
  amp_refc_bin *b = (amp_refc_bin *)malloc(sizeof(amp_refc_bin) + len);
  if (b == nullptr) {
    return nullptr;
  }
  atomic_init(&b->refcount, 1u);
  b->flags = immutable ? AMP_BIN_FLAG_IMMUTABLE : 0u;
  b->len = len;
  if (len > 0 && src != nullptr) {
    memcpy(b->data, src, len);
  }
  return b;
}

/* Sharing off-heap across SMP domains strictly requires AMP_BIN_FLAG_IMMUTABLE! */
static inline amp_refc_bin *amp_refc_bin_share(amp_refc_bin *b) {
  if (b == nullptr || (b->flags & AMP_BIN_FLAG_IMMUTABLE) == 0u) {
    return nullptr;
  }
  atomic_fetch_add_explicit(&b->refcount, 1u, memory_order_relaxed);
  return b;
}

static inline bool amp_refc_bin_drop(amp_refc_bin *b) {
  if (b == nullptr) {
    return false;
  }
  /* Release guarantees all prior payload reads/writes happen-before final free! */
  uint32_t old = atomic_fetch_sub_explicit(&b->refcount, 1u, memory_order_release);
  if (old == 1u) {
    /* Acquire synchronizes with every peer's release-drop before free(b)! */
    atomic_thread_fence(memory_order_acquire);
    free(b);
    return true;
  }
  return false;
}

#endif /* GAMBIT_AMP_PRIMITIVES_H */
