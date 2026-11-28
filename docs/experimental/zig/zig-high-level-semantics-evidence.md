# High-Level Semantic Path: Evidence and Quantitative Boundaries

Date: 2026-10-19. Companion to the
[selected architecture](zig-high-level-semantics-design.md).

This ledger separates direct source observations, literature mechanisms, retained
finite controls, architecture proposals and unmeasured outcomes. Reading sources,
checking document links and rendering D2 diagrams are the only new verification
activities in this research update. No compiler/native benchmark or model is run.

## 1. Source Evidence and Limits

Vendor baseline: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Paths below are relative to `vendor/gambit/`. The
[native-contract provenance](zig-native-contract-design.md#2-source-authority-and-observed-seams)
records the separate runtime overlay; these compiler observations do not admit it
as a working MLIR runtime. Line anchors refer to the baseline bytes below.

| ID | Source anchor | Direct observation | Architectural consequence, not implementation evidence |
| --- | --- | --- | --- |
| S1 | `gsc/_front.scm:225-250` | Parse result and context precede `normalize-program` | Proposed primary hook between `c-intf` and `parsed-program` bindings |
| S2 | `gsc/_ptree2.scm:28-35` | Six normalization calls, including two dead-definition passes | Primary export precedes all six; phase count is not a speedup measurement |
| S3 | `gsc/_ptree2.scm:162-240` | Primitive expansion queries target info and can construct a global-binding identity test | Preserve effective primitive policy and guard obligations; pre-expansion export needs their explicit description |
| S4 | `gsc/_ptree2.scm:481-520` | Lexical mutation becomes unbox/set-box operations; global assignment remains explicit | Preserve cell identity but delay physical boxing |
| S5 | `gsc/_ptree2.scm:1518-1527` | Lambda-lift commentary discusses weakening captures and selected higher-order calls | Late export cannot be assumed to retain original nesting |
| S6 | `gsc/_ptreeadt.scm:116-143` | Procedure fields include ordered parameters, optional defaults, keywords and rest mode | A simple fixed-arity function signature is insufficient |
| S7 | `gsc/_ptree1.scm:616-617` | Effective declaration can require closures even without free variables | Closure identity/generativity is an optimization precondition |
| S8 | `gsc/_front.scm:3923-3990` | Argument order depends on triviality and free-variable heuristics | Define order policy explicitly; parse argument order is not the current scheduling contract |
| S9 | `lib/_thread.scm:4621-4706` | call/cc capture creates a callable continuation wrapper | First-class continuation semantics cannot be replaced by local labels |
| S10 | `lib/_thread.scm:4794-4819,4914-4970` | Dynamic-wind records capture context and unwind/wind paths call after/before procedures | Effects/lifetimes must account for exit and reentry |

| Input | SHA-256, read during this update |
| --- | --- |
| `gsc/_front.scm` | `e05dd9b2370da0e1a7baa3c8b7ea1d212fc3efe23e0e90e8fce3db69119c63de` |
| `gsc/_ptree1.scm` | `1d0f218192d9531d85b5269dd54ba6cd01326446e51e38d538a51eba92b4e2b7` |
| `gsc/_ptree2.scm` | `8dbf9c446430752ce106bc1c650e2eaab5d2f399170ba81677fda76f568b7905` |
| `gsc/_ptreeadt.scm` | `70c9dc143172c3fefbcaf5078a59661ea071b407582545d02e2c557f6e15f8d7` |
| `lib/_thread.scm` | `810f58f679d745826dd18f81f39c84dc3c6e4bb3dd7c6f505a453ca5331e4515` |

These are targeted source reads, not a complete primitive/foreign-form inventory.
The design's coverage specification remains unfinished until that inventory is
written. A byte hash identifies evidence; it does not prove semantic equivalence.

## 2. Primary Literature: What Transfers

### L1. Higher-order Region Analysis

Alexander Aiken, Manuel Fähndrich and Raph Levien,
*Better Static Memory Management: Improving Region-Based Analysis of Higher-Order
Languages*, PLDI 1995 extended abstract.
[Author-hosted PDF](https://www.microsoft.com/en-us/research/wp-content/uploads/1995/06/afl-pldi95.pdf).
Read abstract and introduction, including the two-phase description.

The work combines closure analysis with constraints for allocation/deallocation
placement, relaxing lexical lifetimes. It supports researching call-target and
lifetime analysis together. Its typed applicative setting does not establish
soundness for Gambit's unrestricted control, rebinding, FFI or moving collector.
No memory-reduction figure is transferred to Gambit.

### L2. Checkable Explicit Memory Permissions

Karl Crary, David Walker and Greg Morrisett,
*Typed Memory Management in a Calculus of Capabilities*, POPL 1999 author version.
[Primary PDF](https://www.cs.cornell.edu/talc/papers/capabilities.pdf).
Read abstract and sections 1–1.2.

Static capabilities and alias tracking provide a model for checking permission
to access/free storage with nonlexical lifetimes. This motivates separating
inference from checking the resulting allocation decisions. The paper does not
provide an MLIR verifier, a Scheme continuation contract or a compatible Gambit
region implementation. The proposed allocation verifier remains new work.

### L3. Region Inference Combined with Tracing GC

Martin Elsman, *Garbage-Collection Safety for Region-Based Type-Polymorphic
Programs*, PACMPL 7, PLDI, Article 115, 2023, DOI `10.1145/3591229`.
[Author-hosted PDF](https://elsman.com/mlkit/pdf/gcsafe-pldi23.pdf).
Read abstract and sections 1–2, including Figures 1–2; later proofs and benchmark
tables are not independently audited here.

The paper exhibits a higher-order polymorphic example whose live closure retains
a pointer into a freed region even though the program will not use that field.
A tracing collector can still encounter it. Its revised type/effect treatment
addresses this GC-safety issue. The transferable requirement is to account for
collector-visible edges as well as future program reads. The MLKit result is not
a proof for Gambit's continuations or collector. It supports a conservative hybrid
policy rather than immediate replacement of GC.

### L4. Continuations Through LLVM

Kavon Farvardin and John Reppy, *Compiling with Continuations and LLVM*, EPTCS 285,
2018, pp. 131–142, DOI `10.4204/EPTCS.285.5`.
[Author paper](https://arxiv.org/pdf/1805.08842).
Read sections 2–3.5 and evaluation discussion in section 4.

The PML pipeline separates normalized lambda, CPS, closure conversion and CFG
before LLVM. Its runtime integration explicitly handles tail calls, roots and
preemption. Heap continuations simplify its collector interface; Gambit's physical
stack protocol cannot inherit that property. The historical custom calling
convention and LLVM API limitations are not current API claims. The evaluation
contains workload/hardware-dependent regressions and a known comparator register
allocation defect, so its results supply no Gambit speedup forecast.

### L5. MLIR's Effect Boundary

[Official Side Effects & Speculation rationale](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/),
read 2026-10-19, overview, categorization and modeling sections.

The documented memory/speculation interfaces do not fully model nonlocal control;
the rationale applies to CFG regions. Resource hierarchy is also not a substitute
for detailed alias analysis. The design therefore selects custom control summaries
and an approved-pass policy, rather than claiming ordinary memory-effect annotations
make call/cc safe for generic transformations.

Earlier general MLIR, LLVM, Zig, Polygeist and build-system sources remain in the
[broader bibliography](zig-system-engineering-sources.md). Unavailable full papers
there retain their metadata-only status; this update does not turn them into read
technical evidence.

## 3. Retained Local Controls, Without a New Run

The existing [reader-resumption validation](../reader-resumption-validation.md)
reports the following finite controls:

| Retained result | Count | Relevance to this architecture |
| --- | --- | --- |
| Return-site free counterexample | 5 states | Original return does not prove saved-continuation storage dead |
| Untraced retention counterexample | 6 states | Retained bytes without tracing do not establish GC reachability |
| Imported one-shot consumption counterexample | 7 states | First use does not discharge a supported multi-shot continuation |
| Positive resumption projection | 52 distinct / 88 generated states | Bounded normal/error origins, optional collection/membership growth, two resumptions and discard, under its stated assumptions |

These are document-reported historical observations, not new verifier receipts.
The finite model assumes traced reachability and valid control origin; it does not
prove physical maps, moving-GC relocation, arbitrary FFI reentry or this proposed
region analysis. No native acceptance follows from the counts.

| Read input | SHA-256 |
| --- | --- |
| `docs/experimental/reader-resumption-validation.md` | `12d42f2b20de936eb848b2f03073612c27db1ac5db4700a3d6c26c7a94529d0a` |
| `models/gambit/gc_table_iteration.qnt` | `70f604d64bdb89eb36638db27fab0f4f2b4710b699135c452b5ccf1757208c19` |
| `evidence/scenarios/parallel-gc/runtime-entry-replay.manifest.json` | `f1498d322624ff1d725a75a5bb33c8c761f75c7197267ca8b069bd1396cef3a4` |

The model/manifest digests match the values reported by that document when read.
The report can evolve independently; preserve these identities when citing this
research snapshot. Its stored receipt identities remain in the original report.

## 4. Quantifying Engineering Decoupling

The central potential benefit is reuse across native services and platforms.
The mechanism is visible in [the boundary diagram](engineering-boundary.svg):
language records and runtime descriptors are outside service-private MLIR APIs;
toolchain/process/artifact operations are outside language semantics.

An illustrative relationship-count model compares `m` producer profiles with `n`
service bundles. Duplicated transport/build integration can require `m*n`
relationships; a common contract can reduce that part to `m+n`. With hypothetical
`m=3,n=4`, that is 12 versus 7, five fewer relationships (41.7%). These are invented
scenario counts, not measured LOC, engineering hours or current project inventory.
For `m=1,n=1`, the common layer adds an edge instead of saving one. A shared
contract can be implemented in other languages too; this is not a Zig-only theorem.

The semantic/runtime qualification matrix can still contain `m*n` combinations.
A more honest maintenance model is:

```text
C_direct = sum(pair-specific engineering adaptation) + C_semantics + C_qualification
C_shared = C_contract + sum(producer adapters) + sum(service adapters)
           + C_semantics + C_qualification + C_version_migration
```

The potential reduction is in repeated engineering adaptation. Costs for language
correctness, target/runtime testing and service-version migration remain. Pinning
MLIR in a separate process reduces the blast radius of its C++/C API changes;
it does not remove rebuilding that service or checking its emitted artifacts.

| Benefit/cost dimension | Quantity to record later | Present evidence |
| --- | --- | --- |
| Engineering reuse | Distinct adapter responsibilities, duplicated platform rules, upgrade-touched files/hours | Ownership design only; no measured saving |
| Reproducibility | Cache hit validation, rebuild causes, input closure and invalidation correctness | Required native contract; no new build result |
| Isolation | Service crash/cancellation containment and language-runtime cleanup | Selected process boundary; not fault-tested |
| Semantic opportunity | Reachable function targets, remaining closures/cells/guards, rejection reasons | Source proves information is available earlier; no program census |
| Compile latency | Cold/warm stage times, export size, service RSS/startup and pass time | Historical C-route diagnostic only |
| Execution | Matched wall/CPU time, allocation bytes, peak live/RSS, GC pauses, polls and boundary conversions | No Zig/MLIR comparison |
| Long-term burden | Dialect/verifier changes, supported profiles and upgrade regressions | Explicit work inventory; no schedule/cost estimate |

## 5. Compile-Time and Execution Benefit Models

### 5.1 Historical Cost Is Censored

The [compiler-cost report](../../compiler-cost-boundaries.md) records a corrected
numeric probe: Scheme-to-C completed in **30.818 s**, producing **152,462 C lines**.
C-to-module was killed after **59.250 s**, with whole duration **90.384 s**, DENY;
compiled execution never started. The earlier full campaign remains DENY at
300.316 s. These are retained report observations, not rerun or independently
re-admitted native results.

The 59.250 s phase is right-censored, not a completed compiler time. The report
also says this probe predates the later driver-hash guard. Do not derive a percent
speedup, a completed baseline total, a cache benefit or a maximum achievable gain
by dividing these times. C line count measures emitted volume, not recoverable
high-level optimization or a linear predictor of build time.

For a future matched comparison, account for all selected-path costs:

```text
T_C_path   = parse + normalize + C_emit + C_compile + semantic/platform_link + admission
T_MLIR_path = parse + export + service_start/transport + semantic_passes
              + runtime_lowering + native_codegen + semantic/platform_link + admission
```

Each term must be measured without double-counting. The historical Scheme-to-C
number is a combined stage, not the `parse` term. Zig caching may reduce repeated
construction, but does not remove cold frontend, pass or code-generation cost.
Persistent services amortize startup only if their process/context isolation and
memory-growth rules hold. Cross-process marshalling is an added cost.

### 5.2 Allocation and GC Sensitivity, Not Predictions

Let `A` be baseline allocated bytes, `p` the fraction belonging to eligible sites,
and `r` the fraction of those bytes eliminated. Ignoring new allocations and layout
changes, saved bytes are `A*p*r`. For illustrative `r=0.5`:

| Assumed eligible share `p` | Reduction in total allocated bytes |
| --- | --- |
| 10% | 5% |
| 30% | 15% |
| 60% | 30% |

This is arithmetic over assumptions. Allocation reduction is not the same as peak
memory reduction or proportional GC-time reduction. Regions can retain otherwise
dead objects longer; specialization can increase code size and duplicate constants.

If GC takes fraction `g` of baseline execution and a transformation removes fraction
`q` of that time while other costs are unchanged, speedup is `1/(1-g*q)`.
With assumed `q=0.5`, `g=0.1,0.3,0.5` gives approximately **1.053x, 1.176x, 1.333x**.
These are scenario values, not claims about Gambit. Added per-run overhead fraction
`h` changes the denominator to `1-g*q+h`; the change can lose overall. No evidence
currently supplies `g`, `q`, `h`, `p` or `r` for this architecture.

For extra compilation cost `DeltaC` and verified per-execution saving `DeltaR>0`,
the repeated-use break-even count satisfies `N > DeltaC/DeltaR`. If execution is
slower, amortization cannot rescue it. Whole-workload comparisons must include
Scheme/native transitions, conversion, linking, loading and required validation.

## 6. What Is Concluded

Source evidence selects a concrete earlier export and identifies semantic obligations.
Primary literature supports the relevance of higher-order/control/lifetime analyses
and exposes GC integration traps. Retained finite controls reject specific unsafe
storage policies. Together they justify the proposed research architecture.

They do not establish complete form coverage, a sound implemented optimizer,
Gambit-compatible LLVM objects, safe traced regions, native acceptance or acceleration.
The next design deliverable is the coverage/semantic specification and pass matrix,
not an implementation or minimum prototype. Quantitative claims remain equations,
explicit scenarios or labeled historical observations until matched evidence exists.

## 7. Documentation Verification

All four earlier Zig documents were moved into this directory with relative links
rebased. The experimental index now points here. A local reference check covered
95 file/heading links across the collection and its parent index, with no missing
targets. D2 v0.9.0 rendered all three diagram sources with the dagre layout; SVGs
were rasterized for visual inspection, and the final renders were inspected for
clipping and responsibility labels. No language/runtime test was appropriate to
these documentation and diagram changes.
