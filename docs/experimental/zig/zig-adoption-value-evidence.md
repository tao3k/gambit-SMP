# Evidence for the Long-Term Adoption Questions

Reviewed: 2026-10-20. Research checkout HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; vendor Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Exact local source bytes, including
working-copy changes, are bound by the registered research view. HEAD alone is
not working-copy identity. No compiler, collector or toolchain probe was run.

## 1. Local Evidence and What It Does Not Establish

| ID | Reviewed source / scope | Finding and limit |
| --- | --- | --- |
| VE01 | [target interface](../../../vendor/gambit/gsc/_back.scm), lines 17-145 | Representation, GVM translation, primitives, label/jump locations, frame and C-interface responsibilities are explicit target partners. Presence is not a complete serialization specification. |
| VE02 | [frontend](../../../vendor/gambit/gsc/_front.scm), 225-250; [C target](../../../vendor/gambit/gsc/_t-c-1.scm), 240-261 | Target/context selection precedes normalization; C target installs dump/link/primitive/frame/result functions. A target-free export cannot simply ignore this negotiation. |
| VE03 | [C scanner](../../../vendor/gambit/gsc/_t-c-2.scm), 345-448, 825-905; [completion inventory](semantic-completion-operations.md), OP03-OP13 | Reserve accounting, checks, private internal return points and dirty-live materialization are intertwined with C emission. Moving the language alone does not extract them. |
| VE04 | [CPU packaging](../../../vendor/gambit/gsc/_t-cpu.scm), 142-180 | Native bytes/fixups are currently packaged by compiling a generated Scheme expression through the C target. This identifies a removable dependency only after replacement module/lifetime contracts exist. |
| VE05 | [C scanner](../../../vendor/gambit/gsc/_t-c-2.scm), 123-237; [header](../../../vendor/gambit/include/gambit.h.in), 10040-10061, 10326-10374; [kernel](../../../vendor/gambit/lib/_kernel.scm), 150-218, 1019-1071; [C interface](../../../vendor/gambit/lib/c_intf.c), 6511-6570 | Foreign frames, conversion and nonlocal control span layers. See exact role scopes in the source-bound SC06/SC07/SC13 records; these are selected families, not an exhaustive CFFI denominator. |
| VE06 | [header](../../../vendor/gambit/include/gambit.h.in), 2956-2969 | MOVABLE0/1/2, forwarding, still and permanent tags exist. Tags do not determine effective collector policy, current profile flags or native correctness. |
| VE07 | [memory runtime](../../../vendor/gambit/lib/mem.c), 3270-3305, 6661-6755 | Parallel chunk publication has ordering requirements; configured traversal has processor/worker/steal logic. Not evidence that all VM configurations are qualified or that moving code into Zig changes the algorithm. |
| VE08 | [anchor/root/helper contracts](completion-admission-evidence.md), AR01-AR14; [reserve/helper design](allocation-reserve-helper-contract.md) | Root materialization, stack rebase, collective GC, callbacks and nonlocal exits remain runtime obligations. Conditional reserve arithmetic is not native sufficiency. |
| VE09 | [native request migration](native-request-configuration-migration.md), M1-M12; [HostGraph retirement](hostgraph-retirement-plan.md), H01-H10 | Source-bound replacement inventories and independent conditions exist. Documentation does not retire callers or establish effective toolchain support. |
| VE10 | [Darwin boundary](darwin-first-compile-boundary.md), sections 1-3 and linked historical patch receipts; [constructor state](interface-construction-operations-and-state.md) | First-log ceiling differs from a sleep; consumer C compilation occurs later; construction programs and live lexical/phase instances differ. Historical receipt observations are not current-head timings or a new reread of every historical source. |
| VE11 | [benefit ledger](zig-modernization-benefit-ledger.md), Q01-Q18 and attribution rules | B0/B1/Z1, removable-work measures and recurring-cost accounting are specified. There are no comparative B1/Z1 measurements or horizon/budget inputs here. |

## 2. Primary Literature / Platform Reading Notes

These are reviewed local reading notes. Their local SHA binds this note, not
remote paper/site bytes. Access date is 2026-10-20; rolling upstream pages have
no pinned commit here. They cannot witness native ABI, semantic or measured-cost
requirements. Findings and repository-specific inferences are separated below.

### PE01 — Gambit's Original Retargeting Principle

[Feeley and Miller, A Parallel Virtual Machine for Efficient Scheme Compilation
(1990)](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf),
pages 1-4, sections 1, 2, 2.3-2.5, read as extracted PDF text. PVM communicates
target details bidirectionally and lets the frontend reason with logical
objects/slots. Its closure and calling discussion places optimization and
machine responsibility across a deliberate boundary. This historical design
supports investigating a richer contract. It does not specify today's Gambit
representation, qualify Darwin or select Zig. Our inference is that modernizing
the contract can preserve the design intent without preserving its old emitter.

### PE02 — Zig's C and Native-Memory Mechanisms

