# Durable Questions for the Gambit / Zig Adoption Decision

Date: 2026-10-20. Architecture research only. No backend implementation,
native experiment or performance qualification accompanies this decision record.

The current judgment is to continue investigating a Gambit-owned semantic and
runtime contract with a replaceable native subsystem. Zig is a credible
implementation candidate for that subsystem; its necessity and incremental net
value remain unestablished. Selecting a design to study is distinct from
committing the project to its implementation language.

This register makes the adoption question persistent. It connects the existing
[Q01-Q18 benefit ledger](zig-modernization-benefit-ledger.md),
[M1-M12 migration](native-request-configuration-migration.md),
[H01-H10 replacement plan](hostgraph-retirement-plan.md) and
[DSL research chain](zig-research-chains.md). These are different identifiers:
VQ denotes a value question; Q denotes a benefit measure or a separately named
qualification requirement; D0/D1 denote proposed dispatch designs. None is a
maturity score. DSL means domain-specific language, here the Scheme notation
used to describe research facts and query rules. ASCENT computes declared
relationships; it does not decide that an engineering investment is worthwhile.

![Adoption questions, attribution and revisable decision](zig-adoption-value-questions.svg)
[D2 source](zig-adoption-value-questions.d2).

## 1. Separate the Decisions Before Accumulating Evidence

There are four investment decisions, each of which can have a different answer:

1. Expose and consolidate native contracts currently spread across Scheme
   emitters, C macros, configuration scripts and runtime decoders.
2. Implement the resulting native subsystem in Zig rather than modernized C,
   a bounded C++ service, or another suitable language.
3. Use LLVM for selected native code generation and engineering services.
4. Introduce a high-level MLIR path when language analyses justify its cost.

Agreement with the first is not evidence that all four are necessary. Conversely,
Zig's value should be assessed across the full native subsystem rather than
reduced to replacing the compiler executable. Native resource ownership, typed
product planning, module construction, foreign boundaries and provider adapters
are potential durable responsibilities. Their proposed authority boundaries are
in [the Gambit-centered design](gambit-centered-backend-redesign.md).

Use three comparators throughout: B0 is the retained source-bound architecture;
B1 implements the same new contracts and algorithms with C/existing tools;
Z1 implements them with Zig. B0 to Z1 measures the whole modernization, while
B1 to Z1 isolates the language choice. An additional direct LLVM service is a
real alternative to MLIR, not a failed implementation of the preferred design.
No B1/Z1 implementation or comparative cost observation exists in this study.

## 2. The Twelve Questions

Evidence IDs below resolve in the [source and literature ledger](zig-adoption-value-evidence.md).
Each question has supporting considerations and limiting considerations; the
latter are not necessarily contradictions. A credible possibility is not a
demonstrated benefit. The current judgments are human-reviewed research states.

### VQ01 — Which Future Work Actually Justifies the Investment?

**Question.** Which repeated developer operations, deployed applications and
future capabilities are important enough to fund this refactor?

Current evidence establishes concrete friction: distributed native authority,
native packaging through C, foreign control obligations and a historical Darwin
startup window (VE01-VE05, VE10). It does not establish current workload
frequencies, an exclusive cost breakdown, a staffing budget or a chosen planning
horizon. Those are missing demand inputs, not incidental benchmarking details.

**Current judgment: unresolved.** Keep a demand record for each selected workload:
identity/revision/profile, operation frequency, affected users, required
capability, acceptable regressions, horizon, responsible reviewer and an
alternative that meets the same need. A capability may justify spending without
speedup, but it needs a named consumer and acceptance criterion. “Modern” is not
a workload.

**Alternative and reversal.** Repair selected C/Gerbil paths if the actual
portfolio is narrow. Reduce adoption scope if few operations need the common
subsystem. Connect Q01-Q05 and Q16-Q18; demand evidence is still open.

### VQ02 — What Makes the Result Still Gambit?

**Question.** Which design strengths must modernization preserve and which
physical choices may change?

The 1990 PVM paper describes a parameterized, bidirectional frontend/backend
boundary; registers, calling and closure choices flow back toward the frontend.
Current `_back.scm` exposes corresponding target responsibilities and the
frontend selects a target before normalization (VE01-VE02, PE01). This supports
a negotiated contract rather than recovery of language information from C text.
It does not establish that the 1990 representation is the current ABI.

**Current judgment: research-supported direction.** Preserve Scheme's semantic
authority, proper tail behavior, continuations, configured representation,
runtime ownership and portable output capability. Make physical layout and
native construction explicit replaceable services. Do not freeze today's
representation forever: future changes require an explicit runtime-contract
revision and migration, rather than an emitter silently changing layout.

