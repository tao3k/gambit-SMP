# Candidate Boundaries

These are source-bound experiments, not the accepted release patch chain.
Model or extracted-function success cannot promote them without complete native
correctness, threaded bootstrap, Gerbil/package checks and later performance
acceptance.

- `gc-table-serialization-snapshot.patch`: rooted snapshot for the allocating
  text serializer cursor and captured metadata. Original concurrent-GC key
  query fails; the exact source-bound GNU GCC core rebuild and same regression
  pass both modes. Complete suites/bootstrap and weak/union-find contracts
  remain open. See `docs/gc-table-serialization.md`.

- `shared-pipe-predicate-lock.patch`: exact PR1037 shared endpoint mutex.
  Both predicate and close/wait models are required before the source-bound
  GNU GCC rebuild. Neighboring original I/O files pass both modes; the exact
  upstream timed fixture remains DENY in compiled mode. Its once-set absolute
  deadline requires a separate source/API model obligation, not a larger
  timeout. See `docs/shared-pipe-predicate-lock.md`.

- `test-pipe-read-deadline.patch`: model-bound test-only per-read deadline
  rearming. Keeps all loops and assertions; original cached fixture unchanged.
  Both modes pass with host-auto balanced runner/child topology and the
  unchanged 60-second whole-mode budget. Not a runtime speedup or full-suite
  admission. See `docs/shared-pipe-predicate-lock.md`.

- `test-thread-interrupt-completion.patch`: test-only mutex completion gate
  and join, retaining every original assertion. The equivalent isolated fixture
  passes interpreted and compiled execution; whole-suite admission remains
  open. This is not a runtime repair. See `docs/thread-interrupt-test-protocol.md`.

- `checked-negate-return.patch`: one-line checked arithmetic predicate repair.
  Actual GNU GCC core rebuild and the original interpreted/compiled fxmul
  regression pass. Complete native and bootstrap acceptance remain open.
  See `docs/checked-negate-return.md`.

- `ended-interrupt-lock.patch`: exact PR1047 ended-target unlock repair.
  The old native regression fails two nonblocking trylock assertions; the
  source-bound GNU GCC rebuild and interpreted/compiled regression pass.
  Full bootstrap and native toolchain admission remain open.
  See `docs/ended-interrupt-lock.md`.

- `test-thread-start-join.patch`: test-only explicit completion before the
  original shared-value assertion. Adds one join and removes no original work
  or assertions; the same six-thread campaign now passes both interpreted and
  compiled execution. Complete suite and bootstrap admission remain open.
  See `docs/thread-start-completion.md`.

- `vm-resize-rollback.patch`: partial processor growth rollback candidate;
  extracted-source failure controls and native successful growth do not cover
  every resource-creation failure.
- `processor-zero-cleanup-error-guard.patch`: exact PR793 cleanup condition;
  not the QNT seal/drain design and not a compiler SIGBUS repair.
- `diagnostic-gc-table-header-observer.patch`: diagnostic-only fail-stop probes
  at scan, enqueue, cleanup and rehash. Valid-looking wrong-size/layout headers
  can pass these checks. No retry after the observed diagnostic compiler SIGBUS;
  no performance claim, official promotion or symptom-suppressing return.
- `diagnostic-scan-reference-context.patch`: Darwin high-address mapping probe
  with active scan context; narrow diagnostic, not general pointer validation.
- `diagnostic-old-space-input.patch`: Darwin to-space input refusal before
  movable copying; tests a source precondition, not a runtime repair.
- `diagnostic-scan-input-ownership.patch`: bounded VM/cycle visit tracking and
  scan-entry field snapshots; saturated visit tracking is explicitly unknown.
- `diagnostic-scan-visit-capacity.patch`: capacity/hash extension after an
  observed saturated counter; no collector repair or performance claim.
- `diagnostic-scan-origins.patch`: records local, owner-queue and stealing scan
  origins. The shared diagnostic visit lock can dominate native execution;
  diagnostic timings are not collector performance evidence.
- `gc-queue-acquire-handoff.patch`: three post-ticket-acquisition barriers at
  GC queue consumers. The bounded model and lexical binding pass; native and
  bootstrap admission remain open. See `docs/gc-queue-ticket-handoff.md`.
- `gc-postcopy-headroom.patch`: bases the uncapped GC allocation floor on actual
  copied-section assignment as well as the existing processor/live floor.
  First host-auto decode regression passes all three stages; repeated stability,
  complete suites and bootstrap remain open. Maximum-heap cap is unchanged.
  See `docs/gc-postcopy-headroom.md`.
- `gc-table-iteration-snapshot.patch`: typed rooted snapshots before callbacks
  in GC table for-each/search/fold. A standalone compiled FFI protocol test
  passes; actual GNU GCC core rebuild and twelve related original/regression
  files pass in interpreter and compiled modes. Complete upstream-suite,
  two-pass bootstrap and release admission remain open.
  See `docs/gc-table-iteration.md`.

- `vector-increment-type-guard.patch`: checks an explicit public vector increment
  delta before unsafe atomic fetch-add. The original compiled suite exposes the
  missing type exception, and the bounded QNT negative/positive checks pass.
  Actual GNU compiler rebuild and unchanged increment/CAS tests pass in both
  modes. Complete suites and bootstrap remain separate requirements.
  See `docs/vector-increment-guard.md`.

The shared runtime identity helper reverses the diagnostic patch in a temporary
tree and requires recovery of the prior source inventory. All other inventory
files must remain unchanged. Artifact hashes bind the binaries actually tested;
they do not prove generated-source parity or a complete bootstrap.
