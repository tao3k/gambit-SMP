/*
 * test_amp_primitives.c
 *
 * Multi-threaded hardware stress & sanitizer harness for amp_primitives.h.
 * Compiled and executed under:
 *   1. clang -std=c23 -O3 -Wall -Wextra -Werror -pthread
 *   2. clang -std=c23 -O1 -g -fsanitize=address,undefined -Wall -Wextra -Werror -pthread
 *   3. clang -std=c23 -O1 -g -fsanitize=thread -Wall -Wextra -Werror -pthread
 */

#include "amp_primitives.h"

#include <assert.h>
#include <pthread.h>
#include <stdio.h>

#define NUM_THREADS 8

/* ========================================================================= */
/* Test 1: 8-Thread Lock-Free Batched still_words_delta + STILL_BLOCK_GLOBAL */
/* ========================================================================= */
typedef struct {
  amp_still_vm_acct *vm;
  int tid;
} still_worker_arg;

static void *still_worker_fn(void *arg) {
  still_worker_arg *a = (still_worker_arg *)arg;
  amp_still_proc_acct proc;
  amp_still_proc_init(&proc);

  /* Build 300 local young-still nodes: 100 global (escaped), 100 live, 100 dead */
  amp_still_node *head = nullptr;
  for (int i = 0; i < 300; i++) {
    amp_still_node *n = (amp_still_node *)malloc(sizeof(amp_still_node));
    assert(n != nullptr);
    n->words = 64u;
    if (i % 3 == 0) {
      n->flags = AMP_STILL_FLAG_YOUNG | AMP_STILL_FLAG_GLOBAL;
    } else if (i % 3 == 1) {
      n->flags = AMP_STILL_FLAG_YOUNG | AMP_STILL_FLAG_MARKED;
    } else {
      n->flags = AMP_STILL_FLAG_YOUNG;
    }
    n->next = head;
    head = n;
    amp_still_proc_add(a->vm, &proc, 64);
  }

  size_t skipped_global = 0;
  size_t freed = amp_sweep_local_still_skip_global(&head, a->vm, &proc, &skipped_global);
  assert(skipped_global == 100u);
  assert(freed == 100u * 64u);

  /* Clean remaining 200 nodes (100 global + 100 live) and flush */
  while (head != nullptr) {
    amp_still_node *next = head->next;
    amp_still_proc_add(a->vm, &proc, -(int64_t)head->words);
    free(head);
    head = next;
  }

  /* High-frequency batched accounting stress: +20,000 words net per thread */
  for (int i = 0; i < 2000; i++) {
    amp_still_proc_add(a->vm, &proc, 20);
    amp_still_proc_add(a->vm, &proc, -10);
  }
  amp_still_proc_flush(a->vm, &proc);
  return nullptr;
}

static void test_amp1_batched_still_and_global_skip(void) {
  amp_still_vm_acct vm;
  amp_still_vm_init(&vm, 0);
  pthread_t th[NUM_THREADS];
  still_worker_arg args[NUM_THREADS];

  for (int i = 0; i < NUM_THREADS; i++) {
    args[i].vm = &vm;
    args[i].tid = i;
    assert(pthread_create(&th[i], nullptr, still_worker_fn, &args[i]) == 0);
  }
  for (int i = 0; i < NUM_THREADS; i++) {
    assert(pthread_join(th[i], nullptr) == 0);
  }
  assert(amp_still_vm_read(&vm) == (int64_t)NUM_THREADS * 20000);
}

/* ========================================================================= */
/* Test 2: Contiguous mmap(PROT_NONE) Nursery Arena + 8-Thread Radix Dir     */
/* ========================================================================= */
typedef struct {
  amp_radix_dir *dir;
  amp_msection_desc *descs;
  int tid;
} radix_worker_arg;

