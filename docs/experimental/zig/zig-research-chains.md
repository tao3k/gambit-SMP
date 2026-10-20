# Zig Research in the Existing Scheme DSL and ASCENT

Date: 2026-10-20. Research assets, not a Zig backend implementation. The user
requested a queryable research/reasoning/feasibility/evidence chain in addition
to prose. This adds a downstream evidence scenario using the installed Library;
it does not modify Python inference, ASCENT runtime, Gambit or toolchains.

## 1. Assets and Authority

- [research.ss](../../../evidence/scenarios/zig-native/research.ss): caller-owned
  Scheme relation declarations and rules evaluated by the existing ASCENT engine.
- [research.view.json](../../../evidence/scenarios/zig-native/research.view.json):
  source-bound research facts, citations, dependencies, requirements, roles,
  operations and benefit targets; explicit current references with SHA-256.
- [components.json](../../../evidence/scenarios/zig-native/components.json):
  normal Evidence component registration; no new backend/service installation.
- [clues.ss](../../../evidence/scenarios/zig-native/clues.ss): explicit selector
  for this domain. The other research lane's default selector remains unchanged.
- [evidence/views.json](../../../evidence/views.json): append this scenario to
  existing current views; preserve historical views and concurrent registrations.

The detailed Markdown contracts remain human-reviewed semantic design documents.
The DSL is the queryable research index and dependency model, not an executable
compiler ABI specification. Its summary relations are derived; prose is not
yet generated automatically from the DSL. A source correspondence is a reviewed
claim tied to exact bytes, not a theorem inferred merely from a file hash.

![Source, inference and unresolved research frontier](zig-research-chains.svg)
[D2 source](zig-research-chains.d2).

## 2. Four Chains Plus Cost Accounting

| Chain | Explicit relations / meaning | Boundary |
| --- | --- | --- |
| Research | claim(id, kind, statement), role, operation, expected_item | Catalogue source facts, proposals, feasibility questions, retirement conditions and benefit targets without making them interchangeable |
| Reasoning | depends(child, parent, edge_kind), dependency_path(child, ancestor) | Recursive finite closure over declared edges; it does not discover every missing real-world premise |
| Evidence | source, citation, observation, evidence_path | Join a claim to exact source/hash/anchor/finding; missing references fail loading or produce unbound diagnostics in controlled withdrawal |
| Feasibility | requirement(id, evidence_class, description), requires, witness, missing_requirement, blocked | Match witness class exactly; static-source evidence cannot fill native-ABI, native-semantic or measured-cost obligations; propagate open premises through dependencies |
| Benefit / maintenance | benefit-target claims with metric attributes and explicit cost requirements | Structural targets and prospective work removed are distinct from observed work counts or net speedup |

`traceable` means a claim has bound source support and no declared unbound
reference; it deliberately does **not** mean feasible, proved, completed or
ready to retire. A traceable proposal can have many blocked requirements.
`unbound` detects missing citations, sources, dependency claims, requirement
definitions, expected role/operation rows and conflicting role contracts.
`blocked` tracks missing declared requirements through dependency edges.
No rule emits `satisfies`, native-ready, retired, speedup or execution authority.

The initial domain indexes SDC01-SDC20, OP01-OP24, R01-R15, H01-H10 and selected
structural/cost targets. It connects these to the existing HostGraph/FrameSpec
architecture. It does not pretend to have fully backfilled all earlier Zig
papers, Darwin observation studies, M1-M12 configuration rows or Q01-Q18 measures.
Their documents remain linked context; later chain expansion must bind their
actual premises and sources rather than infer completeness from directory size.

## 3. Read the Actual Registered Relations

From the research checkout, this uses existing read-only Evidence evaluation:

```python
from pathlib import Path
from gambit_smp import engine_api, repository_clues
from gambit_smp.evidence_views import evaluate

with engine_api() as (engine, identity):
    packet = evaluate(Path('.'),
        'evidence/scenarios/zig-native/research.view.json', engine)
    # Named rows retain source paths, hashes and anchors.
    roles = packet['answers']['role_contract']
    open_requirements = packet['answers']['missing_requirement']
    blocked_claims = packet['answers']['blocked']

selector = Path('evidence/scenarios/zig-native/clues.ss').read_text()
slice = repository_clues(selector=selector,
    bindings=[('claim', 'zig.G3')], display_bytes=8192)
# Reuse slice['checkpoint'] on later reads; source changes invalidate identity.
```

Use entity=`zig-gambit` with this explicit selector for the whole domain, or an
exact claim such as `zig.role.R15`, `zig.feasibility`, `zig.retirement.H10` or
`zig.benefit.net-cost`. Increasing display capacity is not stronger inference;
deferred evidence retains its existing expandable references.

Reference changes are not silently blessed. The existing loader rejects
stale hashes. A later source revision requires reviewing affected anchors and
premises, recording the new identity and rerunning research queries. Historical
runtime failures/receipts remain untouched and cannot be promoted by updating
this view. A paper node will need its own source/claim/scope correspondence;
a paper's result cannot become a Gambit-native witness by sharing a keyword.

## 4. Scope of Consistency Checks

Appropriate checks are research-DSL checks: load the real component, inspect
role/operation coverage and recursive dependencies, withdraw a cited source or
required item, and try a wrong evidence class. They test this downstream query
model and source binding. They do not run G3, compile generated hosts, verify a
collector or measure runtime/compiler performance. Detailed check outcomes are
recorded only after the actual query calls complete.

## 5. Observed Operation/Role Baseline Results

The real installed engine evaluated the registered downstream component on
2026-10-20. The [operation/role baseline observation](../../../evidence/research/zig-native/dsl-query-observation-03.json)
binds component/view/source hashes and the engine identity digest. It reports:

| Relation | Observed rows / interpretation |
| --- | --- |
| traceable | 79 source-bound research nodes; not 79 feasible or qualified results |
| evidence_path | 96 claim/citation paths, including separately identified retained-overlay signatures |
| role_contract / operation_contract | 15 / 24, matching the explicit expected-item domain |
| dependency_path | 1,217 derived ancestor pairs over declared edges; no claim that the graph contains all real premises |
| missing_requirement | 12 open requirements; only the static source-binding requirement has a matching witness |
| blocked | 257 claim/requirement pairs, including per-role and propagated operation/retirement gaps |
| unbound | 0 in the original declared dataset; this is reference integrity, not root/native correctness |