**Alternative and reversal.** A C-owned common subsystem can preserve the same
principles. Reject a proposed export if it loses target negotiation, duplicates
language optimization, or requires Scheme semantics to be rediscovered in the
native emitter. Connect Q06, Q10, Q17 and the shared-runtime admission gates.

### VQ03 — What Is the Architectural Debt Inside C Emission?

**Question.** Is the problem merely C syntax, or the authority hidden behind it?

The C target installs primitive/frame/result/dump/link responsibilities together
(VE02). Its scanner also chooses checks and private return labels and flushes
live dirty values (VE03). Native CPU packaging still invokes the C target
(VE04). These are specific coupled responsibilities, not proof that C as a
language is inherently unsuitable.

**Current judgment: research-supported extraction.** Scheme semantic completion
must declare checks, roots, state transitions and continuation points before
export. A common native product engine then owns physical layouts, addressing,
relocations and C/native emission. Replacing only string output leaves the
semantic coupling intact. Forwarding through the whole old dumper leaves the
construction coupling intact.

**Alternative and reversal.** Extract the same contract into a new C subsystem.
Narrow the refactor if the complete producer/consumer census shows less shared
work than anticipated. Reject two independent frame/root authorities. Connect
H01-H10, Q01, Q10, Q16-Q18; source presence does not close those retirements.

### VQ04 — What Does Zig Add Beyond the Same Refactor in C?

**Question.** Is Zig's incremental advantage worth a second implementation
language and its toolchain obligations?

Explicit allocator conventions, typed descriptions and C interoperation make
Zig a plausible fit for product planning and native resource lifetimes (PE02).
The proposed use is to implement those components, not to translate generated
Scheme C into Zig. C translation has documented limitations; modern C with
generated descriptors and disciplined ownership can implement the same design.

**Current judgment: conditional candidate.** The differentiator to investigate
is reduced repeated adapter/layout/resource work per maintained capability,
including review and debugging cost. There is no language-level theorem of
lower maintenance cost, memory safety, or zero FFI work. Do not use Rust
lifetime stereotypes as evidence against a properly scoped alternative.

**Alternative and reversal.** B1 is mandatory in value attribution; a small C++
provider may be preferable when required APIs are C++-only. Prefer another owner
if the required Zig adapter/upgrade burden consumes the demonstrated advantage.
Connect Q08-Q10 and Q15-Q17. `Q-zig-increment` remains open.

### VQ05 — How Is the LLVM Engineering Dividend Amplified?

**Question.** Which maintained mechanisms can be reused, and which Scheme
obligations remain ours?

The proposed leverage comes from giving multiple Gambit native paths one
semantic/product boundary and a bounded provider interface. Instruction
selection, register allocation, object generation and admitted optimization
services are candidates for upstream reuse. Gambit still owns primitive,
effect, control and moving-root laws. MLIR's C API is a useful boundary but
offers no stability guarantee (PE04); its standard effect model does not fully
capture nonlocal control (PE05).

**Current judgment: conditional architecture.** BG can use a low-level native
provider; BH adds semantic MLIR only when high-level analyses earn their cost.
Moving through Zig does not itself preserve higher-order information erased
before GVM. Neither a bundled LLVM toolchain nor LLVM use inside Zig implies
that MLIR libraries, dialects or all required APIs are supplied.

**Alternative and reversal.** Direct LLVM or a separate C++ service may meet a
selected need with less infrastructure. Defer BH if there is no admitted
transformation that benefits a real workload. Connect Q05-Q07 and Q17; retain
tail, root and mixed-edge gates. Provider isolation limits where changes are
implemented, not where correctness/performance must be requalified.

### VQ06 — Which Generated-C Work Can Actually Disappear?

**Question.** Can we eliminate repeated generation/preprocessing/compilation
instead of making one compiler invocation more convenient?

VE03-VE04 locate the C-emission and native-packaging seams. The proposed BG route
can remove selected generated-C artifacts by constructing native products
directly, after equivalent runtime/module obligations are represented. Portable
C output and selected foreign C units still require C tooling.

**Current judgment: conditional structural saving.** Count generated C bytes,
preprocessed tokens, compiler/linker invocations and dependency-triggered work
for a selected route. Unchanged inputs reused as artifacts are a separate
saving from avoiding C on misses. Neither is established by choosing `zig cc`.
An incrementally compiled Zig implementation is not an incrementally compiled
Gambit program. PE03 explicitly bounds its LLVM emission benefit.

**Alternative and reversal.** Generated-C/object reuse in the old architecture
may remove much of the same repeated work. Prefer that narrower remedy if it
meets the goal at lower full cost. Connect Q02, Q04, Q18 and H09; do not count
the same removed invocation once for caching and again for native emission.

### VQ07 — Does This Solve the Darwin Startup Prefix?

