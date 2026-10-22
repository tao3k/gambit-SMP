# Zig System Engineering and Semantic Compiler Research

Design-only research. **Modern C is the mandatory foundation; C-to-Zig is a
conditional implementation evolution.** Gambit retains Scheme semantics, the C
backend, ABI, FFI and embedding capabilities. Zig is not an adopted second runtime
or a prerequisite for LLVM/MLIR. Compare candidate realizations without assuming
two maintained implementations. No implementation or native performance result
is claimed by this collection.

Start with the current [modernization foundation](gambit-modernization-foundation.md),
[benefit / evolution matrix](gambit-modernization-foundation-matrix.md) and
[evidence](gambit-modernization-foundation-evidence.md). Earlier Zig-owned-plane
proposals below are research candidates interpreted through this mandatory C
foundation and replacement gate, not current adoption decisions.

**Current research priority: the complete Gambit native-system reconstruction.**
Start with the [full architecture](modernization-system-architecture.md),
[LLVM leverage / retirement / economic matrix](modernization-leverage-matrix.md)
and [source / primary evidence](modernization-system-evidence.md). The candidate
allows redesigned runtime root/context/participation/control contracts and a
Zig-owned native service plane, with real C-route retirement and independent
LLVM/MLIR providers. Nine modernization objectives, fourteen leverage rows and
nine retirement responsibilities define the scope. The RC/marker minimum is
retained as Bmin control; it no longer sets the Experimental architecture ceiling.
C-full and Z-full compare the same complete capabilities. Total modernization
and Zig-specific incremental value remain separate theory gates; no implementation
or native test is performed.

The [SysML v2 / OpenSysML modeling study](opensysml-architecture-modeling.md)
adds a full-system [unvalidated model draft](modernization-architecture.sysml),
[primary evidence and tool limits](opensysml-modeling-evidence.md), and a
[reviewed trace map](opensysml-model-traceability.json). Six views connect owners,
interfaces, root/context lifecycle, LLVM leverage, actual retirement and two
economic comparisons. Model assertions do not issue research/native witnesses.
No parser, model execution, solver or native test was run; full runtime protocol
refinement and positive cost bounds remain open.

The [shared runtime operation contract](shared-runtime-contract-design.md),
[source/paper evidence](shared-runtime-contract-evidence.md),
[retirement and cost matrix](shared-runtime-value-matrix.md), and
[SysML snapshot draft](shared-runtime-contract.sysml) refine the full design.
Eight records, 26 operation families, six publication/drain obligations and twelve
race/failure cases separate execution, roots, request epochs, GC workers and
code/return lifetime. Seven retirement groups and eight cost denominators retain
the full C/Zig comparison. Architecture names carry no invented generation label.
No implementation, model/solver/native execution or positive net bound is claimed.

The [conditional proof argument](shared-runtime-proof-argument.md), with its
[source/literature ledger](shared-runtime-proof-evidence.md), separates request
enrollment from final safe-point root-cut closure. It supplies five conditional
safety arguments, progress counterexamples, and an economic condition with
nonpositive countermodels. Resource-indexed reclamation permits independent
VM root carriers to survive context retirement when actual dependencies permit.
These are handwritten deductions under explicit premises, not checked proofs,
tool/model outcomes or whole-system qualification. The SysML draft reflects the
corrected ordering; all full architecture/cost requirements remain open.

The [root and real-user closure study](shared-runtime-root-custody-design.md)
follows safe-point production through physical map decoding, names actual
callback/TLS/finalizer/map/queue users, and separates GC workers from mutators and
storage shards. Its [evidence](shared-runtime-root-custody-evidence.md),
[benefit/cost matrix](shared-runtime-root-custody-matrix.md) and three D2 views
refine PA03/PA04/PA05 and retirement dependencies. Local correspondence and
conditional last-use cases are explicit; full caller/map/collector closure and
positive Zig increment remain open. No implementation or native test ran.

The [foreign release and worker-admission study](foreign-release-worker-contract.md)
traces four actual release origins, their different error/ownership behavior,
and nine independent admission obligations. Its
[evidence ledger](foreign-release-worker-evidence.md) and
[shared device service comparison](device-release-support-matrix.md) use ten
actual registration expressions converging on one existing C helper. Memory
collection completion and native resource-release drain are separate; no worker
profile or positive Zig-only bound is qualified. Three D2 views show the design.

The [explicit WaitContext, delivery and drain design](device-release-wait-contract.md)
refines native wait storage/leases, accepted task custody, cooperative observer
cancellation, partial effects and dependency-aware shutdown. Its
[source/paper evidence](device-release-wait-evidence.md) and
[necessary-support matrix](device-release-wait-cost-matrix.md) compare twelve
shared support units in modern C and Zig after actual reuse. Three D2 views
show wait, delivery and shutdown frontiers. Native wake/order/closure and positive
net-benefit bounds remain unresolved; no implementation or native test ran.

The [synchronization and descendant-accounting argument](device-release-sync-proof.md)
now gives a concrete drain-before-check/false-then-wait protocol, serialized
accept/cancel/delivery cuts, and root/child/notification/dependency ledgers.
Its [source/paper evidence](device-release-sync-evidence.md),
[matched maintenance matrix](device-release-sync-cost-matrix.md), and
[trace map](device-release-sync-traceability.json) include the still-object
teardown producer and RC-storage custody before cleanup_rc. Six conditional
arguments and fourteen logical counterexamples distinguish safe accounting from
finite progress. Three D2 views refine the protocol; no implementation, checked
proof, native test, retired path or positive Zig-only bound is claimed.

The [RC payload custody and still-object producer design](rc-payload-custody-design.md)
follows actual TLS nested strings, TCP server readers and managed settings,
RC-backed C closure roots, private still-list cursors and cleanup dependencies.
Its [source/paper ledger](rc-payload-custody-evidence.md),
[modern C / Zig maintenance matrix](rc-payload-custody-cost-matrix.md) and
[trace map](rc-payload-custody-traceability.json) distinguish owner drain,
same-address adoption and independent native allocation from birth. Seven
conditional arguments and seventeen logical countermodels cover storage/root
handoff, discovery seal and internal wait cycles. Three D2 views refine the
architecture; native/root/provider/cost qualification remains open.

The [root-transfer receipt and scan-retirement design](root-transfer-receipt-design.md)
separates protected precommit permits from committed receipts, ties the transfer
to complete terminal epochs and exact physical root cells, and preserves actual
custody during interrupted publication. Its [source/paper ledger](root-transfer-receipt-evidence.md),
[modern C / Zig matrix](root-transfer-receipt-cost-matrix.md), and
[trace map](root-transfer-receipt-traceability.json) distinguish closing transfers
from closing required GC service and retiring physical scan facilities. Seven
conditional arguments, sixteen logical countermodels and three new D2 views
refine the full reconstruction. No native/checked proof or positive cost bound
is established; the earlier payload handoff view is corrected consistently.

The [target-root adapter and collector-entry design](target-root-adapter-design.md)
now separates VM-owned RC carriers from collector work contexts, closes the
selected GC/resize source-reference census, and specifies completion-to-registry
publication during facility closure. Its [evidence ledger](target-root-adapter-evidence.md),
[matched cost matrix](target-root-adapter-cost-matrix.md),
[source inventory](target-root-caller-inventory.json) and
[trace map](target-root-adapter-traceability.json) expose previously omitted
weak-table/bignum allocation and indirect ABI routes. Seven conditional arguments,
sixteen countermodels and three D2 views refine seed accounting, nested resize
collection and actual failure custody. Whole-program/native/order/progress and
positive economic qualification remain open; no implementation or native test.

