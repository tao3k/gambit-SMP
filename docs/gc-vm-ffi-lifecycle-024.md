# Current VM / moving-object / callback observations

All three recipes execute the sealed engine `3839170633ac53bbed5afbce891db89fd912941dc5fd94b3e279b219e0426631`, the same explicit archived completed producer and source lock `316c87a64b5fd16f588141e2601fcce16f38ec88a4e7b7831baffe9467093c52`. GNU GCC16 and all three SMP/multiple-VM/multiple-threaded-VM flags are bound through the original configure and current runtime identity. No runtime source or binary was changed for these observations.

## Executed controls

* `.data/experimental-independent-vms-001`: parent PASS15.249s/300. Two independently allocated VMs each grow a host-derived cohort, retain private roots across forced collections, join workers, shrink and perform owned cleanup. Not initialization-failure injection or every lifecycle interleaving.
* `.data/experimental-moving-retirement-003`: parent PASS15.752s/300. Official `c-define`/`c-lambda` object return verifies the movable header and actual changed address, checks all32 payload entries in C, and checks the returned Scheme root after another collection. The frame fixture rejects removal of the active callback origin, permits unrelated processor removal, returns through the real C frame and completes its join. This is not arbitrary raw movable-pointer borrowing or adversarial callback revoke/drain qualification.
* `.data/experimental-gc-population-performance-001`: parent PASS15.519s/20, complete240 native monotonic samples. Same runtime/executable,1024 live32-element vectors per sample; AB/BA/AB blocks,120 samples each at1 and11 processors. Allocation/checksum/topology changes excluded from individual GC timing, included in the execution/whole cap. Explicit-GC execution capped10s; no timeout caps increased.

All exits0, timeoutfalse; owner finalization and process-group teardown are part of the receipts. Actual `research --read` returned CURRENT, bindingCURRENT and artifactsAVAILABLE for each. Capability and terminal still state runtime/source-refinement/performance admissionfalse. Local `.data` files are recheckable observations, not Git-persistent raw evidence admission.

## Measured cost, not a speedup claim

| Processors | Samples | p50 | p95 | p99 |
| --- | --- | --- | --- | --- |
| 1 | 120 | 66us | 109us | 139us |
| 11 | 120 | 652us | 958us | 1056us |

For this small moving live-set the parallel population's median pause is about9.9times higher. This is correlated within-process population comparison, not independent confidence intervals, a large-heap result, application throughput, RSS measurement, or matched baseline/repair binaries. Preserve this adverse observation; do not cite the unrelated SHA microbenchmark as a GC improvement.

Raw population file SHA: `0f6e8ce5434e89dcc96001e14f3650c0c3bbbbfd81bc235732dd82bae24c0564`. Parent performance receipt SHA: `81760b18bcede661da2b133aa194019647281e890cb8968b387a8a1c4d91c99d`.

## Preserved failures

Moving-retirement001 failed compilation: Gambit's vector-check macro required local `___temp`; no native execution or retirement occurred.002 compiled but failed the physical-movement assertion: the1024-element vector did not establish a moving allocation.003 changes the input to a32-element vector and requires its movable header in addition to physical relocation; no movement assertion was removed.001/002 raw receipts, generated-input copies, logs and original identities remain untouched. These failures are fixture observations, not a claim to have repaired the collector.

## Evidence boundary

`lifecycle-024.view.json` uses the existing reasons DSL. Three exact component requirements have source-bound support; initialization rollback, movable C borrowing, adversarial callback retirement, and matched repair-performance remain unknown. Withdrawal of the moving receipt removes both its support rows. The previous stable-payload view remains historical and unchanged. Full consumer/current-graph qualification and the separate known Gambit runtime failures remain open.

Relevant actual Library consumer regression: `.data/lifecycle-consumer-024`,7tests/0skip, parent8.344s under the unchanged15s whole watchdog, exit0/timeoutfalse/group-quiescent. Includes source withdrawal and real existing payload-transfer/parallel-design consumers. This is the relevant seven-test slice, not full consumer/current-graph admission. `git diff --check` passed.
