# Implemented request delivery and permanent-wake-fault experiment

This is an applied, compiled diagnostic generation in the original task-owned
`c86dff86` producer, not a prepared proposal. No complete native inventory has
been run. Qualification remains **8/12**. The source generation remains
`building`, with `runtimeAdmitted=false`; the historical completed producer
receipt must not be reused as authority for these new bytes.

The canonical single patch is `owned-request-fault-coordinator-native.patch`.
Its seven baseline source hashes, final hashes, actual patch replay and final
GSI/generated-C identities are recorded in `owned-request-native-validation.json`.
It includes the independent-return backend, request ownership, ticket acquire,
fault coordinator, admission hooks, marker retirement and writer-close ordering.
The smaller patch files describe overlapping implementation steps: **do not
apply all of them cumulatively**. Historical run-local patches are unchanged.

## Source operation, transition, last consumer and model premise

All runtime paths below are relative to the original incremental producer's
`source` directory. The audit JSON binds their exact bytes.

| Operation and actual functions | State and synchronization | Last consumer/root | Evidence and limit |
|---|---|---|---|
| `_thread.scm`: `##thread-intr!` → `##thread-intr-propagate!` | `[next,mutex,target,phase]`; Fresh→Queued only under target T lock. Target is immutable. Request link never enters P high-level queue. | Target queue, then mapped execution frame; sender owns second mutex wait. | Native once/reply, nested/migration/GC and flood controls. Combined QNT `publish`, shared-link negative. |
| `##thread-intr-notify!` → `##raise-high-level-interrupt` → `##thread-intr-wake!` | Separate fresh procedure-hint link. T→P with sync participation; release P before releasing T/forwarding. Stale predicate is checked before BTQ/TOQ removal. | Hint closure keeps target reachable; target queue owns request. Every forward creates a new hint. | Native migration and stale-hint QNT negative. Infinite adversarial migration is not proved live. |
| Resume / `##other-interrupt!` → `##thread-intr-drain!` → `##thread-intr-execute!` | Queued→Active under T; execution after unlocking T. Normal/exception result stored before mutex unlock; phase records Replied/Failed. | Request, mutex and outcome stay in mapped Scheme frames through GC/publication/unlock. Dynamic-wind abandons actual mutex on nonlocal escape; completed continuation reentry is rejected. | Native error and continuation-escape controls; unmapped-GC, duplicate execution/reply QNT negatives. |
| `gambit.h.in`: `___TICKETLOCK_LOCK2` | Full barrier after observing ticket grant. Release path unchanged. | Lock-protected P state and queue membership. | Compiled actual source; finite model alone does not establish compiler/hardware ordering. |
| `os_io.c`: `device_select_with_cap` → `device_select_impl` | Internal 50ms recheck preserves actual deadline; internal timeout does not run device-ready callbacks. Scheduler rechecks outside P lock. | Counted native selector; user/device deadline is independent of recheck interval. | Native bare waits and 250ms deadline controls retained from backend generation; current delta leaves deadline logic unchanged. Public cleanup waits retain old semantics. |
| `___device_select_abort` | Writer count SC increment→SC phase check→write→release decrement. At most four EINTR attempts. First hard errno is sticky; ordinary EAGAIN is not permanent failure. | Writer stops using fd before dropping count. Caller must already own valid VM lifetime. | Actual one-EINTR, persistent EBADF, held-write and persistent-EINTR injections. No close while injected write was active. |
| `_thread.scm`: `##wait-fault-observe-unlocked!` → registered P0 control thread → `##fault-control-run!` | Native CAS Faulted→Posted→Running; observation after scheduler P unlock. One traced VM carrier; P0 pin enforced. Public new interrupt/job admission closes before ownership transfer; private GC delivery remains available. | VM `unused-field2`, scanned by `mark_vm_scmobj`, owns coordinator, callback suffix, current callback and caught error. | Actual callback error, GC, suffix, recursive-exit intent, final will and refusal controls; wrong-P/duplicate-carrier/suffix/error-root QNT negatives. |
| `_kernel.scm`: hook setters and exit functions | Setters inside defining module prevent constant folding. Recursive exit records intent instead of opening another unwind. | Sole coordinator commits prepared exit; current callback and remaining suffix remain rooted. | A real earlier generated-C omission was detected, preserved and repaired. Generated C hashes are bound. |
| `setup.c`: `service_procedural_interrupts_pstate` | Dequeue/unlock→callback. Non-NO_ERR returns immediately with mutex already unlocked; suffix stays queued, OTHER remains pending. | Current callback owns detached node; native queue owns untouched suffix. | Actual C error callback, suffix exactly once and subsequent successful enqueue/service control. |
| `c_intf.c`: make/kill marker; `setup.c`: `___run`, worker retirement | Per-P native owner list of still-object markers. Matched return/throw kills once. Nonreturning worker exit retires all remaining markers before OS cleanup. | Native entries hold external refs to still objects. Returnable P0 marker blocks cleanup before cohort/interrupt/root mutation. Worker join is last-reader boundary. | 600 nested C→Scheme callbacks with real GC, matched count restoration and live-owner cleanup refusal at cohort11; ten worker retirement witnesses on permanent fault. One malloc/free per marker is a new cost. |
| `___cleanup_checked`, `vm_native_consumers_clear` | Prepared exit→workers joined→SC Closed store→SC writer-count observation. Outstanding selectors/markers refuse cleanup. Incomplete raw fault unwind retains resources. | No fd/VM release with admitted writer; host publishers must quiesce before releasing their VM borrow. | SC admission litmus and weak-order negative; native held-write injection. Raw unwind is a **retained failure negative**, not graceful successful recovery. |