Seven checks completed with their expected research results: original facts,
withdrawn kernel source, omitted R15 row, static-source witness offered for
native C-tail evidence, missing G3 claim, conflicting R15 anchor, and restored
original facts. Mutations were in-memory controls only. Missing source/item/
dependency and conflicting anchor diagnostics propagated; the wrong witness
class left the native requirement open. Restoring facts recovered the original
answers. No collector/VM/compiler workload was run.

The [registered Clue read](../../../evidence/research/zig-native/registered-clue-read.json)
selected exactly `zig.role.R15`, completed evaluation/presentation, and exposed
its open `Q-denv` premise. Both runtimeAdmitted and executionAuthorized remained
false. This exercises the existing shared read interface, not just a standalone
fixture of the new rules.

The [initial observation](../../../evidence/research/zig-native/dsl-query-observation.json)
and [overlay-signature refinement](../../../evidence/research/zig-native/dsl-query-observation-02.json)
are retained with their original input identities. Their earlier dependency
counts are historical research stages, not the final graph or native receipts.
Updating the model did not relabel those observations.

## 6. Anchor / Reserve / Helper Research Extension

The next source study adds [AP01-AP09 preservation obligations](gvm-anchor-preservation.md)
and [HE01-HE09 helper contracts with separate reserve quantities](allocation-reserve-helper-contract.md),
supported by [AR01-AR14](completion-admission-evidence.md). New exact references
include `_gvm.scm`, `_t-c-1.scm` and `mem.h`. Primary upstream specification
notes explicitly remain rolling web observations, not pinned LLVM binaries.

The [new query observation](../../../evidence/research/zig-native/dsl-query-observation-04.json)
reports 116 traceable research nodes, 139 evidence paths, 1,933 declared-ancestor
pairs, 289 blocked claim/requirement pairs, and zero unbound references in the
original declared dataset. The 15 role and 24 operation inventories remain.
Three new **static-source** audit premises have matching source witnesses;
Q-anchor, Q-reserve and Q-helper retain their stronger classes and remain open.
There are 13 open requirements globally: the earlier 12 plus one for a deferred
argument-root-window alternative. That optional alternative does not block the
selected `zig.feasibility` chain.

`reserve_equations` and `reserve_gap` are now actual Scheme/ASCENT-derived
relations. They check the conditional no-handles inputs/candidate arithmetic
and report the loose finish-bound comparison; they never supply a native
headroom witness. Observed equation row:

```text
(ordinary-no-handles-word8-conditional
  compiler_policy=4096 local_fudge=8194 vm_reserve=204808
  loose_finish=25601 word_bytes=8)
```

Eight research checks completed as expected: baseline, withdrawal of GVM
source, omission of AP07 final-scheduling contract, incorrect finish arithmetic,
static equations offered as native reserve evidence, direct helper source
offered as closure validation, withdrawal of memory-parameter source, and
restored original facts. Missing source/ordering and arithmetic diagnostics
propagated; stronger validation requirements did not disappear.

The first arithmetic declaration was rejected with `operator arity`. Its
[attempt record](../../../evidence/research/zig-native/completion-query-attempt-01.json)
and [original declaration](../../../evidence/research/zig-native/research-arithmetic-arity-attempt.ss)
are retained. Rewriting the arithmetic into equivalent binary expressions
resolved construction; the later actual query and controls produced the new
observation. The rejected construction was not counted as a passing control
or native counterexample.

The [registered completion Clue read](../../../evidence/research/zig-native/registered-completion-clue-read.json)
selected `zig.reserve-contract`, completed evaluation/presentation and retained
Q-reserve as unresolved. Runtime and execution admission remained false. Three
new D2 diagrams were rendered and visually inspected. No G3/backend/collector
implementation or runtime/performance workload was executed.

## 7. Durable Adoption Questions and Contrary Considerations

The [VQ01-VQ12 register](zig-adoption-value-questions.md) brings the chain back
to the investment decision: demand, Gambit's retained strengths, hidden C
authority, Zig versus the same refactor in C, LLVM/MLIR leverage, generated-C
work, Darwin startup, foreign protocols, GC/VMs, upgrades, retirement and net
long-term value. The [new evidence ledger](zig-adoption-value-evidence.md)
separates current source, historical patch observations, primary reading notes
and absent demand/comparative-cost evidence. Failed paper access stays explicit.

New declared inputs are `value_question`, `consideration`, `alternative`,
`value_review` and `value_metric`. Outputs are:

| Relation | Actual scope |
| --- | --- |
| question_record | Human-reviewed question, decision scope, status, next research action, reopen trigger and reversal condition |
| question_evidence | Supporting or limiting consideration joined to exact local source/hash/anchor/finding |
| question_alternative / question_metric | Explicit alternative and existing Q01-Q18 measure/comparator links; no score or automatic preference |
| question_gap | Missing declared question/review/alternative/metric/evidence correspondence, invalid stance, empty review field or conflicting review |
| question_open_premise | Declared missing evidence requirements by their existing evidence classes |

Consideration links also appear in Clue lineage as `supports` or `limits`.
They are deliberately separate from prerequisite `depends`: limiting evidence
and alternative implementations do not become mandatory implementation gates.
One source may support an architectural opportunity while limiting attribution
to Zig. The `support` polarity on a question observation records that its design
record exists; it does not assert a positive answer to its literal question.

The [actual question-query observation](../../../evidence/research/zig-native/dsl-query-observation-05.json)
binds the revised component/view and all cited local inputs. It records 12
question records, 53 consideration/source paths, 12 alternatives, 51 metric
links, 25 question/open-premise pairs and zero declared question gaps. There
are 15 globally missing evidence requirements, including new workload-demand
and comparative-engineering classes. No source or literature witness closes
these. The broader dataset has 146 traceable records and 169 evidence paths;
these counts measure index coverage, not value, necessity or native readiness.

