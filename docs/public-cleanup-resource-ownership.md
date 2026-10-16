# Public Cleanup Resource Ownership

## Source Successor, Not Native Acceptance

The proposed protocol now has a source successor, implemented in the reused
thin workspace. Its immutable source lock is
`evidence/fixtures/public-cleanup-resource-ownership/source.lock.json`
(`b410bc83b89a55056ed99f726e211b0ac503fe0cde338449db30f9ec62f22cf0`),
and overlay is `patches/fixtures/public-cleanup-resource-ownership.patch`
(`086e5a279c0758ecf45acc8221a468039dc7ca38d5a8051730fd80b24c41932b`).
Exactly `include/gambit.h.in`, `lib/os_io.c` and `lib/setup.c` differ from the
population-publication parent. The existing exporter reapplied and checked
all 22 selected source files. No additional retained source tree was created.

The OS resource has an explicit atomic readiness field. Successful I/O setup
publishes readiness; failed POSIX nonblocking setup closes its opened pipe.
Async select abort skips an unready resource. Cleanup exchanges readiness to
zero before closing, making repeated OS cleanup a no-op. The atomic field
alone is not a check/use race fix: public PSTATE cleanup now closes/drains
registry readers under the mutation mutex before releasing resources.
Direct users must still have been joined by the owner.

Already-locked owned cleanup calls the internal PSTATE cleanup helper, not the
new public locking wrapper. VM cleanup also closes P0 OS resources before
VM-level memory cleanup; that includes child P0 on the global path. Existing
root/private-helper P0 cleanup does not close its resource twice because of
readiness ownership. Public signatures remain unchanged. This is a GNU
research candidate, with a PSTATE layout change requiring full regeneration
and bootstrap; it is not a binary-compatible drop-in patch.

| Call context | Registry ordering | Resource ownership |
| --- | --- | --- |
| Public PSTATE cleanup | Wrapper locks, closes/drains, opens, unlocks, replays | Joined direct users are a caller premise |
| Growth setup rollback | Public wrapper; new slots not yet published | Setup owner rolls back initialized slots |
| Worker shrink exit | Count already removed under reader grace | Retiring worker owns its OS teardown; P0 joins before memory reclamation |
| Owned VM helper | Already locked/drained, internal helper | Shrunk/joined owner; no recursive mutation lock |
| Global root cleanup | Registry sealed; public wrapper cannot reopen seal | Root cleanup owns drained users |
| VM locked cleanup | Caller already holds/drains registry | P0 OS release is readiness-conditional; VM memory owns P0 memory |

The QNT receipt below predates this source successor and binds its parent.
It proves the abstract protocol, not this C implementation. C memory ordering,
initialization/rollback completeness, existing source-unit adapter extraction
boundaries, full regenerated compilation and native public-FFI acceptance
remain open. In particular the pinned pipe-opening helper's descriptor-move
error path needs separate rollback auditing; this patch does not repair it.
Cumulative milestone completion stays 3/12; this successor requires
requalification. Missing fixture data does not revoke completed source work.

After export, the existing source-lock validator accepted the record and all
22 candidate digests still matched. Focused protocol publication/materialization
regressions passed 37/37 in 5.168 seconds via the existing unittest entry.
These tests validate framework evidence handling, not C compilation or runtime
semantics. Runtime/release admission fields remain false.

## Reflection And Source Facts

This is the public lifecycle continuation of
`vm-registry-population-publication.md`, not a package-specific optimization
or another Python framework implementation. It binds the existing 22-file
source successor and pinned `vendor/gambit/lib/os_setup.c` through
`evidence/fixtures/foreign-origin-population-publication/public-cleanup-resource-contract.json`.

