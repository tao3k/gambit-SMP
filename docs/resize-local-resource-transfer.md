# Processor Retirement: Still and RC Ownership

## Review

This is a correctness blocker, not a performance optimization. Earlier models
covered queue/synchronization resource lifetimes and successful join, but not
reachable processor-local still objects or registered RC blocks. The native
retired-requester timeout is separate; moving only its continuation would not
establish memory safety.

The pinned source plus `sync-message-atomic-publication` overlay shows:

| Source | Retirement relevance |
| --- | --- |
| `setup.c:___vm_resize_pstate` | Retiring processors call cleanup before OS exit and P0's join. |
| `setup.c:cleanup_os_and_mem_pstate` | Calls processor memory cleanup. |
| `mem.c:___cleanup_mem_pstate` | Frees the entire still-object list and registered RC blocks. |
| `mem.c:free_still_objs` | Does not test reachability; foreign objects invoke release before memory is freed. |
| `mem.c:cleanup_rc` | Frees every registered block, independently of external owners. |
| `_kernel.scm:##still-copy` | Allocates through this processor and returns an object reachable from ordinary Scheme roots. |

## Native Evidence

The source-regenerated linked runtime used host-selected capacity: 12 available
processors on this host, allocation on the last processor (11), caller pinned
to retained processor 0. Those are observations, not fixed test worker limits.

`resize_still_survival.scm` validates the object before shrinking by one
processor. Shrink returns with the expected population. A subsequent forced GC
and equality check fails with `reachable still object lost`, exit 70, in
0.029921 seconds. The 30-second budget did not fire; the process group was
quiescent. Runtime input/artifact identities were validated before and after.

Portable source-bound evidence:
`evidence/source-results/fixtures/sync-message-atomic-publication/still-survival-observation.json`.
This demonstrates failed post-shrink survival, not an RC failure or a complete
proof of the exact corrupting write. The source cleanup path supplies a concrete
ownership violation to audit. No unchanged native retry is justified.

## Model Evidence

`resize_local_resource_transfer.qnt` requires closed allocation/scan admission,
successful thread/OS drain, scanner completion, atomic owner/accounting transfer,
then cleanup. It deliberately grants the bad free-local policy a successful
join first: even that stronger premise does not justify freeing reachable data.

TLC accepted safety and progress over 13 distinct / 17 generated states. Three
negative controls violate reachable-resource preservation (12 states), owner
accounting (11 states), and scanner stability (14 states). Campaign time was
20.833 seconds. Host-auto selected two controls with six TLC workers each and
12 workers for the positive check. Portable receipt:
`evidence/model-results/fixtures/sync-message-atomic-publication/local-resource-transfer-contract/receipt.json`.

The resource tokens are not an allocator proof. Exact still-object word counts,
deferred accounting, list links, registered RC handles, foreign-release reentry
and arbitrary population remain obligations. GC completion is not inferred
from OS join or an empty runnable queue.

## Source Repair Gate

Do not disable cleanup globally or silently leak retired lists. Separate
processor retirement while the VM remains live from terminal VM destruction.
The live-VM path must retain or transfer reachable still/RC ownership and
accounting to a retained owner before destructive cleanup. Closed admission,
GC borrower drain and list-splice serialization require explicit source
refinement. Terminal destruction must still release objects exactly once.

This must be composed with requester/queued/pinned thread drain, result delivery,
failed joins and slot reuse. No implementation patch is admitted by this model
alone; runtime and release admission remain false.