The [collector-context and request-participation design](collector-work-context-design.md)
classifies all 34 selected PSTATE mem members and separates mutators, roots,
heap shards, workers, operation participants and request identities. Its
[source/paper ledger](collector-work-context-evidence.md),
[field inventory](collector-work-context-fields.json),
[matched net-benefit matrix](collector-work-context-cost-matrix.md) and
[trace map](collector-work-context-traceability.json) refine root/frame publication,
GC combining, noncombined resize, child epochs and phase-work termination.
Eight conditional arguments, twenty countermodels and three D2 views expose
single-mutator/multiworker synchronization and source result-publication gaps.
Native/transitive/progress/retirement and positive economic gates remain open.

The [GC capacity/result and resize-stage design](gc-capacity-result-design.md)
separates provisional heap decisions, terminal common outcomes, request credits
and actual native allocation. Its [source/paper ledger](gc-capacity-result-evidence.md),
[modern C/Zig net-benefit matrix](gc-capacity-result-cost-matrix.md) and
[trace map](gc-capacity-result-traceability.json) refine branch/action settlement,
post-commit resize errors, still-credit recount/refund and physical interval
placement for copy/resume storage. Eight conditional arguments, twenty-two
countermodels and three D2 views expose unit, partial-allocation and lifetime
boundaries. Native/ABI/placement/progress and positive economic gates stay open.

The [theoretical net-benefit argument](theoretical-net-benefit.md) separates
source correspondence, theoretical value, scoped empirical tests and final
qualification. It specifies six signed benefit cases, equal-capability C/Zig
comparators, nonoverlapping costs, uncertainty bounds and the gate before any
small empirical test. Shared modernization mechanisms are concrete; a positive
Zig-specific net-benefit bound is still open. No native test is run by that study.

For Zig's own increment, read the
[equal-capability modern-C/Zig comparison](zig-vs-modern-c-net-benefit.md) and
[source/primary-literature evidence](zig-vs-modern-c-evidence.md). Eight paired
mechanism cards include costs, positive conditions and counterexamples. The
strongest candidate is private native product/helper/resource code with ordinary
returns; C access, generic LLVM reuse and GC/cache slogans earn no independent
Zig credit. Local language obligations can shift, while the aggregate theoretical
net-benefit gate remains open on actual support retirement and defensible bounds.

The [native support/change certificate](native-support-change-certificate.md)
follows actual label generation, separates shared route replacement from
Zig-specific support avoidance, and compares resident and streaming designs.
It identifies one avoidable prospective C association family in a scoped pair,
but the current consumers do not require that topology. Nine change events
expose retained work and prevent generator/cleanup work from being overcounted.
No positive aggregate cost bound or native experiment is claimed.

The [reuse and handoff design](native-support-reuse-and-handoff.md), with its
[evidence ledger](native-support-reuse-evidence.md), follows those gaps through
existing Scheme containers, dense IDs, batch/snapshot ownership, work counts
and toolchain/provider upgrade boundaries. The label slice alone does not
justify Zig selection: retained semantic support and shared transport changes
cannot be credited as language-specific savings. The resulting direction is
one immutable semantic handoff and one common physical planner, with the native
language choice still subject to a necessary-support and cost argument.

For the remaining necessary work, the [layout/provider design](native-layout-provider-design.md)
and [evidence ledger](native-layout-provider-evidence.md) separate host layout,
target ABI, Gambit frame/GC encoding and object format. NP01-NP12 assign retained
runtime duties and delegated provider mechanics. Direct LLVM, MLIR-plus-LLVM
and external IR-driver routes can be selected independently of C/Zig planner
language; Zig's IR/bitcode input is a distinct tool role. Provider reuse is
concrete, but these interfaces do not establish a Zig-specific net-benefit bound.

The [planner/facade support-cost study](planner-facade-support-cost.md) and
[source/library ledger](planner-facade-support-evidence.md) compare ten support
categories inside the necessary planner and service boundary. C-G and C-ZT
controls credit checked builtins, reusable/opaque support and common Zig-driver
costs. A source-grounded LLVM failure-output case shows why status propagation
cannot replace ownership normalization. Conditional saving mechanisms,
CE01-CE09 change costs, a sufficient positive domain and a nonpositive small-shim
countermodel make the remaining theory certificate explicit. Two D2 diagrams
cover paired cost accounting and raw failure-output ownership; no native test
or positive aggregate cost bound is claimed.

The selected real component is now the
[return-frame descriptor planner](return-frame-planner-case.md), with an
[eighteen-dimension C-G/C-ZT/Zig benefit report](return-frame-benefit-matrix.md)
and [source/primary evidence](return-frame-planner-evidence.md). It expands the
same exact-allocation/chunk algorithm under all three controls, RF01-RF07 route
retirement boundaries and FM01-FM06 maintenance events. Existing root formation
depends on physical alignment and requires semantic extraction. The chosen
small C control needs no generic visitor/growth/bignum support, so this component
alone supplies no demonstrated Zig-positive cost bound. Architecture and
retirement D2 diagrams accompany the report; no implementation/native test runs.

For a broader necessary systems component, the
[native build job service](native-job-service-design.md) follows actual
Gambit/Gerbil compile/link and package-query paths. Its
[eighteen-row benefit and shared-cost matrix](native-job-service-benefit-matrix.md)
and [evidence ledger](native-job-service-evidence.md) compare C-G/C-ZT/Zig,
including reusable C libraries and a cheaper typed-Scheme alternative. A
source-derived independent-reaper hazard motivates explicit process ownership;
matched worker designs pay the same gateway/TTY/control obligations. SA01-SA09
and NC01-NC07 allocate real sharing once; NJR01-NJR08 distinguish managed-route
replacement from retained runtime/legacy support. The positive portfolio domain
is concrete but has no justified positive cost bound. D2 ownership/portfolio
diagrams accompany the design; no implementation or native tests occur.

The [NJS executor/byte/cleanup contract](njs-executor-storage-cleanup.md) and
[source/OCaml ledger](njs-executor-evidence.md) expand that boundary to actual
Scheme byte APIs, reusable C process callbacks, Zig primitives and seven resource
owners with ten failure cases. The
[residual-cost and Gambit modernization matrix](njs-support-cost-modernization-matrix.md)
adds RS01-RS12, CA01-CA08 and MG01-MG12. Modernization is defined by explicit
semantic authority, composable VM/GC/FFI/control and resource protocols,
replaceable providers, correct reuse and real retirement, with language ROI
evaluated separately. Necessary stdout-only queries can use bounded exact
storage in every control; no mandatory grower/dual-stream framework is charged
to C. No native or positive-cost qualification follows from the design.

For modernization inside Gambit itself, continue with the
[root/blocking/VM contract](runtime-root-participation-contract.md),
[benefit, cost, retirement and migration matrices](runtime-modernization-cost-matrix.md)
and [Gambit/OCaml/paper evidence](runtime-root-participation-evidence.md).
V/E/R/S/P separate VM lifetime, processor execution, root discovery/update,
backing storage and collective participation. Existing frame/RC/still and
participating-wait mechanisms are retained; detached native participation and
arbitrary attachment require new protocols. RT/BW/VE rows, RB01-RB14,
KC01-KC08 and RM00-RM08 make the C-layer reconstruction, Zig increment and
unresolved source/native/cost gates explicit. Three D2 diagrams cover authority,
wait/reentry and migration. No runtime implementation or native test occurs.

