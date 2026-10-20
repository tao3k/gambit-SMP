# Current Repair Consumer Interfaces: Qualification And Handoff

## Claim Boundary

Research checkout: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`, with the
listed working-tree additions. These are not published HEAD results. No runtime,
native fixture, source lock, budget, bootstrap or original stress run was changed
or executed. This is not a native repair, performance result or whole-framework
qualification. The inspected native audit retains eight completed contracts and
four open contracts, including item 9 itself.

The [interface design](../../../docs/current-repair-consumer-interfaces.md)
and [root Recipe](../../../docs/saved-stack-root-closure-recipe.md) own the
source scope. Existing imported model bytes and historical receipts are retained.
The four imported models (`runtime_generation_recovery`,
`saved_stack_root_closure`, `saved_stack_arena_ownership`, and
`resize_saved_stack_retirement_isolated`) match their recorded predecessor SHA-256
identities. These additions refine current obligations, not a new root ABI,
host API, TLS scheme or collector organization.

## Executable Model Evidence

Existing Quint 0.33.0 compile/TLC and publication drivers produced two independently
scoped bundles. `accepted` includes expected negative controls; it does not mean
the negative invariant holds.

| Bundle / property | Expected and observed result | Distinct states |
| --- | --- | ---: |
| handler / `noCross` | Counterexample: old delivery enters reopened generation | 9 |
| handler / `noCompletedDrain` | Counterexample witnesses completion and reopening | 6 |
| handler / `drainSafe` | Exhaustive conditional safety and `progress` | 6 |
| handler / `counterAccurate` | Exhaustive counter consistency and `progress` | 10 |
| last-access / `lastAccessSafe` | Counterexample: reuse overlaps an active consumer | 292 |
| last-access / `noClosedConsumerReuse` | Counterexample witnesses returned consumer and reuse | 304 |
| last-access / `declaredRootSafe` | Exhaustive original root safety and `accessCompletion` | 304 |
| last-access / `completeCensusSafe` | Exhaustive conditional census safety and `accessCompletion` | 304 |

All eight controls were accepted. Positive searches ended with zero queued states.
Progress is conditional on the specified finite transition system and weak
fairness, not general OS fairness or a source refinement theorem. The handler
model gives its abstract C counter the generous first-instruction boundary;
the native registry CAS is later. Even that earlier counter does not observe
delivery before C. Delivery epoch is ghost causality, not an available C token.
The last-access negative can stop at unsafe reuse before a subsequent stale load;
it is not an observation of native memory corruption.

Published exact-byte closures:

- [Handler manifest](handler-admission.manifest.json) and
  [qualified receipt](../../model-results/current-repair-consumer-interfaces/handler-admission-qualified/receipt.json).
  Four exact checks were reused, retaining original checker times of
  11.826, 12.521, 13.015 and 13.686 seconds. The 0.38-second reassembly is not
  checker execution time.
- [Last-access manifest](last-access.manifest.json) and
  [receipt](../../model-results/current-repair-consumer-interfaces/last-access/receipt.json).
  Campaign time: 43.16 seconds; individual checks: 17.826, 17.523, 11.434 and
  13.553 seconds. No native speedup is inferred.
- [Lean guard receipt](../../model-results/current-repair-consumer-interfaces/lean/receipt.json):
  five conditional lemmas, exit 0, timeout false, process group quiescent,
  1.703 seconds. Four lemmas have no axioms; epoch separation uses `propext`
  and `Quot.sound`. There is no `sorryAx`. The census and discharge premises
  remain explicit; elaboration does not authenticate a native event.

Scheduling was selected by the existing host-auto policy: this host reported
12 available processors and 32 GiB physical memory. Controls used two groups
of six TLC workers; positives used twelve. These are recorded observations,
not model cardinalities or hardcoded concurrency defaults.

## Scheme And Session Qualification

The existing registered `current-repair` view now binds exact model/checker/proof
identities and three separate source-correspondence observations. All thirteen
native requirements remain unclosed, with no native receipt or scope-review
witness manufactured from the model checks.

Two real defects were exposed and corrected in the existing Scheme declaration:

- Reusing native-clause IDs for model-correspondence observations violated Clue
  identity uniqueness. The observations now have their own semantic IDs and
  reference the native clauses through existing relations.
- Revision checking incorrectly required the check receipt and applicability
  review to have the same source identity. They are independent bound sources;
  changing a model now exposes a revision gap even when the review is separate.

Actual model path/hash factors are paired. Broader clause references are named
`related-model-reference` and `related-proof-reference`, not presented as the
source corresponding to a different checked hash. Python does not infer these
relationships or select an Agent action.

The final scoped command passed **51 tests in 79.302 seconds**:

```sh
.venv/bin/python -m unittest tests.test_repair_consumer_interfaces \
  tests.test_current_repair_trajectory tests.test_generation_recovery_evidence \
  tests.test_protocol_evidence tests.test_modeling_guidance -fv
