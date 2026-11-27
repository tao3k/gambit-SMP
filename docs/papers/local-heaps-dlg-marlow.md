# Processor-Local Heaps & Nursery Isolation: DLG (POPL 1993) & Marlow-Peyton Jones (ISMM 2011)

Sources:
- [Doligez and Leroy (POPL 1993): *A Concurrent, Generational Garbage Collector for a Multithreaded Implementation of ML*](https://xavierleroy.org/publi/concurrent-gc.pdf)
- [Marlow and Peyton Jones (ISMM 2011): *Multicore Garbage Collection with Local Heaps*](https://simonmar.github.io/bib/papers/local-gc.pdf)

Reviewed PDF identities: `evidence/papers-modern-gc-architecture.lock.json`, `dlg-concurrent-ml-popl-1993` and `marlow-local-heaps-ismm-2011`.
Local source cross-reference: `vendor/gambit/lib/_mem/local-nursery.inc` (lines 1–737).
These are repository-owned analysis notes, not the papers' full text.

## Protocol Obligations By Paper & Section

### Doligez & Leroy (POPL 1993): Private Copying Nurseries + Copy-on-Update + Concurrent Mark-Sweep
- **Strict heap-isolation invariant (§3.1–3.2)**: Zero pointers from the shared major heap into any thread-private minor heap, and zero pointers between distinct private minor heaps. Each thread collects its 32 KiB private nursery asynchronously without synchronizing with peer threads.
- **Copy-on-update (§3.2–3.3)**: Storing a private pointer into a shared mutable object recursively copies the transitive closure into the shared heap and installs forwarding pointers in an extra nursery header word. Because ML distinguishes mutable vs immutable types and lacks physical `eq` on immutable values, duplicating immutable objects is semantically transparent — while **all mutable objects must be allocated directly in the shared heap**, causing major-heap free-list contention on mutation-heavy programs (§5 Figure 6: copy-on-update worst case up to 70 ms, parallel compiler free-list lock up to 110 ms).
- **Concurrent 4-color marking without fixed roots (§4.1–4.4, Figures 4–5)**: Because mutators push/pop roots concurrently before shading roots, the write barrier must shade **both** the overwritten old value (Yuasa deletion) and the newly stored value (Dijkstra insertion) — a classic result explaining why Gambit's single-barrier SATB requires a synchronized root-snapshot handshake (initial mark) before concurrent marking begins!

### Marlow & Peyton Jones (ISMM 2011): Quantifying Transitive Globalisation & Hybrid Movable/Sticky Local Heaps
- **Empirical proof against viral transitive promotion (§3.1 Table 1, §6.3.1 Table 6)**:
  - Promoting the full transitive closure on writes to global mutable objects slows sequential execution by **+29.9% geomean** (`spellcheck` +218.8%) and 8-core parallel execution by **+92.6% geomean** (up to **+576.9%** on `transclos` and **+536.7%** on `prsa`!).
  - Promoting only immutable descendants while avoiding mutable promotion eliminates the sequential penalty (`-7.1%` geomean).
- **Hybrid local heap = movable nursery + non-moving sticky heap (§4.4, §5.3)**:
  - Movable objects bump-allocate in the local nursery and are collected by local copying GC.
  - Non-movable/mutable objects without a read barrier allocate in a processor-local **sticky heap** (4 KiB blocks classified after local mark-sweep into `Free` / `Local` / `Global` — explicitly inspired by Immix, §5.3!). Crucially, once a sticky block contains any globalized object, it is marked `Global` and **skipped by future local sweeps** until the next global GC so local GC never re-scans ever-growing immovable regions.
- **Parallel scaling & OS oversubscription robustness (§6.2, §6.2.3)**:
  - Local heaps keep per-core nurseries inside L2 cache (1 MB) to avoid the multicore DRAM "allocation wall", improving 24-core throughput by **+15% average**.
  - Under OS oversubscription (28 HECs on 24 cores — directly analogous to Apple Silicon hybrid 8P+4E cores or noisy CI hosts where slow cores delay STW barriers!), independent local collection improves median throughput by **+73%** over STW parallel minor GC!
- **Explicit honesty on complexity & migration (§6.2.2, §7)**: Thread migration across processors is `O(stack depth)` if local data must be globalized first, and raw throughput gains on dedicated homogeneous cores are modest (+15%) unless combined with low-overhead globalisation policies and a concurrent old generation.

## Gambit SMP Correspondence & Source Differences

Direct audit of `vendor/gambit/lib/_mem/local-nursery.inc` (737 lines) reveals why Gambit's Phase A3 local nursery achieved a 4.3x speedup on `par_alloc_gc_m65536` (`0.1238s -> 0.0290s`, yet still `gc=38.9%`, `4.0x` slower than Rust):
1. **Global mutex inside local young-still sweep (`local-nursery.inc:371-376`)**: `try_local_young_still_gc` acquires the global `ALLOC_MEM_LOCK()` on every local sweep to update `occupied_words_still`, serializing concurrent local GCs across cores!
2. **All-or-nothing escape abort (`local-nursery.inc` `local_young_escaped_ != 0`)**: A single escaped young object disables local collection for that processor until the next global STW — causing high-churn mixed workloads to fall back to global STW minor GC.
3. **Mutually exclusive movable vs young-still local GC + 32 KiB stack scratch double-copy (`local-nursery.inc:430-690`)**: `try_local_movable_nursery_gc` caps survivors at `___LOCAL_MOV_MAX_LIVE = 200`, double-copies survivors via a 4096-word stack scratch buffer (`heap -> scratch -> heap`), and **aborts whenever `young_still_objs_ != 0`**! Thus mixed movable+still workloads (`par_alloc_gc_m65536`, Gerbil compiler) cannot stay local!
4. **Scheme `eq?` vs ML equality**: Unlike DLG's ML (where immutable objects can be duplicated), Scheme exposes `eq?` object identity on pairs/vectors/strings; therefore Gambit must **never** duplicate a still-reachable nursery object without installing a single authoritative address (via promotion + local root rewrite or atomic forwarding).

### Structural Amplification Path For Gambit
- Replace global `ALLOC_MEM_LOCK()` in `try_local_young_still_gc` with lock-free per-processor `still_words_delta` flushed atomically on threshold/STW.
- Unify movable + young-still local minor GC: promote movable survivors directly to mature (or flip into an alternate nursery chunk without 32 KiB stack scratch double-copy and without the 200-object cap) while sweeping dead local young-still blocks in the same pass — adopting Marlow's `Global`-block skip optimization so escaped still blocks are never re-swept locally!
- Replace the binary `local_young_escaped_` abort latch with a bounded per-processor escape-promotion budget (promoting only escaped roots + immutable/bounded closure up to a threshold before falling back to global STW, avoiding Marlow's +92.6% viral transitive promotion pathology).

## Formal Model Obligations & Non-Import Boundaries

- **Modeled in `dev/refactoring/modern-c/models/`**:
  - Unified movable+still local nursery GC with bounded promote-on-share and `Global`-marked sticky-block skipping is verified in `v2/modern_gc_amplification_v2.qnt` (proving zero cross-nursery pointers, zero double-free of escaped still objects, and safe coexistence of local movable+still sweeps).
  - Lock-free per-processor still-word delta accounting vs global memory budget is verified under weak memory in `modern_gc_amplification_pso.c`.
- **Non-import boundaries**:
  - Do **not** import DLG's immutable-object duplication (violates Scheme `eq?` identity) or DLG's "all mutable objects in global heap" rule (violates Gambit's fast young mutable pair/vector allocation).
  - Do **not** import GHC's proxy-indirection read barrier (Haskell already pays thunk-evaluation indirection; Scheme does not).