Nine actual research controls completed as expected: baseline, removal of
VQ04's limiting evidence, removal of its alternative, removal of VQ12's review,
withdrawal of the reviewed literature-note source, static-source evidence
offered to the comparative-engineering requirement, conflicting VQ12 review,
removal of the declared VQ09 record, and restoration of the original facts.
Missing/contradictory record diagnostics appeared and the wrong witness class
left the value premise open. These are in-memory research controls, not tests
of a compiler, collector, FFI implementation or speed claim.

The [registered value Clue read](../../../evidence/research/zig-native/registered-value-clue-read.json)
continues the earlier checkpoint, selects `zig.value.VQ04`, and shows both
supporting and limiting links, B1 as an alternative, metric links, reversal
conditions and the unresolved `Q-zig-increment`. Evaluation and presentation
completed; runtimeAdmitted and executionAuthorized stayed false. The new D2
diagram was rendered and visually inspected. Earlier receipts keep their
original identities and do not become observations of this revised dataset.

Example after normal registered evaluation:

```python
questions = packet['answers']['question_record']
zig_evidence = [row for row in packet['answers']['question_evidence']
                if row[0] == 'VQ04']
zig_open = [row for row in packet['answers']['question_open_premise']
            if row[0] == 'VQ04']
```

No rule derives `adopt`, `worthwhile`, `retired` or a benefit amount. Review
status remains caller-authored and can be revised with contrary evidence.
Integrity checks cover the declared schema, not every possible malformed
record or every missing real-world premise. Future updates must re-review
changed references and preserve prior query observations.

## 8. ForeignPlan and Actual Kernel Consumers

The [ForeignPlan contract](foreign-plan-contract.md),
[source map](foreign-plan-evidence.md) and
[C/Zig/provider engineering comparison](foreign-plan-engineering-comparison.md)
now bind 18 selected responsibility families, FS01-FS18. New inputs
`foreign_surface` and `foreign_anchor` declare semantic/product ownership and
producer/consumer citations. Derived `foreign_contract`,
`foreign_correspondence` and `foreign_gap` expose the map and missing or
conflicting declared records. Family gaps propagate through claim-item and
source-premise dependencies into the affected value questions.

The source findings locate three information/ownership losses: cleared type
registries, changed c-intf-procs element meaning and vector-clearing as emission
acknowledgement. Other findings bind stable Scheme-object-first wrapper setup,
allocating result conversion, invalidation-before-release and per-edge
nonlocal-control containment. These are source observations/design inferences,
not an implemented converter/adapter or reproduced native failure.

The [first ForeignPlan observation](../../../evidence/research/zig-native/dsl-query-observation-06.json)
records the 18-family/47-anchor map and ten actual research controls. Its
[registered Clue read](../../../evidence/research/zig-native/registered-foreign-clue-read.json)
selects `zig.foreign.plan` and exposes five open requirements, including
source-site completeness, plan correspondence and native control containment.
That observation predates the three kernel-use additions and retains its exact
input identities.

The [current kernel-use observation](../../../evidence/research/zig-native/dsl-query-observation-07.json)
adds KU01-KU03: released-state query, release/error delivery and a real body-form
c-lambda returning an address through size_t/U64 conversion. There are exactly
three literal foreign source occurrences in the stated kernel interval. Their
transitive call/expansion/input closure and usage frequencies remain unknown.
No new native capability or complete application-site denominator is inferred.

| Current relation | Observed scope |
| --- | --- |
| foreign_contract / foreign_correspondence / foreign_gap | 18 families / 47 source-role rows / zero declared correspondence gaps |
| question_record / question_evidence / question_gap | 12 reviewed questions / 96 consideration-source paths / zero declared question gaps |
| traceable / evidence_path | 177 indexed records / 231 source paths, not feasibility or value counts |
| missing_requirement | 18 globally open evidence obligations; no new native, site-completeness or cost witness |
| role_contract / operation_contract | Existing 15 runtime roles / 24 semantic completion operations preserved |

The current eleven research controls cover baseline, omitted emission-owner
family, omitted conversion-order producer, withdrawn parser source, omitted
matching-catcher consumers, conflicting control owner, wrong-class witnesses
for native control and complete site census, withdrawn VQ08 limiting evidence,
withdrawn runtime-converter source, and restoration. Diagnostics and dependency
propagation matched expectations; the wrong evidence classes left their
requirements open. Removing runtime converters also removes KU03 traceability
despite its remaining kernel citation. Restoring facts restores the answers.

The [current registered kernel Clue read](../../../evidence/research/zig-native/registered-foreign-kernel-clue-read.json)
continues the prior checkpoint and selects KU03 with source observations and
the scalar-conversion dependency. Runtime and execution admission remain
false. Two D2 diagrams were rendered and visually inspected. No compiler,
FFI/native adapter, collector or performance workload was executed.

Reviewed additions to previously bound documents are recorded as explicit old
and new hashes in each observation; previous receipts are not rewritten. This
source slice advances VQ03/VQ08. VQ04 stays conditional and VQ01/VQ12 stay
unresolved: comparative engineering cost and actual demand remain separate
requirements from the size of the source map.

## 9. Theory Is a Separate Obligation Before Empirical Work

The [theoretical net-benefit argument](theoretical-net-benefit.md) now separates
source correspondence, theoretical benefit, scoped empirical falsification and
implementation/adoption qualification. TB01-TB06 state six mechanisms with
removed/added work, same-capability alternatives and explicit positive-domain
conditions. A conditional sign equation is not itself a justified positive
bound. Shared modernization gains are excluded from the Zig-over-B1 increment.

The index adds `conditional-theoretical-case` and
`theoretical-decision-obligation` claims, plus two `architecture-argument`
requirements: Q-theory-architecture-net and Q-theory-zig-increment. Neither has
a witness. `zig.decision.zig-small-test` depends on those theoretical obligations;
the record grants no execution authority. These dependencies deliberately do
not require completed native tests before a theory argument can be reviewed.
Native-semantic and measured-cost requirements remain independent later duties.

This revision changes declarations only. It does not run the ASCENT engine or
native small tests, and does not reuse the previous query's counts as if they
described the changed view. Observation 07 is the latest evaluated historical
snapshot. The [theory design-update record](../../../evidence/research/zig-native/theory-design-update-01.json)
binds the new declarations and sources and explicitly records engineEvaluated,
empiricalTestExecuted and theoreticalGateAccepted as false. Static reference
integrity or diagram rendering cannot supply a net-benefit witness.

