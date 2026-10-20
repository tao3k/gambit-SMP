# Evidence-Driven Framework Validation

## Meaning And Ownership

Elapsed wall time is an observation, not a deadlock proof. Framework validation
uses the existing registered Scheme component system, Session and Library
`evidence-progress-fragment` to decide whether an observation establishes a new
completed-work frontier. Python transports observations and enforces the
declared inactivity window; it does not count unique tests as a second semantic
engine, infer an Agent's thoughts, or choose investigation steps.

The application policy is the `validation-progress` entry in
`evidence/dsl/components.json`, implemented by `validation-progress.ss`.
Its `watchdog_window` fact configures the observation window. The CI command
does not repeat its value. The existing explicit `--timeout` override remains
an inactivity-window override, not a whole-campaign quota or performance gate.
Neither a model's small finite clock bound nor host CPU count is a production
timeout configuration.

## Facts And Inference

The worker atomically publishes its actual test inventory, process ID, a fresh
execution epoch and the digest of its collected input bindings before running
tests. The parent checks the observed worker identity against its own spawned
PID. Each completed journal record is submitted as one unit in that test's
declared scope. The Library, not a Python set, checks the contract, source,
actor, incarnation, attestation, completion and retained cursor.

| Observation | Admitted consequence | Not established |
| --- | --- | --- |
| New, source-bound expected test completion | Scheme derives `progress_advanced`; the transport renews the observation window. | Test success, full inventory completion, process quiescence or native acceptance. A completed failing test is real work, not a passing result. |
| Same test completion repeated | Cursor does not advance; the rejected observation is retained. | Fresh progress, even when output continues. |
| Unknown test, wrong actor or epoch, changed inventory | No admitted progress, or a typed transport identity failure. | Permission to inherit another run's frontier. |
| No admitted progress throughout the configured window | `no-admitted-progress-within-window`; the owned process is stopped and retained as incomplete. | Proven deadlock, a source cause, or evidence that every internal operation stopped. |
| SIGINT / SIGTERM or infrastructure cancellation | External interruption / incomplete execution, with available observations preserved. | Inactivity expiration, successful completion or a native regression verdict. |

The existing `EvidenceProgress` cursor is the Session baseline. Repeated or
restored evidence is not new work. A missing inventory or absence of output
does not synthesize a completed unit. The engine returns facts and reasons;
it does not restrict a model's alternative hypothesis or investigation.

## CI And Durable Partial Observations

The former ten-minute job override could cancel a healthy full campaign before
its own inactivity observer reached a verdict. It is removed. GitHub still has
external infrastructure limits, but those remain cancellation boundaries, never
application deadlock or performance criteria. The application window is not
increased to compensate for a slower host.

`tests.log` is flushed during execution. `inventory.json`, `context.json` and
`progress.jsonl` bind the population, incarnation, raw observations, accepted
frontiers, rejections and changed-key cursor deltas. The immutable inventory
supplies the initial zero cursors; replay applies only the Scheme-admitted
changes. Repeating the entire unchanged population in every record is neither
needed for recovery nor a new completeness witness. On a caught external
interruption the parent
retains an interruption receipt and diagnostic process log, without inventing
an exit or quiescence witness. The final exit, actual test outcomes, unchanged
inputs, complete inventory, reaping and group quiescence remain separately
required for framework PASS.

CI uploads an existing partial output tree even when it has only logs and no
final JSON receipt. An uncatchable kill or forced runner removal can still
prevent finalization/upload; no framework can retroactively reconstruct logs
that the old run did not retain. The cancelled `39406034219` run is preserved
as such, not relabelled after this repair.

## Existing Model Connection And Falsifiers

`models/gambit/completed_work_watchdog.qnt` already distinguishes completed
work, repeated noise and a wall-quota policy. Its `truthfulClock` and
`noFalseTimeout` negative controls explain why the ten-minute cancellation and
heartbeat renewal are different from the intended policy. This is a finite
abstraction, not an instruction to hardcode its clock bound, a C refinement
proof or an unbounded fairness claim. Historical receipts retain their original
context bindings; new source applicability is not granted by copying a PASS.

The actual Library progress fragment supplies contract/actor/epoch/source and
replay checks. Host integration is tested against real Scheme Sessions and
owned Python children, including total execution beyond a short observation
window, repeated-completion expiration, configurable Scheme policy, wrong
incarnation, unknown test, and real SIGTERM with preserved partial output.
The producer failure and missing-quiescence controls continue to reject PASS.

This work changes framework observation, not Gambit runtime behavior. Existing
handler/root QNT and Lean ownership/last-consumer obligations remain separate.
No bootstrap, original stress suite, GC/FFI or Gerbil native campaign is repeated
to qualify this adapter. Framework green cannot close an SMP native gate.
