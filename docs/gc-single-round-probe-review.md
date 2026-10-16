# GC Single-Round Probe Review

## Before Code

| Question | Evidence-based answer |
| --- | --- |
| Is the path supported? | Current `mem.c` runs `(np-1)*1000` unlocked hints and retains a locked all-queue recheck before scanner retirement. Idle probing can be reduced without deleting the Q/M wait handshake. |
| Was it explored? | Earlier recursive/ranking records explicitly leave the repeated-probe source correspondence open. No accepted single-round native candidate is recorded. Existing notification and memory-order controls must remain unchanged. |
| Is it worth trying? | Yes as a bounded Darwin performance hypothesis. It removes redundant hint loads and modulus calculations, not roots, parallel workers, locks, barriers or active-scanner accounting. |
| Expected benefit? | On the current 11-processor topology, one complete round uses 11 rather than 10,000 hints on the empty path. End-to-end speedup and attribution of the TFIB failure are unknown. |

Do not merely set the existing cycle constant to one. Its index expression can
omit a queue in a single round. The proposed order visits all processor queues
once, including the owner's queue, without assuming the preceding local scan
necessarily drained all exported work. The existing protected recheck remains.

`gc_scan_probe_round.qnt` composes bounded index coverage with the existing
Q/M visibility/notification model. The bounds are logical verification domains,
not hardcoded host cores. Coverage does not establish payload correctness,
worker fairness, arbitrary memory behavior, or the cause of the native timeout.
Only after the positive check and naive-single-round negative control pass may
a Darwin-only source candidate proceed to bootstrap and real regression tests.