VQ04/VQ12 now prioritize a defensible theoretical positive case before small
empirical tests. The architecture mechanisms are source-grounded; their full
net signs and especially Zig's incremental positive bound remain open. Future
test observations must address named falsifiable premises in separate records,
without promoting theoretical assumptions to observed outcomes.

## 10. Same-Capability Modern-C / Zig Differential Argument

The [paired comparison](zig-vs-modern-c-net-benefit.md) and
[source/primary evidence](zig-vs-modern-c-evidence.md) refine the previously open
TB06. BC01-BC08 give C a serious generated/opaque/allocator/diagnostic design;
ZC01-ZC08 identify mechanisms, added costs, sign conditions and counterexamples.
PC01/PC02 make private product and ordinary resource relations concrete.
L1/L2 are bounded theoretical deductions, not native or measured results.

New indexed records distinguish the comparator design, four bounded mechanism
candidates, neutral/shared/rejected attribution, local obligation-transfer
deductions, and the remaining cost certificate. TG4/TG5 are explicit
architecture-argument requirements: Q-zig-support-retirement and
Q-zig-cost-domain. Neither has a witness. Their scope is theoretical design
closure, not inspection of an implementation that does not exist. No native or
measured-cost requirement is silently weakened to satisfy them.

The strongest candidate scope is ordinary-return private native product/layout/
resource code. Generic C access, LLVM reuse, no-GC/multicore promises and build
slogans do not independently establish a Zig increment. The paired designs
retain the same logical owners and semantic obligations; any saving must be
identified inside their support implementation and charged against the full
language/control/provider burden.

The [second theory design-update record](../../../evidence/research/zig-native/theory-design-update-02.json)
binds the revised source declarations, the reviewed update to the earlier theory
document, and the prior design record. No ASCENT execution or native small test
occurs in this refinement. Observation 07 remains the last evaluated historical
dataset; none of its counts are presented as an evaluation of these declarations.
The theoretical gate remains not passed, now narrowed to a concrete support-
retirement and cost-domain certificate rather than generic unknown benefit.

## 11. Source-Grounded Support Retirement and Change Events

The [support/change certificate](native-support-change-certificate.md) follows
G09-G14 from Scheme label producers to C descriptor/table construction and
the proposed shared physical planner. It separates R-old route replacement,
R-support prospective support avoidance and R-work maintenance reduction.

SC-ADT-C is a named prospective project association-support family. In the
specified resident LP-C/LP-Z pair, typed Zig construction and payload capture
make that implementation unnecessary while semantic, layout, lifetime, ABI and
version obligations remain. The LP-stream counterdesign may avoid the same
family in C. A consumer matrix does not establish native source-variant
residency as necessary; this absence of established demand is a bounded finding,
not a complete qualification of streaming for all backends.

E01-E09 record changes and retained responsibilities. Stable C generator output
is not independently maintained per field/variant; shared C cleanup need not
change per failure return. TG4 therefore has a scoped constructive mechanism
result, without unconditional necessity or actual existing-code retirement.
TG5 has no robust positive lower bound across current alternatives. Neither
open architecture requirement receives a witness.

The source/declaration update adds these findings, a separate residency-demand
question and the streaming alternative to the existing scenario. The optional
resident topology is a consideration, not a mandatory prerequisite of every
Zig use. The [third theory design-update record](../../../evidence/research/zig-native/theory-design-update-03.json)
preserves the previous input hashes and records each reviewed rebind. Observation
07 remains historical; no engine execution, native test or implementation is
performed. Static reference/link checks and diagram rendering are document
integrity checks only.

## 12. Reusable Support, Handoff and the Label-Slice Decision

The [reuse/handoff design](native-support-reuse-and-handoff.md) and
[source/primary ledger](native-support-reuse-evidence.md) add SR01-SR10,
HT1-HT4, a proposed ownership/failure state machine and successful-protocol
crossing counts. Existing Scheme vector/ordered-table/queue support is retained;
no existing C ADT generator is inferred from Scheme accessors. A dense-ID
snapshot refinement can avoid a duplicate native identity map without removing
reference validation, sparse/cross-module resolvers or runtime identity rules.

Language, native representation and deployment/transport are independent design
choices. C/HT1 versus Zig/HT3 is not a language-only comparison. The narrowed
direction is immutable revision-bound batch/snapshot input, one common physical
planner and an explicit service facade hiding native container/library types.
The facade's converters, statuses, lifetime and GC/control participation still
need design/native admission. No unsafe borrow or long blocking call is admitted.

The label slice alone is insufficient to justify Zig adoption. This limiting
finding is now indexed separately from the larger open net-benefit question.
The next value argument must identify support that remains necessary after
shared simplification, rather than recalculate optional tag helpers, duplicate
identity maps or shared transport savings. Version-specific allocator/container,
C translation, I/O and provider boundaries are charged only where selected.

The [fourth theory design-update record](../../../evidence/research/zig-native/theory-design-update-04.json)
binds these declarations, reviewed source references and the prior design record.
No architecture/native requirement receives a witness, no existing caller is
retired, and TG5 is not passed. Observation 07 remains the last evaluated
historical dataset. This update runs static integrity checks and diagram
rendering only, without ASCENT execution, implementation or native experiments.

## 13. Necessary Layout, Product and Provider Duties

The [layout/provider design](native-layout-provider-design.md) and
[evidence ledger](native-layout-provider-evidence.md) cover the work remaining
after the label/support simplifications. LD1-LD4 separate service-host storage,
target C ABI, Gambit frame/object/GC formats and OS object format. NP01-NP12
name retained project authority and candidate upstream delegation. One physical
DescriptorDecision supplies C/native outputs and count/placement consumers;
shared producer identity still does not replace an independent runtime decoder.

New primary notes establish specific interfaces: LLVM 21.1 TargetData and object
emission APIs, explicit musttail kind through C, current MLIR-to-LLVM C-facing
translation, and Zig 0.15.1 CLI recognition of LLVM IR/bitcode. These reading
identities are not a qualified combined provider version or an installed tool.
Direct LLVM, MLIR-plus-LLVM and an external driver are independent options for
a C or Zig planner. An external Zig tool does not require a Zig-written planner.