[Zig 0.15.1 documentation](https://ziglang.org/documentation/0.15.1/), sections
Memory, C Translation / Translation failures and C Macros, read in HTML.
Allocation is explicit by convention; no managed collector is supplied for
Scheme. Translation can demote unsupported constructs, including goto,
bitfields and token-pasting macro cases. This supports native adapters and
explicit resources, not transparent translation of Gambit's macro backend.
Our inference: generated typed interfaces may fit Zig well, while rooting,
ownership and nonlocal cleanup still need a Gambit-specific contract. The
release is a versioned reference, not an assertion that it is installed or is
the project's selected supported version.

### PE03 — Versioned Evidence Against Automatic Toolchain Gains

[Zig 0.16.0 release notes](https://ziglang.org/download/0.16.0/release-notes.html),
sections @cImport Moving to Build System, Incremental Compilation, aarch64
Backend and LLVM 21, read in HTML. C-import API evolution is explicit. Incremental
LLVM support accelerates bitcode construction but excludes LLVM Emit Object;
incremental mode retains known bugs and is disabled by default in that release.
The notes describe the self-hosted aarch64 backend as work in progress, and an
LLVM regression workaround disabling loop vectorization. These release-specific
facts disallow transferring generic incremental/x86 claims to Gambit Darwin C
compilation. They do not prove Zig unsuitable, describe every later release, or
establish behavior of any installed binary. Our inference is to price upgrade
and regression work and separate compiler, provider and target identities.

### PE04 — MLIR Service Entry and Stability

[Official MLIR C API](https://mlir.llvm.org/docs/CAPI/), Design and Ownership,
read in HTML. The API favors simple C-interoperable wrappers and explicit
ownership; it expressly offers no stability guarantee. Our inference is to
bound a versioned service adapter and its ownership surface. C access neither
requires Zig nor proves complete support for every dialect/pass interface.
Generated/C++ dialect services may remain necessary.

### PE05 — Effect Infrastructure Has a Semantic Boundary

[Official MLIR Side Effects & Speculation](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/),
Overview and Modeling, read in HTML. Memory effects and speculation interfaces
provide reusable machinery. The document explicitly leaves full nonlocal-control
modeling incomplete. Our inference: Gambit continuation/exception/reentry rules
must restrict pass legality; “has an effect interface” is insufficient admission.
This note does not qualify a particular version or implementation of a pass.

### PE06 — Functional LLVM Integration Requires Runtime Design

[Farvardin and Reppy, Compiling with Continuations and LLVM,
version 2](https://arxiv.org/html/1805.08842v2), sections 2.1-2.3 and 3.2-3.5,
read in HTML. The PML/Manticore design introduces explicit CFG allocation checks
and runtime conventions, and addresses guaranteed tails and continuation/GC
interaction. It demonstrates a concrete functional-language integration route,
not an automatically compatible runtime model. Its historical API/LLVM-version
limitations must not be repeated as current API facts. Our inference is that
upstream code generation can be reused while Gambit must still own and validate
its runtime protocol. No timing or continuation representation is transferred.

### PE07 — OCaml's Collector / FFI Tradeoff

[Sivaramakrishnan et al., Retrofitting Parallelism onto OCaml,
version 3](https://arxiv.org/html/2004.11663v3), sections 1.2-1.4 and 4.3-4.4,
read in HTML. Existing C access invariants constrain collector choices;
the paper compares a concurrent minor collector requiring C API changes with a
stop-the-world parallel alternative retaining that API. Our inference is to
evaluate Gambit collector/FFI changes jointly, including sequential behavior,
rather than equating a new systems language with multicore modernization.
This is the paper's design/evaluation, not a complete description of current
OCaml 5 or evidence for Gambit performance. No “ten-year rewrite” cost estimate
is used.

### PE08 — Access Boundary Retained

The [2018 Gambit native/C tail-call paper](https://www.schemeworkshop.org/2018/Huberdeau_Feeley.pdf)
could not be reopened through the web reader this turn. The
[author-hosted copy](https://www.iro.umontreal.ca/~feeley/papers/HuberdeauFeeleySFPW18.pdf)
returned access denied; a workshop mirror also failed. Existing prior notes
remain historical context. No new detailed claim or native witness is derived
from this failed access. Earlier inaccessible portable-C/continuation texts
remain open reading obligations; they are not reconstructed from their titles.

## 3. Evidence Obligations Still Missing

| Requirement | Evidence class | Why this record cannot close it |
| --- | --- | --- |
| Q-demand-portfolio | workload-demand | Named consumers, frequencies, desired capabilities and decision horizon are absent. A source pain is not portfolio priority. |
| Q-zig-increment | comparative-engineering | B1/Z1 capability-matched implementation/review/upgrade/incident costs are absent. Language documentation is not cost evidence. |
| Q-net-cost | measured-cost | Existing matched full-cost requirement stays open; no timings or maintenance observations are fabricated. |
| Existing semantic/ABI/retirement requirements | their original classes | Question coverage, literature relevance and exact hashes do not substitute for native or artifact observations. |

The next research can refine alternatives, ownership and comparative cost models
without authorizing implementation. Eventual empirical evidence requires its
own authorized phase and receipts. Zero unbound research references is useful
integrity, not proof of completeness, priority or net value.