The writer-close SC operations are deliberate: a release store to the close flag
and acquire load of a different count do not alone rule out both sides observing
old values. In the SC order, a writer that observes Open has already published
its count before Close; a closer that observes zero either precedes that writer's
admission check (which then sees Closed) or follows its completed write. The
QNT litmus abstracts the allowed weak observation and is not a full C11 checker.

## Real evidence on the final executable

Final GSI SHA256:
`1a32b364a5b421ea674db68b67e8219570cebfe2d2398a120fec2096a29aa184`.

The same supervised run `bf4296759c0f4a20b2ef6c43dbb2ab54` contains:

- `outputs/owned-request-native`: healthy p11, 1000 exact request/replies,
  40 nested/migration/GC rounds, ordinary error, continuation escape and four
  actual wake-write injection modes. EINTR once exits0; three permanent modes
  deliberately exit70 after P0 preparation and zero-consumer grace.
- `outputs/marker-ffi-native`: 600 real nested FFI callbacks across collection,
  baseline marker count restored, live-owner cleanup refused with cohort11.
- `outputs/owned-request-final`: eight rounds of 100000 requests at p11,
  each under its original12s cap; all exit0 with exact counter checks.
  The C procedural-error suffix control exits0. Raw pre-prepared unwind exits70
  with retained resources and **without** a false native-grace witness.

The flood is byte-identical to this experiment's retained earlier fixture,
SHA256 `d940a05a0880e06e7ff3364b52103eb5fb274834f9dc6543fdc781baf4f11f17`.
It is not asserted to be the other thread's historical fixture. Timing is
observational, not a matched performance win. The original combined QNT's
candidate plus twelve decoded negatives passed under audit `eedc727e...`;
the writer-close litmus has a separate retained validation receipt.

## Costs and remaining admission conditions

The stability tradeoff is explicit: independent idle rechecks can add up to
20 native returns/second per indefinitely waiting processor, while preserving
real deadlines. Each request has two extra fields and a fresh hint when needed;
forwarding allocates another hint. Each C→Scheme marker has one native owner
entry. Each abort write has an SC RMW and SC phase load; closing adds the paired
SC store/load. No matched application-level latency/CPU/ABI benchmark is claimed.

This closes the tested delivery/fault path under a live owner contract. It does
not prove all native shutdown or all12 gates. Explicit remaining conditions:

1. The host must acquire a valid VM lifetime **before** the first pointer
   dereference and quiesce external publishers before cleanup. These counters
   do not make arbitrary stale C pointers safe. Native selector admission relies
   on the existing owner/cohort contract; it is not a new external selector API.
2. Exit callbacks must eventually return or raise an ordinary exception.
   Arbitrary continuation escape from the fault coordinator or a nonterminating
   callback is not certified; the raw-unwind negative proves retention only.
3. Device cleanup still removes a device before close, and group cleanup still
   frees its group after a non-NO_ERR break. The successful native injected-wake
   controls do not certify this independent device-error ownership path.
4. Full native qualification, the same-contract repeated9/12 receipts, FFI/VM
   embedding ABI coverage and the other remaining gates have not run. No old
   seal, producer completion or negative receipt was relabeled as their pass.

No peer process/thread was operated on, no full inventory was launched, and no
commit, staging or push was performed for this implementation.


## Final same-executable supplements

`owned-request-native-supplement.json` binds two additional native receipts to
exactly the same final GSI and rechecks the seven source hashes. Run
f3034e01144342f2907ffff3dad92bb6 completed all five bare waits and measured the
250ms real deadline at252.415895ms. Run4d758a9fd98746f3a317e12c872601b5 triggered
persistent EBADF and EINTR with an accepted, active thunk and a still-blocked
result sender. In both cases the fault exit callback observed the pending
sender, ran GC and verified payload, then P0 preparation, all worker retirements
and zero-consumer grace completed with exit70. This is actual VM terminal
failure of an outstanding request, not a successful reply or mutex polling.
These four checks supplement the20 final controls above:24 targeted controls,
including expected refusal/failure negatives, all on one executable. They do not
advance the complete native qualification count.