For the first owned-entry cohort, the [same-owner callback and participating-wait design](owned-callback-participating-wait-contract.md), [source/OCaml ledger](owned-callback-wait-evidence.md) and [twelve-row paired matrix and migration](owned-callback-wait-matrix.md) refine the RC registration/scanner domain, real pre-marker GC boundary, invocation-local target, no-switch binding, and legal wait/service cut. Twelve callback states, five selected retirement conditions and OS00-OS06 preserve current mechanisms while separating common runtime reconstruction from Zig's bounded private-support increment. Two D2 diagrams accompany the study; no positive aggregate bound, implementation or native test is claimed.

The [nonzero RC / pre-marker minimum](rc-marker-minimal-contract.md),
[caller/source ledger](rc-marker-caller-evidence.md) and
[maintenance/migration matrix](rc-marker-maintenance-matrix.md) now credit the
existing candidate scan/transfer and saved-target repairs. They separate direct
movable RC data, positive-still carriers and native bytes, use short-window MP1
only under a real reservation/no-clobber/exit contract, and keep pending-join
root coverage unresolved. Modern C can reuse this small runtime shell; a Zig
handle/status wrapper alone has no established positive saving. Two D2 diagrams
cover RC custody and nested marker exits. No implementation/native tests occur.

For the continuing adoption decision, start with the
[twelve durable value questions](zig-adoption-value-questions.md) and their
[source/literature ledger](zig-adoption-value-evidence.md). They distinguish
shared-contract modernization, Zig's incremental value over the same refactor
in C, LLVM services and optional semantic MLIR. Supporting/limiting evidence,
real alternatives, missing demand/cost inputs and reversal triggers are indexed
in the existing Scheme DSL/ASCENT scenario. The current position is to continue
research; adoption and net incremental value remain unresolved.

The next concrete slice is the [ForeignPlan contract](foreign-plan-contract.md):
parse-time typed capture, ordered conversions, explicit emission ownership,
stage-specific effects and control containment across C/Zig callbacks. Its
[18-family source map](foreign-plan-evidence.md) names producers/consumers;
the [same-contract C/Zig/provider comparison](foreign-plan-engineering-comparison.md)
separates common refactoring cost from plausible Zig gains and added obligations.
Source-family coverage is not a complete call-site denominator or native support.

The current D1-H direction is a [substantial C backend/runtime-interface refactor](d1h-c-runtime-refactor.md):
Gambit semantic HostGraph/FrameSpec -> Zig common product engine -> new C and
LLVM emitters, with a declarative per-host module contract. It replaces selected
C emission/setup/exit paths rather than forwarding through them. Read its
[independent edge/module evidence plan](d1h-edge-admission.md) and
[source ledger](d1h-refactor-evidence.md) for 10 replacement paths, 12 edge
receipts, 8 module cases and concrete unresolved owners. This is a selected
architecture, not implemented or qualified runtime support.

The [HostGraph/FrameSpec/runtime-role generation contract](hostgraph-generation-contract.md)
now defines Scheme semantic completion before export, frozen point identities,
Scheme-owned root obligations versus Zig-owned FrameLayouts, and role-anchor
preservation through CFG transformations. Its [C-path replacement order](hostgraph-retirement-plan.md)
gives ten dependent retirement stages and structural benefit measures; the
[source ledger](hostgraph-generation-evidence.md) binds twelve producer/decoder
scopes and seven unresolved gates. Three D2 diagrams cover generation, role
lineage and retirement dependencies. A raw GVM dump is insufficient because
the current C scanner itself creates some internal check/resume points.

The [Scheme semantic-completion inventory](semantic-completion-operations.md)
extracts 24 control/root/check/exception operation families. The
[15 runtime-role entry contracts](runtime-role-entry-contracts.md) locate actual
handler/post-thunk anchors, typed scratch payloads, complete versus partial
frames, foreign markers and the saved dynamic-environment field. Their
[source ledger](semantic-completion-evidence.md) feeds the existing
[Scheme DSL/ASCENT research chains](zig-research-chains.md): source facts,
proposals, dependency closure, missing feasibility/retirement requirements and
benefit targets remain distinct, queryable records. DSL consistency is not
native qualification; no backend or performance experiment was performed.

Continue with [GVM anchor preservation](gvm-anchor-preservation.md) for nine
pass-specific obligations, including external roots in final scheduling, and
[allocation reserves / helper effects](allocation-reserve-helper-contract.md)
for separate compiler/local/VM budgets and nine source-bound helper contracts.
The [admission evidence ledger](completion-admission-evidence.md) preserves the
static/native boundary and primary MLIR/LLVM constraints. Source equations and
their conditional arithmetic do not close allocation, relocation or exception
qualification.

For the concrete GVM-to-native seam, read the
[Gambit shared runtime contract](gvm-shared-runtime-contract.md),
[12-path C replacement and 10-row benefit matrix](gvm-native-replacement-matrix.md)
and [source/paper evidence with unresolved register](gvm-shared-runtime-evidence.md).
They specify logical GVM export, configured object/control/frame representation,
tail dispatch, continuation and GC root/reload duties, module packaging and the
conditional removal of generated C. D0/D1 are proposed dispatch capabilities;
SR01-SR08 are open admission gates, not implemented runtime support.

The [D0/D1 cross-backend protocol](d0-d1-cross-backend-protocol.md) and
[Darwin/control/frame evidence](d0-d1-cross-backend-evidence.md) refine that seam:
retained GCC defaults conditionally select exclusive-tail host exits; D0 needs
a centralized cohort, while proposed D1-H uses a uniform C host ABI. They
separate host transfer readiness from GC scanner readiness and enumerate
X01-X12 transfer cases, B01-B08 bridge responsibilities and deferred D1-R work.