static void *radix_worker_fn(void *arg) {
  radix_worker_arg *a = (radix_worker_arg *)arg;
  for (uint64_t i = 0; i < 128; i++) {
    uint64_t idx = (uint64_t)a->tid * 128u + i;
    a->descs[idx].msection_id = (uint32_t)idx;
    a->descs[idx].region_age = 1u;
    a->descs[idx].region_generation = idx + 100u;
    assert(amp_radix_insert(a->dir, idx, &a->descs[idx]));
  }
  /* Concurrent lookups across own and peer chunks */
  for (uint64_t round = 0; round < 500; round++) {
    uint64_t own_idx = (uint64_t)a->tid * 128u + (round & 127u);
    amp_msection_desc *got = amp_radix_lookup(a->dir, own_idx);
    assert(got != nullptr);
    assert(got->msection_id == (uint32_t)own_idx);
    assert(got->region_generation == own_idx + 100u);

    uint64_t peer_idx = ((uint64_t)((a->tid + 1) % NUM_THREADS)) * 128u + (round & 127u);
    amp_msection_desc *peer = amp_radix_lookup(a->dir, peer_idx);
    if (peer != nullptr) {
      assert(peer->msection_id == (uint32_t)peer_idx);
      assert(peer->region_generation == peer_idx + 100u);
    }
  }
  return nullptr;
}

static void test_amp1_virtual_nursery_and_radix(void) {
  /* Contiguous virtual nursery arena */
  amp_nursery_arena arena;
  assert(amp_nursery_arena_init(&arena, 8u, 65536u));
  uint8_t *s0 = (uint8_t *)amp_nursery_arena_commit_slice(&arena, 0u);
  uint8_t *s7 = (uint8_t *)amp_nursery_arena_commit_slice(&arena, 7u);
  assert(s0 != nullptr && s7 != nullptr);
  s0[0] = 42u;
  s7[65535] = 99u;
  assert(amp_is_young(&arena, &s0[0]));
  assert(amp_is_young(&arena, &s7[65535]));
  int stack_var = 7;
  assert(!amp_is_young(&arena, &stack_var));
  void *heap_var = malloc(64);
  assert(heap_var != nullptr);
  assert(!amp_is_young(&arena, heap_var));
  free(heap_var);
  amp_nursery_arena_destroy(&arena);

  /* 8-thread lock-free 2-level radix directory */
  amp_radix_dir dir;
  amp_radix_init(&dir);
  amp_msection_desc *descs = (amp_msection_desc *)calloc(NUM_THREADS * 128u, sizeof(amp_msection_desc));
  assert(descs != nullptr);

  pthread_t th[NUM_THREADS];
  radix_worker_arg args[NUM_THREADS];
  for (int i = 0; i < NUM_THREADS; i++) {
    args[i].dir = &dir;
    args[i].descs = descs;
    args[i].tid = i;
    assert(pthread_create(&th[i], nullptr, radix_worker_fn, &args[i]) == 0);
  }
  for (int i = 0; i < NUM_THREADS; i++) {
    assert(pthread_join(th[i], nullptr) == 0);
  }
  assert(atomic_load_explicit(&dir.active_readers, memory_order_acquire) == 0u);
  amp_radix_destroy(&dir);
  free(descs);
}

/* ========================================================================= */
/* Test 3: OCaml-5 256-Entry Prefetch Ring + Forced-Overflow addrmap         */
/* ========================================================================= */
static void test_amp2_prefetch_ring_and_addrmap(void) {
  const uint32_t N = 4096u;
  amp_graph_node *nodes = (amp_graph_node *)calloc(N, sizeof(amp_graph_node));
  uint32_t stack[8]; /* Tiny stack cap = 8 forces massive overflow into addrmap! */
  uint32_t words = (N + 63u) >> 6;
  uint64_t *addrmap = (uint64_t *)calloc(words, sizeof(uint64_t));
  uint64_t *marked = (uint64_t *)calloc(words, sizeof(uint64_t));
  assert(nodes != nullptr && addrmap != nullptr && marked != nullptr);

  /* Connected cyclic + stride-13 graph covering all 4096 nodes */
  for (uint32_t i = 0; i < N; i++) {
    nodes[i].next0 = (i + 1u) % N;
    nodes[i].next1 = (i * 13u + 7u) % N;
  }

  amp_prefetch_marker m = {
      .head = 0u,
      .tail = 0u,
      .stack = stack,
      .stack_top = 0u,
      .stack_cap = 8u,
      .addrmap = addrmap,
      .marked = marked,
      .node_count = N,
      .addrmap_pending = 0u,
  };
  uint32_t got = amp_marker_trace_all(&m, nodes, 0u);
  assert(got == N);
  assert(m.addrmap_pending == 0u);
  assert(m.head == m.tail);
  assert(m.stack_top == 0u);

  free(nodes);
  free(addrmap);
  free(marked);
}