Custom MLIR dialect/pass support is charged separately. Stock services, ODS/C++
and IRDL have different supported scopes; generic operation construction is
not a rewrite/effect/continuation proof. BG and BH remain separate semantic
windows. Gambit object/global/primitive fixups and code lifetime are not
replaced by OS relocations alone.

The narrowed result is a concrete provider delegation architecture, without a
positive Zig-language increment established for these components. The existing
TG4/TG5 requirements receive no witness. Three static descriptor-predicate
call sites are not three maintained algorithms; one packaging source site is
not an executed compiler-process count. These limits are represented in the
source declarations, not deferred to a misleading small timing experiment.

The [fifth theory design-update record](../../../evidence/research/zig-native/theory-design-update-05.json)
binds the new design, source/primary notes and reviewed prior-link update.
Observation 07 remains the last evaluated historical dataset. No ASCENT run,
implementation, native experiment, performance result or retirement occurs.

## 14. Necessary Planner / Facade Support and Maintenance

The [paired support-cost study](planner-facade-support-cost.md) and
[evidence ledger](planner-facade-support-evidence.md) refine NP02/NP06/NP11
inside the necessary planner/service facade. PS01-PS10 distinguish primitive
arithmetic, units, result association, propagation, growth, ownership,
diagnostics, C API normalization, state legality and independent/version work.
C-G credits qualified compiler builtins; C-ZT uses the same selected Zig
external driver, so common driver costs cannot be charged twice.

The source-specific failure case is independently indexed: LLVM 21.1
TargetMachineC.cpp sets module layout before a possible failure and assigns the
memory output independently of status. A raw adapter must adopt all returned
owned outputs before propagation and cannot infer unchanged retry state. Zig
scope cleanup reduces expression work only after preserving that law. The
six provider resource kinds and public Diagnostic/status protocol remain in
both designs; fatal/nonreturning paths are not made recoverable by the proposal.

CE01-CE09 connect changes to retained and differential support. Candidate
private association, checked primitive and growth support are conditional;
propagation wiring is not proof of a mandatory C helper library. The existing
SC-ADT-C identity prevents product/results double counting. A conditional
positive domain and a fixed-width/reusable-C small-shim countermodel are
theoretical deductions, not chosen cost estimates or native observations.

The [sixth theory design-update record](../../../evidence/research/zig-native/theory-design-update-06.json)
binds these declarations, the prior record, exact local source identities and
the reviewed link update. Existing TG4/TG5 and native provider/control gates
receive no witness. Observation 07 remains the last evaluated historical
dataset. No implementation, research-engine run, native test or performance
validation occurs; only document/reference integrity and diagram rendering
are checked.

## 15. Selected RFD Component and Multi-Dimensional Report

The [RFD case](return-frame-planner-case.md),
[eighteen-row benefit report](return-frame-benefit-matrix.md) and
[source ledger](return-frame-planner-evidence.md) select actual return-frame
metadata production required by the existing scanner. C-G/C-ZT/Zig share one
homogeneous exact-sized chunk algorithm. The current Scheme producer already
uses physical alignment to build roots, so logical/physical extraction is a
real shared prerequisite. Native scalar helpers alone cannot close it.

RF01-RF07 distinguish selected old reconstruction calls from global helper
deletion, retained root laws and runtime consumers. Bounded source inspection
finds CFUN all-live/alignment uses that prevent ordinary-return migration from
claiming global retirement. The 32-based inline-capacity formula and variable
map length are explicit protocol requirements, not host word-size inference.

BM01-BM18 cover semantics, retirement, support, local expression, work/memory,
macro compilation, build/cache, FFI, GC/VMs, historical startup, portability,
LLVM upgrades and maintenance/net value. Statuses distinguish shared mechanism,
local conditional benefit, no credit, unknown magnitude and added/substituted
work. They are not a weighted score or a count-based adoption rule. C-ZT's
downstream Zig driver is outside RFD and its actually common costs cancel.

The concrete result narrows prospective PS01/PS03/PS05 credit: the chosen
checked C topology needs no generic growth/visitor/native-bignum support to
retire. Private expression/review work could differ, but no defensible positive
bound exists. The component has justified reconstruction duties, not a
demonstrated Zig-language ROI. FM01-FM06 and the source ledger define the
remaining work/capability closure without implementation or native tests.

The [seventh theory design-update record](../../../evidence/research/zig-native/theory-design-update-07.json)
binds these declarations, prior input update, matrix and D2 sources. It is
distinct from the historical `dsl-query-observation-07.json`, which remains
the last evaluated dataset. No ASCENT execution, theoretical/native witness,
runtime admission, implementation, timing result or existing-code retirement
is issued by this update.

## 16. Native Job Service and Shared-Support Portfolio

The [native job service](native-job-service-design.md),
[benefit/accounting matrix](native-job-service-benefit-matrix.md) and
[source/library ledger](native-job-service-evidence.md) select actual Gambit
compile/link dispatch and package-query duties beyond pure RFD. Native job
execution is necessary; a resident daemon or universal scheduler is not.
The existing process utility is retained as a cheaper typed-Scheme alternative.

The inspected POSIX SIGCHLD handler waits for any child, so an independent
in-process C/Zig reaper needs an integrated owner or separate process boundary.
The matched worker design assigns worker custody to Gambit and tool-child custody
to the worker. Signal bootstrap, inherited fd/TTY, query bytes, terminal status,
Scheme GC/control, shutdown and unknown outcomes remain explicit open gates.
No current native failure is asserted from this source hazard.

JB01-JB18 separate shared architecture gains from possible language/library
support savings. SA01-SA09 record actual support incidence; Q/B share a runner,
RFD does not use it, and optional LLVM deployment cannot be counted as existing
demand. RNC01-RNC07 allocate concrete change events once. NJR01-NJR08 retain
semantic generation, generic invoke/process runtime and residual legacy callers.
Managed-route bypass does not establish global helper deletion or Zig-only gain.

The [eighth theory design-update record](../../../evidence/research/zig-native/theory-design-update-08.json)
binds the new declarations and current source/docs/diagram inputs. This is a
declaration update, distinct from historical `dsl-query-observation-07.json`,
which remains the last engine-evaluated dataset. No source requirement,
theoretical cost gate, native gate or support retirement receives a witness.
Multiple demanded consumers expose a conditional positive domain; they do not
prove positive aggregate ROI by distributing fixed costs over more names.

