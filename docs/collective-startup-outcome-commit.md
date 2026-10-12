# Collective Startup Outcome Commit

## Native Failure and Model Correction

The header-consumer fixture was compiled coherently after discarding five
zero-byte objects left by a killed compiler. Its single-processor startup
passed in 0.065 seconds, but host-auto parallel startup timed out at 30.046
seconds with no output. Neither is full runtime admission. Their portable
observations and exact runtime identity are under
`evidence/source-results/fixtures/header-consumer-dependencies/`.

Source audit found a real gap in the earlier collective-ack abstraction:
it required a terminal collective round before old members returned, while
the C implementation published ready before submitting that round. Failure
status had the same window: failed status preceded the ERROR operation carrying
the nonzero return code. The early status allows old members to take their
final NOOP exit before the new requester joins its first synchronous round.
This is a source-consistent explanation, not a same-run stack proof of the
observed startup timeout.

`resize_startup_publication_round.qnt` models those intervening steps explicitly.
Its two negative controls cover early ready and early failed publication. The
first bounded check run printed both expected violations and a fixed no-violation
result, but failed to save its summary because the directory did not exist.
That failure is retained as a non-admitted summary; it is not a raw trace receipt.
The source-bound exhaustive contract is the authoritative model acceptance gate.
Both old controls were reproduced with five distinct states each. The fixed
contract exhausted eight distinct states (ten generated) and passed safety and
temporal completion. The published receipt is
`evidence/model-results/fixtures/collective-startup-outcome-commit/publication-round-contract/receipt.json`.
Datalog records one finite `protocol_checked`, two controls, four source
locations and five open obligations; it does not record native acceptance.

## Source Repair

The `collective-startup-outcome-commit` fixture removes pre-round ready/failed
stores. READY carries processor identity and epoch; synchronous operation
dispatch commits ready for the current slot generation. ERROR dispatch commits
failed for a pending new processor using the winning processor identity.
The missing-ready zero-return conversion is retained. Queue initialization and
unlock still precede READY submission, and the existing final NOOP/reset rounds
remain in place.

The cumulative overlay and source lock contain 16 files at the pinned submodule
revision. Only `lib/setup.c` changes relative to header-consumer-dependencies.
The incremental core build completed in 17.562 seconds under the unchanged
180-second budget, using host-auto make capacity and valid parent objects.
This is not a cold build, fresh configure or two-pass bootstrap result.

The actual host-auto parallel startup still timed out at 30.148 seconds without
output. The process group was reaped. Reuse and GC were not launched after that
failed gate. Thus the publication-window repair is insufficient for native
startup; the source-consistent race is not proven to be its unique cause.
Physical barrier first-iteration resets, startup-GC participation and readiness
interaction must be added to the model using further native diagnostics.

## Open Requirements

Model cardinalities do not limit host processors. Arbitrary cohort membership,
generation overlap/wrap and epoch transport through `___WORD` remain source
refinement obligations, especially on narrower word targets. The one-slot
model does not prove those properties or C memory/physical barrier semantics.

Native parallel startup must pass before repeated resize, still/RC survival,
forced GC and custom startup-failure tests are admitted. Cancellation, rollback,
failed joins/quarantine, idle-queue unlink, full GC composition, upstream suites,
bootstrap and Gerbil build/test remain required. A finite model or incremental
compiler success must not imply release acceptance.
