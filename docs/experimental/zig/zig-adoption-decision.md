# Is Zig Necessary? System Responsibilities and Adoption Criteria

Date: 2026-10-19. Architecture decision refinement; no implementation or
performance qualification. Complements the
[system engineering design](zig-system-engineering-architecture.md),
[native contract](zig-native-contract-design.md) and
[interface operation/state design](interface-construction-operations-and-state.md).

## 1. Direct Answer

The [complete system layer comparison](zig-system-layer-value.md) develops the
broader case beyond command invocation: native resources and algorithms,
artifact/compatibility lifecycle, compiler services and host integration. Its
[source ledger](zig-system-layer-evidence.md) adds actual request, process,
load/setup and child-reaper evidence, alongside retained positive/negative costs.
The [migration refinement](native-request-configuration-migration.md) further
specifies the LLVM engineering dividend: reuse infrastructure behind a versioned
service boundary while containing provider upgrade scope. Logical non-necessity
of Zig does not diminish the need for that decoupling contract.

**An AOT interface-construction program does not require Zig.** Gerbil can emit
Scheme factories and compile them with Gambit's existing native pipeline. A
separate MLIR service can expose a language-neutral protocol. The correctness
and most structural work elimination come from staging and semantic contracts,
not the implementation language of the engineering tools.

If Zig only replaces a few compiler command lines or packages one factory,
there is no established necessity to introduce it. Keep that comparison as a
real alternative. This updates the earlier managed-Zig selection: it remains
the candidate implementation for a broader product profile, not an already
justified prerequisite for the interface optimization or upstream Gambit.

Conversely, restricting Zig to native-owned state does not restrict it to
running `zig cc`. It can own a coherent compiler engineering subsystem:
effective requests, target/ABI compatibility, artifact construction and reuse,
compiler-service execution, native diagnostics and distribution policy. The
question is whether owning these together pays for another language/toolchain.
Do not enlarge its semantic authority merely to justify its introduction.

![Zig adoption and responsibility](zig-adoption-boundary.svg)

## 2. A Substantial but Bounded System Layer

| Responsibility | Concrete input/output | Why it might justify a Zig implementation | What it cannot solve by itself |
| --- | --- | --- | --- |
| Native request normalization | Gambit/Gerbil-owned semantic product plus explicit host/target/flags -> one effective native recipe | Replace scattered environment/shell reconstruction with typed native data | Missing semantic dependencies remain a producer defect |
| Artifact compatibility and construction | Source/tool/runtime identities -> native code, manifest and provenance | One target-aware implementation for C assets, factory bundles and external libraries | A digest is neither live-instance validity nor runtime acceptance |
| Isolated compiler services | Inert IR/request -> compatible output or structured failure | MLIR/LLVM lifetime and process ownership can be contained behind a stable project protocol | A process boundary does not define Scheme effects or GC maps |
| Native IR transport and verification scaffolding | Encoded operations/schema -> decoded native-owned representation and diagnostics | Explicit allocation and C-compatible service boundaries; reusable across backends | Semantics and operation legality still come from Gerbil/Gambit contracts |
| Work coordination | Required semantic products -> actual missing native work | Shared execution machinery across constructor and ordinary native compilation | Not another scheduler layered over Bazel without a demonstrated need |
| Packaging and host integration | Qualified compatible artifacts -> installable distribution or embedding assets | Common engineering ownership across platform-specific integrations | Does not authorize replacing current runtime load/unload ownership |

These are proposed products with explicit owners, not features already supplied
by writing a `build.zig`. The [native contract source map](zig-native-contract-design.md)
identifies existing `_gsclib.scm`, `gambuild-C`, process, setup and dynamic-loader
seams. A managed implementation must replace its chosen legacy construction
path directly, rather than accumulate a permanent adapter translating a new
request back into the same environment/shell protocol.

The original compiler/runtime remains the authority for frames, roots, module
composition, control, phase and lexical identity. A Zig subsystem may eventually
implement independently specified, native-owned compiler algorithms, including
IR transformations with admitted legality. The proposal does not require those
algorithms to remain in Scheme forever. But “can write it in Zig” is not evidence
that changing ownership is beneficial or that the semantic specification exists.

