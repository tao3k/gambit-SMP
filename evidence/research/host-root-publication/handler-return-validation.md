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

The corrected publication tree `d1e6559e53ee2285e87402c5d11e340962fecc7d`
was checked against all **287 registered repository references**, including
vendor files loaded from the tree's pinned submodule commits: zero mismatches.
It was published as `882a6eb4b42995ceb2a6edf529c0c767b9f98a9a`.

## Outer Caller And Device-Consumer Continuation

The updated Recipe follows the actual global cleanup caller, device close /
release failure paths and TTY aliases. It retains the counterevidence that
`cleanup_all_interrupt_handling` already attempts user-handler removal before
the inner I/O cleanup. No race is asserted from inner call order alone.
Disposition success, already entered callback completion and per-device error
ownership still lack source-bound witnesses. No such failure was injected or
observed in this research.

OCaml's `BT_TERMINATE` request, last-use `BT_INIT` release publication and
acquire-observing carrier cleanup distinguish a concrete acknowledgement from
join or a stop request. Chez's separately recycled GC carrier prevents equating
TC free with universal consumer completion. Their populations, storage lifetime
and no-later-access premises cannot be silently borrowed by Gambit.

The existing registered view adds the `tty-device-last-access` mechanism and
its unbound `consumer-interface-lemmas` census obligation, including the outer
caller counterevidence. It adds no native requirement, completion receipt,
scope review or Python inference. Existing QNT sources/checks and six-lemma
proof bytes remain unchanged; saved-stack GC transitions are explicitly not
claimed as a TTY-source refinement. No unchanged TLC run was repeated.

Focused working-tree verification:
`python -m unittest tests.test_repair_consumer_interfaces -fv` passed **7/7**
in **107.189 seconds**. This includes the new real registered factor query,
exact proof-path/hash association, counterevidence, checkpoint continuation,
absence of native admission and source-revocation controls. The guarded Lean
subcheck completed in **2.969 seconds**, exit 0, no timeout, process group
quiescent; the same six lemmas have no `sorryAx`. This is a working-tree result,
not a relabelled exact-head CI or a new native test campaign. This lane did not
write candidate locks, runtime patches, native checkpoints, the shared Git index
or the main checkout's HEAD. Publication uses an alternate index; concurrent
shared-checkout changes are retained, not reset to an earlier index snapshot.

Independent publication-scope verification used tree
`e462ac42377691225f94b6e8b0a6c99b45c0ccf3`, without the dirty checkout's Python
or extra DSL rules. It materialized the tree and 74 exact referenced vendor
files, copied the installed Library wheel and reused only the pinned Lean
dependency cache. No native runtime fixture was cloned or built.

The first guard invocation lacked the disposable Lake manifest and attempted
network dependency resolution: exit 1 after 0.190 seconds, no timeout, process
group quiescent, `Could not resolve host: github.com`. This was a validation
environment failure, not a theorem counterexample. Reusing the existing manifest
for the exact same pinned LeanPoo dependency corrected the environment; no
source, theorem, timeout or assertion was changed.

On that isolated tree, the seven repair-interface plus six reasoning-method
tests passed **13/13 in 52.767 seconds**. Actual full Evidence export returned
`DATALOG-COVERAGE-OK`. Its open protocol/source/native obligations remain open;
neither result is native acceptance or a performance improvement measurement.
The subsequent text-only receipt addition does not change the tested Recipe,
DSL view, proofs, model bytes, framework source or test source.

## Definitive Latest-Head Framework CI Boundary

Head `882a6eb4b42995ceb2a6edf529c0c767b9f98a9a`, framework run
`39406034219`, job `118572075122`, was **cancelled**, not PASS. The test step
started at 10:12:26 UTC and was cancelled at 10:20:44 UTC on 2026-10-20.
GitHub's annotation states: `The job has exceeded the maximum execution time
of 10m0s`. Setup and sealing passed. The final export and artifact upload were
skipped, so there is no complete test inventory/verdict or retained CI producer
receipt from which to infer a particular test failure or deadlock.

The 10-minute workflow cap already exists in pre-research parent
`dcd91b2c6948f19c55da9046796012516c7f0207`; it is separate from the unchanged
300-second completed-test-inactivity watchdog. This research neither raises
that cap nor calls the cancelled full campaign green. The corrected reference
and new declarations have the independent publication-tree results above.
The additional five-file research change remains in the working tree rather
than pushing another known-cap campaign or touching native acceptance.

## Post-Publication Source Continuation

The preceding pending-publication boundary was superseded by `03bb217`, which
publishes that audited research with the Scheme-driven framework observation
repair. The full framework result remains separately qualified. This subsequent
source audit changes no runtime, model bytes or native acceptance.

Pinned OCaml `runtime/domain.c:1122-1146` registers the callback and `term_sync`
slots in an independent C carrier as generational global roots. At :1372-1389,
`sync_and_terminate` retains a raw `mut` across domain teardown, then performs
its final unlock. The caller removes the carrier's roots only at :1450-1455,
explicitly after that unlock. `runtime/caml/sync.h:34`, `runtime/sync.c:101-111`
and `runtime/sync_posix.h:32-62` distinguish the rooted movable wrapper from
the separately allocated native mutex. This is not permission to retain an
arbitrary interior pointer into a moving Gambit object.

The existing Lean consumer-composition theorem requires this post-teardown
borrower in the actual consumer census. Its last-resource-use witness permits
the root removal before whole OS-thread return only after that borrow ends.
The saved-stack last-access QNT supplies the analogous omitted-consumer
countercheck, not a refinement of OCaml mutexes or Gambit TTY records. The
missing Gambit witness remains the actual owner, last alias and supported
publication/reuse edge, not a request to add a second model or global lock.

The successful OCaml backup-thread acknowledgement path also has a scope limit:
`domain.c:1248-1258` publishes `BT_ENTERING_OCAML` before thread creation and
returns an exception result on creation error. The two inspected callers at
:1421-1424 and :1499-1501 take different exception paths. Their full rollback /
retry correspondence is not established by the successful `BT_INIT` handshake.
No creation failure was injected, and no OCaml runtime defect is claimed.
This is counterevidence to importing that mechanism as a universal failure
recovery proof.

Chez `c/gc.c:1041-1043` and :1158-1161 provides actual downstream consumers of
the preserved `thread_gc` carrier: a segment whose creator has no live TC can
be reassigned to the current collector. This completes the source reason for
retaining the carrier after TC free, without claiming that every carrier field
or incarnation can be reused concurrently. It complements, rather than
replaces, the existing saved-origin and producer-lifetime conditions.
