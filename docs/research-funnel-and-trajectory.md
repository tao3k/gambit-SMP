# Evidence-Driven Research Funnel

## Real SMP Problem

Several stack-frame successors completed bootstrap but failed the stress suite's
processor probe before starting its four pressure files. Preserve the native
receipts, rather than labeling these as four stress-file failures. Existing
bootstrap, GSI/GSC inventories and PR regressions do not close either pressure
gate. Five historical gates are not automatically five current-candidate gates.

Bound examples are the native observations in:

- `evidence/fixtures/darwin-stack-frame-ra-padding/native-observation.json`:
  floor-push source lock, probe exit -6, FRAME-RA-BOUNDARY, filesLaunched=false.
- `evidence/fixtures/darwin-stack-padding-step/native-observation.json`:
  frame-ra-padding source lock, probe exit -11, empty output, filesLaunched=false.
- `evidence/fixtures/darwin-stack-padding-plant/native-observation.json`:
  padding-step source lock, probe exit -11 in 0.518903 seconds,
  filesLaunched=false.

Names are not identity. Each observation names its actual source lock and SHA,
original receipt SHA and JSON fields. The membership failure also has a real
sealed receipt at `.cache/stack-member-header-stress-compiled-002/run/receipt.json`;
its processor-probe command is `/steps/2/commands/2`. Raw logs stay in `.cache`.
An unavailable raw receipt is an explicit evidence gap, not an invented success
or a reason to delete the historical observation.

## Responsibility Boundaries

Trajectory retains immutable attempts, source/product generations, hypotheses,
phase outcomes, receipts, time expenditures and unstarted workloads. New
analysis does not rewrite an earlier attempt or its identity. Source A -> B -> A
does not restore the first A's receipt to the current generation.

Evidence DSL derives stage blockers, missing premises, explicit dependency
closure and possible investigations. Action Catalog exposes these options with
their reasons, source references, expected observations and risks. The Agentic
AI chooses and may propose new hypotheses/DSL modules; the catalog is not an
exhaustive universe or a mandatory schedule. The sealed kernel independently
checks supported capability, current inputs, causal retry review, permission,
scope, topology, teardown and original execution budgets.

Python transports typed values and identities. It must not implement a special
SMP failure classifier, cost-based retry waiver or research inference engine.
Stage matching does not establish a common cause: tag-zero abort and SIGSEGV
without stderr remain distinct observations until causal evidence connects them.

## Two Dependency Graphs

Diagnostic dependencies describe what an experiment needs to falsify a specific
hypothesis: a runnable image, the exact triggering entry, matching source/config,
compiler and seed identities, observability, a reviewed change and authorization.

Acceptance dependencies describe what a formal gate needs: its own matching
native receipt, full declared inventory, actual exit zero, no timeout, completed
teardown and verified provenance. Bootstrap, finite modeling and early probes
are different receipt kinds. Neither a failed downstream prerequisite nor an
early diagnostic PASS creates a successful stress receipt.

An early diagnostic is an optional branch, not a substitute for bootstrap. If a
first-pass/intermediate image actually exercises the relevant transition, it may
falsify a candidate before the complete bootstrap is paid. That correspondence
is an obligation, not a consequence of sharing source text. A failure may stop
further expenditure; a success still leaves final-image bootstrap and stress
acceptance open. A final-image-only bug can escape the early probe entirely.
Without a suitable runnable product/capability, only design or read-only
investigation actions are available; no missing runner is silently invented.

## Facts And Derived Options

Bind candidate/source/product/seed/compiler/topology identities separately from
the observation's phase, exit/signal, timeout, file-launch inventory, original
budget and elapsed time. Closed launch inventories support NOT_STARTED; absent
launch information supports UNKNOWN, not a negation-as-failure conclusion.

Suggested DSL relations are `PhaseObservation`, `ExpectedWorkload`,
`LaunchObservation`, `DiagnosticDepends`, `AcceptanceDepends`, `ReceiptKind`,
`ReceiptIdentity`, `TriggerCorrespondence` and `EvidenceReference`. Derived
relations include `EntryBlocked`, `UnstartedWorkload`, `MissingDiagnosticPremise`,
`MissingAcceptancePremise`, `RepeatedBoundary` and `InvestigationOption`.
These are contracts to implement, not claims that these rules already run.

