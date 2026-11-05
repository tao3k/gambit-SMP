# Repair 9: new producer, carrier and interrupt-flood evidence

Research date: 2026-10-23. Native acceptance remains **8/12**. This study reads retained artifacts only; it does not execute gsi, change runtime code, reproduce a hang, or operate the implementation thread.

## What the additional data changes

There are two unresolved phenomena: the original TFIB invalid header load, and intermittent synchronous interrupt-flood noncompletion. They may interact through GC and scheduling, but no retained witness establishes one common cause. A select-heavy sample does not establish that every processor is deadlocked, nor does successful collective entry/exit establish that each interrupt request has completed.

The retained `interrupt2-p11-stall.json` reports many failed variations: timeout/pipe wake changes, interrupt flag acknowledgement/rearming, target placement, queue draining, and yield-path polling. Reported improvements such as 7/8 and one 8/8 followed by 4/8 reject the claim of a stable fix. These are narrative observations, not newly reconstructed per-trial receipts. Different edits, processor counts, iterations and heap settings must not be pooled into a pass rate. In particular, larger-heap success at one workload does not close the longer workload or original inventory.

## Producer identity separation

| Artifact | Binary SHA prefix | Source significance | Admission |
|---|---|---|---|
| Original vector-inc archive, build-4 | `5620dd70` | Bound TFIB crash UUID c823a9d8, PID 66761 | Stress failed; aggregate DENY |
| Mark archive, build-6 | `829075f8` | `mem.c` skips noncanonical tagged words with `continue` | Cannot qualify a repair; changes marking semantics |
| Origin archive, build-7 | `9eca674b` | Removes that skip; adds shared pre-header carrier | Completed source-core build; no native inventory PASS |

Archive/manifest, embedded receipt, binary and selected source bytes are checked in the companion evidence JSON. Build-7's `_thread.scm`, `_thread.c`, `_thread#.scm`, `setup.c` and generated `gambit.h` match the original archive byte-for-byte. Its `mem.c` differs (SHA 629cbef4726db02e59b442025591f252d06d4433bd61e847973f09f6b7d3edba). Later scratch scheduler edits described in the observation are **not** thereby bound to the exported build-7 source. The common incremental directory is not a generation identity.

The reported 200-second TFIB run without a new SIGSEGV is censored evidence on the diagnostic generation. It is neither `(go 15 5000)` completion nor a classification of the earlier fault. No `gsi-2026-10-23*.ips` file was present in the specifically inspected DiagnosticReports directory at this read; this is a bounded file observation, not proof of absence of crashes elsewhere.

## Actual carrier versus the existing observation model

All source lines in this section refer to **build-7 archive** `runtime/lib/mem.c`, not the moving checkout.

| Operation / field | Actual source | What is established | Missing model premise / minimal design correction |
|---|---|---|---|
| Open mapping | `gc_origin_open`, 50–76; called at 5016 | `MAP_SHARED`, 64 slots, open/create then ftruncate | Same-size ftruncate preserves old content; no run/VM identity or clear. Use a run-bound header/carrier and reject stale records. |
| Per-processor slot | 105–110 | Processor IDs 0–63 select slots | Processor ID is not VM incarnation/process identity. Separate sessions/VMs; reject unsupported capacity and multiwriter sharing. |
| Publish record | 110–120 | Invalidates commit, writes fields, release-stores commit=seq | This is one reusable slot, not the prior two-slot design. Matching sequence alone does not establish current ownership, GC epoch, fault association, or concurrent reader coherence. |
| Cell load | 3768–3772 | Reads `*cell` before diagnostic hook | No pre-cell witness; failure here leaves an older record. Add operation/presence protocol before the original load. |
| Header load | 3781–3789 | Records tagged word before source-level header read; original read remains | Native compiled ordering and survival must be checked independently. No claim that the hook already satisfies all model assumptions. |
| `scan_start` / `remain` | 3766–3768, 3781 | Arguments are already advanced `start` and decremented `n` | They are next outer cursor and remaining outer count, **not** original span start/size. Store explicit original span and current cursor separately. |
| Tail scan | same `again` loop | Hook sees current `cell` | Outer return address/start/count survive tail marking and do not identify copied object's parent/type/field. Add tail provenance; existing `initLostTail` control applies. |
| Frame / root origin | no fields in record type, 33–44 | Raw RA alone exists | No selected GC map, frame lifetime, parent header/layout, root category or allocation generation. Same bits remain ambiguous. |
| Fault freeze | no explicit freeze or fault token | Last committed pre-header attempt can remain | Latest attempt is not automatically faulting operation. Match native PC/owner/sequence and preserve the fault slot; timeout is not a header fault. |

