# Sources for the Zig System Engineering Architecture Study

Checked: 2026-10-19. Companion:
[architecture assessment](zig-system-engineering-architecture.md).

The [native contract follow-up](zig-native-contract-design.md) adds direct
reading of native driver option handling, semantic module linking, process
ownership, module loading and the locked candidate's compiler/FFI patch hunks.
Its provenance section records the additional source identities and distinguishes
baseline code from candidate changes. It selects interfaces without running
implementation or native validation work.

This is an annotated research bibliography, not an executable receipt or a
qualification report. Primary papers, project documentation, author-hosted texts
and project-maintainer accounts are used. Search snippets and community comments
were discovery aids, not technical evidence for the conclusions.

Reading coverage below distinguishes inspected text from bibliographic discovery.
Published dates and venues are taken from the publication/project record, not a
search engine's crawl date. Live documentation describes available design
surfaces; no dependency revision or supported toolchain has been selected.

## Research Papers and Their Transfer Limits

### P1. A Parallel Virtual Machine for Efficient Scheme Compilation

Marc Feeley and James S. Miller. ACM Conference on Lisp and Functional
Programming, 1990.
[Author-hosted paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf).

- **Read:** abstract and sections 1-2, especially the PVM description and
  bidirectional frontend/backend information flow.
- **Finding:** target descriptions supply register, calling-convention, closure
  and primitive information to the compiler. The IR boundary is a cooperative
  contract rather than an interchangeable final text emitter.
- **Use here:** motivates auditing target-dependent choices before selecting
  a GVM export. This is consistent with the inspected current `_back.scm`.
- **Limit:** the historical PVM and its futures model are not a specification of
  the current GVM, current SMP scheduler or repaired runtime. Historical
  performance claims are not transferred.

### P2. Compiling Higher-Order Languages into Fully Tail-Recursive Portable C

