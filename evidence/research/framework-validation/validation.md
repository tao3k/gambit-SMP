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