For the broader modernization decision, start with
[Gambit's paper-driven backend redesign](gambit-centered-backend-redesign.md),
[Zig, LLVM and runtime modernization](zig-llvm-runtime-modernization.md),
the [18-row quantitative benefit/cost ledger](zig-modernization-benefit-ledger.md)
and [source/literature evidence](zig-runtime-modernization-evidence.md).
They separate native engineering, proposed runtime components and future
collector/compiler co-design, including no-GC Zig versus moving Scheme heaps,
FFI effects, parallel GC and VM lifecycle lessons from Chez and OCaml 5.

Read in this order:

For the Darwin patch's approximately five-second pre-first-compile execution
window, start with the [focused boundary correction](darwin-first-compile-boundary.md).
It distinguishes compiler/expander execution and interface instantiation from
Bazel caching and later C compilation.
Continue with [AOT interface construction](interface-construction-aot-design.md)
and its [evidence ledger](interface-construction-evidence.md): reusable code
versus current instances, two-stage execution, live dispatch, ownership and
the limits on structural startup savings.
The [operation inventory and instance state machine](interface-construction-operations-and-state.md)
adds direct Gerbil source evidence for dynamic bindings, lexical identity,
phase cycles and exceptions. The [Zig adoption decision](zig-adoption-decision.md)
separates the semantic refactor from the case for a broader Zig subsystem;
Zig is not a prerequisite for the constructor architecture.
For the broader modernization question, read the
[complete system layer value/cost comparison](zig-system-layer-value.md) and
[source/literature evidence](zig-system-layer-evidence.md). They cover native
resources, compiler algorithms/services, host integration and process ownership
as well as construction, with explicit alternatives and adoption costs.
The [native request, effective configuration and migration design](native-request-configuration-migration.md)
now specifies the one-resolver path, source-bound M1-M12 retirement inventory,
LLVM engineering reuse/upgrade isolation and benefit/maintenance criteria;
[its ledger](native-request-migration-evidence.md) records the exact mappings.
Continue with the [effective configuration and managed Darwin/GCC profile](effective-configuration-darwin-gcc.md)
for field/provenance requirements, exact mode parameter algebra, selected versus
deferred support and role-specific upgrade invalidation;
[its source ledger](effective-configuration-evidence.md) distinguishes symbolic
source mappings from an actual configured or qualified toolchain.
The [configured Darwin inputs and decoding design](darwin-configured-input-design.md)
adds recovered `.unix` bindings, source-specific string/argv admission,
metadata conditions and an M1-M12 retirement recheck; its
[evidence ledger](darwin-configured-input-evidence.md) preserves exact configured
flag strings and distinguishes historical receipts from missing raw artifacts.
The [single-source dual-output design](single-source-native-profile.md) specifies
the configure-owned model, legacy/typed renderers, concrete records and request
examples. Its [E01-E32 matrix and M2-M8 retirement gates](native-argv-equivalence-matrix.md)
separate supported-input equivalence from explicit rejection;
[source evidence](single-source-profile-evidence.md) binds the encoding seam.
The [independent observation plan](independent-equivalence-evidence-plan.md)
expands each E row into old-path boundaries, matched controls and failure rules;
the [actual caller/replacement plan](native-caller-retirement-plan.md) maps
M2-M8 sites, lexical branches and staged retirement dependencies.
[Observation source evidence](equivalence-observation-evidence.md) separates
verified call sites from proposed, still-unqualified capture capabilities.
The [Darwin recorder and original-tool observer study](darwin-recorder-observation-design.md)
defines L1 main-entry calibration and a conditional native Endpoint Security
notification path for L2, with explicit permissions, bytes/cwd/status/loss gaps.
[Platform evidence](darwin-observation-platform-evidence.md) binds local SDK/man
sources and official Apple API/SIP documentation; no observer was run.
The [Darwin supplemental evidence design](darwin-supplemental-evidence-design.md)
traces failed launch returns, hidden query/tty channels and Scheme delivery,
with explicit ES joins and independent source-copy versus original evidence.
[Supplemental source/platform evidence](darwin-supplemental-evidence.md) binds
error-pipe/status code, SDK syscall manuals, output-event limits and audit caveats.
The [external syscall/I/O observer study](darwin-external-observer-design.md)
separates failure returns, byte snapshots, fd transformations and ES association,
with bounded binary capture, spawn-action gaps, concurrency and calibration gates.
[Its evidence](darwin-external-observer-evidence.md) includes native consumer
headers/link-stub limits and published Apple kernel probe/action source;
no original observation capability is yet qualified.
The [native DTrace consumer and adapter architecture](darwin-dtrace-adapter-architecture.md)
refines arm64/arm64e eligibility, callback/record ABI, declared versus firing
probes, kernel spawn actions and snapshot fidelity. Its
[source ledger](darwin-dtrace-adapter-evidence.md) binds SDK, Apple consumer,
linker and kernel evidence; every runtime qualification gate remains open.
The [consumer support and probe admission matrices](darwin-consumer-support-matrix.md)
trace version-specific TAPI selection, dyld interoperability/loading and typed
libdtrace callbacks into conditional C0/C1 profiles and P01-P10 scope decisions.
[Their evidence](darwin-consumer-support-evidence.md) distinguishes named source
revisions from installed-stack correspondence, which remains unresolved.
The [local stack correspondence](darwin-local-stack-correspondence.md) now binds
actual CLT/Mach-O/cache metadata: local TAPI 2100 and dyld 1387 differ from the
public branches previously studied; cached libdtrace has a 413 version-label
match. None establishes C0/C1 runtime or callback admission.

1. [System engineering architecture](zig-system-engineering-architecture.md):
   scope, ownership, integration choices and long-term costs.
2. [Native contract design](zig-native-contract-design.md): construction,
   generated-code/runtime protocol, host entry, loading and service isolation.
3. [High-level semantics design](zig-high-level-semantics-design.md): exact
   export boundary, higher-order functions, effects, continuations and allocation.
4. [Evidence and quantitative boundaries](zig-high-level-semantics-evidence.md):
   source anchors, paper coverage, retained controls and benefit/cost equations.
5. [Primitive/FFI coverage](primitive-ffi-coverage.md) and the
   [complete primitive metadata catalogue](primitive-catalogue.md): source-bound
   coverage decisions, reusable mechanisms and required producer/lowering changes.
6. [Evaluation and effect contract](evaluation-effects-contract.md): selected
   sequential policy, observation rules, unknown effects and rewrite obligations.
7. [MLIR pass admission](mlir-pass-admission.md): per-domain conditions, upstream
   evidence, custom legality and excluded pipelines.
8. [Compilation cost, Bazel/Zig caching and layered AOT](compilation-cost-and-aot-design.md):
   retained positive/negative evidence, miss cost, cache overhead, invalidation
   and the direct MLIR bypass; [bound evidence snapshot](compilation-cost-evidence.md).
9. [Correct compilation units, artifact contracts and invalidation](compilation-unit-artifact-contract.md):
   semantic units versus request groups/actions, layer contracts, dependency
   propagation and precise Bazel/Gambit/Gerbil/Zig ownership.
10. [Source and literature review](zig-system-engineering-sources.md).
11. [Earlier backend feasibility assessment](zig-mlir-feasibility.md).

Architecture diagrams are maintained here as D2 sources and rendered SVGs:

- [Runtime modernization and LLVM leverage](zig-runtime-modernization.d2) / [SVG](zig-runtime-modernization.svg).
- [Gambit-centered backend separation](gambit-centered-backends.d2) / [SVG](gambit-centered-backends.svg).
- [Moving GC and native FFI ownership](zig-gc-ffi-ownership.d2) / [SVG](zig-gc-ffi-ownership.svg).
- [Local Darwin stack correspondence](darwin-local-stack-correspondence.d2) / [SVG](darwin-local-stack-correspondence.svg).

- [Phase and ownership diagram](semantic-pipeline.d2) / [SVG](semantic-pipeline.svg).
- [Continuation and allocation diagram](allocation-lifetimes.d2) / [SVG](allocation-lifetimes.svg).
- [Engineering decoupling diagram](engineering-boundary.d2) / [SVG](engineering-boundary.svg).
- [Semantic/pass admission diagram](semantic-admission.d2) / [SVG](semantic-admission.svg).
- [Compilation cost and bypass diagram](compilation-cost-paths.d2) / [SVG](compilation-cost-paths.svg).
- [Layered AOT reuse diagram](layered-aot-reuse.d2) / [SVG](layered-aot-reuse.svg).
- [Compilation units and invalidation diagram](compilation-units-and-invalidation.d2) / [SVG](compilation-units-and-invalidation.svg).
- [Darwin first-compile boundary](darwin-first-compile.d2) / [SVG](darwin-first-compile.svg).
- [Interface construction code and current instances](interface-code-instance.d2) / [SVG](interface-code-instance.svg).
- [Interface instantiation and delayed evaluation states](interface-instantiation-state.d2) / [SVG](interface-instantiation-state.svg).
- [Zig adoption and system responsibilities](zig-adoption-boundary.d2) / [SVG](zig-adoption-boundary.svg).
- [Existing surfaces and complete system layer](system-layer-before-after.d2) / [SVG](system-layer-before-after.svg).
- [MLIR service and process lifecycle](mlir-service-lifecycle.d2) / [SVG](mlir-service-lifecycle.svg).
- [Unified native request and configuration resolution](native-request-resolution.d2) / [SVG](native-request-resolution.svg).
- [LLVM provider and upgrade decoupling](llvm-provider-decoupling.d2) / [SVG](llvm-provider-decoupling.svg).
- [Effective configuration and managed admission](effective-configuration-model.d2) / [SVG](effective-configuration-model.svg).
- [Native profile and service invalidation](native-profile-invalidation.d2) / [SVG](native-profile-invalidation.svg).

Blue denotes retained Gambit responsibilities; purple denotes proposed compiler
service work; orange denotes a contract or an unresolved qualification boundary.
Rendered diagrams describe proposals, not implemented components.

Return to the [experimental research index](../README.md).

- [Legacy string decoding](legacy-string-decoding.d2) / [SVG](legacy-string-decoding.svg).
- [Metadata admission and resolution](metadata-admission.d2) / [SVG](metadata-admission.svg).

- [Single-source legacy/typed output](single-source-dual-output.d2) / [SVG](single-source-dual-output.svg).
- [Native retirement gates](native-retirement-gates.d2) / [SVG](native-retirement-gates.svg).

- [Independent observation boundaries](independent-observation-boundaries.d2) / [SVG](independent-observation-boundaries.svg).
- [Caller retirement dependencies](native-caller-retirement-dependencies.d2) / [SVG](native-caller-retirement-dependencies.svg).

- [Darwin L1 recorder calibration](darwin-l1-calibration.d2) / [SVG](darwin-l1-calibration.svg).
- [Darwin L2 observation feasibility](darwin-l2-observation.d2) / [SVG](darwin-l2-observation.svg).

- [Darwin independent supplement paths](darwin-supplement-paths.d2) / [SVG](darwin-supplement-paths.svg).
- [Darwin evidence correlation and delivery](darwin-evidence-correlation.d2) / [SVG](darwin-evidence-correlation.svg).

- [External Darwin observer capabilities](darwin-external-observer.d2) / [SVG](darwin-external-observer.svg).
- [Darwin fd lifecycle and ES association](darwin-fd-es-association.d2) / [SVG](darwin-fd-es-association.svg).
- [Darwin DTrace ABI containment](darwin-dtrace-abi-boundary.d2) / [SVG](darwin-dtrace-abi-boundary.svg).
- [Darwin DTrace scope qualification](darwin-dtrace-scope.d2) / [SVG](darwin-dtrace-scope.svg).
- [Darwin consumer link/load profiles](darwin-consumer-link-load.d2) / [SVG](darwin-consumer-link-load.svg).
- [Darwin consumer callback/probe admission](darwin-consumer-probe-admission.d2) / [SVG](darwin-consumer-probe-admission.svg).

## Still Construction, Cross-GC Quota and Worker Tails

The [construction and interval design](still-construction-tail-design.md),
[source/paper ledger](still-construction-tail-evidence.md),
[matched support matrix](still-construction-tail-cost-matrix.md) and
[trace map](still-construction-tail-traceability.json) refine GCM04--08 and
GAL01--08. Known private storage consumes credit before scan publication;
refcount release is neither native free nor unused-credit refund. Held-cut
recount carries actual private/enrolled/detached blocks and unused promises
through the current ledger, including new prepared grants only once. Worker
tails transfer disjoint interval rights with explicit alignment, chunk/gap/run
layout, reserve and resume bindings; live prefixes remain VM-owned.

The [design-artifact record](../../../evidence/research/zig-native/theory-design-update-26.json)
binds 98 document trace units, 15 selected-source groups, 6 primary-reference
groups, 8 handwritten conditional arguments, 22 logical counterexamples and
three D2/SVG views. Ten support rows, six maintenance events and five net
conditions credit equal-capability modern C reuse before any Zig increment.
No implementation/native/model/engine execution, checked proof, registered
witness/relation, qualified worker, retired path or positive net bound is added.
All five full architecture questions remain unresolved.

## InitSpec Endpoints and SegmentLayout at the Next GC

The [constructor and next-collection design](init-spec-segment-layout-design.md),
[source/paper ledger](init-spec-segment-layout-evidence.md),
[16-family producer inventory](init-spec-constructor-inventory.json),
[modernization/net-benefit report matrix](init-spec-segment-layout-cost-matrix.md)
and [trace map](init-spec-segment-layout-traceability.json) refine
SCR03/04/06, SCI01--04 and STL03/04/06/07. Real fill/copy/encoding endpoints
are separate from allocator return and decref; the marker wrapper's source
root TODO remains open. Next GC follows actual roots into copied prefix and
context suffix, then scans new destination work; it does not root old runs.
Tentative check cursors, committed objects and used trigger reserve have distinct
layout/accounting states. Compiler 4096, runtime F and the inspected unused check
argument do not establish the complete target write bound.

The [design-artifact record](../../../evidence/research/zig-native/theory-design-update-27.json)
binds 108 document trace units, 18 source groups, 7 primary-reference groups,
8 handwritten conditional arguments, 24 logical counterexamples and three
D2/SVG views. Ten matched support rows, six maintenance events and five net
conditions credit generated modern C before Zig-specific savings. No producer/
worker qualification, implementation/native/model/engine execution, checked
proof, registered witness/relation, path retirement or positive net bound is
added. All five full architecture questions remain unresolved.

## Actual Allocation Bounds and a Genuine Scheme-to-Zig Backend

The [bound/metadata design](allocation-check-bound-design.md),
[Scheme-to-Zig architecture position](scheme-to-zig-architecture.md),
[source/paper ledger](allocation-check-bound-evidence.md),
[conditional case list](allocation-check-bound-cases.json),
[modernization report matrix](allocation-check-bound-cost-matrix.md) and
[trace map](allocation-check-bound-traceability.json) refine ACH01--07,
IOP03--08 and SLM03--07. The position is affirmative for a real Zig native
backend/system-service candidate, while full native/control admission and
positive economics remain separate gates. Tail-host and dispatch-host are
explicit alternative whole-cohort profiles; generated Zig and an isolated
MLIR/LLVM provider need not be serial compilation stages.

Bound contracts distinguish actual writes, formed addresses/provenance,
guard-sensitive excess, pending post-check work and actual sparse completion.
Selected no-handles source arithmetic supplies pair/box/vector and isolated
small-object bounds, not a universal B. Rest/key finish capacity and native
rebase/GC/error edges retain complete-root/continuation obligations.

The [design-artifact record](../../../evidence/research/zig-native/theory-design-update-28.json)
binds 101 document trace units, 14 source groups, 7 primary-reference groups,
10 conditional source cases, 8 handwritten arguments, 24 logical counterexamples
and three D2/SVG views. Ten matched support rows, six maintenance events and
five net conditions credit generated modern C/C-ZT before Zig-specific saving.
No implementation/native/model/engine/analyzer execution, checked proof, issued
bound certificate, admitted backend/worker, registered witness/relation, retired
path or positive net bound is added. All five full architecture questions remain
unresolved.

## A Real Scheme Function and the Modernization Decision

The [public reverse compilation design](scheme-function-zig-design.md),
[source/paper ledger](scheme-function-zig-evidence.md),
[conditional arguments and counterexamples](scheme-function-zig-arguments.md),
[matched report matrix](scheme-function-zig-cost-matrix.md),
[handwritten control cases](scheme-function-zig-cases.json) and
[trace map](scheme-function-zig-traceability.json) connect semantic completion,
local tail iteration, a selected whole-cohort dispatch protocol, post-cons
allocation checks, roots/GC reload and image/VM publication. The stored C
artifact supplies correspondence evidence, not newly reproduced output.

Gambit's modernization is explicit language/runtime contracts and replaceable
native products. Zig remains a candidate subject to equal-capability residual
net cost; modern C and an independent LLVM/MLIR provider remain valid carriers.
The [design record](../../../evidence/research/zig-native/theory-design-update-29.json)
binds this refinement without executing compiler/native/model/engine work or
accepting a positive economic gate. No architectural generation name is added.

## Higher-Order Map and a Fully Costed Modern C Alternative

The [real public map path](map-scheme-zig-design.md),
[source/paper ledger](map-scheme-zig-evidence.md),
[conditional arguments/refuters](map-scheme-zig-arguments.md),
[report matrix](map-scheme-zig-cost-matrix.md),
[unevaluated review cases](map-scheme-zig-cases.json) and
[trace map](map-scheme-zig-traceability.json) extend reverse to generic Scheme
closures, callback mutation, non-tail pending work, multi-shot continuation,
GC roots/reload and multi-list helper policy. Three D2/SVG views distinguish
semantic lowering, suspended control and complete candidate economics.

Modern C is a proposed reconstruction whose generator, services, integration
and delivery cost must be paid. Zig can realize the architecture directly;
no intermediate modern-C implementation is required. Compare C versus current,
Zig versus current and Zig versus fully costed C as separate ledgers.
The [design record](../../../evidence/research/zig-native/theory-design-update-30.json)
adds no implementation/native/model/engine execution, path retirement or accepted
economic gate, and introduces no architectural generation naming.

## Complete Native Reconstruction With Managed GC

The [full-layer candidate](zig-native-layer-reconstruction.md) and
[trace map](zig-native-layer-traceability.json) clarify that Gambit-owned native
implementation can migrate to Zig while Scheme retains automatic managed-heap
GC and a declared C-facing ecosystem. Collector implementation migration,
runtime-contract modernization and algorithm/generation/concurrency redesign
are distinct decisions. Chez and OCaml supply explicit GC reference designs;
no full collector/profile or positive economics is inferred. The
[design record](../../../evidence/research/zig-native/theory-design-update-31.json)
records this research-only extension and its D2 view.

## Current Collector and Complete Native GC Architecture

The [current-mechanism audit](gc-current-mechanism-audit.md) establishes the
selected source's nongenerational full movable copying, still mark/sweep and
parallel STW branches, with a separate materialized Darwin configuration
boundary. The [GC architecture](gc-native-runtime-design.md) joins allocation,
direct survivor promotion, stores/roots, continuation, FFI and phase closure in
a complete generational/multicore research candidate. Read its
[evidence ledger](gc-native-runtime-evidence.md),
[conditional arguments](gc-native-runtime-arguments.md),
[maintenance and benefit matrix](gc-native-runtime-cost-matrix.md),
[writer inventory](gc-native-store-inventory.json),
[unevaluated cases](gc-native-runtime-cases.json) and
[trace map](gc-native-runtime-traceability.json). Three D2/SVG views cover heap
domains, phases and benefit attribution. The
[design record](../../../evidence/research/zig-native/theory-design-update-32.json)
preserves the earlier records. This is source/document research only: no native
experiment, complete GC proof or accepted positive Zig net.

## Quantified Benefit and Language-Independent Modernization

The [quantified assessment](modernization-quantified-benefit.md) derives exact
conditional avoided payload-copy work, whole-program sensitivity thresholds and
Zig-versus-funded-modern-C budget thresholds. Its
[arithmetic ledger](modernization-benefit-arithmetic.json) uses explicitly
hypothetical inputs rather than timing or labor estimates. The
[modernization direction](gambit-modernization-direction.md) and D2/SVG separate
Gambit's required compiler/runtime architecture from the choice of C-G, C-ZT or
direct Zig realization. Read the [local trace](modernization-benefit-traceability.json)
and [design record](../../../evidence/research/zig-native/theory-design-update-33.json).
No native implementation/test, transferred OCaml speedup or accepted project-net
bound is claimed.

## Source-Informed Service Work and Modern C Reference

The [service design](native-service-support-design.md),
[cost and maintenance matrix](native-service-support-costs.md),
[WBS ledger](native-service-support-ledger.json) and
[trace](native-service-support-traceability.json) expand RootRegistry, BarrierLog
and ReleaseCoordinator to actual native callers, shared support and retirement
conditions. The scoped engineering estimate currently favors modern generated C;
source establishes required work while person-day ranges remain low-confidence
author estimates, not measured labor or a full-runtime bound. The
[design record](../../../evidence/research/zig-native/theory-design-update-34.json)
preserves the arithmetic/evidence boundary; no implementation or native test.

## Modern Generated C Native Contract Mainline

The [unified native contract](generated-c-native-contract.md) and
[Scheme generator](scheme-native-generator-design.md) choose Scheme semantic
completion/product planning and generated C as the mainline. RootRegistry,
BarrierLog and ReleaseCoordinator share typed products/native mechanisms while
retaining distinct policies. Read the [provider and retirement plan](generated-c-provider-retirement.md),
[cost scope matrix](generated-c-contract-cost-matrix.md),
[evidence](generated-c-contract-evidence.md),
[inert examples](generated-c-contract-samples.json) and
[local trace](generated-c-contract-traceability.json). Three D2/SVG views cover
providers, shared support and retirement. The
[design record](../../../evidence/research/zig-native/theory-design-update-35.json)
preserves prior estimates and evidence; there is no implementation/native test.

## Map as a Modernization Architecture Test

The [map-to-generated-C path](map-generated-c-design.md) connects actual public
map semantics to Scheme completion, FrameSpec/PointId, root/check/resume
products and whole-module binding. Read the [capability and runtime tradeoff
matrix](map-generated-c-modernization-matrix.md), [all stored return points](map-generated-c-points.md),
[conditional arguments](map-generated-c-proof-obligations.md),
[evidence](map-generated-c-evidence.md) and [trace](map-generated-c-traceability.json).
The decision criterion is substantive runtime/compiler modernization, following
the requirements discipline illustrated by OCaml, rather than human-day ROI.
Three D2/SVG views show provider flow, control/roots and module lifetime. No
implementation/native test or architectural version naming is introduced.

## Map Continuations and Generational GC

The [captured-map GC design](map-continuation-gc-design.md) studies lazy
stack-backed capture, mature materialization/promotion, real frame/denv mutation,
minor root closure, major value snapshots and repeated restoration under modern
generated C. Read the [learning/reflection](map-continuation-gc-learning.md),
[benefit and runtime-overhead matrix](map-continuation-gc-benefit-matrix.md),
[conditional arguments](map-continuation-gc-arguments.md),
[selected edge inventory](map-continuation-gc-edges.json),
[evidence](map-continuation-gc-evidence.md) and
[trace](map-continuation-gc-traceability.json). Three D2/SVG views cover lifecycle,
collector closure and benefit conditions. OCaml provides research mechanisms
and questions for Gambit-specific choices; no implementation/native experiment
or human-day value ranking is introduced.

## Captured Frame, Denv and Native Writer Closure

The [writer/caller closure design](continuation-writer-closure-design.md)
traces real frame mutation, reconstruction, dynamic parameter/cache writes,
scheduler root handoff and SFUN/CFUN/RC/marker paths. Read the
[caller matrix](continuation-writer-caller-matrix.md),
[edge-cut proof and counterexamples](continuation-minor-scan-proof.md),
[net-runtime benefit matrix](continuation-writer-benefit-matrix.md),
[evidence](continuation-writer-evidence.md),
[inventory](continuation-writer-callers.json) and
[trace](continuation-writer-traceability.json). Three D2/SVG views show aliased
graph writers, epoch publication and native callbacks. Learning from OCaml
exposes assumptions which are then evaluated against Gambit's own semantics.
No implementation/native tests, human-day value scoring or architecture
generation naming is introduced.


## Native Callback, Captured Map Continuation and Custody

The [callback study](native-callback-continuation-design.md) composes the real
public map call with the actual Tcl RC/vector/static-export callback path,
while keeping the combined capture/nesting history explicitly unexecuted.
The [custody protocol](native-callback-custody-contract.md) specifies root-cell
serialization, moving-cut/reload order, borrowed resource and copied-string
boundaries, nested markers, wait participation and nonlocal exit ledgers.
[Conditional arguments](native-callback-arguments.md),
[source/paper evidence](native-callback-evidence.md),
[net-benefit matrix](native-callback-benefit-matrix.md),
[caller inventory](native-callback-callers.json) and
[trace](native-callback-traceability.json) retain unresolved external/native
qualification. Three D2/SVG views distinguish actual callers, GC publication
and value. Native root scans and mature graph scans have separate cost terms;
zero safety-obligation families have been shown removable just by choosing Zig.
No implementation, native test, human-day score or full-gate promotion.


## Tcl Command Creation, Deletion and Library Cleanup

The [Tcl custody study](tcl-command-custody-design.md) follows actual widget
exports, registration/removal, callback/string release, setup/cleanup and the
active DoOneEvent Scheme thread. It distinguishes command structure lifetime
from client data, creation rejection from rollback, and root/marker custody
from Tcl cleanup bypassed by a raw jump.
[Conditional arguments and counterexamples](tcl-command-custody-arguments.md),
[modern C/Zig net-benefit matrix](tcl-command-custody-benefit-matrix.md),
[evidence](tcl-command-custody-evidence.md),
[external reading identities](tcl-command-external-readings.json),
[caller inventory](tcl-command-custody-callers.json) and
[trace](tcl-command-custody-traceability.json) accompany three D2/SVG diagrams.
Pre-dispatch library-scope grace, independent result-image leases and owner-thread
drain are proposed contracts. Unrestricted foreign escape and installed Tcl/Tk
source correspondence remain unresolved; no native run or implementation.


## Tcl Continuation, Wind and Result-Boundary Semantics

The [control-boundary study](tcl-control-boundary-design.md) distinguishes
native Gambit returning handlers, catcher grafts, dynamic-wind hooks and
C marker validity from explicit Tcl/host result policies.
[Conditional arguments and distinguishing traces](tcl-control-boundary-arguments.md),
[modern C/Zig value matrix](tcl-control-boundary-benefit-matrix.md),
[evidence](tcl-control-boundary-evidence.md),
[cases](tcl-control-boundary-cases.json),
[caller inventory](tcl-control-boundary-callers.json),
[external readings](tcl-control-external-readings.json) and
[trace](tcl-control-boundary-traceability.json) accompany three D2/SVG diagrams.
The study recognizes Tcl cancel-unwind as stronger than an ordinary catchable
error without equating it with Scheme transfer. Nested event delivery and
control-aware shutdown keep distinct acceptance/quiescence/disposal receipts.
No native run, universal foreign-control theorem or Zig-positive gate.

## Tcl Cancel-Unwind Propagation and Shutdown

The [cancellation propagation study](tcl-cancel-propagation-design.md) separates
host acceptance, pending async installation, bytecode/direct/NRE propagation,
route-specific reset and durable delivery. It distinguishes terminal interpreter
retirement from the stronger reusable-reset profile.
[Conditional arguments and 18 inert cases](tcl-cancel-propagation-arguments.md),
[modern C/Zig net-benefit matrix](tcl-cancel-propagation-benefit-matrix.md),
[source and paper evidence](tcl-cancel-propagation-evidence.md),
[operation inventory](tcl-cancel-propagation-callers.json),
[external readings](tcl-cancel-external-readings.json) and
[trace](tcl-cancel-propagation-traceability.json) accompany three D2/SVG diagrams.
Exact compiled Try lowering, direct-entry reuse reset, installed Tcl identity and
finite progress remain conditional or unresolved; no native test or implementation.

## Compiled Try and Interpreter Reuse

The [reuse study](tcl-interpreter-reuse-design.md) resolves the Try compiler
reading gap with 20 coherent pinned Tcl files and verified Git blob hashes. It
derives four actual compiler selections, direct Tcl_Eval/NOERR reset behavior
and a sealed old-epoch to next-evaluation barrier.
[Conditional proofs/cases](tcl-interpreter-reuse-arguments.md),
[modern C/Zig net-benefit matrix](tcl-interpreter-reuse-benefit-matrix.md),
[evidence](tcl-interpreter-reuse-evidence.md),
[source identities](tcl-reuse-source-bindings.json),
[caller inventory](tcl-interpreter-reuse-callers.json),
[cases](tcl-interpreter-reuse-cases.json) and
[trace](tcl-interpreter-reuse-traceability.json) accompany three D2/SVG diagrams.
Private reset access, installed-library correspondence, complete producer/async
closure and native admission remain separate unresolved predicates. No implementation
or native test; no architecture version names or labor-day criteria.

## TclReuseService Private Binding and Producer Closure

The [service study](tcl-reuse-service-design.md) traces real stub initialization,
private slot access, interpreter token lifecycle, builtin/fixture/native request
producers, notifier/timer consumers and parser reset. A pinned 350-file lexical
corpus distinguishes selected source closure from loaded Tk/plugin closure.
[Conditional proofs and cases](tcl-reuse-service-arguments.md),
[modern C/Zig value matrix](tcl-reuse-service-benefit-matrix.md),
[evidence](tcl-reuse-service-evidence.md),
[source bindings](tcl-reuse-service-source-bindings.json),
[corpus ledger](tcl-reuse-producer-corpus.json),
[caller inventory](tcl-reuse-service-callers.json),
[cases](tcl-reuse-service-cases.json) and
[trace](tcl-reuse-service-traceability.json) accompany three D2/SVG diagrams.
Six receipts and an exclusive ticket link binding, real owner idleness, pending
settlement, reset and next epoch. Targeted cancellation settlement is a new Tcl
integration candidate; no native profile, implementation or positive Zig gate.

## Targeted Tcl Cancellation Settlement

The [core settlement design](tcl-targeted-cancel-design.md) specifies token
identity, attributed marks, raw interference, list-order preservation, readiness
repair and a single reset/publication critical interval. It preserves raw idle
cancellation and marks full mixed-domain refinement unresolved.
[Conditional arguments and counterexamples](tcl-targeted-cancel-arguments.md),
[modern C/Zig matrix](tcl-targeted-cancel-benefit-matrix.md),
[source/paper evidence](tcl-targeted-cancel-evidence.md),
[source bindings](tcl-targeted-cancel-source-bindings.json),
[operation inventory](tcl-targeted-cancel-operations.json),
[inert cases](tcl-targeted-cancel-cases.json) and
[trace](tcl-targeted-cancel-traceability.json) accompany three D2/SVG diagrams.
No implementation, native tests, gate promotion or positive Zig increment.

## Mixed Cancellation History Discharge

The [mixed-history design](tcl-mixed-cancel-design.md) distinguishes pending
replacement, installed C/UNWIND and message provenance, destructive checks and
actual native return. RawHistoryDischargeReceipt can relax permanent taint only
for complete permitted histories, with real next-evaluation consumption for idle
requests. Early bytecode ERROR, empty direct evaluation, repeated installation
and filtered OK remain explicit refusal cases.
[Arguments](tcl-mixed-cancel-arguments.md),
[modern C/Zig matrix](tcl-mixed-cancel-benefit-matrix.md),
[evidence](tcl-mixed-cancel-evidence.md),
[source bindings](tcl-mixed-cancel-source-bindings.json),
[site inventory](tcl-mixed-cancel-site-inventory.json),
[operations](tcl-mixed-cancel-operations.json),
[inert cases](tcl-mixed-cancel-cases.json) and
[trace](tcl-mixed-cancel-traceability.json) accompany three D2/SVG diagrams.
No implementation/native test, full mixed-domain qualification or Zig-exclusive
positive benefit is claimed.

## Next Evaluation Identity and Consumption

The [next-evaluation design](tcl-next-evaluation-design.md) separates reservations,
actual target-specific entries, forwarding/command steps, nested script attempts
and NRE/coroutine lifetimes. Natural callback scripts may win first; empty
attempts cannot be hidden. Identity, observation, consumption and raw neutrality
are separate facts. [Arguments](tcl-next-evaluation-arguments.md) include both
conditional positive source controls and refusal cases;
[the modern C/Zig matrix](tcl-next-evaluation-benefit-matrix.md) charges ten shared
support families. [Evidence](tcl-next-evaluation-evidence.md),
[source bindings](tcl-next-evaluation-source-bindings.json),
[bounded sites](tcl-next-evaluation-site-inventory.json),
[operations](tcl-next-evaluation-operations.json),
[inert cases](tcl-next-evaluation-cases.json) and
[trace](tcl-next-evaluation-traceability.json) accompany three D2/SVG diagrams.
Uniform entry/return normalization is a separate changed-contract candidate, not
a source-equivalence or native admission claim.

## Unified Entry Gate and Completion Guard

The [gate/guard contract](tcl-entry-cancel-design.md) specifies source-preserving,
ordered-entry and cancellation-first policies; C-serialized entry permits;
callout-free publish/install; active-aware readiness; early durable guards;
actual native/logical completion; and generation-owned clearing.
[Arguments/cases](tcl-entry-cancel-arguments.md) distinguish preserved dispatch
rules from changed timing/priority and expose why a final guard cannot repair
unqualified earlier resets. [The modern C/Zig matrix](tcl-entry-cancel-benefit-matrix.md)
charges twelve shared support families. [Evidence](tcl-entry-cancel-evidence.md),
[source bindings](tcl-entry-cancel-source-bindings.json),
[bounded sites](tcl-entry-cancel-site-inventory.json),
[operations](tcl-entry-cancel-operations.json),
[inert cases](tcl-entry-cancel-cases.json) and
[trace](tcl-entry-cancel-traceability.json) accompany three D2/SVG diagrams.
No implementation/native test, policy qualification or exclusive positive Zig
benefit is claimed.

## Cancellation Writer Closure

The [writer/immutable-payload design](tcl-cancel-writer-design.md) rereads all 350 selected pinned C/H/M blobs and exposes trace whole-word flag restoration alongside named reset paths. [Arguments and inert cases](tcl-cancel-writer-arguments.md) distinguish source-point clearing from normalized completion and give explicit preparation/publication/reclamation custody. The [modern C/Zig matrix](tcl-cancel-writer-benefit-matrix.md) charges thirteen shared support families, eight conditional replacement bundles and zero completed or Zig-exclusive retirements. [Evidence](tcl-cancel-writer-evidence.md), [source bindings](tcl-cancel-writer-source-bindings.json), [corpus](tcl-cancel-writer-corpus.json), [flag audit](tcl-cancel-writer-flag-audit.json), [operations](tcl-cancel-writer-operations.json), [cases](tcl-cancel-writer-cases.json) and [trace](tcl-cancel-writer-traceability.json) accompany three D2/SVG diagrams. This is design-only; no native/prover/model execution or provider admission.

## Trace State Separation and Completion Handoff

The [trace/cancellation design](tcl-trace-cancel-design.md) separates whole-word snapshots from a single cancellation authority while preserving distinct nested recursion controls, source points, result folding and actual dispatcher lifetimes. [Arguments and inert cases](tcl-trace-cancel-arguments.md) distinguish algebraic bit histories, source-composed reachability candidates and unexecuted upstream fixtures. The [modern C/Zig matrix](tcl-trace-cancel-benefit-matrix.md), [evidence](tcl-trace-cancel-evidence.md), [source ledger](tcl-trace-cancel-source-bindings.json), [site inventory](tcl-trace-cancel-site-inventory.json), [operations](tcl-trace-cancel-operations.json), [cases](tcl-trace-cancel-cases.json) and [trace](tcl-trace-cancel-traceability.json) accompany three D2/SVG diagrams. SourceSnapshot and SeparatedCancellation have explicit different semantics; no implementation, native test, full qualification or exclusive positive Zig benefit.

## Same-Command Reentry and UNWIND Reachability

The [reachability study](tcl-trace-reachability-design.md) closes a fixed same-command independent-record public-source construction, derives exact conditional callback work, and proves a restricted positive-depth U invariant. A depth-zero private bracket path is body-closed but its actual caller/support remains unresolved; generic force hooks remain unqualified. [Arguments](tcl-trace-reachability-arguments.md), [matrix](tcl-trace-reachability-benefit-matrix.md), [evidence](tcl-trace-reachability-evidence.md), [ledger](tcl-trace-reachability-source-bindings.json), [sites](tcl-trace-reachability-site-inventory.json), [operations](tcl-trace-reachability-operations.json), [cases](tcl-trace-reachability-cases.json) and [trace](tcl-trace-reachability-traceability.json) accompany three D2/SVG diagrams. Source research only; no implementation/native test or provider admission.

## Private Entry and Coroutine Admission

The [private-entry/coroutine study](tcl-private-coro-design.md) distinguishes unsupported private table access from actual caller admission, derives coroutine depth/cleanup phases, and refines completion custody. See its [arguments](tcl-private-coro-arguments.md), [evidence](tcl-private-coro-evidence.md), [matrix](tcl-private-coro-benefit-matrix.md) and [trace](tcl-private-coro-traceability.json). Private depth-zero dispatch and legal force-reset-hook producer closure remain unresolved; no implementation or native tests.

## Coroutine Debt, Environment Pairing and Reuse

The [coroutine-invariant study](tcl-coro-invariants-design.md) separates credited/deferred depth, root debt, affine aux updates, two yieldto emitters and direct rewind without ordinary command credit. Its [arguments](tcl-coro-invariants-arguments.md), [source evidence](tcl-coro-invariants-evidence.md), [matrix](tcl-coro-invariants-benefit-matrix.md) and [trace](tcl-coro-invariants-traceability.json) define conditional reuse receipts while retaining all-history producer, pairing and liveness gaps. Design/source research only; no implementation or native tests.