Marc Feeley, James S. Miller, Guillermo J. Rozas and Jason A. Wilson.
Universite de Montreal Technical Report 1078, August 1997.
[Primary publication listing](https://gambitscheme.org/research/),
[listed paper location](https://www-labs.iro.umontreal.ca/~feeley/papers/FeeleyMillerRozasWilsonDIRO1078.pdf).

- **Coverage:** bibliographic record verified; full text was blocked by the
  university site's access protection through both listed host variants.
- **Use here:** identifies the historical portable-C/tail-recursion research
  lineage. Current functionality is supported by the local README, generator
  and runtime source rather than an unread paper.
- **Limit:** no algorithmic detail or numerical result from this paper is
  treated as established by this review. It remains a follow-up reading item.

### P3. LLVM: A Compilation Framework for Lifelong Program Analysis and Transformation

Chris Lattner and Vikram Adve. CGO 2004.
[LLVM publication and author abstract](https://llvm.org/pubs/2004-01-30-CGO-LLVM.html).

- **Read:** official publication record and abstract.
- **Finding:** LLVM's common SSA representation supports language-independent
  analysis and transformation at several stages of program construction/use.
- **Use here:** a direct LLVM service is a real alternative when Gambit needs
  low-level optimization rather than multiple domain abstraction levels.
- **Limit:** this is not an analysis of present-day LLVM API compatibility,
  Gambit's runtime representation or the cost of a new backend.

### P4. MLIR: Scaling Compiler Infrastructure for Domain Specific Computation

Chris Lattner, Mehdi Amini, Uday Bondhugula, Albert Cohen, Andy Davis,
Jacques Pienaar, River Riddle, Tatiana Shpeisman, Nicolas Vasilache and
Oleksandr Zinenko. CGO 2021, pages 2-14.
[Published DOI](https://doi.org/10.1109/CGO51591.2021.9370308),
[official citation guidance](https://mlir.llvm.org/getting_started/Faq/).

- **Read:** the official publication record and the authors'
  [earlier public draft](https://arxiv.org/pdf/2002.11054), introduction and
  design-principle discussion, including progressive lowering.
- **Finding:** retaining several abstraction levels enables domain information
  to survive until a suitable transformation/lowering stage. Reusable compiler
  infrastructure can reduce repeated compiler construction work.
- **Use here:** separates MLIR's semantic/optimization role from Zig's
  engineering role; motivates comparing C, GVM and earlier/domain exports.
- **Limit:** the draft has a different title and is not the peer-reviewed
  publication. It is identified as reading material, not cited as if the final
  article had been read. The IEEE full text was not retrieved. Current syntax
  and APIs are checked against project documentation instead. No performance
  or integration-cost estimate for Gambit follows from this paper.

### P5. Polygeist: Raising C to Polyhedral MLIR

William S. Moses, Lorenzo Chelini, Ruizhe Zhao and Oleksandr Zinenko.
PACT 2021. [Author-hosted paper](https://c.wsmoses.com/papers/Polygeist_PACT.pdf),
[maintained project](https://github.com/llvm/Polygeist).

- **Read:** abstract and section III, particularly frontend control-flow
  structure and the Polygeist/C ABI distinction.
- **Finding:** a Clang-AST frontend can generate structured MLIR. Its internal
  array/pointer representation requires explicit adaptation to external C ABIs.
- **Use here:** corrects an overly categorical dismissal of C-to-MLIR. It is a
  valid architecture to compare, with a real frontend and ABI cost.
- **Limit:** the evaluated numerical C workloads are not Gambit's generated
  control flow, tagged objects, GC macros or continuations. No PolyBench speedup
  or arbitrary generated-C compatibility is transferred to Gambit.

### P6. The MLIR Transform Dialect: Your Compiler Is More Powerful Than You Think

Martin Paul Lucke, Oleksandr Zinenko, William S. Moses, Michel Steuwer and
Albert Cohen. CGO 2025.
[Author-hosted paper](https://michel-steuwer.github.io/files/publications/2025/CGO-2025-2.pdf),
[published DOI](https://doi.org/10.1145/3696443.3708922).

- **Read:** abstract, introduction, conclusion and artifact description.
- **Finding:** transformation control can be expressed through a separate IR
  that composes available transformations rather than requiring a new compiled
  pass for every optimization policy.
- **Use here:** optimization policy could become a separately versioned input
  to an optional compiler service.
- **Limit:** Gambit still needs semantic operations, legal lowering and target
  policy. The paper's case studies and artifact resource needs are not estimates
  for a Gambit integration. No artifact was installed or executed.

### P7. Retrofitting Parallelism onto OCaml

KC Sivaramakrishnan, Stephen Dolan, Leo White, Sadiq Jaffer, Tom Kelly,
Anmol Sahoo, Sudha Parimala, Atul Dhiman and Anil Madhavapeddy.
PACMPL 4, ICFP, Article 113, 2020.
[Author-hosted paper](https://anil.recoil.org/papers/2020-icfp-retropar.pdf).

- **Read:** sections 1.2-1.4, the C-API/read-barrier discussion and section 4.4.
- **Finding:** C heap-access semantics constrain collector changes; the work
  compares collector designs partly to preserve existing C behavior while
  considering sequential and parallel costs together.
- **Use here:** system-language modernization must account for generated C and
  foreign access contracts before changing GC/scheduling assumptions.
- **Limit:** OCaml domains, heap invariants and the evaluated collector are not
  Gambit VMs/processors, continuations or root maps. This study selects no
  collector and treats no OCaml result as a Gambit correctness/performance result.

### P8. Build Systems a la Carte

Andrey Mokhov, Neil Mitchell and Simon Peyton Jones. ICFP 2018.
[Author publication page](https://simon.peytonjones.org/build-systems-a-la-carte/),
[paper](https://simon.peytonjones.org/assets/pdfs/build-systems-original.pdf).

- **Read:** abstract and sections 4.2-5, focusing on traces, scheduling and
  rebuilding strategies.
- **Finding:** scheduling and deciding whether/reusing how to rebuild can be
  factored. Trace-based reuse relies on the modeled dependencies and relevant
  determinism assumptions.
- **Use here:** distinguish toolchain distribution, dependency completeness,
  graph scheduling and artifact reuse when comparing Zig and existing tools.
- **Limit:** the abstract framework does not establish that a particular Zig,
  Bazel or Gambit build is hermetic or correctly invalidated.

### P9. A Portable Implementation of First-Class Continuations for Unrestricted Interoperability with C in a Multithreaded Scheme

Marc Feeley. Scheme and Functional Programming Workshop, September 2000.
[Primary publication listing](https://gambitscheme.org/research/),
[listed paper location](https://www-labs.iro.umontreal.ca/~feeley/papers/FeeleySW00.pdf).

- **Coverage:** bibliographic record verified; full text could not be retrieved
  through the primary host variants (access protection/cache failure).
- **Use here:** identifies a particularly relevant follow-up on foreign control
  flow. The architecture's actual ownership restrictions come from local source
  and existing runtime audits, not a reconstruction of the paper.
- **Limit:** the title is not evidence of arbitrary external-thread attachment,
  automatic Zig cleanup on continuation escape or current SMP acceptance.

## Zig Documentation

### Z1. Zig 0.16.0 Release Notes

[Versioned primary documentation](https://ziglang.org/download/0.16.0/release-notes.html).

- **Read:** target-support discussion, C-import migration, compiler/toolchain
  sections and roadmap.
- **Finding:** `@cImport` is deprecated in favor of build-managed C translation;
  `zig cc` remains Clang-based. The document also describes ongoing changes to
  the LLVM dependency and warns about bugs and regressions.
- **Use here:** exact tool versions and a project-owned C-facing boundary matter
  more than preserving one Zig API spelling. Zig's own native backend work is
  not evidence that compiling Gambit's C becomes faster.
- **Limit:** 0.16.0 is an inspected version, not a selected project dependency
  or a claim about the newest downloadable build. Roadmap items are intentions,
  not present capabilities or delivery guarantees.

### Z2. Zig Build System

[Primary documentation](https://ziglang.org/learn/build-system/).

- **Read:** construction graph, native artifacts, options and cache examples.
- **Finding:** a Zig build can describe tool execution, compilation and reusable
  construction artifacts.
- **Use here:** supports the candidate engineering-layer role and coexistence
  with an outer graph owner.
- **Limit:** no Gambit build was authored; no documentation example establishes
  dependency completeness, cold-build speed, remote execution or bitwise
  reproducibility for this project.

### Z3. Zig C Interoperability and Translation

[Primary language documentation](https://ziglang.org/documentation/master/#C).

- **Read:** C ABI primitives, target/flag consistency, C translation failures
  and pointer interpretation.
- **Finding:** C interfaces can be represented, but translation has limits and
  must use consistent target/flags.
- **Use here:** prefer narrow native declarations and separately compiled C
  where the runtime uses complex macros or control flow.
- **Limit:** this is moving development documentation, not a stable API pin.
  Interoperability does not imply ownership safety, rooted Scheme pointers or
  semantic conversion of generated code.

## MLIR and LLVM Documentation

### M1. MLIR C API

[Primary documentation](https://mlir.llvm.org/docs/CAPI/).

The inspected design/scope/object-model sections describe a deliberately
low-level interface, opaque handles and ownership conventions, with no API
stability guarantee. This supports a Zig client while making lifetime and
version policy explicit. It does not establish feature completeness for every
custom dialect or availability in an unselected LLVM release.

### M2. Defining Dialects

[Primary documentation](https://mlir.llvm.org/docs/DefiningDialects/).

The static definition and extensible/dynamic-dialect sections describe both
TableGen/C++ organization and dynamic mechanisms. This review therefore avoids
claiming that all custom IR construction unavoidably requires handwritten C++.
The semantic definitions, interfaces, verification and conversion still need an
implementation; generic operation construction is only part of that work.

### M3. Developer Guide

[Primary documentation](https://mlir.llvm.org/getting_started/DeveloperGuide/).

The verifier and compatibility-policy sections distinguish local IR validity
from wider semantic assumptions and provide no C++ API compatibility guarantee.
Use this to constrain claims about IR verification and library coupling. This
does not prove that a proposed Gambit lowering preserves its language semantics.

### M4. Bytecode Format

[Primary documentation](https://mlir.llvm.org/docs/BytecodeFormat/).

The introduction promises a stable versioned container subject to dialect
definitions and describes dialect-specific upgrades. Container stability must
not be confused with stable custom operation semantics or a universally stable
compiler-service protocol. A project export still needs dialect and semantic
version requirements.

### M5. LLVM IR Target and C-Compatible Memory References

[Primary target documentation](https://mlir.llvm.org/docs/TargetLLVMIR/),
[project FAQ on memref/pointer conversion](https://mlir.llvm.org/getting_started/Faq/#how-to-convert-a-memref-to-a-pointer).

The memory-reference and C-interface discussions make descriptors and layouts
part of the calling convention. A native kernel boundary must account for them.
The chosen lowering may support special bare-pointer cases, but the review
does not equate arbitrary `memref` values, C pointers and Scheme vectors.

### M6. LLVM Garbage Collection and Statepoints

[GC integration](https://llvm.org/docs/GarbageCollection.html),
[statepoints](https://llvm.org/docs/Statepoints.html).

Read the GC introduction/goals and statepoint relocation examples. LLVM offers
mechanisms for expressing collector requirements; the language implementation
still supplies a collector and runtime integration. Relocated references are
represented explicitly by the statepoint machinery. This is a possible future
backend mechanism, not a recommendation to add it to the current C target or
evidence that it already matches Gambit's physical frames and roots.

### M7. EmitC

[Primary dialect documentation](https://mlir.llvm.org/docs/Dialects/EmitC/).

The overview documents emission of C/C++ with feature-dependent requirements.
This creates an architectural option for returning selected MLIR code to the
C toolchain. No Gambit conversion, whole-language support or cheap round trip
has been established.

### M8. GPU Dialect

[Primary dialect documentation](https://mlir.llvm.org/docs/Dialects/GPU/).

The overview and host/device execution model identify device compilation and
execution boundaries. They motivate separate device artifacts, memory transfers
and synchronization. They do not provide Gambit continuation, heap or scheduler
implementations for GPUs.

### M9. Pass Infrastructure

[Primary documentation](https://mlir.llvm.org/docs/PassManagement/).

Read operation-pass restrictions, dependent-dialect initialization and analysis
invalidation. Parallel pass execution has its own mutation/state restrictions.
The Gambit scheduler and a host engineering executor cannot be substituted for
those restrictions. Pass preservation claims also require explicit invalidation
reasoning; a retained compiler context is not proof of reusable analysis.

## Engineering Accounts and Build Contracts

### E1. Uber: Bootstrapping Infrastructure on arm64 with Zig

[First-party engineering account](https://www.uber.com/gb/en/blog/bootstrapping-ubers-infrastructure-on-arm64-with-zig/).

Read the Bazel/Zig integration section. The historical account reports using
Zig as the C/C++ toolchain inside a Bazel-managed Go monorepo, with significant
work to repair non-hermetic dependencies. It supports architectural coexistence
and demonstrates that migration has real work. It is not a current deployment
audit or evidence of Gambit compatibility.

### E2. hermetic_cc_toolchain

[Maintainer repository](https://github.com/uber/hermetic_cc_toolchain).

Read the README's role, origin and Bazel integration/cache configuration.
This is a concrete toolchain adapter design rather than a replacement of Bazel
by `build.zig`. Its README's tool versions are not imported into this proposal,
and its sandbox/cache exceptions need project-specific review. No installation
or recommendation of its current release is made.

### E3. Bazel Hermeticity

[Primary documentation](https://bazel.build/basics/hermeticity).

Read the definition, tool/source identity requirements and non-hermeticity
examples. Use it to distinguish a convenient build script from isolation and
complete input declaration. It does not certify the current outer repository,
any delegated Zig action or any historical native receipt.

### E4. MLIR Is Not an ML Compiler, and Other Common Misconceptions

Alex Zinenko. LLVM Developer Meeting, 2023.
[Maintainer presentation](https://llvm.org/devmtg/2023-10/slides/techtalks/Zinenko-MLIRisNotAnMLCompiler.pdf).

Read the frontend/pipeline and concluding architecture discussion. MLIR supplies
abstractions and transformations from which a compiler is assembled, rather
than a universal frontend/pipeline. This supports naming a compiler-service
owner. Its sample pass syntax is historical and is not an implementation recipe.

## Local Evidence and Provenance

The working repository resolves on this host to `.data/gambit-SMP` despite the
user-facing `.data/gambit-smp` spelling. Both refer to the same checkout here.
Research HEAD observed: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor Gambit HEAD: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, with no
tracked vendor modifications reported at inspection. The research checkout had
pre-existing changes and is not described as clean.

The following inspected baseline inputs were hashed. This records what was
read, not what a qualified runtime was built from:

| Input relative to research root | SHA-256 |
| --- | --- |
| `vendor/gambit/gsc/_back.scm` | `fe9021d1e7f88c46a869d0701d4dc960346b7383e21857102ef2150b448ecf3b` |
| `vendor/gambit/gsc/_t-c-1.scm` | `cd9030133390377167b2b29ad5f06f3854606e762a8a7cb44d932b62127d6b0a` |
| `vendor/gambit/gsc/_gsclib.scm` | `c4068e8d8c34135354d26c8a6e79adcac73bf34f432b857961bdb4932da94dd0` |
| `vendor/gambit/bin/gambuild-C.unix.in` | `bdd99a03bb24206e348bdc6ae760a02c04573694090e21cc0a9b748dc8522b4c` |
| `vendor/gambit/configure.ac` | `2a62dade3dd7174d9c091df7ed1018cb376619163c1e0ac1185dee923d874fc5` |
| `vendor/gambit/include/gambit.h.in` | `2bd9579c7124e0e18eec14180735621351d379a17410047b31b4b74fe2af9ac2` |
| `vendor/gambit/lib/setup.c` | `047e88c4561f9a95d770732ff13b942620824a1f74727b3f12ed170063239d46` |
| `vendor/gambit/lib/_kernel.scm` | `9afa811a1c15104b953a10d42cd11bddffbfa0b8684b4f8f8191d848fdb6d9ec` |

Related local studies read:

- [C-backend compatibility](../c-backend-compatibility.md): generated code,
  continuations, FFI and matched rebuild boundaries.
- [Runtime entry contracts](../runtime-entry-contracts.md): actual entry ownership,
  VM/processor distinctions and unsupported attachment assumptions.
- [SMP foundations](../smp-design-foundations.md): runtime evolution and reference
  transfer limits.
- [Runtime transfer boundary](../../runtime-transfer-boundary.md): existing overlay
  source maps and remaining correspondence obligations.
- [FFI/GC protocol](../../ffi-gc-frame-protocol.md): root/state publication,
  relocation and the model/native boundary.
- [Compiler cost boundaries](../../compiler-cost-boundaries.md): retained historical
  native compilation DENY; no new timing or rerun.

The existing overlay source-lock file was rehashed as
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
This review did not rematerialize or requalify its 26 target files. Its source
maps remain claims of the cited audits, separate from the directly inspected
vendor baseline.

The registered `repository_clues` interface returned two relevant scoped
observations under source identity
`54f6d553c3856701d9e4f9881515eea98159799fd482e462709b4982ea96e2b2`:

| Claim | Retained observation | Explicit limit |
| --- | --- | --- |
| `shared-registry-lifetime` | `registry-current-native`, digest `2f27c9ce2f7510a18cc5ecac6763d4a25f43d833b1b08251a8ed919fd450c4ce` | Native topology/replay-model scoped PASS, not release admission |
| `root-signal-native-comparison` | `root-signal-native`, digest `d01375c77a7289c99548cc5d718f7b96aea41f7e28ece41bc7a8a1a0f95c47cd` | Before/after native PASS, not terminal sealing |

Continuation token:
`clue-read:2a2766de0cbd269b637a66213e1913d6493b98a13ff49ed18faedefb0480113d`.
The response explicitly reported `runtimeAdmitted: false` and
`executionAuthorized: false`. These observations were read, not rerun. They
support keeping lifecycle obligations distinct; neither is Zig/MLIR evidence.

## Remaining Reading Questions

1. Obtain the full P2/P9 texts through an accessible primary publication route
   before borrowing their detailed control-transfer techniques.
2. Audit the complete current GVM/primitive target contract before specifying
   a semantic export; this study read the relevant entry interfaces, not every
   transformation or generated instruction.
3. Specify the continuation/unwind behavior of any future host adapter and JIT
   lifetime policy against an exact runtime candidate.
4. Review exact selected dependency revisions for dynamic-dialect C APIs,
   object/bitcode interoperability and platform support. Moving documentation
   cannot choose those versions on the project's behalf.
5. Establish product and maintenance requirements that determine whether one
   shared engineering layer saves more work than it adds.

No paper's benchmark, another project's deployment or a source-level API read
has been promoted into Gambit native correctness or performance evidence.
