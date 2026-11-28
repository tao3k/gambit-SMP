# Chez Scheme / Racket CS (ICFP 2019) & MemBalancer Optimal Heap Limits (OOPSLA 2022)

Sources:
- [Flatt, Derici, Dybvig, Keep, Massaccesi, Spall, Tobin-Hochstadt, and Zeppieri (ICFP 2019): *Rebuilding Racket on Chez Scheme (Experience Report)*](https://www.cs.utah.edu/plt/publications/icfp19-fddkmstz.pdf)
- [Kirisame, Shenoy, and Panchekha (OOPSLA 2022): *Optimal Heap Limits for Reducing Browser Memory Use (MemBalancer)*](https://arxiv.org/pdf/2204.10455.pdf)

Reviewed PDF identities: `evidence/papers-modern-gc-architecture.lock.json`, `racket-chez-icfp-2019` and `membalancer-oopsla-2022`.
Local source cross-reference: `vendor/chez/c/{segment.c,segment.h,gc.c}` (Chez Scheme 10.0) and `vendor/erlang-otp/erts/emulator/beam/erl_gc.c` (Erlang/OTP 28).
These are repository-owned analysis notes, not the papers' full text.

## Citation Provenance Correction

- `docs/modern-gc-architecture-rfc.md` (line 5) cites `"Chez Scheme Parallel GC (Keep & Flatt, ICFP 2024)"`. Primary literature audit confirms that the published Racket-on-Chez architecture experience report is **Flatt, Derici, Dybvig, Keep et al. (ICFP 2019)** (`racket-chez-icfp-2019`), while the parallel collector implementation (`ENABLE_PARALLEL`, creator-owned `SEGMENT_IS_LOCAL`, `send_remote_sweep_stack`) resides directly in the **Chez Scheme 10.0 (2024) source tree** (`vendor/chez/c/gc.c`, `vendor/chez/c/segment.c`). Future documentation updates should cite both the ICFP 2019 paper and the exact `vendor/chez/c/` source anchors separately.

## Protocol Obligations By Paper & Vendor Source

### Racket on Chez Scheme (ICFP 2019) + Chez Scheme 10.0 Source Audit
- **Memory management extensions (`racket-chez-icfp-2019` §4.3, §4.6–4.7)**:
  - **Mutability tag bit (§4.3)**: Storing immutability in the type tag of strings, byte strings, and vectors allows identical read accessors with near-zero cost while enabling safe sharing / write-barrier elimination on immutable aggregates.
  - **Phantom byte strings (§4.6)**: Associate off-heap C-allocated resources with tiny Scheme handles so GC pacing accounts for external memory pressure (analogous to OCaml 5.5.1's `caml_alloc_dependent_memory` / `caml_adjust_gc_speed`).
  - **Non-quadratic ephemerons & ordered/unordered guardians (§4.6)**: Unordered guardians are default; ordered guardians prevent premature finalization of foreign-backed objects still reachable from another finalizer.
  - **Foreign-thread activation & CAS (§4.7)**: Explicit thread activation for C callbacks plus lock-free CAS primitives.
- **Chez Scheme 10.0 parallel GC (`vendor/chez/c/segment.h:29-38`, `gc.c:37, 855, 1949`)**:
  1. **O(1) radix `SegInfo(i)` table (`segment.h:29-38`)**: Multi-level radix page table (`segment_t3 -> segment_t2 -> segment_t1`) maps any heap pointer to its `seginfo` descriptor in `O(1)` shifts/loads — completely eliminating `O(log M)` binary searches!
  2. **Creator-owned parallel sweep routing (`gc.c`)**: Segments carry `SEGMENT_IS_LOCAL` ownership; remote targets are batched via `send_remote_sweep_stack` rather than contested atomic mark-bit writes.
  3. **Static / immortal generation (`gc.c:37, 855, 1949` `static_generation`)**: Permanently live compiler/runtime boot structures are promoted into `static_generation` and **never re-traced** by ordinary major collections unless explicitly dirty-marked!
- **Erlang/OTP 28 off-heap binaries (`vendor/erlang-otp/erts/emulator/beam/erl_gc.c`)**: Large immutable byte binaries (`> 64` bytes) are stored as off-heap reference-counted `ProcBin` nodes (`erl_off_heap_header`), enabling zero-copy cross-actor sharing without inflating per-process GC scanning, paired with immediate heap shrinking (`shrink_new_heap` when `4 * need_after < HEAP_SIZE`).

### MemBalancer (OOPSLA 2022): Compositional Square-Root Heap Limit Theory
- **Non-compositionality of proportional limits (§4, Eq. 1–2)**: Under steady allocation rate `g`, live set `L`, GC throughput `s`, and heap limit `M`, GC fraction is `ratio = (L * g) / (s * (M - L))`. Minimizing total GC fraction across multiple heaps (or multiple phases of one heap over time!) subject to a total memory budget requires equal marginal exchange rates `-d(ratio)/dM = (L * g) / (s * (M - L)^2) = c` across all heaps.
  - Proportional rules (`M = (1 + alpha) * L`) violate compositionality because `c = g / (s * alpha^2 * L)` varies inversely with `L` — giving too much headroom to huge heaps and starving small heaps!
  - The unique compositional optimum is the **square-root rule**:
    `M = L + sqrt((L * g) / (c * s))`
    which coordinates multiple independent processes/heaps **with zero inter-process communication**.
- **Practical EWMA implementation (§5–6, Figure 4)**:
  - Track smoothed allocation rate `g* = g_m* / g_t*` with EWMA `alpha_g = 0.95` (13s half-life) and smoothed GC speed `s* = s_m* / s_t*` with `alpha_s = 0.5` (updating numerator and denominator separately).
  - Add minimum headroom `E_min` (2 MB in V8) plus nursery size `M_nursery` so idle-to-burst transitions never OOM before `g*` ramps up.
  - Because `g*` decays exponentially during idle periods, MemBalancer automatically shrinks idle heaps and supersedes ad-hoc idle memory reducers!
- **Empirical validation (§7, §7.4)**:
  - On ACDC-JS (4 threads), MemBalancer cuts GC time by **30.0%** at equal memory or cuts average heap by **8.2%** at equal GC time.
  - On multi-tab Chromium (2–3 tabs), MemBalancer cuts GC time by **48%–49%** or average heap by **16.0%**.
  - **Racket 8.5 deployment (§7.4)**: Matthew Flatt deployed the simplified `M = L + c * sqrt(L)` rule in mainline Racket 8.5, cutting batch build memory by **10%** for only 1–2% CPU change (noting larger gains are expected for multi-process/multi-threaded builds — exactly matching parallel `gsc` / Gerbil compilation!).

## Gambit SMP Correspondence & Source Differences

- Gambit's current adaptive live-percent ramp (`50% -> 80%`) and `O(sqrt(P))` processor headroom approximate only the sublinear `L` dependence while ignoring `g` (allocation rate) and `s` (GC sweep/mark speed).
- **Three concrete structural amplifications for Gambit + Gerbil**:
  1. **O(1) radix/aligned msection metadata lookup**: Replace `find_msection()` binary search in Gambit's write barrier and concurrent major mark loop with a Chez-style O(1) radix directory (or power-of-2 aligned `msection` header masking), removing `O(log M)` branchy searches from every mature pointer edge.
  2. **Chez-style `static_generation` / immortal cohort for `gsc` & Gerbil boot/expander tables**: Promoting boot/macro/module-registry structures into an immortal generation skips re-marking megabytes of static compiler metadata on every major cycle.
  3. **True `(L, g, s)` MemBalancer limit controller**: Computing `M = L + max(E_min, sqrt(L * g* / (c * s*))) + M_nursery` per Gambit VM process automatically balances memory across 8 parallel `gsc`/Gerbil build processes without inter-process coordination AND gracefully shrinks idle VMs.

## Formal Model Obligations & Non-Import Boundaries

- **Modeled in `dev/refactoring/modern-c/models/`**:
  - `ModernGcAmplificationRefinement.lean` proves unbounded algebraic properties of the MemBalancer square-root rule (strict monotonicity in `L` and `g`, anti-monotonicity in `s` and `c`, sublinear headroom ratio `(M - L)/L -> 0` as `L` grows, and two-heap Cauchy-Schwarz / Lagrange optimality over equal-ratio proportional rules!).
- **Non-import boundaries**:
  - Do **not** spawn an extra background OS heartbeat thread per Gambit VM if Gambit's existing timer/allocation-check polling already wakes periodically; sample `g_m, g_t` at safepoints/minor-GCs and idle wakeup hooks instead.
  - Do **not** import Erlang's per-process isolated copying heaps into Gambit's shared-memory Scheme heap; only the off-heap ref-counted immutable binary representation (`u8vector` / immutable string backing buffer) is applicable behind an explicit immutability tag.
