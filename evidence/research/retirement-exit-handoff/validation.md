# Current Retirement Exit/Handoff Composition

## Scope And Sources

This is research for the current 9/12 repair, not a new runtime, collector,
foreign-host attachment API or native qualification. The recipient VM survives.
The QNT model imports the existing callback-result, saved-stack and retained-slot
machines and the shared `WorkObligations` definitions. Their sources and old
receipts are unchanged. New state expresses the missing composition boundaries.

| Checked input | SHA-256 |
| --- | --- |
| `models/gambit/retirement_exit_handoff.qnt` | `c3e28a9b6df19c3b6c4edb90f2517e17938d64ab05ef6b66e2c2fa76aa9f68d7` |
| `models/gambit/lean/RetirementExitHandoff.lean` | `6cffccf3be4287e07f97a0e56b0082a990f32ea2afda03ff61780d00b45dc760` |
| `tests/test_retirement_exit_handoff.py` | `d082a08f14e4bb89f8e4d7adcba931de9576a5c22a7746094329cd5d15691ebc` |

Pinned Gambit, Chez and OCaml identities and the detailed source ranges are in
the [current Recipe](../../../docs/current-repair-research.md). They are design
references, not evidence that the implementation candidate satisfies this model.

## QNT Checks

Command: `.venv/bin/python -m unittest tests.test_retirement_exit_handoff -v`.
The final campaign passed three tests in 75.497 s. It used the existing
Quint/TLC backend, a host-derived CPU/memory schedule, a 30 s per-check watchdog
and guarded Lean execution. No runtime build or native test was started.

The positive safety and final-scheduled temporal check completed with 621
distinct states, 1,832 generated states, no queued states and no timeout in
17.027 s. Weak fairness and finite returning C callbacks are environment
assumptions, not a claim that arbitrary user C code terminates.

| Omission control | Decoded actual state violating the protocol | Seconds |
| --- | --- | --- |
| `initMarkerAsExit` | Marker invalid, origin tail not left, yet collective entered. | 11.957 |
| `initMissingRoot` | Source roots removed before all declared target roots exist. | 12.220 |
| `initQueueOnlyWork` | Donor reclaimed while private work remains outside public queues. | 14.393 |
| `initStaleCensus` | Handoff commits a census from an old GC epoch or work revision. | 13.678 |
| `initReleaseCallAsDone` | Donor reclaimed while external release invocation has not returned. | 11.814 |
| `initRetryReleasedCallback` | Two invocations despite an invalidated release-function field. | 11.151 |
| `initJoinOnlyBorrowers` | Donor reclaimed before a remote sender's unlock/signal tail finishes. | 9.332 |

These are decoded finite counterexamples, not reproduced C failure schedules.
Negative runs stop at the counterexample, so a nonempty TLC queue is expected.

Two additional reachability checks use `initFixed`, not fault initializers:
`noSuccessfulHandoff` produces a completed safe handoff with nonempty
recipient-owned work (10.845 s); `noRetainedFailure` produces an explicit failed
join with source ownership retained and no reclamation (10.395 s). Each makes
one join attempt. This rules out a model which only refuses everything and does
not fabricate a legal native error-then-success recovery operation.

## Lean Checks

The guarded companion imports the existing `WorkAccounting` proof, not another
package. Fourteen checked statements distinguish invalid markers from C-tail
discharge, receiver join from remote-tail completion, release invocation from
return, hidden private work from empty public queues, destination coverage,
unfinished recipient-owned work, exactly-once release budget, and binding
identity under changed scope, model, property, observed sources or refinement,
and a partially checked interface bundle. No `sorryAx` is admitted.

Root-slot completeness, actual C return/unwind routes, exclusive host ownership,
memory ordering, real collector phases and source reachability are premises or
open obligations. The integer tokens and root roles are finite census witnesses,
not CPU limits or an enumeration of every native root/work class. Larger host
attachment or independent post-VM carriers remain Experimental.

