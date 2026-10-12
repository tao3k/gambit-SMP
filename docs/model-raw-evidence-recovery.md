# Raw Model Evidence Recovery

## Why Summary Admission Was Insufficient

The legacy `ticket_queue_handoff` public receipt names two TLC logs without
shipping those logs alongside it. Its accepted fields alone are insufficient
for ASCENT reuse. The recovered original campaign still has both raw logs and
the QNT snapshot; recovery rechecks them rather than rerunning Quint.

The reusable framework entrypoint is:

```sh
uv run --locked gambit-smp recover-model --case ticket_queue_handoff \
  --from-dir "$RECOVERY_SOURCE_DIR" \
  --out evidence/model-results/ticket-queue-handoff-raw-v2
```

Output directories must be fresh; the command documents the recovery procedure,
not permission to overwrite existing archives. The source directory is local
input, not a durable evidence reference. Registered/current model identity,
original snapshot, initializers, complete result matrix, stable-source marker,
exit/timeout and raw log verdicts must agree. Negative logs must decode an
actual counterexample; positive logs must report complete safety and zero queue.
Logs are redacted with the shared portable formatter, preserving raw hashes in
the recovery provenance. The original and public summary are unchanged.

The first portable recovery omitted the explicit snapshot field subsequently
required by the review interface. It remains historical, unregistered output;
the v2 recovery contains the snapshot attestation. The recovery utility's output
containment guard was then moved before directory creation; it does not alter
the restored model/log bytes. ASCENT revalidates those bytes with the current
checker independently, not by trusting the utility's recovery.json.

## Exact Recovery

The archived and current QNT both have SHA-256
`e471a1bcf5f31d8e2670b55606aa7bb3c3b33e9ae14e040968aa8ac5d32a5947`.
The archived control logs yield the expected handoff counterexample and positive
13-state complete safety result. No progress property was checked in this old
model; safety-only reuse must not be represented as liveness or C refinement.

`evidence/model-raw-log-attestations.json` binds the existing public receipt,
restored snapshot and both portable logs. It uses the review framework's typed
raw-log interface, not free-text cause claims or a newly copied model.

An ASCENT review can report `raw-log-revalidated` only after checking the
archived files against the manifest and current model. It still exits 2 with
execution unauthorized. Source
correspondence, GC/lifecycle, bootstrap and Gerbil build/full tests remain open;
the model's absent fine-grained native obligations are not proof of their
completion. No new runtime test, native retry or performance claim followed.

Negative checks reject missing logs, incomplete positive exploration, negative
logs without a decodable trace, snapshot drift, mismatched initializer, timeout
or unstable source. This repairs one legacy evidence chain, not every
historical summary in the repository.