## 17. Executor Residuals and Modernization Acceptance

The [executor/byte/cleanup contract](njs-executor-storage-cleanup.md),
[cost/modernization matrix](njs-support-cost-modernization-matrix.md) and
[source/primary ledger](njs-executor-evidence.md) continue SA02-SA05. Q's actual
stdout-only capture and B's inherited stdio narrow the required support domain.
Existing Scheme byte-vector reads and bounded BS1 storage provide serious
controls; no generic native grower or dual-stream framework is required.

OR01-OR07 and FT01-FT10 separate terminal status, EOF, callback quiescence,
fallible transfer and result acknowledgement. Scheme dynamic control, C
asynchronous close and Zig local cleanup mechanisms leave different wiring but
the same explicit custody obligations. RS01-RS12 name remaining project work;
CA01-CA08 account for unique support, actual consumers and incremental changes.
No source-count or cleanup-branch multiplication establishes net value.

MG01-MG12 add Gambit modernization targets rather than a language-feature score.
Current backend, byte/root and parallel-collector assets are retained as source
premises. OCaml paper/manual readings motivate collector/C-interface/control/
memory-model co-design, not copying its APIs, benchmarks or declaring every
mechanism new in OCaml 5. Native-boundary engineering, enabling infrastructure
and Gambit core-runtime evolution remain separate adoption/acceptance scopes.

The [ninth theory design-update record](../../../evidence/research/zig-native/theory-design-update-09.json)
binds current declarations, reviewed parent-link changes and inputs. Historical
`dsl-query-observation-07.json` remains the last evaluated dataset. No engine
run, implementation, native test, performance observation, cost-theory witness
or completed modernity/retirement criterion is issued.

## 18. Gambit Core Roots, Wait Participation and VM Ownership

The [runtime contract](runtime-root-participation-contract.md),
[cost/retirement/migration matrices](runtime-modernization-cost-matrix.md) and
[source/OCaml/paper ledger](runtime-root-participation-evidence.md) bring
MG03/MG04/MG07 into Gambit itself. V/E/R/S/P distinguish live VM, exclusive
execution, updateable/discoverable roots, backing storage and collective
participation. Existing mechanisms are assets, not evidence all capabilities
are absent or that every configured branch is admitted.

RT01-RT07, BW0-BW3 and VE01-VE08 define separate root, wait and entry domains.
The current writeback/reload wrapper is retained. Source RC scan applicability
and marker allocation TODO remain obligations rather than reproduced defects.
BW1 participating waits precede optional BW2 detached membership/root-carrier
design; TLS/refcount/unlock cannot replace that protocol. The pinned OCaml 5.5.1
source snapshot is separate from the 5.3 manual and 2020 paper readings.

RB01-RB14, KC01-KC08, RR01-RR07 and RM00-RM08 separate common reconstruction,
private Zig mechanisms, retained runtime/control costs, actual retirement and
the staged dependency order. Already-owned callers are the initial cohort;
arbitrary foreign attachment, cross-VM switching and collector changes remain
new independently justified capabilities. Existing conditional root/entry/
participant models and native history are not rerun or promoted.

The [tenth theory design-update record](../../../evidence/research/zig-native/theory-design-update-10.json)
binds these declarations and the reviewed modernization link extension.
`dsl-query-observation-07.json` remains the last engine-evaluated historical
dataset. No new native, cost-theory, retirement or runtime witness is supplied;
no implementation, model/native test or performance experiment occurs.

## 19. Owned Callbacks and Participating-Wait Closure

The [focused contract](owned-callback-participating-wait-contract.md),
[twelve-row C-G/C-ZT/Zig matrix](owned-callback-wait-matrix.md) and
[OW01-OW14 / OO01-OO06 ledger](owned-callback-wait-evidence.md) refine the first
owned-entry cohort. CS00-CS11 preserve roots, marker, conversions, matching and
outer nonlocal return, cleanup and binding. OR01-OR05 name conditional policy
retirement; OS00-OS06 separate design dependencies and future native acceptance.

The marker allocator can reach GC before target installation. RC uses a
processor-associated list while the inspected scanner calls mark_rc on P0;
managed closure data is distinct from native string bytes. Global callback self,
architecture-limited trampoline generation and real/effective binding need
separate invocation/cohort closure. The initial plan preserves the same owner
rather than adding attachment or VM switching. Existing wait materialization,
abort and collective service are retained; cached native aliases, device methods,
lock order and disabled-interrupt callers' checkpoints remain gates. Add-fd in
selected select/poll helpers does not itself resize; constructor capacity
admission can enter a collective operation and stays a separate effect.

The [eleventh theory design-update record](../../../evidence/research/zig-native/theory-design-update-11.json)
binds the declaration update and reviewed parent links. It adds 67 claims and
four unwitnessed architecture requirements; the Scheme engine is unchanged and
not run. `dsl-query-observation-07.json` remains the last evaluated historical
dataset. Shared runtime reconstruction is not Zig-only benefit; the private
support union must exceed all marginal costs after modern C reuse. TG4/TG5 and
future native qualification remain open. No implementation, native test,
performance result or execution authority is issued.

## 20. Nonzero RC and the Minimal Marker Root Window

The [minimal contract](rc-marker-minimal-contract.md),
[actual caller/source ledger](rc-marker-caller-evidence.md) and
[maintenance/migration matrix](rc-marker-maintenance-matrix.md) bind existing B1
candidate per-processor RC scanning, successful RC/still handoff and saved-target
repairs separately from B0 vendor source. RC-C1..RC-C7 distinguish direct movable
data, native bytes, positive-still carriers and actual run/SFUN callers. The
retained retirement fixture is read as source, not executed or duplicated.

MP1 is one short borrowed saved0 extent with reservation, full effect and all-exit
cleanup; it is not a root stack. MP0/MP2 reuse real existing storage. MP3/MP4 need
necessary caller demand. RE01-RE10 cover nesting and normal/nonlocal/failure exits,
including direct run and the earlier worker-start collective. MR01-MR08 and
RN01-RN10 credit actual existing C support; a Zig handle/status-only topology
can be nonpositive. RMS00-RMS06 separate design and future native admission.
Pending-join storage retention still needs a next-GC custodian/recovery argument.