The sampled 4096-byte carrier decodes as 64 64-byte slots on the exported arm64 layout: slots 0–10 are nonzero and have equal seq/commit; others are zero. Nonzero slots all have kind=1 and remain=0, with next outer cursor equal to cell+8 in that snapshot. This does not identify parent layout, establish a current run, or associate a slot with a crash. The file is retained as **unbound forensic bytes** with its digest, not admitted first-fault evidence. Sequence magnitudes are not measured work counts: old mappings can retain earlier values.

## Interrupt request ownership: why wake-only changes are insufficient

This is the `enable-smp` branch of the archived `_thread.scm` (starts at line 9). The later non-SMP definitions with the same names are not the applicable call chain.

| Transition | Concrete functions / fields | Last consumer and open obligation |
|---|---|---|
| Construct synchronous request | `##thread-intr!`, 1336–1358: interrupt vector, result-mutex name/thunk and specific/target; caller locks result mutex | Caller remains blocked until result publication/unlock or supported abandonment/error. Producer queue removal is not completion. |
| Choose destination | `##thread-intr-propagate!`, 1360–1414: thread lock, last-processor/current-thread check | Running target routes to processor queue; nonrunning target routes to thread interrupt queue then run queue. Migration/publication must preserve unique ownership and rediscovery. |
| Enqueue processor request | `___raise_high_level_interrupt_pstate`, setup.c 364–393: HEAD/TAIL under PRIMLOCK, then INTR_OTHER | Queue/root publication exists. Flag and pipe are notification channels, not request identity or result acknowledgement. |
| Dequeue processor request | `___get_next_high_level_interrupt_pstate`, 396–427 | Detaches exactly one node and clears its successor under lock. Returned request is now dispatcher-owned even if **all queues are empty**. Root coverage and completion must include this interval. |
| Dispatch / reroute / execute | `##other-interrupt!`, 1416–1448: local interrupt, result mutex, target/current check | Executes thunk and stores result/unlocks if target is current; otherwise propagates again. A queue-only census misses dispatcher, action, transfer and result-publication ownership. |
| Fast yield | `##thread-yield!`, 1893–1951 | Singleton branch unlocks and returns without explicit queue drain in this function. This is a source fact, not proof that no interrupt checks happen elsewhere. Fast-path liveness requires the complete native interrupt-check path. |
| Wait / collective | `##wait!`, 2550–2566; `___disable_interrupts_pstate`, setup.c 430–439; `___sync_wait`, 675–687 | Wait registers idle processor, selects, then unregisters; disabled interrupts retain SYNC_OP. Neither select return nor one collective completion establishes target-action/result delivery. |

The reported observation that all processor high-level queues were empty while worker progress stopped narrows the search; it does not prove the request vanished. The missing request can be in a thread queue, dispatcher-local transfer, action, result mutex publication, or an unobserved state. Conversely a target that keeps yielding proves target execution, not execution of the missing action. The next discriminating record should follow a **specific blocked sender's request** from allocation to reply/abandon, rather than log more aggregate queue emptiness.

## Minimal research contract before a stable small refactor

1. Keep GC safety and interrupt completion as separate obligations until a common witness connects them. Never skip a bad tagged word to manufacture progress.
2. For GC diagnostics, refine the existing carrier at the boundaries above. Do not add arbitrary logging, allocation or handler-time heap traversal. Preserve source generation, operation, actual cursor, coverage and last-consumer identity.
3. For interrupt delivery, define one request ownership chain: processor queue → dispatcher → thread queue/executing target → result publication → caller consumption, including rerouting, target termination and GC relocation. Keep notification/wake acknowledgement separate from terminal request acknowledgement. Reuse the existing request vector/result mutex and lock discipline where possible; adding a universal scheduler lock is not justified by these data.
4. Before implementing any wake/placement change, demonstrate the exact unserved ownership state or racing transition. Any fix must preserve scanner coverage of the request, result/error semantics, unique execution and progress under GC/migration. Existing partial batches have not done that. First-eight and full native acceptance remain required after a justified implementation.

## QNT value and limits

`repair9_new_data_boundaries.qnt` adds two small safety controls motivated by actual missing evidence:

- Reopening a carrier preserves an old committed slot. Accepting seq==commit alone wrongly admits a previous session; checking identity rejects it.
- Processor dequeue makes queues empty while the request is dispatcher-owned and caller still pending. Calling that state completed violates request completion; retaining ownership until result publication is safe.

Each mechanism has a positive exhaustive safety check and a deliberately weakened check requiring a decoded distinguishing counterexample. These establish why the proposed evidence/ownership distinctions matter. They do **not** establish native liveness, root preservation in actual C, an implemented request ledger, or the location of the real stuck request. Existing `tfib_scan_origin.qnt` results remain tied to their original source hash; its strong metadata premises are not silently attributed to the new partial carrier. The new validation summary records actual results and the retained first parser failure.
