# Failure Premise Review

## Purpose

Repeatedly reading a PASS model receipt alongside a native DENY is not a
decision procedure. The existing Scheme Evidence DSL now exposes a relational
review for whether another attempt has a declared source-level justification.
It uses the existing ASCENT backend, manifest loader and hash-bound references;
there is no second Python inference engine or native runner.

For each candidate/failure pair, every declared failure requirement needs:

- A relevant source change identity.
- A checked source review identity.
- Model support with a checked result identity.
- Source-to-model correspondence evidence.

A missing requirement classification fails closed. Any unsupported requirement
derives `retry_denied`; all supported requirements derive `retry_reviewable`.
The latter is a review result, never execution authorization or native success.
These relations rely on the correctness and completeness of their input
classifications: the model cannot infer arbitrary source semantics from hashes.

The current source audit checked the locked candidate `lib/mem.c` hash
`6f2245e37edf0f79d5853dc225eef05aa7cd949d7190136a0e11f1508a5f6ce4`:
chunk publication (3422-3451), saved-cursor ownership (3456-3491), own FIFO
consumption (4484-4590), and steal/termination rechecks (7130-7244).
Those mechanisms are already present. This inspection does not establish their
full correctness or infer a missing barrier from the BTQ fault; it prevents
reintroducing already-applied repairs as supposedly new candidates.

## Current Bound Observation

The registered `btq-retry-review` view binds the current diagnostic source lock,
the native failure and the checked copy-epoch composition. It deliberately has
no relevant repair, source review or source-refinement facts. Thus model success
does not justify repeating the unchanged native stress. Inspection actions name
the missing requirement, rather than suggesting another unchanged run.

The composition binding now uses the source-corrected movable-queue successor:
red is false, black/container references track the movable queue. The earlier
boolean-color/permanent-queue projection remains a historical conditional
model, not full source correspondence. Strengthening model context leaves the
native failure and missing source repair/refinement facts unchanged.

IDs are opaque join keys. They do not encode chronological order, progress,
fixture directory availability or the number of closed native gates. Cache
cleanup cannot change the bound source and retained failure facts.

## Scope

This review does not invent a root cause from a failure site, assert an
exhaustive list of causes, close the twelve-gate milestone, or integrate an
automatic runner veto. Execution still uses the existing sealed framework's
authorization and native result checks. Next integration must consume this
review without allowing missing/withdrawn facts to bypass a denied decision.
