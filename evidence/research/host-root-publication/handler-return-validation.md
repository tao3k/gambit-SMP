# Handler Return And Resource Ordering: Research Receipt

## Publication And Research Boundary

The preceding audited research was published to SMP PR #1 as
`a71c24cd8773cd4a7d4818a67cd233de0b386207`, using a separate Git index. The main
directory's HEAD and shared index were not changed. The frozen reconstruction
patch is provenance, not a newly selected runtime implementation.

This continuation reads pinned Gambit/Chez/OCaml sources and updates the existing
handler model, conditional proof and Scheme declarations. No runtime source,
native fixture, native checkpoint or budget changes; no local bootstrap,
stress test, debugger or Grok run. It awards no native contract.

## Source Finding And Falsifier

The [source Recipe](../../../docs/handler-return-resource-order.md) distinguishes
OS delivery, admitted VM use, release/flush/reacquire, invocation return and
resource/code lifetimes. In particular, the retained `vm_registry_leave` drops
its count before its pending/flush tail, while flush obtains a new lease before
VM delivery. A live tail therefore establishes neither whole-handler return nor
an unleased old-pointer access. The SIGWINCH/TTY and single-VM paths cannot
inherit that VM-lease proof. The void signal-disposition wrapper ignores syscall
results, so a call is not a disposition-success or OS-completion witness.

Chez frees a TC before the enclosing teardown function returns; OCaml forbids
access to one reusable structure while retaining a different lifetime lock.
Those are counterexamples to imposing a single whole-function frontier on every
resource, not proofs of Gambit safety. OCaml's continuation marking/consumption
and C-link relocation supply additional obligations without importing one-shot
continuation semantics. Gambit's actual complete root/consumer census, supported
host entry contract, C ordering and producer causality remain unbound.

## Executable Checks

- The refined `handler_admission_window` has six accepted controls: three
  expected counterexamples and three exhaustive safety/progress checks. The
  post-release counterexample now requires actual modeled admission and reaches
  `admitted=true, stage=4, cReaders=0`. Its finite model is still not a native
  instruction-level refinement or unbounded OS progress theorem.
- The six handler checker observations were 22.519, 20.966, 27.378, 23.175,
  32.185 and 26.892 seconds. A declaration-only rebind reused all six checks and
  compiled artifacts in 0.553 seconds; this is not a checker speedup.
- The four unchanged last-access controls were reused from their original
  exact receipt, with original checker times intact. Their 1.340-second rebind
  is not a new TLC campaign. The current pair therefore has **10 accepted
  controls**, not ten native tests or ten completed SMP gates.
- The existing guarded Lean driver checked six lemmas, including the nonempty
  resource-use witness showing access completion before invocation return.
  Five have no axioms; epoch separation uses `propext` and `Quot.sound`.
  No `sorryAx`, timeout or surviving process group.

Current bindings:

- [Handler manifest](handler-return-tail.manifest.json) and
  [accepted receipt](../../model-results/current-repair-consumer-interfaces/handler-admitted-tail-qualified/receipt.json).
- [Last-access manifest](last-access.manifest.json) and
  [rebound receipt](../../model-results/current-repair-consumer-interfaces/last-access-declaration-bound/receipt.json).
- [Six-lemma guard](../../model-results/current-repair-consumer-interfaces/lean-return-tail/receipt.json).

Earlier checked bytes, logs and counterexamples are retained, not overwritten.
The first post-release abstraction also admitted a rejected-entry tail. That
was too broad for the new source correspondence; it remains an unregistered
historical bundle with its exact original declaration, SHA-256
`29308f8bd1e43bfe955320485db2d6bf488c605c6dd09a04a040b5fd554e92bc`.
It is not counted among the current ten controls or called a native failure.

## CI Failure And Declaration Repair

The initial research head's framework job rejected before running tests:
`KeyError: 'composes'` in `protocol_evidence.bundle_facts`. Direct checker
qualification had missed the full Evidence producer's metadata contract.
The two registered manifests now explicitly provide `composes`, `source` and
`papers`; empty paper lists make no borrowed-paper coverage claim.

The isolated full export then exposed unregistered imported model identities.
The existing registry now includes [the four actual imports](imports.manifest.json)
as **registration-only** records. They have no acceptance receipt, temporal
verdict or new proof credit. This reuses the existing registry/schema; Python
inference, exporter checks and acceptance conditions are unchanged.

The **final independent publication tree** passed:

```sh
python -m unittest tests.test_repair_consumer_interfaces -fv
python -m gambit_smp.evidence_index --validate
```

Results: **6/6 tests, 14.473 seconds**; actual full catalog validation returned
`DATALOG-COVERAGE-OK`. The tests also exercise direct bundle-to-index projection,
explicitly unqualified imports, admitted-only negative trace, first related
query, checkpoint continuation, stale-source revocation and native non-admission.
Coverage output deliberately retains hundreds of unclosed source/native
obligations; successful export is not complete SMP acceptance.

The earlier 51-test local run passed in 171.193 seconds before the admitted-only
tightening. It remains historical, not a claim that all 51 were rerun on the
final publication tree. Native CI's `upstream-check` also reported failure;
this research neither changes its source nor reruns it to manufacture green.

## Remaining Implementation Evidence

Exact supported signal disposition/return and resource-exclusion witnesses;
complete actual raw-root/private-work/FFI consumer enumeration; the real C
publication-to-last-access/reuse ordering; and a discriminating original-producer
observation are still owed. Native correctness, full GC/FFI/Gerbil acceptance
and release performance stay separate. A general host/root/signal architecture
redesign remains Experimental. The Recipe supplies premises and falsifiers,
not an Agent plan or a new runtime mechanism.

## Dependent View Binding Audit

The framework job for `08fc280` subsequently rejected before its test producer:
`Evidence view reference changed: evidence/dsl/modeling-guidance.ss`.
The only registered dependent reference was `reasoning-methods.view.json`'s
`existing-dsl` premise. It describes an existing inference component; it is not
a native receipt or a model/source acceptance review.

The audited DSL delta adds exact model-path provenance and separates model-check
and source-review identities in revision detection. The dependent declaration
was rebound to the actual reviewed DSL SHA-256
`030cfc1abf4d324d8cf7cbd6102a16f14d5182ff580c69387745b25003ae9b4c`.
JSON comparison established that only this reference identity changes; all
candidate, review, policy, method, question and acceptance data remain identical.
The existing six `tests.test_reasoning_methods` tests passed in 6.447 seconds,
including real view loading, optional/nonexclusive methods, withdrawal/restoration
and no proof/execution-authority grant. No historical native result was rebound.
This local check does not relabel the failed CI job as passing; latest-head CI
must report its own result.

## Publication-Tree Identity Correction

The framework job for `5b7671a` failed at the same reference before tests.
The preceding local check did not validate the isolated publication bytes:
`030cfc1a...` includes concurrent, unpublished mechanism rules in the shared
working tree. The reviewed, owner-scoped DSL actually published in that commit
has SHA-256 `c8af243de911827c19050fd071d9cde79c3f7b29b48640a0d46c18214292fe45`.
The previous binding was therefore incorrect; its local six-test result remains
historical and is not evidence for the published reference. The correction
changes only that dependent reference in the publication index, without changing
the concurrently maintained working-tree view or DSL. Native and model results
are not rebound. Registered references are checked from the publication Git
objects and pinned vendor objects, not inferred from the dirty working tree.
