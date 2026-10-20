# Framework Progress Integration: Research And Qualification

## Preserved Failure

PR head `882a6eb4b42995ceb2a6edf529c0c767b9f98a9a`, framework run
`39406034219`, was externally cancelled by the ten-minute job cap. It did not
establish a deadlock or a complete test verdict. Available GitHub console output
is retained in ignored cache, SHA-256
`15469d7203c881b47d52ba3c735031acf8259b882211d7fec6689eeeb39eebe4`.
The old worker journal was not uploaded; that missing evidence is not recreated.

## Change And Scope

The registered `validation-progress` component composes the existing Library
progress fragment. The host submits per-test completion observations bound to
the actual producer, fresh epoch and input inventory; Scheme owns frontier and
replay admission. The observation window is configured by the DSL, not repeated
in the Python default or CI flags. CI's ten-minute override is removed; external
infrastructure cancellation remains distinct from inactivity and acceptance.
Partial logs are uploadable without a final receipt, and caught SIGINT/SIGTERM
produce incomplete interruption observations without an invented exit/PASS.

The existing Session, registry and EvidenceProgress transport are reused. No
new command family, workflow planner, runtime patch, compiler flag, native
checkpoint, acceptance budget or dependency revision is introduced. Other
threads' pending Python task/broker/isolation changes are excluded from the
publication index, without reverting their working-tree edits.

## Negative Observations And Corrections

- A direct working-tree collect initially rejected a concurrently changing
  model receipt as belonging to another model. The isolated publication tree,
  not that dirty catalog, is the qualification subject. No unrelated model
  receipt was rebound or weakened.
- The first short healthy-child control allowed cold Scheme construction to
  consume its 0.8-second observation window. It expired; the restricted local
  process-group cleanup also reported EPERM. This was not a Gambit failure.
  Policy construction now precedes process observation, including with an
  explicit window override. The same short window and assertions are retained;
  actual owned-process cleanup is checked with the required host permission.
- Temporary fixture setup errors remain diagnostics: copying only a component
  manifest omitted source files in its registered closure. The isolated fixture
  now materializes that actual declaration closure instead of bypassing it.

## Local Qualification

The isolated publication-scope tree passed:

```sh
python -m unittest tests.test_review_validation tests.test_repair_consumer_interfaces tests.test_reasoning_methods -fv
python -m gambit_smp.evidence_index --validate
```

Results: **34/34 tests in 53.209 seconds**, and `DATALOG-COVERAGE-OK`.
Controls include real registered Scheme inference, configurable policy, unknown
test and wrong incarnation, actual healthy execution beyond the observation
window, repeated-completion expiration, real SIGTERM with preserved journal and
reaped owned child, source revocation, no false completion, anchored Clue query
and checkpoint continuation. Existing guarded Lean consumer lemmas are included.
This is focused framework/research qualification, not the full CI or SMP native
campaign. No original bootstrap or stress test was repeated.

## Existing Models And Source Research

The completed-work watchdog QNT already distinguishes noise, genuine completion
and premature wall-quota termination. The new adapter uses those distinctions,
not its finite numerical clock bound as a runtime constant. The Library owns
identity/cursor semantics; source correspondence still requires actual host
observations. No historical model PASS is reissued for new host source bytes.

The coordinated research also publishes the audited outer-handler / TTY alias /
close-error Recipe, Chez carrier lifetime comparison, OCaml release/acquire
acknowledgement comparison and registered source-census gap. Existing handler,
last-consumer QNT and Lean model bytes remain unchanged and retain their scope.
No model or framework result closes an SMP native contract.

## Finite-Inventory Reasoning Boundary

The source adapter's immutable inventory gives each expected test its own
contract, and each completed-unit observation has value one. With a valid
initial cursor zero, a given key can advance at most once. Consequently an
inventory of N test identities admits at most N fresh frontiers; replaying
records cannot create an infinite sequence of renewals. This is the useful
engine-side alternative to a ten-minute global wall cap.

This argument assumes an attested immutable inventory, correct scope/actor/
epoch/source binding, returning observation/inference operations and a fairly
scheduled host clock. It does not prove those host premises, an unbounded
end-to-end liveness theorem, or that a long internal operation is deadlocked.
The existing QNT negative controls and actual Scheme replay tests check the
relevant distinction; they are not relabelled as that stronger theorem.

## Complete CI And Storage Follow-Up

Exact head `03bb21733def2943ff0928af0d7cef93aead23b7` passed framework run
`39409796528`, job `118584461462`: **1837/1837**, zero failures, errors,
skips, expected failures or unexpected successes; complete inventory and no
changed inputs. Test work was **480.546808099 seconds**; supervised execution
was **484.387088324 seconds**, exit zero, no timeout, parent reaped and process
group quiescent. The configured inactivity window remained 300 seconds.
Full Evidence export and upload passed. The separate sealed domain's 110 tests
passed on two host-selected lanes; 1727 local completions produced 302 admitted
progress batches. The frontier count is not falsely reported as 1837 individual
parent-stream observations.

Official receipt SHA-256:
`68fa108efa85ba8b2f9cef20d5096c12eca3d6437fe1545fcf29e84966ef9237`.
The complete original artifact is retained in compressed cache, not Git.
The duplicate native workflow for this head was cancelled; older native runs
were not modified.

Artifact inspection exposed repeated full cursor snapshots: **275939536 bytes**
in `progress.jsonl`. The storage projection now records changed keys directly
from Scheme's `progress_advanced`, plus the same observations and rejections;
it does not recalculate admission in Python. `cursorProjection=changed-keys`
prevents treating an empty delta as an empty complete census. The producer also
hash-binds this delta log, checked before reuse alongside its process log.

Independent replay checked all 302 actual CI records against their original
full before/after states. The initial state exactly matched the immutable
1837-test inventory, and its source digest matched the official receipt's
input bindings. Every projected transition reconstructed the same full state:
1837 retained cursors, 1727 advanced. Projected size is **1840574 bytes**, a
**99.333%** storage reduction for this actual trace. This is not a runtime
speedup or a new full-framework verdict for the follow-up source revision.

The isolated follow-up source passed the same three focused modules:
**35/35 in 63.184 seconds**, including changed-key projection and delta-log
tamper rejection. The whole-CI result above remains bound to `03bb217`; the
follow-up must obtain its own exact-source framework result.