The [twelfth theory design-update record](../../../evidence/research/zig-native/theory-design-update-12.json)
adds 82 declarations and four unwitnessed architecture requirements.
It rebinds reviewed owned-study follow-up links, new sources and a concurrent
module-end managed-entry import relocation; the cited loader body is unchanged. The Scheme
engine is unchanged and not run; dsl-query-observation-07.json remains the last
historical evaluated dataset. No implementation, native/model test, current
runtime acceptance, retirement, measured saving or execution authority is issued.

## 21. Full Modernization as the Primary Experimental Candidate

The [complete system architecture](modernization-system-architecture.md),
[LLVM leverage / retirement / economic matrix](modernization-leverage-matrix.md)
and [source/primary ledger](modernization-system-evidence.md) correct the research
priority. Bmin remains a repair/capability/cost control. C-full and Z-full compare
the same complete reconstruction; neither a local saved0 countermodel nor generic
LLVM availability decides adoption. Existing minimum studies and historical
receipts are preserved with explicit scope notes.

SharedRuntimeContract allows VM-owned retained roots and published execution-context
carriers, independent execution/member/return lifetimes and CT0-CT6 transitions.
It is new design work, not current detachment or pending-join acceptance. High
semantic and completed GVM products share one realization/provider/product plane.
SO/MA rows specify owners/modernity; LM01-LM14 distinguish shared reconstruction,
upstream reuse, language increments and optional features. FD01-FD09 require real
selected C retirement; AG01-AG06 retain independent full theory/cost gates.

The [thirteenth theory design-update record](../../../evidence/research/zig-native/theory-design-update-13.json)
adds 89 declarations and five unwitnessed architecture/economic requirements,
reviews four parent scope/link changes and updates the durable value questions'
current direction. No local control requirement is inherited as a mandatory
storage choice for the full design; future native qualification remains AG07.
The Scheme engine is unchanged and not evaluated. dsl-query-observation-07.json
remains the historical evaluated dataset. No implementation, native/model test,
positive cost witness, code retirement or execution authority is issued.

## 22. SysML v2 Architecture Modeling and Evidence Projection

The [modeling design](opensysml-architecture-modeling.md),
[primary tool/source evidence](opensysml-modeling-evidence.md),
[unvalidated SysML draft](modernization-architecture.sysml) and
[trace map](opensysml-model-traceability.json) introduce addressable architecture
views for the complete modernization candidate. The draft includes eight
responsibility declarations, compiler/product ports, CT0-CT6 event/guard skeleton,
three necessary runtime laws and separate unbound total/incremental economic
conditions. Guard inputs are obligations, not source observations. Full root,
participant, nonlocal-control and weak-memory refinement remain unresolved.

The map tracks 54 existing SO/CT/MA/LM/FD/AG design rows; only 15 rows have direct
draft structural/state elements. The rest point to existing documents, not
executable model coverage. Five analytic conditions link existing claims and
requirements; ten MQ questions retain explicit unresolved status and negative
cases. The Go REDK runtime, Rust static toolkit and normative SysML definitions
have separate capability/qualification boundaries.

The [fourteenth design-artifact record](../../../evidence/research/zig-native/theory-design-update-14.json)
binds this design-only projection and its source/declaration targets. No model
extractor, new research relation, claim, witness or engine evaluation is added.
The registered declaration file and Scheme engine are unchanged by this update;
the historical evaluated dataset cited by this slice remains dsl-query-observation-07.json.
No parser/interpreter/solver/compiler/native test, positive net-benefit result,
retirement or execution authority is issued. Runtime/model/native evidence
and theory decisions retain separate authority.

## 23. Shared Runtime Operations, Epoch Cuts and Real Retirement

The [operation design](shared-runtime-contract-design.md),
[source/primary ledger](shared-runtime-contract-evidence.md),
[retirement and value matrix](shared-runtime-value-matrix.md),
[SysML snapshot draft](shared-runtime-contract.sysml) and
[tracking map](shared-runtime-traceability.json) deepen MQ01-MQ06 for the complete
modernization candidate. RD01-RD08, RT01-RT26, HB01-HB06 and RC01-RC12 make the
required runtime authorities, state transitions, root custody and failures
explicit. A short metadata gate orders park/request/entry/registry changes;
managed acknowledgements, root contributor domains and GC worker teams are separate
ticket sets; final actual locations close after safe acknowledgements. Correct
set coverage, physical memory-order refinement, complete
control/caller coverage and cost bounds remain open.

The official LLVM statepoint GC-transition discussion does not supply Gambit's
handshake. FR/SP retain runtime/continuation integration. RR01-RR07 name real
retirement dependencies, RV01-RV08 distinguish modernization mechanisms and
QE01-QE08 require quantitative denominators. Common LLVM/GC value cannot be
counted again as Zig increment over equal-capability C-full.

User-directed naming correction removes invented architecture generation labels
from current prose, diagrams and authored research declarations. Claim IDs and
obligations are preserved. Historical receipts/output retain their identities.
The generated view needs its own producer-bound refresh; this study does not
invoke that producer or equate a separately observed producer binding with a
SysML/model result. No producer receipt is synthesized by this study.

The [fifteenth design-artifact record](../../../evidence/research/zig-native/theory-design-update-15.json)
binds this study and reviewed naming/reference changes. There are no new claim
IDs, witness rows, research relations or engine results. MQ questions and all
five Q-full requirements remain unresolved. SysML laws are unvalidated necessary
conditions over snapshots, not complete transitions, weak-memory proof or native
qualification. No implementation, solver/model/compiler/native test, measured
saving or execution authority is issued.

## 24. Conditional Proof and Two Distinct GC Cuts

The [proof argument](shared-runtime-proof-argument.md) and
[source/primary evidence](shared-runtime-proof-evidence.md) expose and correct an
early-root-cut gap in the preceding proposal. Request admission fixes contributors
and required members; active contexts can still change roots before acknowledging.
The final root-location union therefore closes only after their complete safe
descriptors and VM/global-domain descriptors stabilize. Source global-root worker
dispatch and mapped-frame location laws need explicit adaptation/refinement.

