# Interrupted Suite Observation

## Contract

The existing Python framework retains a plan before workers start, then replaces
the aggregate progress snapshot atomically after each completed future. A
reader sees an entire old or new JSON snapshot, not a partially written one.
This is not an fsync durability guarantee or permission to resume expired work.

The interrupted collector accepts only an actual sealed DENY root timeout with
observed root teardown, no final child receipt, the exact candidate identity,
matching preflight budget and root-owned native suite directory. It projects
process outcomes only when completion and process teardown were observed.
STARTED records have no invented exit, duration or timeout. Every projected
group has `suiteAccepted=null`; the whole record remains DENY and non-admitted.
Neither a process exit nor a log marker certifies file membership or complete
source-stable suite success.

Personal paths, arguments and environments are not copied into the versioned
projection. Original byte hashes bind the local observations. The projection
does not replace those originals for future admission or reconstruct a lost
complete suite receipt.

## Existing Model Correspondence

`models/gambit/interrupted_producer_recovery.qnt` already requires committed
passing evidence, current identity, quiescence and unreset elapsed budget at
both recovery and consumption. An interrupted suite projection has no committed
passing suite evidence; it cannot satisfy `qualified`. Root quiescence does not
invent child completion. The expired whole deadline cannot be reset by reading
this archive. `checkpoint_dependency_recovery.qnt` additionally rejects missing,
stale and cyclic parent evidence. No new resume permission is introduced here.
This is a contract correspondence, not a new formal verification receipt.

## Native Checkpoint

The configuration Grid's original 300-second envelope ended at 300.297 seconds.
Its portable interrupted observation is at
`evidence/source-results/fixtures/vm-registry-reader-lease/interrupted-compiled-configuration-grid/receipt.json`.
The selected source inventory contains 379 files. Eleven process records exist;
eight have observed zero exits and three have no completion observation. There
is no inferred passing-file count and no full SMP admission.

Reproduce collection from retained local original inputs using the framework:

```sh
python -m gambit_smp.native_archive \
  --source RUN/run/native-gsc \
  --identity RUN/run/producer/identity.json \
  --interrupted-parent RUN/receipt.json \
  --out FRESH_ARCHIVE
```

`RUN` denotes the original sealed run, not a numbered source authority. A fresh
checkout cannot recreate identical historical timings by rerunning a timeout;
the versioned observation preserves that distinction.

## Validation

The current-suite archive tests cover partial success without suite acceptance,
portable output, fresh-only archival, root timeout/teardown, budget mismatch,
final-child receipt rejection and invented unfinished outcomes. The native
recipe test checks that one slow owner does not hide another completed owner,
while preserving exact inventory and existing deadlines. Fifty-seven focused
framework tests passed; these do not constitute native SMP correctness tests.