## ASCENT Correspondence

The existing Scheme component now derives composition requirements from declared
event edges. All declared model interfaces need checks matching the exact model
and receipt digests. An optional source binding must additionally match condition,
scope, both source events and their observed hashes, and the hash of a
source-backed refinement reference. A local model pass cannot create
that binding. The current real bindings remain absent, so all three source
composition obligations remain visible after formal checks succeed.

`composition_gap` feeds the existing `transfer_gap`, premise evidence and Clue
outputs. Observation digests bind the declaration profile, so changes to model
or applicability facts are not hidden behind an unchanged C-source digest.
Caller-declared edge identities are checked for cross-scope/event
collisions rather than synthesized by Python. Empty declarations are allowed;
they do not imply source completeness, native success or execution authority.
New source semantics still have to be registered as domain facts: this is not
automatic extraction of C meaning and does not select the Agent's next action.

The registered view uses the same component and existing selection/Session
interfaces. Its root scope is the pinned source audit, not a new runtime claim.
Source withdrawal, stale model checks, wrong-scope bindings and newly introduced
edges are executable Scheme regression cases; missing native obligations stay
missing even for a synthetically linked relation fixture.

The real `repository_clues` path passed a cross-process registration test in
7.097 s: the first relevant factor query returned one scoped gap; a new process
resumed its checkpoint without repeating that family; widening the factor scope
returned only the other two families. It used the native ASCENT implementation,
not mocked query answers. An automatically removed metadata registration with
read-only hardlinks isolated this test from the native owner's active registry.
Only the PR publication registry receives the new research view.

## Preserved Failures

Initial checks rejected private nested-import references (`QNT404`), colliding
aliased state effects (`QNT202`), an empty instantiation and a shared init action
unsupported by the TLA target (`QNT409`). The final composition imports the
elementary machines and instantiates the remote machine with an explicit role;
it neither edits historical models nor patches the compiler. Lean initially
rejected a missing theorem type and a non-unfolded `decide`; no incomplete proof
was admitted. The first sandbox attempt could not bind the verifier's loopback
endpoint; it was not classified as a model counterexample. Cached failed runs
remain distinct from the completed campaign.

The first Clue key expression used an unsupported closed scalar operator. It
was rejected, not moved into Python. Explicit configurable edge identities plus
Scheme collision detection replace it. There is no new CLI, prompt instruction,
Python inference, runtime change or increase to the owner's 9/12 native count.
The first cross-process integration also rejected a nonstandard Clue role;
the final projection uses the existing `observation` role and ordinary factors,
not a new role or a permissive adapter. A missing process-runner environment
argument was fixed in test orchestration, not in the Library's semantic layer.

The earlier 111.052 s model campaign and its eleven-statement proof remain
historical cache evidence. Final qualification adds the source/refinement and
all-declared-interface contracts; earlier proof identities are not relabeled.


## Campaign Composition Requalification

The model now exposes its complete `configuration` and a distinct `restartFixed`
action for a caller's subsequent cohort. Neither is added to the original `step`;
all existing single-cohort transitions and invariants remain unchanged. A caller
must preserve the surviving recipient's work/roots before starting another donor.
The campaign loss-on-restart control tests this extra obligation separately.

The existing three guarded tests passed again as part of the six-test run in
258.265 s, with unchanged formal inputs. Receipt family:
`.cache/retirement-exit-handoff/run-roojjv8v/`. Its ten QNT checks include the
positive 621-distinct-state safety/progress check, seven decoded omission traces
and two reachability witnesses. Its existing fourteen-statement Lean contract
also passed. New QNT SHA-256: `6678a2de5f4b297b7e12bcbaa524e88bbec9a1bcfac757edee6cb42d67f1040e`.
The historical identities and executions above are retained, not rewritten.
This requalification does not establish a native restart/owner-transfer operation.