PA01-PA08 distinguish independent premises. PT01-PT05 provide handwritten
conditional arguments for custody, final root coverage, root-entry partition,
freshness and resource-indexed reclamation. PT06 excludes unconditional progress;
PT07 supplies a cost inequality and nonpositive countermodels. PX01-PX12 are
logical traces, not executed tests, native failures or model-checker output.

The [sixteenth design-artifact record](../../../evidence/research/zig-native/theory-design-update-16.json)
binds the proof text, corrected operation/model/diagram and traceability changes.
The snapshot model has eleven necessary laws; no Boolean discharges a premise.
Claim IDs, witnesses, engine and registered declarations are unchanged by this
slice. No prover/model/solver/compiler/native execution, positive cost witness,
retirement or execution authority is issued. Whole-system Q-full requirements
and source/physical/cost questions remain unresolved.

## Root and Real-User Source Refinement

The [source closure study](shared-runtime-root-custody-design.md),
[evidence ledger](shared-runtime-root-custody-evidence.md),
[cost matrix](shared-runtime-root-custody-matrix.md) and
[trace map](shared-runtime-root-custody-traceability.json) refine PA03/PA04/PA05.
They link nine safepoint/root families, eight actual user/resource families,
eight collector-work duties and six support/retirement rows to the existing
full-runtime/retirement/total/increment questions. These are document-side
source correspondence and handwritten arguments, not new registered engine
claims or witnesses. The Scheme declarations, producer binding, generated view
and engine are not edited or evaluated by this study. Whole-cohort completeness
and positive economics remain unresolved.

## Foreign Release and Device Service Refinement

The [foreign release study](foreign-release-worker-contract.md),
[source/paper ledger](foreign-release-worker-evidence.md),
[device-service cost matrix](device-release-support-matrix.md) and
[trace map](foreign-release-worker-traceability.json) refine PA04--PA07,
RUC08/GWD07, and the full runtime/retirement/total/increment questions.
FRO/FRE/FRU/FRA/DRS/DRX/DRR identifiers are document-side trace units; no new
registered engine claim or witness is emitted. Source facts, conditional
arguments and worker/economic qualification remain distinct. No engine, model,
solver, compiler or native test is evaluated by this study.

## Device Wait, Task Delivery and Shutdown Refinement

The [wait/task/drain contract](device-release-wait-contract.md),
[source/paper ledger](device-release-wait-evidence.md),
[support and cost matrix](device-release-wait-cost-matrix.md), and
[trace map](device-release-wait-traceability.json) refine FRA03--FRA09 and
PA02/PA04--PA08. RWC/WCT/DLT/WCN/RSD and WSU/WCE/WRT/WNB are document trace
units linking actual consumers to records, custody commits, failure and cost
conditions. No registered engine declaration, relation, witness, producer result
or native admission is added. Model/solver/engine and native execution remain
outside this research slice; the five full architecture questions stay open.

## Wait Synchronization, Cancellation Cuts and Teardown Credits

The [conditional protocol argument](device-release-sync-proof.md),
[source/paper ledger](device-release-sync-evidence.md),
[matched maintenance matrix](device-release-sync-cost-matrix.md) and
[trace map](device-release-sync-traceability.json) refine the existing wait study.
WSP/WSO/WSL/WST/WSX and WSM/WSE/WSN are document-side units. The argument
requires one serialized persistent predicate, one pipe drainer, live notifiers,
a unified resource/attempt authority and a complete producer/user census.
Still-object teardown after final GC and unconditional cleanup_rc reclamation
require real payload drain/transfer, not a refcount-only pin. Child reservations
are counted before parent completion; retained unknown work keeps dependencies.
Six handwritten arguments and fourteen logical countermodels do not constitute
checked/native evidence, finite progress, retirement or positive cost bounds.
The [design-artifact record](../../../evidence/research/zig-native/theory-design-update-20.json)
binds this slice. No registered engine declaration, relation, witness or producer
result is added/evaluated; all full architecture requirements remain unresolved.

## RC Payload Custody, Still Discovery and Shutdown Dependencies

The [custody design](rc-payload-custody-design.md),
[source/paper ledger](rc-payload-custody-evidence.md),
[matched support matrix](rc-payload-custody-cost-matrix.md) and
[trace map](rc-payload-custody-traceability.json) deepen WST04--06 and PA02--PA08.
RCU/RCP/RCO/RPS/RDD/RCT/RCX and RCM/RCE/RCN identify document-side units.
Source-owned preparation, target-owned committed storage and accepted work have
separate cuts; nested TLS storage, RC data roots and raw/managed server users
remain real dependencies. A private still-list cursor keeps its producer permit;
internal blocking-wait ranks apply only to a complete admitted wait graph.
The [design-artifact record](../../../evidence/research/zig-native/theory-design-update-21.json)
binds seven conditional arguments, seventeen logical countermodels and three D2
views. No checked/native proof, registered claim/witness/relation, engine result,
worker admission, retired path or positive economic bound is added. All five
full-runtime/provider/retirement/total/increment requirements remain unresolved.

## Root Transfer Receipts and Scan-Facility Retirement

The [receipt design](root-transfer-receipt-design.md),
[source/paper ledger](root-transfer-receipt-evidence.md),
[matched support matrix](root-transfer-receipt-cost-matrix.md), and
[trace map](root-transfer-receipt-traceability.json) refine RCO03--09/RCT03 and
PA02--PA08. RTU/RTP/RTA/RTO/RTF/RFS/RTPR/RTX and RTM/RTE/RTN are document
trace units, not runtime or registered-engine authority. RootTransferPermit
prepares a protected same-heap cut; RootTransferReceipt follows membership and
target-discovery publication. The receipt does not establish whole-heap last use
or old scan-facility physical drain. Required GC remains live while existing
users need it; failed post-membership publication retains actual VM/root custody.
The [design-artifact record](../../../evidence/research/zig-native/theory-design-update-22.json)
binds seven conditional arguments, sixteen logical countermodels, three new D2
views and the corrected earlier payload view. No engine/model/prover/native
execution, registered claim/witness/relation, retired path or positive net bound
is added. All five full architecture questions remain unresolved.