**Question.** What is reusable construction code and what is fresh live state?

The historical five-second figure is a first-log ceiling with retained observed
values, not an OS cooldown. Later consumer C compilation cannot remove earlier
expander execution. The linked patch studies distinguish compiled interface
construction code from fresh lexical/phase/dynamic instances (VE10).

**Current judgment: attribution constrained.** Constructor AOT may remove
repeated interpretation/expansion of reusable programs. It must preserve fresh
identity, initialization, cycles and exceptions. Zig may carry artifacts and
lifetimes once that semantic design exists; it is not a prerequisite or an
independent cause of the proposed startup saving.

**Alternative and reversal.** Implement constructor reuse in the existing
Gerbil/Gambit path. Reopen the benefit if exclusive prefix evidence changes;
never transfer timings from a different historical candidate. Connect Q03-Q04;
the full removable fraction and current end-to-end gain remain unknown.

### VQ08 — What Does a Modern C FFI Contract Buy?

**Question.** Can foreign integration become explicit enough to evolve without
silently fixing language and GC choices in every adapter?

Foreign wrapper generation, marker lifetime, conversion errors and nonlocal
returns span emitter/header/kernel/C-interface sources (VE05). This is a real
protocol, not only compatible function signatures. OCaml's parallelism paper
shows how existing C API invariants constrain collector choices (PE07); its
specific collector or timing is not evidence for a Gambit implementation.

**Current judgment: research-supported contract, conditional Zig benefit.**
Use typed ownership/borrow, pin-or-copy, blocking/reentry, processor/VM identity,
root publication and unwind rules. Generate physical adapters from that single
contract. Zig can implement native resources; Gambit retains managed roots and
exception semantics. A Zig error union or `defer` is not automatically executed
by Gambit's nonlocal transfer: cleanup must follow the actual control protocol.

**Alternative and reversal.** Generate equivalent C adapters. Revise or reject a
foreign capability if it cannot state its lifetime/control obligations. The
actual F0-F5 denominator and selected adapter coverage still need a census;
primitive-name counts are not FFI coverage. Connect Q08-Q10 and Q15.

### VQ09 — Can This Improve GC and Multicore VMs Fundamentally?

**Question.** What changes the collector and VM protocols, rather than their
implementation language?

Current Gambit has generation tags and configured parallel scanning/publication
code (VE06-VE07). It is incorrect to describe this checkout as having no
multicore foundations, or to infer a fully qualified modern collector from
those branches. Zig's manual allocation concerns native subsystem memory;
Scheme objects continue under Gambit's moving-root contract (PE02, VE08).

**Current judgment: enabling boundary, unresolved runtime payoff.** Explicit
safe points, root layouts, service effects, VM resources and teardown owners
make later collector/scheduler changes easier to locate and assess. They do
not implement a concurrent collector, remove barriers, make interior borrows
safe, or establish independent-VM isolation. The OCaml lesson is explicit
collector/FFI tradeoffs and evaluation, not “rewrite C and gain multicore.”

**Alternative and reversal.** Improve collector algorithms and VM ownership in
the current C runtime. Undertake a runtime change only with a concrete algorithm,
invariants and demand. Retain sequential-regression and lifecycle costs as
first-class criteria. Connect Q11-Q15 and existing root/helper/marker gates.

### VQ10 — Is the Service Boundary Durable Across Toolchain Changes?

**Question.** Can Zig/LLVM/MLIR upgrades be contained without freezing Gambit
development or pretending backend ABI changes are local?

Versioned semantic/configuration/product contracts isolate provider-specific
mechanics (VE09). Upstream change remains material: PE03 records C-import API
evolution and LLVM emission limits; PE04 explicitly denies C-API stability.
These are published observations, not qualification of an installed toolchain.

**Current judgment: conditional isolation.** Keep compiler implementation,
generated-code provider, target ABI/SDK, runtime-contract and artifact schema
identities separate. A provider-only change invalidates provider-dependent
artifacts; a representation/root/calling change reaches semantic products and
the rebuilt cohort. Only a reviewed unchanged input closure permits reuse.

**Alternative and reversal.** A C ABI service or process service can provide the
same isolation. Select packaging according to lifetime, diagnostics, failure,
distribution and deployment requirements. If upgrades routinely cross the
claimed boundary, revise it and cost the real closure. Connect Q04-Q05, Q16-Q17.

### VQ11 — Does Complexity Leave the System?

**Question.** Which old authorities and callers actually disappear when a new
managed route becomes ready?

The existing M and H inventories name replacement conditions, while VE03-VE04
locate coupled paths and VE09 records migration scopes. None is retired by
writing this design. M2-M8 configuration/argv replacement does not by itself
retire C host/frame/module logic; H stages do not by themselves close mode or
shell-behavior equivalence.

