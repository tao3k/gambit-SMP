# Retrofitting Parallelism onto OCaml (ICFP 2020) & OCaml 5.5.1 Runtime Audit

Source: [Sivaramakrishnan, Dolan, White, Jaffer, Kelly, Sahoo, Parimala, Dhiman, and Madhavapeddy](https://arxiv.org/pdf/2004.11663.pdf).
Reviewed PDF identity: `evidence/papers-modern-gc-architecture.lock.json`, `ocaml5-retropar-2020`.
Local source cross-reference: `vendor/ocaml/runtime/{shared_heap,major_gc,minor_gc,domain,memory}.c` and `vendor/ocaml/runtime/caml/{address_class,sizeclasses,minor_gc}.h` (OCaml 5.5.1).
These are repository-owned analysis notes, not the paper's full text.

## Protocol Obligations By Section

### Sections 3–4: Memory Architecture, ParMinor vs ConcMinor, and Virtual Address Partitioning
- OCaml 5 reserves a single contiguous virtual address range (`caml_minor_heaps_base .. caml_minor_heaps_end`) subdivided into per-domain minor arenas (`caml/address_class.h:55`). Testing `Is_young(v)` compiles to two pointer comparisons with zero heap metadata lookups.
- **ParMinor vs ConcMinor (§4.2–4.3, §6.2)**: The paper implements and evaluates *both* a stop-the-world parallel minor collector (`ParMinor`, adopted by OCaml 5.x) and an independent concurrent minor collector (`ConcMinor` using OS virtual-memory traps on cross-domain minor reads plus youngest-5% partial promote-on-share).
  - On 24 domains (`Table 1`, `Figure 11`), `ParMinor` scales linearly on channel-intensive workloads (`floyd_warshall`, `game_of_life`, `spectralnorm2`) because workers read shared tasks directly without promotion faults. `ConcMinor` stalls workers behind master-domain promotion interrupts and increases major allocations (`test_decompress`: 5,157 MB vs 3,693 MB).
  - Conversely, `ParMinor` performs more minor collections when one fast domain fills its fixed slice early (`minilight`: 210,146 vs 116,433 minor GCs). Section 6.2 explicitly notes this is addressable by allocating large pages dynamically from a shared contiguous minor region.
- **Lock-free parallel promotion (`minor_gc.c:130-195`)**: Promotion claims young objects via a 3-state CAS protocol on the header word (`original_hd -> In_progress_update_val -> forwarding_ptr`), with contenders spinning in `spin_on_header` until the winner publishes the destination pointer.

### Section 5 & Appendix A: Mostly-Concurrent VCGC Major Heap, Size-Segmented Pools, and Termination
- **Size-segmented non-moving major heap (`shared_heap.c`, `caml/sizeclasses.h`)**: Small objects (`<= 128` words) allocate in 32 size classes from 4096-word (32 KiB) domain-owned pools (`avail_pools`, `full_pools`, `unswept_avail_pools`, `unswept_full_pools`). Orphan pools from exited domains are adopted without global locks (`caml_orphan_pool_adopt`). Compared to next-fit free lists (`Section 6.1.1`), size-segmented pools cut peak heap memory by 54%–61% on average (`menhir.ocamly`: 5.3 GB -> 3.3 GB).
- **VCGC 3-state color rotation (`Appendix A`, `cycleHeap`)**: Colors rotate atomically at cycle end (`MARKED -> UNMARKED -> GARBAGE -> MARKED`, keeping `NOT_MARKABLE` for free slots), eliminating any stop-the-world bitmap-clear pass over the live heap.
- **Bounded-work SATB deletion barrier (`major_gc.c`, `memory.c:210-310`)**: `caml_modify` executes a deletion barrier (shading overwritten old pointers during marking) with `atomic_thread_fence(memory_order_acquire)` for delayed-acquire ordering, while `caml_initialize` elides the SATB check on fresh initializing writes.
- **Ephemeron and finaliser termination (`Appendix A`)**: Global termination uses atomic `gNumDomsToMark`, monotonic `gEpheRound`, and per-phase `gPhase` (`MARK -> MARK_FINAL -> SWEEP_EPHE -> cycleHeap`) rather than empty-queue polling.

### OCaml 5.5.1 Runtime Amplifications Beyond the 2020 Paper
Direct audit of `vendor/ocaml/runtime/` reveals four production engineering amplifiers absent from the ICFP 2020 text:
1. **256-entry software prefetch ring (`major_gc.c:159-236, 1423-1549`)**: Marking decouples popping from scanning through a ring buffer (`PREFETCH_BUFFER_MIN = 64`), issuing `prefetch_block` on both the header and field 3 (`&Field(v, 3)`) 64 objects ahead to hide 60–100 ns DRAM pointer-chasing stalls.
2. **Compressed `addrmap` overflow mark stack (`major_gc.c:mark_stack_prune`)**: When the mark stack overflows, OCaml compresses pending ranges into a compact address-map bitset instead of unbounded queue growth.
3. **Opportunistic major work during STW entry spin (`domain.c:1814-1930`)**: `caml_try_run_on_all_domains_with_spin_work` invokes `enter_spin_callback`, letting fast cores waiting for stragglers perform bounded `caml_opportunistic_major_collection_slice` mark/sweep work instead of burning pure spin cycles.
4. **Allocation-proportional global pacing (`major_gc.c:862-1057`) + 4-phase parallel pool compaction (`shared_heap.c:caml_compact_heap`)**: Global `alloc_counter` and `work_counter` pace concurrent major work smoothly across all domains; explicit compaction evacuates sparse pools in parallel without global stop-everything defragmentation during ordinary cycles.

## Gambit SMP Correspondence & Source Differences

- Gambit's current baseline (`vendor/gambit/lib/_mem/`) uses a generational movable nursery + young-still objects + concurrent SATB major GC over Immix-style mature msections (`docs/modern-gc-architecture-rfc.md`).
- **Key difference 1 (Address classification)**: Gambit classifies young vs mature and resolves msection metadata via `find_msection()` / `___gc_find_msection_cached` binary searches over `ms->sections[]` instead of OCaml 5's contiguous virtual nursery range (`Is_young` = 2 pointer compares).
- **Key difference 2 (Mature heap layout)**: Gambit's mature msections use Immix bump-pointer line recycling rather than OCaml's 32-class fixed-slot pools; this preserves contiguous mutator locality (cf. `immix-pldi-2008`, `rc-immix-oopsla-2013`), so Gambit should adopt OCaml's *prefetch ring*, *addrmap mark-stack compression*, *opportunistic STW-spin major slices*, and *virtual nursery range* WITHOUT replacing Immix line allocation with fixed-size free-list pools.
- **Key difference 3 (FFI & backup threads)**: OCaml 5 uses a dedicated `backup_thread_func` (`domain.c:1050-1260`) to service STW barriers while a domain is inside `caml_enter_blocking_section`. Gambit handles parked OS threads via its processor sleep/wakeup handshake; any opportunistic STW-spin work must respect Gambit's processor-state transitions and never mutate phase flags before all active processors enter STW.

## Formal Model Obligations & Non-Import Boundaries

- **Modeled in `dev/refactoring/modern-c/models/`**:
  - Opportunistic major slice execution during STW entry spin is formally verified in `v2/modern_gc_amplification_v2.qnt`, `ModernGcAmplificationRefinement.lean`, and `modern_gc_amplification_pso.c` (verifying acquire/release phase-fence safety and zero race with STW color/phase flip).
  - Contiguous virtual nursery range disjointness is proven in `ModernGcAmplificationRefinement.lean`.
- **Non-import boundaries**:
  - Do **not** import OCaml's `ConcMinor` virtual-memory fault read barrier into Gambit C/FFI paths (incompatible with Gambit's unbarriered C-interface pointers and `___STILL` pinning).
  - Do **not** replace Gambit's Immix contiguous mature allocator with OCaml's size-segmented free-list pools (free lists trade away Immix's sequential cache locality and bulk zeroing).
  - No OCaml benchmark speedup is claimed for Gambit without native Gambit SMP measurements.
