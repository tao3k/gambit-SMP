# Root signal implementation acceptance audit

## Execution contract

The human authorized Grok to edit the scoped implementation and the supervisor
to audit and execute acceptance. Relevant source transfer to Grok was explicitly
authorized after an automatic review rejection. The rejected invocation did not
execute. The first sandboxed continuation failed service access; retain both logs.

Use the retained collective-wait runtime. `research --read` of
`.cache/processor-interrupt-collective-wait/procedural-retirement-native` returned
PASS/CURRENT with retained custody on 2026-10-19. This is permission to reuse its
declared outputs, not release admission. Never change the retained runtime in
place. Do not repeat configure, seed, source-core regeneration or bootstrap.

## Review findings

1. `lib/os_setup.c:user_intr` writes root P0 directly; the ordinary broadcast
   path in `lib/setup.c` already owns reader admission and drains readers.
2. Preserve root-only USER delivery independently of broadcast USER. Reserve a
   representable bit outside the interrupt-code range and audit every consumer.
3. A temporarily closed registry may defer and replay. A terminal sealed
   generation must not reopen. Pending bits are cleared at exclusive new setup;
   this does not prove quiescence of arbitrary old-generation external callers.
4. The earlier proposed signal fixture had no readiness acknowledgement before
   pthread_kill. Require a blocked-signal ready handshake and bounded waits.
5. Real self-join must happen inside a worker after its thread handle is
   published. Its later owner must successfully join that same worker. This is
   wrapper error preservation, not a runtime pending-retirement-join failure.
6. Existing registry close/open/replay exports are research controls. A fixture
   using them must not be described as upstream official-public-only acceptance.
7. External raw PSTATE users still require joined-owner lifetime. Do not destroy
   active resources to turn a caller contract violation into a runtime defect.

## Retained model failures

The supervisor extended the finite SC model with transient reopening, deferred
root-only replay and terminal sealing. The first trajectory test used `enabled`,
which Quint's simulation runtime does not support; its failure remains in
`.cache/root-signal-retirement-extended-tests.log`. Replace those trajectory
assertions with shared guard predicates, retaining TLC's enabledness invariant.

An attempted verifier resume correctly rejected the changed model with
`resume model/initializer differs`. Recheck changed models without reusing an
old model receipt. Model rechecking is not a runtime bootstrap.

## Required native receipts

Before repairing a copied runtime, compile the exact fixture against the retained
baseline. Preserve the expected closed-admission failure and its exact exit and
output. Recompile that same fixture against a copy with only setup.c/os_setup.c
changed, rebuilding the two native objects, static archive and linked drivers.
Record source, compiler, archive, drivers, fixture and executable hashes, raw
logs, finite budgets, process exit and group quiescence. The original runtime
must still match its initial identity after the campaign.

Run the unchanged external procedural producer/consumer fixture against the
repaired runtime as a source-change regression. Keep full GC/FFI, current Gerbil,
release performance and runtime failed-join/sticky-root acceptance open until
their own exact-source native contracts complete. Cumulative completion remains
8/12; neither this audit nor a finite model grants a new completed gate.
