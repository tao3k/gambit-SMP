# Source-level C contracts

Organize a harness by contract and then by control-flow or outcome branch.
The enclosing canonical runtime interface identifies the source responsibility.
A verification result applies to the selected branch, assumptions and source
bytes. It does not qualify sibling branches or the complete interface.

```text
allocation-grant/
  copy-certificate/valid-demand/
  copy-capacity/byte-budget/
  copy-capacity/integer-overflow/
  copy-capacity/wp-fit/
  copy-capacity/wp-invalid-postcondition/
  copy-capacity/wp-inconsistent-precondition/
  section-storage/claim-geometry/
  section-growth/no-growth/
  section-growth/single-section/
  section-growth/partial-failure/
  section-growth/no-growth-reachability/
  section-growth/first-failure-reachability/
  section-growth/second-failure-reachability/
  section-growth/success-reachability/
  section-growth/byte-storage-control/
  plan-refusal/cleanup/
  rest-demand/path-footprint/
  support/
```

Each branch owns `harness.c` and `check.recipe.json`. `support/` contains shared
analysis-environment declarations and explicitly described external-call
summaries. Production algorithm text comes from the declared `vendor/gambit`
cuts, preserved verbatim with source hashes and original diagnostic line names.
There is no second implementation of the planner or resize algorithm.

The aggregate Recipe is
`evidence/fixtures/dev-cbmc-copy-plan/check.recipe.json`. Each branch Recipe
runs its selected observation, explicit proof prerequisites and the existing
terminal ASCENT evaluation. The partial-failure entry covers all three original
demand values; its no-growth and single-section siblings can be run separately.
Use the single dispatcher, for example:

```sh
.venv/bin/gambit-smp --task modern-c-frame-contract --process audit research \
  --run tests/contracts/allocation-grant/copy-capacity/byte-budget/check.recipe.json \
  --engine ENGINE --out OUTPUT
```

Seal the explicit CBMC executable with `research --seal ... --cbmc PATH`.
Execution does not install or discover a verifier. GCC preprocessing uses the
sealed compiler, no system includes, and a checked snapshot include inventory.
CBMC receives the resulting `.i` file. Failed branches retain the raw JSON
counterexample, property ID, source location, projected bytes, input hashes,
ABI/environment assumptions and process observations. `research --read OUTPUT`
reads these results without executing them.

ASCENT keeps `c_verdict`, `c_property`, `c_source` and `c_assumption` separate
from Recipe completion. `repair_needed` includes contract and branch identity.
A completed observation with a counterexample is not a verified contract.
Timeouts, incomplete reports and unresolved properties remain inconclusive.
Grok chooses the next repair or experiment from this evidence; no retry order
or repair choice is encoded here.

The first scope is LP64 and bounded resource configurations declared by each
branch. Certificate arithmetic is distinct from the mathematical soundness
of its packing bound. Resize checks expansion while existing metadata has
capacity; metadata relocation, contraction and concurrency remain separate
branches. The refusal epilogue checks cleanup and measured-demand custody;
the identity and precedence of all incoming refusal branches remain an open
caller correspondence obligation. These limits are retained with the results.

This verification does not launch Grok, build core, close Family A or admit
Family 6. The original p2 then p1 campaign, 295/300-second limits and 5/12
ledger remain unchanged.

## Rest demand and mechanism composition