## 3. Alternatives Must Remain Comparable

| Architecture | Gains available without further assumptions | Added obligations | Current judgment |
| --- | --- | --- | --- |
| Gerbil/Gambit staging with existing native construction | Avoid eligible repeated interface interpretation and reuse compiled factory code | Producer/loader refactor and equivalence, already substantial | Sufficient architecture for the interface problem alone |
| Defined contracts plus Zig system subsystem | Same semantic gains plus a possible common owner for native/service engineering | Zig version/target policy, native ownership, diagnostics, migration and packaging | Plausible for broader modernization; incremental value unproved |
| Defined contracts plus C/C++ subsystem | C runtime adjacency and direct MLIR implementation integration | Manual native ownership and same project contract/migration work | Viable comparison; no evidence it is intrinsically too expensive |
| Scheme orchestration plus separate MLIR executable | Service isolation without making Zig mandatory | Native service maintenance, data protocol and toolchain distribution | Viable if service integration is the dominant requirement |

Rust or other system languages are not excluded by a claim that their ownership
models are inherently unsuitable. No matched engineering study here ranks their
maintenance effort. The language-independent contract should survive replacement
of the Zig executor. Reusing the exact same factory artifact through two native
executors must not require changing Gerbil semantics.

## 4. What the Upstream Documentation Actually Establishes

The [Zig language reference](https://ziglang.org/documentation/master/), reviewed
2026-10-19, documents C-compatible types, C translation, native artifact tasks,
build caching and explicit ownership. It also requires matching C translation
targets/flags and describes translation failures. This supports technical fit,
not automatic compatibility with Gambit's macro-heavy private runtime header or
a promised C-frontend speedup. API/toolchain choice must be pinned before adoption.

The [MLIR C API](https://mlir.llvm.org/docs/CAPI/) exposes core IR and passes
through opaque C handles. It states that the API is under development and has
no stability guarantee. Zig can consume such an interface, but that neither
removes the underlying C++ implementation nor makes all custom dialect/pass
work available without native extensions. Pin the service build and expose a
project-owned protocol, rather than leaking MLIR handles across the system.

[Racket linklets](https://docs.racket-lang.org/reference/linklets.html) provide
an architectural precedent for compiled code instantiated against imported
variables; that separation does not depend on Zig. Flatt's
[Composable and Compilable Macros, ICFP 2002](https://www.cs.utah.edu/plt/publications/macromod.pdf)
motivates explicit phase dependencies and phase-specific binding identity.
Those are semantic obligations, not toolchain conveniences or a transferable
Darwin speedup result.

## 5. Benefit Accounting and Adoption Gates

Separate three ledgers:

1. **Semantic staging benefit:** equivalent interface work removed by producer/
   loader changes. Credit this to the architecture, even on the existing toolchain.
2. **Native execution benefit:** additional measured saving or capability from
   Zig versus that same staged architecture on the existing native path. Use
   identical semantic products and workload boundaries; do not count staging twice.
3. **Engineering benefit and cost:** reduction in distinct configuration owners,
   adapters, duplicated integrations and supported release procedures, against
   language/toolchain upgrades, service distribution size and migration burden.

For the same staged design, `incremental Zig value` is the avoided engineering
and execution cost plus required new capability, minus migration and continuing
maintenance. This is a decision framework, not a measured scalar. A second
build cache that duplicates existing ownership can make it negative.

Adopt the broader Zig profile only when concrete requirements span enough of
the responsibility table, each has one owner, the existing route cannot meet
them as economically, and the team accepts the version/platform support burden.
There is no arbitrary rule that a project needs two backends or a particular
number of features: name the actual requirements and compare the costs.

**Selected now:** retain Zig as a researched candidate system layer; keep the
constructor protocol and semantic state machine independent of it. Do not make
Zig mandatory to solve the Darwin import prefix. If the broader requirements
collapse to command invocation and packaging, defer adoption. If modern compiler
services, native product management and cross-target integrations become a
coherent maintained subsystem, Zig can carry substantial work without becoming
the owner of Scheme semantics. No implementation decision or speedup is admitted.