/* ========================================================================= */
/* Test 4: Amp-4 MemBalancer + Global Work Pacing + 8-Thread RefC Binary     */
/* ========================================================================= */
typedef struct {
  amp_global_pacing *pacing;
  amp_refc_bin *bin;
  uint64_t expected_sum;
} amp4_worker_arg;

static void *amp4_worker_fn(void *arg) {
  amp4_worker_arg *a = (amp4_worker_arg *)arg;
  /* Concurrent read of immutable off-heap binary payload */
  uint64_t sum = 0;
  for (size_t i = 0; i < a->bin->len; i++) {
    sum += a->bin->data[i];
  }
  assert(sum == a->expected_sum);
  /* Drop shared refcount with release/acquire barrier */
  (void)amp_refc_bin_drop(a->bin);

  /* Concurrent global alloc + phantom bytes pacing */
  for (int i = 0; i < 100; i++) {
    (void)amp_pacing_record_alloc(a->pacing, 1024u, (i % 4 == 0));
  }
  return nullptr;
}

static void test_amp4_membalancer_pacing_and_refc(void) {
  /* MemBalancer idle-to-burst E_min safety */
  amp_membalancer mb;
  amp_membalancer_init(&mb, 0.5, 2.0, 2.0);
  amp_membalancer_on_gc(&mb, 20.0, 0.05, 64.0);
  for (int i = 0; i < 120; i++) {
    amp_membalancer_on_sample(&mb, 0.0, 1.0);
  }
  assert(amp_membalancer_limit(&mb) >= 68.0);

  /* Mutable binary MUST be rejected from off-heap sharing! */
  uint8_t payload[2048];
  uint64_t expected_sum = 0;
  for (size_t i = 0; i < sizeof(payload); i++) {
    payload[i] = (uint8_t)((i * 31u + 7u) & 0xFFu);
    expected_sum += payload[i];
  }
  amp_refc_bin *mut_bin = amp_refc_bin_create(payload, sizeof(payload), false);
  assert(mut_bin != nullptr);
  assert(amp_refc_bin_share(mut_bin) == nullptr);
  assert(amp_refc_bin_drop(mut_bin)); /* final drop frees cleanly */

  /* Immutable off-heap RefC binary shared across 8 concurrent threads + global pacing */
  amp_refc_bin *imm_bin = amp_refc_bin_create(payload, sizeof(payload), true);
  assert(imm_bin != nullptr);

  amp_global_pacing pacing;
  const uint64_t total_alloc_bytes = (uint64_t)NUM_THREADS * 100u * 1024u;
  amp_pacing_init(&pacing, total_alloc_bytes, 4096u);

  pthread_t th[NUM_THREADS];
  amp4_worker_arg args[NUM_THREADS];
  for (int i = 0; i < NUM_THREADS; i++) {
    args[i].pacing = &pacing;
    args[i].bin = amp_refc_bin_share(imm_bin);
    assert(args[i].bin == imm_bin);
    args[i].expected_sum = expected_sum;
    assert(pthread_create(&th[i], nullptr, amp4_worker_fn, &args[i]) == 0);
  }
  /* Drop creator's reference concurrently while 8 workers still read/drop! */
  (void)amp_refc_bin_drop(imm_bin);

  for (int i = 0; i < NUM_THREADS; i++) {
    assert(pthread_join(th[i], nullptr) == 0);
  }

  /* Pacing invariant: hitting headroom E guarantees work_counter >= total_work_w! */
  assert(atomic_load_explicit(&pacing.alloc_counter, memory_order_acquire) == total_alloc_bytes);
  assert(atomic_load_explicit(&pacing.phantom_bytes, memory_order_acquire) == total_alloc_bytes / 4u);
  assert(atomic_load_explicit(&pacing.work_counter, memory_order_acquire) >= 4096u);
}

int main(void) {
  test_amp1_batched_still_and_global_skip();
  test_amp1_virtual_nursery_and_radix();
  test_amp2_prefetch_ring_and_addrmap();
  test_amp4_membalancer_pacing_and_refc();
  puts("C23_AMP_PROTOTYPES_ALL_PASS");
  return 0;
}
