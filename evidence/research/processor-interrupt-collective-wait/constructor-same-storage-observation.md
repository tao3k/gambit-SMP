# Current Constructor OS Failure And Same-Storage Retry

## Source And Reachability

This is real current-source native coverage of non-root P0 OS-constructor
failure, complete failure return, resource restoration and same-storage retry.
It is not coverage of every constructor failure or the complete lifecycle gate.
Cumulative progress remains **8/12**, with this specific requirement newly closed.

Source lock: `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
Patch: `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
The source is the pinned vendor revision **plus this patch**, not the vendor
checkout alone. No new C repair was needed: the retained cumulative source
already has the tested rollback. An unnecessary duplicate repair is not added.

The current path is `___setup_vmstate -> ___setup_pstate ->
setup_os_and_mem_pstate -> ___setup_os_pstate -> ___setup_io_pstate ->
___open_half_duplex_pipe`. With no available descriptor slots, real `pipe`
returns `EMFILE`. The current I/O callee leaves both pipe descriptors at -1,
keeps `select_abort_ready=0`, and releases its allocated fdset before returning
the encoded error. The outer VM caller aborts private msections, global-root
tables, OS state and activity-log ownership. `cleanup_interrupts_pstate` only
drains interrupt payloads; the final `cleanup_interrupt_resources_pstate`
destroys the retained mutex and clears its readiness flag. The model tracks
that deferred ownership explicitly instead of conflating draining with freeing.

## Bounded Standard POSIX Fixture

The fixture uses official Gambit table setup/run/cleanup and standard POSIX
resource APIs. There is no RTLD_NEXT, function replacement, runtime fault hook,
debugger, process fork or global host configuration change.

The isolated test executable creates its worker threads and allocates private
VM storage first. It lowers only its own soft `RLIMIT_NOFILE` to no more than
`available CPUs + 8`, retaining the original hard limit. It opens only owned
`/dev/null` descriptors until real `EMFILE` and independently checks pipe failure.
Each CPU-derived worker calls the real constructor concurrently and requires:

- The exact encoded `EMFILE`, not an arbitrary failure or exception.
- Zero published processors, target one, no VM-list links or private glo tables.
- No msections, interrupt/sync readiness, abort-pipe readiness or fdset storage.
- Both abort-pipe sentinel descriptors equal -1, establishing I/O setup reachability.

Only after every failed call has returned does the owner close its own opened
descriptors, restore and read back both original limit values, and check a real
successful pipe creation. The root VM remains ready and alone in the list.
Each worker then calls setup on the **same pointer without free, memset or
replacement allocation**. Successful workers run the real Scheme module with
private rooted vectors across forced GC, call public table cleanup and join.

## Native Result And Work Boundary

Observed available capacity: 12 CPUs; derived child owners: **11**. There are
11 exact OS-error returns and 11 successful same-address retries. Each retried
VM executes 12 root/forced-GC rounds: 132 in total. GNU GCC 16 and the retained
Bazel profile keep SMP, multiple VMs and multiple threaded VMs enabled.

| Measurement | Observation |
| --- | --- |
| Fixture compilation | 1.623764 seconds |
| Actual executable | **0.560270 seconds**, exit 0, no timeout |
| Whole supervised campaign | **12.487721 seconds** |
| Build stages | source/configure/seed/core all `executionLaunched=false` |
| Teardown | parent reaped, process group quiescent |

This is a new workload, not a matched speedup against the earlier 0.583/0.889
admission fixtures. No fixed 0.8-second deadline or release performance threshold
is inferred. No bootstrap or unchanged stress campaign is repeated.

Native program SHA: `01692ccc51ce4c68c3c3f72b725866620ea1c25135df233fa352fd6b44877c6d`.
Outer receipt SHA: `f0b8c03eb6d5a4ad63105d284d73f75fdd945423e405ae078f7c64ae5383b294`.
Child receipt SHA: `ccf99eb358c3ddb1fa7af730dfd319b979c821882ad1df2fde6c257eed791dd6`.

## Model Correspondence And Remaining Requirements

`vm_constructor_same_storage_retry.qnt` imports the existing five-stage
`pstate_setup_transaction` instead of rewriting its local protocol. It adds
the outer private resource prefix, unpublished error return, retained interrupt
ownership, explicit external restoration, same logical storage, and cumulative
setup visits across attempts. Its faulty-policy controls expose leaked outer
resources, replacement storage, premature/unsupported retry, and redundant work.
The deterministic OS-failure trajectory matches the real native case.

The finite model also considers memory and publication catch-up allocation
failure as **explicit unqualified hypotheses**. Terminal registry sealing is
excluded: reopening admission does not undo a terminal seal. Returning memory
callees/destructors, quiescent users, stable registry conditions and eventual
external restoration are premises, not kernel guarantees. This is not a C
weak-memory refinement. Per-attempt stage bounds are semantic roles, not a
fixed host worker count; accumulated work is never erased by retry.

The later model refinement is separately checked; it does not rewrite the
earlier native receipt or turn its whole-input identity into a fresh verdict.
Same-source evidence is composed through explicit reviewed bindings.

Remaining lifecycle requirements include real allocation/publication and OS
mutex/condvar failures, root/global-constructor ownership, failed joins and sticky
root disposition. Full GC/FFI, current Gerbil and release performance remain open.
Current-source complete GSI/GSC/PR qualification is still required independently.

## Preserved Review And CI Failures

The first QNT attempt was rejected by the backend's shared initializer lowering;
explicit initializers corrected it. Coarser passes remain historical, not current
source-refinement proofs. The disallowed interposition proposal was never run.

The published predecessor's framework CI rejected an old Reflection artifact
after the live design document grew. The exact original bytes and hash
`d279cc7f...` are now preserved in
`docs/callback-context-performance-reliability-stability.md`; only the historical
reference path changes, not its content hash or verdict. Full review-input
collection and 26 focused Reflection/audit tests pass locally after repair.

The same predecessor's official upstream job separately failed error-handling
test 2 (`-:m1,h10000`), exit 70, with `ERROR IN ##make-source -- Heap overflow`.
That CI recipe selected `darwin-stack-trip-owner-limit/source.lock.json`
(23-file overlay, patch SHA-256
`8a5b29b6a9b0867fbb7d858e03ae390f591c393872039ebd73fc5f0c5f74f46a`),
not this observation's 26-file collective-wait candidate. Its failure is retained
for that producer and cannot be attributed to, or qualify, this current runtime.
Neither its heap limit nor assertions are changed and the unchanged failure is
not rerun. Current-candidate complete official qualification remains open.
