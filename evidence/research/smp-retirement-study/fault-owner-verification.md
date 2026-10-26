# Verification handoff: device ownership and fault callback control

Runtime integration belongs to **Grok**. After the user's verification-only
instruction, this lane made no additional runtime source edits or production
compiles. It tested the already-built experimental producer and updated evidence.
No other thread was contacted or operated on. No commit, staging, push or full
inventory was performed.

The final receipt index is `final-device-owner-verification.json`. It binds GSI
SHA256 `7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808`,
six changed and four retained source identities, generated C, actual patch replay,
39 targeted native control rows and11 QNT controls. The experiment remains in
the original `repair-9-12` / `c86dff86` producer, with source phase `building` and
`nativeAdmitted=false`. Complete qualification stays **8/12**.

## Exact ownership and last-consumer correspondence

Runtime paths are relative to that producer's `source` directory; receipt hashes
define their identity, rather than a mutable path alone.

| Boundary | Actual function and ordering | Last consumer / root | Validation |
|---|---|---|---|
| Read/write close fails | `os_io.c:___device_close` records the first hard error; `___device_cleanup` keeps its group link and reference. CLOSED stage does not erase that error. | Native group remains owner of the failed device and ambiguous fd. No subsequent close/release is attempted. | Read/write failure fixtures and real file-port EIO/EBADF/EINTR injections. QNT early-unlink / forgotten-error negatives. |
| Close reports EINTR | POSIX file/pipe/socket device close makes one syscall attempt. Readiness-select EINTR after an EAGAIN close is a separate, retryable wait event. | The original fd number is never retried after ambiguous close. A replacement fd has its own owner. | EINTR both before and after an actual close; original attempt count1; replacement usability and legitimate close. Native EAGAIN case succeeds. |
| Native release fails | `___device_release` restores the allocation's reference; `___device_cleanup` restores the group link and preserves the error. | Partly executed release is not called again. Allocation and owner stay retained. | Release callback count1, refcount1, still-linked group; QNT free-on-release-error negative. |
| Scheme foreign still references device | `mem.c:___prepare_device_foreigns_vmstate` visits canonical device wrappers; `___release_foreign` disarms native pointer/function before its one-shot callback. This runs while VM roots remain intact. | Wrapper's finalizer is the last pointer consumer. After disarming, group owns failure; on success later `free_still_objs` cannot release it again. | Live foreign wrapper across GC; success once; failures disarmed but owned/rooted. P1-created wrappers exercise actual retirement handoff. QNT free-before-foreign-handoff negative. |
| Group/module teardown | `___device_group_cleanup_checked` stops with failed node and untouched suffix retained. `___cleanup_checked` checks foreign handoff and IO result before processor/VM/GC destruction. | Group, device, module code/data and VM roots survive a checked failure. GSI reports exit70; an embedding gets the retained error state. | Global device failure witness checks actual owner, refcount, module/VM state and live coordinator record. QNT group/root premature-free negatives. |
| Public continuation leaves callback | `_thread.scm:##fault-control-callback!` installs a per-invocation winding guard with recovery outside the guard but inside the mapped coordinator frame. Escape records failure and returns to that recovery point. | VM record owns current item, suffix and escape/error object across GC. Prefix is already consumed and never replayed. | Exit-job call/cc and final-will `continuation-graft`; stale continuation attempts; suffix/error values after GC. QNT escape/replay negatives. |
| Callback tries to kill/park carrier | Private entries `##thread-terminate!` / `##thread-suspend!` call `##fault-control-protect-owner!` outside held scheduler locks before lifecycle mutation. Only the fault coordinator is protected once fault admission closes. | The same P0 carrier remains responsible for the suffix. Ordinary request/thread state is not substituted for coordinator ownership. | Actual public self-terminate/self-suspend calls under EBADF and persistent EINTR; observed refusal, suffix/error GC and final prepared exit. QNT separate terminate/suspend mutants. |
| Final native exit | Prepared P0 exit joins workers and checks wake writers/selectors/markers. Device ownership handoff and checked IO outcome precede root destruction. | Wake-fd grace and device completion are separate facts. A printed wake grace does not imply device cleanup succeeded. | Ten worker marker witnesses, zero wake consumers, native device-retained witnesses, and preserved raw-unwind refusal control. |

## What the results establish

On the exact experimental executable, the two named gaps have a closed tested
disposition: success releases once; permanent close/release failure preserves
ownership and roots and reports failure; public winding escape is contained; the
unique coordinator cannot be consumed by public terminate/suspend. Native fatal
exit70 in hard-failure controls is expected failure disposition, not successful
resource release or a fabricated request reply.

The39 native rows include expected fatal/refusal controls. They also cover all
prior targeted request/wake/FFI/active-sender/deadline cases on this same GSI,
including100000 requests ×8 rounds atp11,600 nested C/Scheme callbacks with GC,
and the real250ms deadline. The new QNT candidate passes safety and fair terminal
disposition; ten decoded mutants identify specific missing mechanisms. Retained
failure is terminal in this model without falsely asserting that failed storage
was freed.

This is verification of supported checked-host/canonical-device/public-winding
contracts on the Darwin producer. It does not turn arbitrary stale VM pointers,
nonterminating callback bodies, or raw private no-winding/C jumps into recoverable
operations. Existing live/quiesced host ownership remains required. No complete
native/Gerbil acceptance, other-platform ABI admission or performance improvement
is asserted. Grok still owns code integration and subsequent qualification.

Historical native/model/fixture failures and previous executable identities are
retained. The final index supersedes earlier source-specific validation summaries;
it does not rewrite their results.


The final index uses strict owner controls from
`5f62b1bf99b443e9b092f0766b300109`: both actual refusal exceptions were
validated individually and rethrown to the outer coordinator catcher. All other
37 native rows are from `0435aab786604b139a320715f8535ec4` on the same GSI.
Source/generated-C/executable hashes were rechecked unchanged at completion.
