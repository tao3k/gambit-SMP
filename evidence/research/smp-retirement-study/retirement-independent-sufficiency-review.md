# Independent sufficiency review: retirement proposal

2026-10-23. Evidence review only. No runtime, qualification inputs or model changed.

## Judgment

The proposal is a credible ownership/safety architecture, but it is not yet a
sufficient correctness or progress argument for 9/12. Contract reachability,
resource safety and eventual successful retirement are three different claims.
The present evidence supports the first and conditional parts of the second.
It does not establish the third, nor resolve the independent interrupt/GC/FFI,
Gerbil or release gates. Formal qualification stays8/12.

Changing OS-error recovery to pending-to-join0 deliberately changes the claim.
It preserves no-early-reclamation and exact-owner completion only if the new
observable obligations are all met. It does not prove the old OS-error retry
sequence, and must not be described as a logical equivalent contract. Keeping
historical failures and a separately required native-error retention control is
necessary. An errno printing change or relaxed observer cannot supply this proof.

## Additional holes found in independent review

1. **Finalize starvation.** A strictly higher-priority GC can indefinitely beat
   finalize when collections recur. The latest finite model drains one competing
   GC, and its preparation has two GCs; it does not establish progress under an
   indefinitely replenished stream. Weak fairness does not rescue a finalize
   action that is never enabled. The implementation needs an explicit safe
   arbitration window: finish a necessary selected GC, retain finalize, then
   reserve a bounded nonallocating collective commit window before admitting
   further mutator work, while still honoring genuine higher-priority faults.
   This is a new proof obligation, not an implemented or model-verified policy.
   Continuous urgent faults or a permanently unavailable member cannot honestly
   be promised successful retirement.
2. **Unsafe member contexts.** Scheme sync return, startup NOOP collective
   (`setup.c:980-1001`), post-___run native loop (`946-975`), lock retry and direct
   shutdown are distinct. A per-processor notification is not proof of a usable
   landing. The preflight must classify every old member and refuse before
   commit if a live context has no supported landing. Such refusal is safe but
   does not satisfy a contract requiring successful resize in that context.
3. **Reaper head-of-line blocking.** One fixed join owner preserves uniqueness,
   but a single serial reaper blocked on donorA can delay donorB indefinitely.
   A fixed owner and durable mailbox do not prove all-donor progress. Specify
   either a supported eventual-exit assumption for every earlier donor or a
   bounded owner assignment per independent join lane before publication.
   More helpers cost native threads and lifecycle/teardown obligations; silently
   switching a live join owner is disallowed. No helper is being created here.
4. **Retained failure is not recovery success.** Quarantined roots/epoch prevent
   unsafe reuse, but a leaked or permanently pinned VM is not a production
   availability solution. Specify which failures complete ABORT, which reject
   before commit, and which require checked terminal retention/host intervention.
   No implementation can guarantee callback termination or OS thread progress
   without an explicit environmental or execution assumption.

## A smaller sufficient transfer design is plausible

Requiring a rollback journal for every transfer is not necessarily justified.
The actual `mem.c:5257` ___transfer_mem_pstate is void, performs no allocation or
callback, and splices still/RC lists and adds counters under MISC_MEM_LOCK.
There is no ordinary error-return branch in that splice. Prefer prevalidation
and preallocation before the first write, then an infallible ownership commit
under collective GC exclusion, with the pending descriptor retained until the
receiver owns the lists and accounting is complete. Check counter capacity and
list/owner invariants before writes. Cleanup and fallible OS operations remain
outside that transaction. MISC_MEM_LOCK alone does not exclude collector scans.

An ownership journal becomes necessary if integration introduces a recoverable
failure after its first destructive write. Arbitrary memory corruption, process
crash or invalid pointer dereference is not a recoverable transfer error merely
because a journal was allocated. The no-corruption/process-survival premise
must be stated, not hidden in the word infallible. Still-list tail traversal is
linear in donor objects; a nonallocating finalize is not automatically bounded
in latency or constant time.

## Next work before a runtime patch is acceptable

A contract review must contain explicit old-to-new claim differences, observable
real pending and join results, exact identity binding, native-error retention,
root/last-consumer coverage, two campaigns on one final producer and negative
controls. It must be approved and migrated as a unit before changing admission.
The existing proposal remains inactive.

The C protocol needs a complete entry classification, explicit opcode/result
and common-exit design, starvation-resistant safe finalize arbitration, exact
once restore/ACK coverage, and a fallibility boundary around the existing splice.
Model additions should allow recurrent GC rather than only a fixed finite prefix,
and distinguish an unserviceable member or blocked donor from successful recovery.
No new QNT results are claimed by this review. Previously accepted19 controls
remain unchanged and conditional. Generated C and source-bound native faults
are required after implementation; model success cannot replace them.
