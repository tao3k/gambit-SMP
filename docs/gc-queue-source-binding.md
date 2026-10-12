# Queue/Wait Source Correspondence Guard

## Purpose And Admission

The finite composed queue/wait model is checked, but a Datalog dependency edge
does not prove correspondence to runtime C. This adapter adds a deliberately
limited lexical-order guard. It does not execute GC, prove C semantics or grant
native permission. Expected runtime benefit is unknown; no runtime code changes
are made. Existing failed native routes are not rerun.

`gambit-smp gc-queue-binding --source <reviewed-mem.c> --out <new-campaign>` first
requires the complete five-check partition receipt and the current paper/source
context. It binds model, manifest, proof/logs/traces, source, checker and shared
binding code by digest, then rechecks those inputs before writing its receipt.
No historical observation is accepted as a current runtime pass.

## Boundaries Checked

- Exact reviewed function boundaries; ambiguous/missing boundaries are rejected.
- Publisher Q lock, link publication, first barrier, tail publication, second
  barrier, Q unlock, unprotected notification, in that order.
- Current publisher has no new M acquisition; a changed proposal needs its own
  source audit, rather than borrowing the source characterization verdict.
- Local and remote queue consumers retain post-ticket barriers, pop under Q,
  and release Q before scanning complete chunks.
- Idle count decrement precedes wait; the complete post-wait zero branch exits
  without increment and the nonzero branch increments before releasing M.

Comment/whitespace normalization is only a lexical aid. Preprocessor branches,
macro definitions, hidden aliasing, compiler ordering, omitted control-flow
paths and global lock correctness are not established by substring guards.
The adapter explicitly records `combinedPolicyImplemented: false`: the existing
source does not implement the modeled combined notification proposal. All eight
composition obligations remain open, including source refinement and C ordering.

## Adversarial Validation

The first checker accepted a mutation that inserted an early mutex release
before activity restoration, because the expected restoration/unlock suffix
still occurred later. This is a checker false acceptance, not a runtime defect.
The negative test failed and led to a stricter continuous post-wait branch guard.
Keep that failure as a limitation of lexical reasoning; do not call the first
checker stronger than it was.

Campaign001 receipt SHA-256:
`ae2b20b35016995f713374f62e5643670b88cf7040033db8efe6c1d49f7105e3`.
It binds the earlier checker and is not current evidence after the checker edit.
Campaign002 receipt SHA-256:
`0c125a70fdfcd83f421d5642ac21760ce17cfaf798723006c88e26c256dd273d`.
Its checker SHA-256 is
`a586b1d6405dc678029964de0a4cb12791174a8e48ff5ac04fa44b6b1427fdfb`.
Raw receipts remain under `.data/gc-queue-source-binding-001/` and `002/`.

Current source passes the strengthened guard. Mutation tests reject notification
inside Q, added publisher M, omitted or early-unlocked restoration, zero-count
resurrection, scanning before Q release, and missing acquire/publication fences.
The initial focused run had one failed negative test; after correcting the guard,
21 binding/composition/CLI tests passed. These tests check the guard's rejection
boundary, not native GC, bootstrap, Gerbil or a performance improvement.