The optional `c.genmc` lane checks finite C/LLVM concurrency under a declared
memory model. `concurrency/copy-gate/two-carriers/check.recipe.json` projects
the actual Gambit copy gate and sync definitions unchanged. Its relaxed
publication companion qualifies counterexample reporting only. GenMC retains
compiled LLVM, model runtime/header identities, explored/blocked counts, bounds
and the first error graph. Bounded or random exploration does not become a
complete proof. See [Tool Reasoning](../../docs/tool-reasoning.md#genmc-source-concurrency-lane).

`allocation-grant/rest-demand/path-footprint/check.recipe.json` checks the
actual fast/full demand functions and native constants. It also runs the
existing QNT, Lean and connected SysML owners, then evaluates native ASCENT
rules. The deliberate `fast==full` assertion is a qualified reachability
control, not a production-defect claim. Caller bounds and fresh-section
eligibility remain explicit premises. See
[the mechanism packet](../../dev/refactoring/modern-c/family6-mechanism-assurance.org)
for refusal/reentry composition, logical source extent and remaining native
obligations. This focused Recipe does not replace the copy-plan aggregate.

The separate `modern-c/rest-native/image-cuts/check.recipe.json` uses the
existing `source.contract` capability to check a declared linked image's bytes,
direct edges and caller-stack address windows. Its image is a read-only,
non-executable task observation artifact, not a repository source alias or a
qualified runtime. C/WP source contracts cannot qualify code absent from that
image. Static cuts do not supply a native GC trace or Scheme reachability.

## Retained first C verification

The complete local run is
`.cache/tasks/modern-c-frame-contract/processes/audit/runs/cbmc-copy-contracts-5`.
Normal `research --read` returned `CURRENT` identity and evidence bindings.
The aggregate outcome is `DENY` because resize verification timed out. The
terminal ASCENT evaluation completed and retained each branch independently.

```sh
.venv/bin/gambit-smp --task modern-c-frame-contract --process audit research \
  --read .cache/tasks/modern-c-frame-contract/processes/audit/runs/cbmc-copy-contracts-5
```

| Contract / branch | Result | Evidence meaning |
| --- | --- | --- |
| copy-certificate / valid-demand | VERIFIED | 30 properties, including the three declared arithmetic/output-frame assertions, within the recorded finite domain. |
| copy-capacity / byte-budget | COUNTEREXAMPLE | A valid incoming 36-section pool with a 38,273,024-byte limit requests growth to 37 sections, requiring 38,797,312 bytes. The implementation compares a word count with the byte limit. |
| copy-capacity / integer-overflow | COUNTEREXAMPLE | `n=4`, `k=2147483646` overflows the actual C `int need=n+k` expression. This is a separate boundary finding; reachability from the historical header census is not established. |
| section-growth / partial-failure | INCONCLUSIVE | The 60-second verifier budget expired during propositional reduction. Original section geometry and memory-safety checks were retained, including with symbolic arrays. |
| plan-refusal / cleanup | VERIFIED | 35 properties, including decision publication, temporary-owner detachment, retained storage/demand and cleared traversal cursors, under the recorded entry assumptions. |

Each branch's `run/STEP/verification.json` retains its verdict, input hashes,
projection ranges and assumptions. `run/STEP/cbmc.json` retains the raw property
report and counterexample trace. Earlier projection/inventory failures and
solver timeouts remain in runs 1-4. The original header reproduction, Make
target identity and production GSI qualification have their own obligations.

These historical traces identified the byte/word/still budget and checked-sum
repair directions. Later Grok work reports VERIFIED results for both affected
capacity Recipes, and the maintained source now contains those checks; retain
and read that generation's exact receipts before reusing the result. Do not
request the old repair again from this historical table. Existing resize entrypoints show
the current budget convention. The unresolved resize proof can be refined by
separating storage geometry from the linked-list transaction or by another
sound verifier representation. It is not evidence of a resize source defect.
The refusal epilogue result does not establish incoming branch precedence.
No verified sibling branch closes either open obligation.

## Storage geometry and linked-list transaction

The original byte-storage control remains under
`section-growth/byte-storage-control/`. Run
`cbmc-byte-storage-profile-1` retained a stack sample during the same 60-second
budget: CBMC reached about 2.2 GB while converting conditional whole-object
assignments, before SAT solving. Its equation contained 8,783,360-bit section
objects. This measures verifier representation cost, not collector liveness.

`support/section-storage.h` exposes the full native storage layout. Static size
checks retain the 131,072-word section and all bitmap, claim and raw-map bytes.
The geometry branch calls the actual `section_claim_at` helper, proves its two
native addresses equal the typed claim slots, executes the actual two claim
initialization statements, and checks arbitrary payload/bitmap/raw-map indices
are preserved. The transaction branch requires this source-current proof and
uses that exact address equality; every native initialization store remains.

`support/growth-fixture.h` supplies a valid one-section caller state with
metadata capacity seven and two fresh full-size disjoint allocation grants.
Each actual allocation request can fail independently. The provider checks
the native requested extent; it does not implement resizing or publication.
Actual `find_msection` and `adjust_msections` bodies are projected unchanged.
This contract excludes metadata relocation, contraction, OS allocator behavior
and concurrent callers, as before.

The original demand domain is exactly `{1,2,3}`. An assumption on symbolic
`need` let symex construct infeasible `need>7` metadata growth before solving;
the three constant entrypoints cover the same domain and prune those paths
before equation construction. Their budgets are geometry 20, no-growth 10,
single-section 10 and partial-failure 20 seconds: still 60 seconds total.
No section, failure outcome, source body or mandatory memory check is removed.

Run `cbmc-section-growth-split-11` completed the four observations without a
timeout. Geometry verified 120 properties (7.97 seconds); no-growth verified
524 (0.57 seconds). Single-section and partial-failure returned in 1.03 and
1.97 seconds with failed and unresolved properties. They are **INCONCLUSIVE**,
not verified transaction contracts. Their raw reports retain traces for
`find_msection.pointer.1`, the cross-allocation comparison at
`movable-sections.inc:40`. CBMC reports a same-object violation. Later
dereference/assertion failures after that undefined comparison are not
independent native corruption diagnoses.

The diagnostic-retention follow-up is `cbmc-section-growth-split-12` using
`cbmc-storage-engine-6`. It keeps the same C sources and budgets. Geometry
verified 120 properties in 3.32 seconds and no-growth verified 524 in 0.53.
The one-section report retains all 527 properties (22 failed, 185 unknown)
and the partial-failure report all 528 (35 failed, 172 unknown), in 0.92 and
2.58 seconds. Both remain INCONCLUSIVE. Failure and UNKNOWN records now survive
in `c_property` and normal aggregate reads; ASCENT keeps them unresolved rather
than promoting them to verified contracts or mandatory source repairs.

```sh
.venv/bin/gambit-smp --task modern-c-frame-contract --process audit research \
  --read .cache/tasks/modern-c-frame-contract/processes/audit/runs/cbmc-section-growth-split-12
```

Grok must resolve the address-order contract: either repair the actual source
to use an explicitly justified address ordering, or establish the intended
target/compiler semantics and verify with a corresponding sound memory model.
Do not suppress pointer checks, place separate native allocations in one
analysis object merely to avoid the obligation, or assume downstream failures
are the first source defect. A Frama-C memory model is also a declared proof
premise; switching tools alone cannot discharge it.

## Tool reasoning through the existing ASCENT entry

Use [Tool Reasoning](../../docs/tool-reasoning.md), not a separate repair runner.
The registered `c-section-contracts` focus derives optional CBMC, Frama-C/WP and
verifier-sampling choices, their boundaries and missing premises:

```sh
.venv/bin/gambit-smp --task modern-c-frame-contract trajectory clues \
  '((bindings (("kind" "tool-choice") ("focus" "c-section-contracts"))))'
```

Continue with the returned checkpoint and expand claims to read the policy,
question and environment routes. Options are hypotheses; they do not prescribe
an execution order. CBMC executions use the existing source-bound Recipe lane.
Frama-C 33.0 was discovered through the existing opam tool-environment entry
with switch `herdtools7` in `frama-c-environment-1`. The optional `c.frama-c`
capability now supplies actual WP observations with explicit model, ACSL,
runtime closure and all normal/smoke goal statuses. The qualification Recipe
is `evidence/fixtures/dev-cbmc-copy-plan/wp-check.recipe.json`. It checks the
actual `___gc_copy_plan_fits` body under a valid contract, a deliberately wrong
postcondition, and inconsistent preconditions. No algorithm is reimplemented.
An unproved WP goal is not by itself a C counterexample; proving a smoke goal
is a warning about unreachable context, not a successful contract test.

The source-level outcome witness Recipe is
`evidence/fixtures/dev-cbmc-copy-plan/reachability.recipe.json`. Its geometry
producer and four outcome entries share 60 seconds of C verification, plus
the existing 30-second terminal evidence evaluation. The caller fixes only
the external allocator outcome: no growth, first grant failure, failure after
one grant, or two successful grants. Every entry includes the unchanged native
resize algorithm and full physical section extent. A deliberate negated-goal
assertion supplies a candidate trace. All other checks must succeed before
that witness becomes `REACHED`; otherwise it stays `UNQUALIFIED_TRACE` or
`UNRESOLVED`. A witness neither suppresses the address-order obligation nor
proves coverage of every native address permutation. Existing safety branch
Recipes remain separate.

## Retained WP and reachability qualification

The engine is
`.cache/tasks/modern-c-frame-contract/processes/audit/runs/c-source-contract-engine-4`.
It binds Frama-C 33.0, Why3 1.8.2, Alt-Ergo 2.4.3 and the explicitly declared
package/configuration inputs. The WP positive/negative controls are retained in
`c-wp-qualification-3` under the same audit runs directory:

| Branch | Observation |
| --- | --- |
| wp-fit | Eight normal goals proved; six smoke goals timed out. The conditional C contract is VERIFIED; premise consistency is explicitly not proved. |
| wp-invalid-postcondition | The deliberately false postcondition is unproved. INCONCLUSIVE, with dead-code smoke warnings but no root-precondition smoke proof. This is not a production C counterexample. |
| wp-inconsistent-precondition | Normal goals appear proved, but all six smoke goals are proved too, including the entry precondition warning. INCONCLUSIVE. |

Each report contains all 14 scheduled top-level goals, their native WP verdicts,
normal/smoke distinction and source locations. The whole child observation took
54.543 seconds. The first tool-configuration failures and intermediate timeout
remain retained in `c-wp-qualification-1` and `c-wp-qualification-2`.
`c-wp-diagnostic-2` supplies the successful focused diagnostic. WP configuration
is applied before selecting its prover identity. Optional `debug`,
`messageKeys` and `counterexamples` parameters support further caller-chosen
diagnosis without changing adapter code or prescribing a retry path.

`c-resize-reachability-1` completed in 27.622 child seconds. Its geometry is
VERIFIED. No-growth and first-allocation-failure witnesses are REACHED.
Second-allocation-failure and full-success traces remain UNQUALIFIED_TRACE;
the same C address-order boundary still prevents their safety qualification.
No failed/unknown memory obligation was removed to obtain the witnesses.

Read both complete observations through the normal entry:

```sh
.venv/bin/gambit-smp --task modern-c-frame-contract research \
  --read .cache/tasks/modern-c-frame-contract/processes/audit/runs/c-wp-qualification-3
.venv/bin/gambit-smp --task modern-c-frame-contract research \
  --read .cache/tasks/modern-c-frame-contract/processes/audit/runs/c-resize-reachability-1
```

Their aggregate `executionSummary` exposes the complete normalized property
inventory, receipt-bound raw reports and actual `cContractEvidence` ASCENT
answers. Native WP goal/prover detail and CBMC traces remain in those bound
raw references. Recipe PASS records a completed observation, including the
intentional negative controls; it does not make unresolved goals pass.
Neither campaign supplies Gate 2's same-linked-image evidence.