**Current judgment: conditional replacement.** Keep caller coverage, live old
paths, duplicate authority, adapter surfaces, supported profile cells and
upgrade obligations visible. Temporary coexistence needs a named cohort and
exit condition; an indefinitely supported duplicate route is a recurring cost.
Retained portable C capability can be emitted by the new subsystem without
retaining the entire old emitter as a second authority.

**Alternative and reversal.** Keep the old route and abandon the replacement if
semantic/native equivalence or removal is infeasible at acceptable cost.
Reject a “thin wrapper” success claim when all old decisions remain live.
Connect Q01, Q16-Q18, M1-M12 and H01-H10 without declaring any closed.

### VQ12 — When Is the Long-Term Investment Worthwhile?

**Question.** Over an agreed horizon, does Z1 improve the valued portfolio enough
to pay for migration, recurring ownership and uncertainty?

VE11 provides an accounting design, not measurements. Runtime and research
gates establish whether a route can be considered; even all gates passing
would not choose the implementation language or establish net value.

**Current judgment: unresolved adoption.** Compare B0, B1 and Z1 with the same
capabilities and supported profiles. Report performance, reliability,
maintainer time and newly admitted capability separately. Avoid a weighted
“modernity score.” For a time-only subcase with compatible units, let `m` be
one-time migration hours and `s` recurring hours saved minus added recurring
hours per period: break-even is `m/s` only when `s > 0`. Values are unknown;
this equation is not an estimate. Price latency/capability separately if the
decision maker supplies values; do not silently monetize developer and CPU time.

**Alternative and reversal.** Stop at the shared contract with B1, narrow Zig
ownership, choose a different provider, or defer BH independently. A modular
design earns option value only if the preserved alternative can actually meet
its contract at a cost we are prepared to carry. Connect Q16-Q18; demand and
Zig-increment evidence stay open. Sunk research effort is not future benefit.

## 3. Trackable Research State and Change Policy

The authoritative questions live as typed records in the existing
[view](../../../evidence/scenarios/zig-native/research.view.json). Each has:

- a stable ID, literal question and decision scope;
- separately named supporting and limiting claim links with source paths,
  reviewed anchors and exact local hashes;
- at least one real alternative, existing ledger metric links and comparator;
- a human-reviewed current judgment, next research action, reopen trigger and
  reversal condition;
- declared missing evidence requirements, independent of reference integrity.

`question_record` exposes the reviewed judgment. `question_evidence` joins
considerations to citations. `question_gap` detects missing declared fields or
source correspondence. `question_open_premise` lists absent evidence by class.
Neither a zero gap count nor a traceable record means “adopt Zig.” Alternatives
and limiting considerations are not added as prerequisite `depends` edges:
doing so would accidentally make every optional architecture mandatory.

The shared Clue read can select a question by its `zig.value.VQxx` claim and
`value-question` factor. Registered fields are queryable facts, not a new
research engine. Prose and records require a reviewed coordinated update; this
document is not generated automatically from the view.

Revisit a question when its cited source/profile changes, new contrary evidence
arrives, a target workload or maintainer budget changes, a provider version is
proposed, or its replacement cannot remove the intended old owner. At each
review, record old/new input identities, changed anchors, contrary findings,
affected questions/metrics/gates and a new rationale. Preserve prior observations
and rejected routes. Updating a source hash does not revalidate an old result.
No recurring job or native work is scheduled by this policy.

The immediate research priority is VQ04/VQ08: a producer/consumer inventory for
the proposed typed foreign contract, with the same responsibilities costed in
B1 and Z1. In parallel in the reasoning order, VQ01 needs a real demand
portfolio. Additional ABI detail should be driven by those questions rather
than expanding the obligation graph indefinitely.

## 4. Foreign-Contract Research Update

The [ForeignPlan source study](foreign-plan-evidence.md) now maps 18 selected
producer/consumer responsibility families. The [contract](foreign-plan-contract.md)
specifies parse-time typed capture, stable identity/product ownership, ordered
conversion/failure programs and explicit control containment. This advances
VQ03/VQ08 beyond a general FFI manifesto. It does not close the selected-site
census or establish new native support. In particular, target-only leaf facts
cannot classify allocating result conversions, and an outer C catcher does not
prevent an intervening Zig frame from being skipped by nonlocal control.

The [same-contract comparison](foreign-plan-engineering-comparison.md) locates
ten engineering responsibility groups across B1/Z1/provider choices. VQ04
remains conditional and VQ01/VQ12 remain unresolved: no comparative engineering
hours or demand portfolio has been invented. The next source slice is transitive
custom-converter/release and dynamic closure ownership, alongside selected real
consumers. The rules and query observations retain both gains and limitations.
