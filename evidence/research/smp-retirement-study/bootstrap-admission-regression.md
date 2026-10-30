# Bootstrap request-admission regression: exit71

2026-10-23. Evidence only; runtime unchanged. This corrects attribution of the
reported mapped/executing GSI exit71, without erasing the separate linker failure.
No debugger/native execution or full inventory was run by this audit.

## Source correspondence and evidence grade

The immutable setup.c observation in audit bad1e9aa8d7d47e2a1304a6225f6f2ae proves:

1. ___setup:7290 has the known VM0 pointer and calls setup_interrupts_pstate on
   its P0 before general OS/memory/module setup.
2. setup_interrupts_pstate:736 calls request_open_slot; request_slot_id:383–393
   derives the VM through ___VMSTATE_FROM_PSTATE before computing the slot.
3. ___setup_pstate:5380 writes ps->vmstate, after the earlier bootstrap entry;
   its VM0/P0 arm skips the already initialized interrupt resources.
4. gambit.h.in:8790 defines the threaded accessor as ps->vmstate. At12037 the
   processor-id macro subtracts a pointer based on vms->aligned_pstate[0]. A
   null/unestablished VM makes that pointer derivation/subtraction invalid; an
   eventual range check does not make it valid C or a checked-owner protocol.
5. Saved main.c:1368–1373 maps a negative setup error to EXIT_CODE_OSERR.

The user's debugger observation supplies the actual execution evidence, not
an independently rerun trace: ___main_char→___main→___setup+236→interrupt setup;
x19=___gstate0 at0x100617a68; [ps+0x3f0]=0 (vmstate); x2=0x3346b2=3360434;
cmp w2,#0x7f branches high to IMPL_LIMIT_ERR; returned fixnum0xffffffff0e000010.
UNKNOWN_ERR from mutex initialization would instead be0xffffffff0e000018.
This execution reaches interrupt initialization, so the earlier entry cleanup-
phase refusal is not the source of this particular return.

The source path and supplied machine trace agree on an initialization-order
regression. The bogus id is one observed manifestation, not portable arithmetic
behavior to reproduce or a real capacity demand of3360434 processors.

The separate makefile observation has C_COMPILER=gcc-16, LIBS empty, dynamic
bundle flags containing -undefined dynamic_lookup and executable flags without
it. The user reports direct-link unresolved libSystem/libemutls symbols. That
link failure produces no running process; the reported exit71 binary was already
dyld-mapped, had libSystem mapped and reached main_char. Therefore it is wrong
to attribute this exit71 to missing libSystem linkage. This does not certify that
adding dynamic_lookup is a correct production link configuration.

## Implementation order for Grok (no runtime applied here)

1. **Explicit bootstrap identity, before lookup.** The bootstrap caller already
   owns vms0 and slot0. Add/refactor a private identity/native-resource prepare
   entry taking (known_live_vm, checked_slot, ps, incarnation). Check bounds and
   ps==PSTATE_FROM_PROCESSOR_ID(slot,vm) after validating the live VM capability;
   do not derive the slot by subtracting through an uninitialized ps->vmstate.
   In threaded builds establish ps->vmstate before any existing reader, including
   failure cleanup. Preserve SINGLE_THREADED conditional layout. An early bind
   using the known pointer can fix this immediate order bug; it is not OPEN.
2. **Prepare CLOSED.** Separate setup_interrupts_pstate native mutex/flag/queue
   initialization from request_open_slot. Initialize the native slot record,
   full VM/slot key, incarnation and exact resource mask while public admission
   remains CLOSED/STARTING. Internal bootstrap/SYNC/GC notifications use their
   existing private path; do not expose Scheme request queues early to make
   bootstrap progress. Do not reset incarnation/producer counts on a repeated
   call over an already live or retained slot.
3. **READY then OPEN.** ___setup_pstate/VM0 special-case must reuse the same
   prepared record rather than initialize/destroy it twice. After Scheme P0
   startup and mapped root setup, release-publish exact READY; publish OPEN and
   identity under the same admission mutex used by acquire/close. Apply the
   same two-stage contract to subsequent workers/VMs. Count committed or mutex
   initialized is not evidence of Scheme readiness.
4. **Exact prefix cleanup.** Early failure must know whether identity, slot
   mutex, procedural mutex, queues and root owners actually exist. Native-only
   cleanup of a partial CLOSED slot must not call a helper requiring later
   pstate initialization or public OPEN. Keep prior live producers/queue/wake
   consumers and retained failure records pinned. A failure after OPEN uses
   normal close/drain; no unsynchronized producer-zero reclamation.
5. **Reject invalid identity before pointer arithmetic.** For non-bootstrap
   live paths retain checked owner/incarnation admission. Do not return slot0
   on null VM, infer all early pstates are P0, enlarge128, hide IMPL_LIMIT_ERR,
   or translate the failure into successful setup. Those shortcuts turn a
   startup regression into slot aliasing, stale-owner acceptance or silent loss.

## Required focused native controls

- Cold normal startup, using supported existing build settings: early P0 identity
  correct; CLOSED/STARTING before READY; first public acquire denied before READY
  and admitted after READY; genuine startup/exit0 receipt on newly bound GSI.
- Fail each bootstrap native init prefix, including mutex failure: exact error
  (UNKNOWN_ERR distinct from IMPL_LIMIT_ERR), no uninitialized mutex destroy,
  no lookup through absent vmstate and no double initialization/cleanup.
- Null/wrong VM/negative/out-of-range slot checked calls rejected before pointer
  subtraction; an unbound secondary pstate must not alias VM0/P0.
- Repeat setup after an actually completed teardown; separately refuse setup
  over retained cleanup or active borrowers without resetting identity/counts.
- Growth slot prepared CLOSED: count→GO→Scheme READY→OPEN; concurrent acquire/
  close test uses real expected incarnation, queue and wake last consumers.
- Link audit and startup audit are separate receipts. Record compiler/SDK/link
  flags and executable bytes; do not inherit old39 rows or a completion seal.

The integrated30-case QNT starts with an established abstract VM identity. It
proves neither this bootstrap C ordering nor dynamic linking. Record the missing
precondition explicitly: identity/native prepare precedes every slot lookup;
public OPEN follows Scheme READY. No unchanged QNT suite was rerun here and no
new model/native pass is claimed. Bootstrap correction is necessary but does
not complete staged-worker integration, retirement roots/finalize or formal9/12.
Count remains the previously observed8/12; pending is not an OS join errno.
