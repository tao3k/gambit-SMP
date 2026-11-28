# OCaml 5 Memory Model (PLDI 2018) & Effect-Handler Fibers (PLDI 2021)

Sources:
- [Dolan, Sivaramakrishnan, and Madhavapeddy (PLDI 2018): *Bounding Data Races in Space and Time*](https://kcsrk.info/papers/pldi18-memory.pdf)
- [Sivaramakrishnan, Dolan, White, Kelly, Jaffer, and Madhavapeddy (PLDI 2021): *Retrofitting Effect Handlers onto OCaml*](https://arxiv.org/pdf/2104.00250.pdf)

Reviewed PDF identities: `evidence/papers-modern-gc-architecture.lock.json`, `dolan-memory-model-pldi-2018` and `ocaml5-effects-2021`.
Local source cross-reference: `vendor/ocaml/runtime/{memory,fiber}.c` (OCaml 5.5.1).
These are repository-owned analysis notes, not the papers' full text.

## Protocol Obligations By Section

### Dolan et al. (PLDI 2018): Local DRF, Load-Buffering Prohibition, and ARMv8 Compilation
- **Local DRF (§2–4, Theorem 13)**: Unlike C/C++ global DRF (where any data race yields undefined behavior) and Java (where past or future races violate spatial/temporal bounds, §2.1–2.2 Examples 1–3), OCaml's operational frontier model guarantees *all data-race-free parts of a program observe sequential semantics*, even when unrelated code races.
- **Load-buffering ban (§2.2 Example 3, §9.1)**: Preventing future data races from corrupting private initializing reads requires prohibiting `poRW` (load-to-store) reordering on mutable shared locations.
- **Zero-cost initializing stores & immutable loads (§8.1)**: Fresh objects in a thread-local minor heap are initialized with plain stores; a single full fence (`dmb ish` on ARMv8, `sync` on POWER) at minor GC / promotion (and after initializing major-heap large objects) publishes all initializing stores before any remote thread can observe a pointer to them. Immutable loads compile to plain loads.
- **ARMv8 empirical costs (§8.2–8.3, Figure 7)**: On 96-core AArch64, compiling mutable stores as Fence-Before-Store (`FBS`: `dmb ld; str`) costs **0.6% geometric mean** overhead (0% on x86-TSO), beating Branch-After-Load (`BAL`: 2.5%) and Strong Release-Acquire (`SRA`: 85.3%, penalized by float loads/stores lacking `ldar`/`stlr`).
- **OCaml 5.5.1 `memory.c` implementation**: `caml_modify` issues `atomic_thread_fence(memory_order_acquire)` on the delayed-acquire path while `caml_initialize` skips the write barrier on fresh allocations; `caml_atomic_exchange_field` integrates SATB marking with atomic RMW.

### Sivaramakrishnan et al. (PLDI 2021): Segmented Fibers, Red Zones, and Incremental Stack Scanning
- **One-shot heap-allocated fibers (§5.2, Figure 3a)**: Each handled computation runs on an initially small (16-word) malloc-backed fiber cached in a per-domain size-classed `stack_cache` (`vendor/ocaml/runtime/fiber.c:1-260`, 5 size classes). On overflow, the fiber doubles in size by copying; a **16-word red zone** eliminates prologue stack-overflow checks in small leaf functions (keeping OCaml text size growth to 19% vs 30% without a red zone, §6.1 Figure 5).
- **Zero-copy capture & C-stack separation (§5.3–5.4)**: External C calls switch to the OS system stack (`caml_call_c`). Capturing a one-shot continuation unlinks the fiber chain in `O(1)` without copying frames (microbenchmark §6.3: 23 ns alloc+switch, 5 ns perform, 11 ns resume, 7 ns return). Sequential overhead across 54 benchmarks without effects is `< 1%` geometric mean (§6.1 Figure 4).
- **Incremental stack-frame scanning (`vendor/ocaml/runtime/fiber.c:285-293`)**: OCaml 5.5.1 tracks `SCANNING_ONLY_RECENT_FRAMES` via per-frame `Already_scanned` / `Mark_scanned` markers on stack frames. Minor GC stops walking a fiber stack as soon as it hits an already-scanned frame below the return-mutation watermark, reducing stack root scanning from `O(stack depth)` to `O(new frames since last minor GC)`.
- **SATB interaction on fiber switch (`ocaml5-retropar-2020 §8`)**: Because OCaml uses a deletion (SATB) barrier, switching to an unmarked fiber during concurrent major marking must shade the fiber's roots before resuming it (unlike Go's hybrid insertion+deletion barrier).

## Gambit SMP Correspondence & Source Differences

- **Memory model boundary (C23 DRF-0 vs OCaml LDRF)**: Gambit compiles to standard C/C23 (`vendor/gambit/lib/`). Under C23, data races on non-atomic objects remain undefined behavior; Gambit's runtime synchronization therefore enforces strict C23 atomic release/acquire/seq_cst edges (audited under CBMC `--mm pso`) rather than claiming OCaml's racy-program Local DRF semantics for arbitrary unsynchronized Scheme mutations.
- **High-leverage Gambit amplification — Initializing-store barrier elision & incremental stack scanning**:
  1. Gambit's compiler (`gsc`) and runtime (`___ALLOC_SCMOBJ`, constructor paths) can safely elide SATB/generational write barriers on *initializing stores* to freshly allocated young objects, relying on the release fence at promotion / STW / publication (exactly mirroring Dolan §8.1 and `caml_initialize`).
  2. Gambit's segmented continuation stack (`___STILL`/movable stack sections, Feeley 2000) currently rescans all active frames on every minor GC. Adopting OCaml 5.5.1's **incremental stack-frame watermark** (`stack_scanned_watermark` reset whenever control returns across or mutates a frame below the watermark, or when `call/cc` captures/reinstates frames) makes minor GC root scanning `O(new frames)` rather than `O(total depth)` — directly benefiting deep recursive Scheme and Gerbil macro-expansion/compiler stacks!

## Formal Model Obligations & Non-Import Boundaries

- **Modeled in `dev/refactoring/modern-c/models/`**:
  - Incremental stack-frame watermark soundness (proving that mutating a frame slot below the watermark or unwinding past the watermark invalidates it so no young pointer in an older frame is missed by Minor GC) is modeled and mutation-tested in `v2/modern_gc_amplification_v2.qnt`.
- **Non-import boundaries**:
  - Do **not** restrict Gambit's first-class multi-shot `call/cc` to OCaml's one-shot fiber semantics; Gambit must preserve full R5RS/R7RS multi-shot continuations (captured frames become copy-on-mutate / heapified per Feeley 2000).
  - Do **not** assume C23 non-atomic reads/writes enjoy OCaml's Local DRF safety under data races; all cross-processor shared metadata in Gambit C runtime requires explicit C23 atomics and weak-memory verification.