```

Controls cover exact compiled-artifact closure, source revision change/restoration,
withheld native applicability, three uncovered model assumptions, actual model
path/hash pairing, changed/colliding/escaping reuse artifacts, registered first
query and checkpoint continuation. A preceding revision also passed the same
51-test roster in 146.343 seconds; these are not matched performance samples.

Two separate CLI processes exercised the final declaration:

```sh
.venv/bin/gambit-smp trajectory clues \
  '((bindings (("mechanism" "saved-stack-last-access"))) (displayBytes 16384))'
.venv/bin/gambit-smp trajectory clues \
  '((checkpoint "RETURNED-TOKEN") (displayBytes 16384))'
```

The first query matched `consumer-census-source`, `inflight-last-access-source`
and `repair-retirement-census`. The second returned no families, zero added,
zero removed and 53 retained relations. Both kept exploration open and runtime
admission/execution authority false. Registered repository coverage was reported
as 22 available views and one unavailable view, not global completeness. No
Grok behavior, token reduction or native progress is claimed by this CLI check.

## Retained Failures And Reuse Repair

Rejected attempts remain in the owner-local validation history: unexported
import access; flattened Quint namespace collisions; missing/wrong TLC support
jar; sandbox loopback allocation; Lean reserved identifiers and incomplete
proof attempts; mismatched-model resume; incomplete compiled-artifact custody;
duplicate Clue identities; and the separate-review revision regression.
None is relabeled a native failure or a successful qualification.

The existing resume transport copied logs/traces but omitted compiled TLA/config
artifacts. Publication correctly rejected that incomplete closure. The generic
transport now retains exact checked artifacts with source/target hash, collision
and path-boundary checks. Changed model/context identity is still rejected.
The incomplete `handler-admission` publication has no accepted receipt and is
unregistered; only `handler-admission-qualified` is registered. The combined
manifest is not claimed as an accepted combined TLC campaign.

Accepted bundles are portable evidence, not disposable build caches. They remain
under the repository's ignored `evidence/model-results` policy until explicit
owner-scoped Git publication; no commit or push occurred in this turn. Failed
scratch products are not publication candidates. Public artifacts were scanned
for personal absolute paths; none were found in this new qualified scope.

## Implementation Handoff: Still Open

| Obligation | Source evidence needed, not supplied by this research |
| --- | --- |
| Delivered handler lifetime | For the supported entry/configuration, distinguish delivery, first C instruction, registry admission and actual return. Prove the reopen/reclamation boundary or a supported terminal/exclusion contract. A zero entry count alone is insufficient. |
| Complete roots and consumers | Enumerate actual queue carriers, saved/raw origins, foreign tails and private scan work; map their surviving scanner, last access and resource incarnation before reuse, including no-GC shrink and non-consuming continuation use. A legitimate empty branch needs a scoped witness. |
| Publication and reuse order | Map actual C publication, collective phases, exceptional exits and final consumers to the existing root/arena/work models. An omitted consumer counterexample is not proof that this candidate has one. |
| Causal acceptance | Establish a discriminating observation from the original producer, compatible source repair, full GC/FFI and Gerbil qualification, then matched release measurements. Do not infer the Gerbil failure's cause from a plausible root hazard. |

Chez/OCaml mechanisms are counterchecks, not transplanted guarantees. If an actual
source protocol excludes an abstract schedule, record that mapped premise and
its supported scope rather than adding unnecessary runtime machinery. No
`composition_binding`, native `satisfies`, or scope-review witness has been
invented. The implementation task can choose a different mechanism satisfying
the same obligations; this handoff prescribes neither locks nor investigation
steps.