Options may include reviewing the original probe receipt, tracing the earliest
invalid frame word, comparing competing descriptor/layout hypotheses, or
designing a bounded early falsifier. Repeating the unchanged failed native route
remains inadmissible. Editing a model or adding an explanation alone does not
constitute a causally relevant runtime change. Evidence sufficiency never grants
host execution permission.

Historical elapsed times can inform an uncertain cost estimate. They are neither
future runtime guarantees nor permission to increase a budget. Early rejection
can save the remaining bootstrap cost; successful paths may pay an extra probe.
No speedup or optimal action ordering follows without matched native experiments.

## Lean And Quint Contract

`models/library/lean/ResearchFunnel.lean` proves identity-scoped receipt support,
non-native receipt non-substitution and unchanged unique-gate counts,
stale-generation rejection, failed-probe/unauthorized launch rejection,
unknown launch evidence rejection and conditional early-rejection cost savings. It includes
concrete witnesses for misleading bootstrap credit and same-stage/different
failure signatures. The receipt provenance predicate is a trusted host premise,
not a proof of actual C execution or cryptographic authenticity.

`models/library/ResearchFunnel.qnt` explores probe outcomes, model/bootstrap
success, workload launch, native completion, publication, candidate replacement
and retained failure history. The checked instance and eight mutated instances
test premature early/model/bootstrap credit, stale acceptance, launching after
failure, loss of historical failures, fabricated not-started classifications
and unauthorized execution. Identities and generations are bounded
for exploration. No scheduler fairness, native progress or frame semantics is
proved by this finite model.

The finite profile has one representative open native gate. Bootstrap success
is deliberately a different kind of evidence for that gate; it does not deny
that bootstrap has its own independently passable acceptance gate. Lean's gate
parameter ranges over arbitrary identities, and counting deduplicates gate IDs.
Source/product IDs stand for the full source, configuration, compiler, seed,
binary and topology binding. Correct construction of those identities and
closed launch inventories remains a host/refinement obligation.

| Engineering obligation | Lean property | Quint fault control |
| --- | --- | --- |
| Early/model/bootstrap PASS cannot close stress | nonNativeCannotAdvance / nonNativeCannotChangeCount | Early / Model / Bootstrap |
| Duplicate gate IDs cannot increase progress | duplicateGateCannotInflateCount | Gate counting is abstracted to one Boolean |
| A -> B -> A cannot revive an old receipt | staleReceiptCannotSupport / abaCannotRestoreReceipt | Stale |
| Failed entry cannot launch downstream work | failedProbeCannotLaunch | Launch |
| Missing launch facts are not NOT_STARTED | unknownCannotBecomeUnstarted | Unknown |
| Eligibility is not host permission | missingAuthorizationCannotLaunch | Authorization |
| Candidate replacement retains old observations | advanceRetainsReceipts | History |
| Same phase does not identify a common cause | sameBoundaryNotSameSignature | Causal inference is outside this profile |

These mappings constrain the future DSL/Trajectory integration; they are not an
already-proved refinement from a Scheme query or C runner to either model.

## Admission Before Runtime Integration

Run the Lean checker and the existing Quint/TLC backend; retain decoded negative
traces, original budgets, source/tool SHA, exits and logs in git-toplevel `.cache`.
Do not commit raw execution logs. A model must not be called checked merely
because it parses or a bounded random simulation finds no counterexample.

Then implement the declared relations as caller-owned Evidence DSL and bind this
real case to the current candidate. Test missing/raw-mismatched receipts, unknown
launch inventory, different product identities, withdrawal and A -> B -> A,
failed teardown, source drift, unchanged retry and explicit permission refusal.
Use actual Trajectory/Action consumers, not a Python transition simulator.
The published Library must genuinely support the required Trajectory API.

Only the gate's own complete native PASS can change its acceptance count. Until
then no early probe, Quint/Lean theorem, ASCENT `missing: []`, or two-pass
bootstrap may turn the open stress milestone into 6/12.
