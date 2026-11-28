# Mark-Region & Low-Latency GC Lineage: Immix (2008), RC Immix (2013), Deconstructing G1 (2020), LBO (2022), and LXR (2022)

Sources:
- [Blackburn and McKinley (PLDI 2008): *Immix: A Mark-Region Garbage Collector with Space Efficiency, Fast Collection, and Mutator Performance*](https://users.cecs.anu.edu.au/~steveb/pubs/papers/immix-pldi-2008.pdf)
- [Shahriyar, Blackburn, Yang, and McKinley (OOPSLA 2013): *Taking Off the Gloves with Reference Counting Immix*](https://users.cecs.anu.edu.au/~steveb/pubs/papers/rcix-oopsla-2013.pdf)
- [Zhao and Blackburn (VEE 2020): *Deconstructing the Garbage-First Collector*](https://users.cecs.anu.edu.au/~steveb/pubs/papers/g1-vee-2020.pdf)
- [Cai, Blackburn, Bond, and Maas (ISPASS 2022): *Distilling the Real Cost of Production Garbage Collectors*](https://users.cecs.anu.edu.au/~steveb/pubs/papers/lbo-ispass-2022.pdf)
- [Zhao, Blackburn, and McKinley (PLDI 2022): *Low-Latency, High-Throughput Garbage Collection (LXR)*](https://arxiv.org/pdf/2210.17175.pdf)

Reviewed PDF identities: `evidence/papers-modern-gc-architecture.lock.json`, `immix-pldi-2008`, `rc-immix-oopsla-2013`, `zhao-deconstructing-g1-vee-2020`, `lbo-ispass-2022`, and `lxr-pldi-2022`.
These are repository-owned analysis notes, not the papers' full text.

## Protocol Obligations By Paper & Section

### Immix (PLDI 2008): Hierarchical Blocks/Lines, Demand-Driven Overflow, and Opportunistic Defragmentation
- **Two-level region hierarchy (§3.1)**: 32 KiB blocks subdivided into 128 B lines. Mutators bump-allocate sequentially into contiguous runs of unmarked lines ("holes") within recycled blocks, matching semi-space L2 locality while avoiding 2x copy-reserve overhead.
- **Demand-driven overflow allocator (§3.1.1, §5.4 Table 3–4)**: Medium objects that do not fit the current hole in a recycled block are diverted to a dedicated empty overflow block instead of abandoning the recycled block or wasting small holes. Overflow handles ~4% of allocations on average (`jython` 23%, `xalan` 18%) and prevents tight-heap exhaustion.
- **Ablation proof (§5.4 Tables 3–4)**:
  - Block-only reclamation (no line marking) inflates marked volume by **+93%** and more than doubles minimum heap size.
  - Line marking without defragmentation inflates marked volume by **+23%** (+45% average minimum heap, up to +361%).
  - Zero defragmentation headroom increases minimum heap by **+16%**, whereas 2%–2.5% headroom achieves 86% of mark-sweep's minimum heap and **95% defragmentation yield** (87% of evacuated objects tucked into recycled blocks, not clean blocks).
- **Native pinning support (§5.4 Table 3)**: Because Immix is non-moving by default and evacuates opportunistically, pinned objects simply lock their containing block out of evacuation candidacy with negligible mutator penalty.

### RC Immix (OOPSLA 2013): Why Contiguous Line Layout Beats Free Lists
- **Hardware counter proof (§2.1 Tables 1–2)**: Comparing identical collector logic on free-list vs Immix contiguous bump-into-lines shows free-list allocation degrades mutator time by **8.7%–9.3%**, retires **7.1%–9.2%** more instructions (cell-by-cell zeroing vs bulk zeroing), and suffers **26.6%–32.9%** more L1 data cache misses (defeating hardware spatial prefetchers).
- **Per-line live object counts + coalesced deferred RC (§2.2, §3)**: Combining 4-bit saturating RC, allocate-as-dead, lazy mod-buf insertion, and per-line live counts allows prompt line reclamation without free-list fragmentation, while backup tracing resets stuck counts and reclaims cycles.

### Deconstructing G1 (VEE 2020) & LBO Cost Distillation (ISPASS 2022)
- **Barrier decomposition (`zhao-deconstructing-g1-vee-2020` §1, §3.2–3.3)**: G1's SATB pre-barrier adds **5.5%** overhead and its XOR-filtered cross-region remembered-set post-barrier adds **7.7%** (**12.4% combined**), while remembered-set metadata averages only 0.66% of heap.
- **Lower Bound Overhead methodology (`lbo-ispass-2022` §III–IV)**: Distilling out explicit STW costs across multiple collectors yields `MDC` (minimum distilled application cost) and an empirical lower bound `LBO = Total - MDC` on any metric (wall-clock time, CPU cycles, cache misses, energy).
  - Production OpenJDK 17 GCs cost at least **7%–82%** wall-clock time and **6%–92%** CPU cycles at modest heaps.
  - Low-pause concurrent-copying collectors (Shenandoah/ZGC with LVB/Brooks read barriers) pay massive cycle overhead (e.g., `h2`: +110.6% cycles) and frequently exhibit **worse metered application tail latency** than STW collectors once request queuing is accounted for.

### LXR (PLDI 2022): 1.6%-Overhead Unified Write Barrier, SATB-with-Interruptions, and Line Reuse Counter
- **Unified field-logging coalescing barrier (§3.1, §5.3)**: A single 1-bit per-object unlogged flag + field-logging buffer serves *both* coalesced RC and SATB concurrent tracing with **1.6% average overhead** (max 4.6% on `h2o`) and **zero read barrier**.
- **2-bit side-table RC + lazy concurrent decrements (§3.2, §5.4)**: 2-bit saturating RC in a side table beats 4-bit (+2.9% slower) and 8-bit (+3.4% slower). Applying decrements lazily on concurrent threads keeps short pauses bounded.
- **Survival-rate GC trigger & 32-entry lock-free block buffer (§3.5, §5.4)**: Triggering opportunistic compaction by survival rate and using a 32-entry lock-free free-block buffer (128 entries regresses `lusearch` by 12%) minimizes allocator contention.
- **CRITICAL Safety Invariant 1 — SATB-with-Interruptions (§3.3)**: When a short RC pause interrupts an ongoing concurrent SATB trace, **RC MUST NEVER delete an object that is unmarked in the active SATB trace**, even if its reference count drops to zero! Deleting it could drop outgoing pointers to still-live descendants that the concurrent SATB tracer has not yet visited. Such objects are deferred until SATB completion.
- **CRITICAL Safety Invariant 2 — Line Reuse Counter (§3.3)**: Reclaiming and immediately reusing a dead line in a mature block invalidates stale remembered-set entries referencing the previous epoch of that line. Each line carries a bounded reuse epoch counter checked during remset scanning so stale entries never misinterpret freshly allocated objects as old-epoch slots.

## Gambit SMP Correspondence & Source Differences

- Gambit's Phase B/C concurrent SATB old-gen (`docs/modern-gc-architecture-rfc.md`, `big_oldgen_chez_immix.qnt`) already adopts Immix-style line marking and multi-hole recycling inside mature msections, and intentionally rejects LVB/Brooks read barriers — directly validated by `lbo-ispass-2022` and `lxr-pldi-2022`.
- **Three concrete structural gaps amplified by these five papers**:
  1. **Demand-driven overflow mature msection (`immix-pldi-2008 §3.1.1`)**: When promoting medium movable objects into a recycled mature msection whose current line hole is too small, routing overflows to a dedicated clean overflow msection avoids discarding partially filled recycled msections and preserves dense line packing.
  2. **LXR SATB-with-interruptions & line-reuse-counter discipline (`lxr-pldi-2022 §3.3`)**: Whenever Gambit couples concurrent SATB major tracing with *any* eager/prompt reclamation (e.g. local young-still reclamation, future prompt RC reclamation of large buffers, or immediate Immix line reuse between remark and next mark), it MUST enforce: (a) no unmarked object is reclaimed during active SATB, and (b) recycled lines bump a line-reuse epoch before any deferred remset/dirty-card scan reads them.
  3. **LBO benchmarking discipline (`lbo-ispass-2022`)**: Gambit SMP evaluations should report *both* wall-clock time AND total multi-core CPU cycles (not just GC pause percentage) so concurrent GC work or spin-wait overhead is never hidden behind idle cores.

## Formal Model Obligations & Non-Import Boundaries

- **Modeled in `dev/refactoring/modern-c/models/`**:
  - `v2/modern_gc_amplification_v2.qnt` + `ModernGcAmplificationRefinement.lean` + `modern_gc_amplification_pso.c` explicitly verify LXR's **SATB-with-interruptions unmarked-delete prohibition**, **line-reuse-counter stale-remset rejection**, and **Immix demand-driven overflow preservation**.
- **Non-import boundaries**:
  - Do **not** adopt G1's dual SATB + XOR cross-region remset barrier (12.4% overhead) or Shenandoah/ZGC's LVB read barrier (severe LBO cycle tax and C-FFI incompatibility).
  - Do **not** assume LXR's Java 32 KiB block / 256 B line constants are optimal for Gambit's `msection` word geometry without native profiling.