The source calls `___cleanup_pstate` for root P0 before the global VM loop.
The loop then invokes `cleanup_vmstate_locked` on every VM. That operation
cleans synchronization/interrupt queue resources and VM-level OS/memory, but
does not invoke child P0 `___cleanup_os_pstate`. The OS setup dispatcher maps
PSTATE cleanup to `___cleanup_io_pstate`, and VM cleanup to
`___cleanup_io_vmstate`. The latter is empty; the former closes the async
select-abort pipe/event when `USE_ASYNC_DEVICE_SELECT_ABORT` is enabled.
Memory cleanup of P0 in `___cleanup_mem_vmstate` does not close that OS object.

Thus a successfully initialized child with no prior owner-side PSTATE cleanup
has an unpaired OS-resource teardown on this global cleanup path. This is a
source-level resource ownership finding, not a measured native descriptor
leak, crash or explanation of the historical stress timeout. Platform/configuration
guards must be preserved. The observation is not limited to Darwin.

The path was not closed by the existing registry-drain model: draining readers
protects resource lifetime but does not ensure all resources are released.
Nor does public void VM cleanup prove that direct users have joined. Replacing
the research-only helper in ten fixtures with public cleanup calls without
closing these obligations would not establish official-interface acceptance.

Expected benefit is complete, reliable teardown and an admissible public-only
multi-VM regression path. No quantified throughput or startup benefit is claimed.

## Checked Model

`models/gambit/public_cleanup_resource_ownership.qnt` includes the root and
one child, an explicit registry reader, sealing/draining, root P0 cleanup,
child P0 cleanup and child memory destruction. Root/child are semantic roles,
not a host worker-count limit. Successful startup, retired cohorts, joined
direct users and exclusive global lifecycle ownership are premises.

- Current omitted child cleanup: resource-completeness counterexample,
  16 distinct / 22 generated states.
- Injected unconditional-close repair: exactly-once counterexample when the
  caller has already cleaned P0, 18 / 22. This is not an allegation of that
  unconditional call in current source.
- Proposed readiness ownership with readiness-filtered interrupt dispatch:
  safety and weak-fair completion exhaust 28 / 43, queue zero.

The existing framework completed in 18.149 seconds. Check times were
5.425, 5.438, 5.423 and 7.278 seconds, each below the unchanged 15-second cap.
Scheduling was host-auto: available CPUs 12, controls two concurrent checks
with six TLC workers each, positive checks 12 workers. No machine count is
encoded in the model. Context stable and accepted are true; native was not
run and runtime admission is false.

Portable evidence is in
`evidence/model-results/fixtures/foreign-origin-population-publication/public-cleanup-resource/`.
Publication returned `PROTOCOL-EVIDENCE-OK`; the bundle is registered for the
existing Datalog/ASCENT pipeline. Registration is not a completed full graph
query. Composition references record obligations, not whole-model refinement.

## Requirements Before Source And Native Acceptance

1. Give OS resource initialization, publication and cleanup one explicit
   readiness owner. Pair successful/partial initialization with rollback;
   prior public PSTATE cleanup must not permit double-close.
2. Order readiness changes and actual resource use with reader draining, not
   just an atomic boolean check. A check followed by close is still a race.
   Late delivery must not access a retired child's pipe or HANDLE.
3. Separate already-locked internal cleanup from public entry ordering to
   avoid recursively acquiring the VM registry mutation mutex. Enumerate
   resize, constructor rollback, global and public caller contexts first.
4. Preserve direct-user join and foreign-frame ownership requirements. A
   processor count of one is not proof of quiescence; do not silently expand
   API guarantees beyond the model's premises.
5. Validate on the exact new producer through public loader/FFI only, including
   ordinary multi-VM shutdown and a previously cleaned child. Preserve all
   failed receipts, source budget and full native/GC/Gerbil/performance gates.

These requirements are encoded as open model obligations. At the model
checkpoint, the readiness ownership/dispatch semantics were proposals only.
The source successor described above followed the caller-context audit; it
does not discharge the remaining source/native obligations. No private cleanup
or injection fixture was executed. The retained producer remains stale under
the current framework readback contract; see `current-smp-qualification-audit.md`.
