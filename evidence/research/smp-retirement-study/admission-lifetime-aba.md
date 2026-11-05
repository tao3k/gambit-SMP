# Admission-word lifetime, ABA, and destruction funnel

2026-10-23. Evidence and proposed implementation contract for Grok. No runtime
patch or native admission. Qualification remains 8/12.

## Finding and independent conclusion

The four-gap protocol is necessary but not yet sufficient. A packed counter
cannot protect its own address if obtained through a freed VM pointer. A
`destroy_admit()` snapshot cannot exclude a concurrent enrollment. A generation
check after pointer dereference cannot repair use-after-free. A resource pin does
not cover the service code that continues after releasing that pin. Finally,
release/acquire publication does not make concurrent plain reset/reads legal.
These are separate obligations; stronger fences alone do not close them.

This review uses the immutable per-file observation at audit run
`4b8ae711116341ceb0592c720d586417/outputs/finalizer-implementation-review`, as
bound by `implemented-pin-review.json`. It does not certify the mutable c86 tree,
a coherent native producer, or the currently linked gsi.

## Stable lookup before the admission word

Use a bounded process-lifetime registry of native control cells. Cells and their
lookup synchronization are never freed/reinitialized during VM setup/cleanup.
Each stores generation, phase/count word and a VM pointer; entry slots and their
synchronization are likewise native control storage, not memset-reset VM storage.
The bounded capacity is an explicit compatibility/resource limit, not an
unbounded tombstone allocation. On capacity or generation exhaustion, reject
before publication. Do not wrap generations. Process termination is the last
consumer of cell storage; VM destruction is the last consumer of VM backing.

External token = registry index + VM generation, never a raw dereferenceable VM
pointer. Proposed `vm_token_acquire` takes the stable cell's lookup protection,
checks index/generation and OPEN, increments the packed word, snapshots the VM
pointer, then releases lookup protection. No VM field may be read earlier.
Closing/destruction/republication obey that same protection. If lock-free token
lookup is later desired, it needs a separate proven reclamation scheme; a
load-pointer/increment-pointer-ref sequence is invalid.

Cohort callers use a checked try variant or already-held parent capability;
known busy produces common DEFER, without blocking in a collective. External
host callers may use an independently specified blocking API outside the cohort.
No lookup mutex is held while taking a slot lock, entering GC, joining, invoking
callbacks or running destructors. Unknown lock/unlock results do not return a
usable capability: retain ownership and take the independent shared-fault stop
policy. This is terminal containment, not host-preserving recovery.

Old C APIs taking raw VM/pstate pointers cannot promise stale-pointer safety.
Migrate callers to tokens or explicitly require a live parent capability. If
neither is available, reject without dereferencing the pointer. Keeping an
unchecked exported alias would reopen the protocol.

## C ordering and linearization table (proposed functions)

| Operation | Exact condition/order | What it establishes |
|---|---|---|
| `vm_token_acquire` | stable lookup protection; checked generation; SC compare-exchange OPEN,n -> OPEN,n+1; reject max count before addition; SC failure observation and retry | lifetime before pointer exposure; enrollment and close have one order |
| `vm_admission_close` | SC CAS OPEN,n -> DRAINING,n, preserving count | no new root enrollment; existing capabilities remain valid |
| `vm_unit_derive` | live parent capability; SC checked CAS in OPEN/DRAINING only; never DESTROYING/DEAD | child service/reader unit exists before parent may release |
| reservation -> resource | initialize full K/root ownership; release-publish entry; convert existing unit, no decrement/reacquire | no zero-count interval during handoff |
| `entry_claim` | acq_rel CAS JOINED -> CLAIMING; failure acquire; unique claim ticket | one payload writer, no receiver overwrite by duplicate claimant |
| `entry_publish_owned` | initialize receiver full key and transfer ticket, then release OWNED; users acquire OWNED under a live entry capability | receiver payload visible; does not alone protect entry lifetime |
| `vm_unit_release` | finish VM/entry accesses, detach local capability once, then SC decrement; underflow/double release is a fault | zero means last covered access finished; no post-decrement VM logging/callback |
| `vm_destroy_begin` | stable lookup protection; SC CAS DRAINING,0 -> DESTROYING,0; issue sole internal destructor ticket | exclusion acquired before the first destructive mutation |
| `vm_destroy_finish` | all ticket-owned destructors complete; SC DEAD publication; clear VM pointer under lookup protection | backing may be released; cell remains valid |
| `vm_republish` | DEAD, no old entry readers/leases, fresh nonwrapping VM generation; initialize payload then OPEN publication under lookup protection | old token cannot address the new VM, even at the same native address |

Start with SC gate operations, including failures. This avoids introducing a
weaker cross-atomic admission proof. Ordinary payload is legal only behind
release/acquire publication and exclusive mutation/reader grace. Use one aligned,
actually lock-free native word in each supported configuration; assert the
compiler/target capability. A compiler-emitted hidden lock is not acceptable in
cohort code. SC is a conservative design choice, not a measured performance
claim or a complete C11 proof. Existing ticket-lock implementations still need a
real acquire edge after ticket grant and release on unlock; SC on this unrelated
word cannot supply that edge.

## Reference units and actual last consumers

All rows below must be accounted in the same total or have a documented enclosing
unit that outlives them. Counting the same ownership twice is unnecessary;
leaving an independent consumer out is unsafe.

| Unit | Register / transfer boundary | Last release and concrete source migration |
|---|---|---|
| registry lookup | before reading generation/control payload | after gate acquire/rejection; stable cell survives release |
| setup/host entry | token acquire before VM/P0 access, including READY helpers | `setup_entry_release` / `___setup_p0_ready_current` after last access and native lock release; bridge generated C still needs W_ALL/R_ALL and marker coverage |
| staged reservation | before private sections/worker/handle become accessible | failure prefix cleanup fully complete, or conversion to accepted resource pin; never drop while rollback retains resources |
| accepted donor resource | `___retirement_reserve_pin` before marker retirement | after join0, exact-once move/accounting, scan-domain removal, checked empty destruction and reader grace; tail CAS is not release of this unit |
| join/reaper operation | derive before touching native handle/entry | after saving native result and publishing JOINED/error; retained donor pin survives a failed join; native handle lifetime and join lane are in K |
| request producer | `___pstate_request_acquire[_current]` before ps/queue access | `___pstate_request_release` after publish/rejection/unlock and last ps access; request lifetime after enqueue needs queue/root ownership, not just producer count |
| service/finalizer | derive before selecting/dereferencing entry | after common result/ACK, locks released and all entry accesses; can outlive the resource pin |
| entry/scan reader | derive while resource/parent is held, before snapshot | after final scan/writeback and reader lease exit; pending RC writes actual header data; no cached SCMOBJ substitute |
| wake writer/selector | before fd/VM/deadline use | after final syscall/result processing and lock release; migrate `wake_writers`/`wake_selectors` or retain an enclosing VM unit through their full intervals |
| Scheme/C marker + native tail | live call context or donor pin registered before marker drops | actual unwind/return for marker, join0/claim CAS for tail; marker0 alone grants no destruction |
| accepted fault coordinator/callback | before scheduling/root publication or foreign callback | completion/escape captured at rooted landing; outstanding callback and queued fault work retain parent even after sender returns |
| destructor ticket | atomically replace DRAINING0 with exclusive destruction authority | after last destructor and DEAD publication; not an ordinary positive unit that would prevent its own zero-count admission |

A native unit is not a Scheme root. Existing typed carriers, pending still/RC
scan descriptors, context markers and generated frame maps remain required.
The count protects their owner storage; GC needs the actual traced graph and
exclusive scan-owner transfer. Global IO ownership shared by VMs requires a
separate global close-and-drain ticket after every VM is sealed; a per-VM zero
cannot authorize global OS/allocator teardown.

## ABA and reset rules

Full entry K remains VM id/generation, resize epoch, slot/incarnation, native
handle lifetime, join lane/generation; receiver has its own full identity. An old
entry message carries index + K, not a pointer to movable/recycled storage.
Resolve the VM token first; under entry protection compare complete K before
access, derive a reader unit, and release entry protection. Reset requires
resource ownership gone, service/readers gone, no pending queue reference, and a
fresh key. A live reader cannot observe memset or a new phase paired with old K.

Registry slot reuse is serialized with token lookup; a lookup either increments
old-generation gate before close (therefore blocks destruction), or sees closed /
new generation and rejects. Slot reuse does not imply entry reuse. New epoch,
new VM and repeated native handle address are independent ABA cases. Generation
exhaustion must fail closed. A timeout does not cancel a live reader or erase its
unit. Abandoned units may retain capacity; forced reuse is not recovery.

## Destruction audit: existing entrances are not uniformly closed

Line references below are to the immutable observed files, not current source.

| Entrance | Observed behavior | Required funnel |
|---|---|---|
| `___cleanup_checked`, setup.c:6727 | checks global retirement snapshot before cleanup, later checks consumers; mutates setup/IO state | close all relevant admission; acquire VM/global tickets before first corresponding destructor; status on retained debt |
| `___cleanup_owned_vmstate`, :6540 | registry close, consumer check, P0 cleanup then locked VM cleanup | per-VM ticket covers BOTH P0 and VM cleanup, retained until success/quarantine; no false success from a nested void refusal |
| `___cleanup_vmstate` / `cleanup_vmstate_locked`, :6501/:6475 | exported void wrapper / global debt check then resource destruction | checked entry obtains ticket; private internal helper requires it; exported function-table entry cannot bypass |
| `___cleanup_pstate`, :6282 | direct interrupt queue cleanup then OS/memory cleanup; no retirement gate here | published donor ticket or parent VM destructor ticket, exact slot K; legacy void misuse must not silently report success |
| `cleanup_interrupt_resources_pstate`, :1500 | closes slot; reads producers and writes CLOSED outside slot lock | same sealed admission/capability protocol; producers and phase checked atomically under slot protection; checked destroy result and readiness retention |
| `cleanup_interrupts_pstate`, :1473 | releases procedural nodes under native mutex | queue consumers must be stopped; release callback/escape policy explicit; cannot call arbitrary callback under uncertain shared lock |
| `cleanup_os_and_mem_pstate` / VM helper, :6161/:6188 | directly delegates to raw destructors | ticket-bearing private helpers; propagate retained/unknown outcome, do not free enclosing storage on refusal |
| growth prefix cleanup :2138/:2151, `cleanup_failed_pstate` :6292 | partial/unpublished cleanup branches | constructor ticket proves never published; initialized-resource mask; if worker/entry escaped, convert to retained ledger instead of private abort |
| `___abort_mem_vmstate`, mem.c:5346 | frees sections/tables and destroys locks directly | unpublished constructor-only authority; published abort must enter ordinary close/drain; never infer private status from processor_count0 |
| `___cleanup_mem_vmstate`, mem.c:6243; raw pstate cleanup | destroys VM locks, P0 memory, sections/list membership | internal ticket check before first destruction; note VM helper calls P0 memory cleanup again, so ticket tracks completed subresources to prevent double cleanup |
| `___cleanup` / globals, setup.c:6886/:6215 | checked wrapper may call fatal_error; global memory/OS cleanup | explicit terminal vs returnable host policy; arbitrary fatal host callback is not the independent unknown-lock stop; global ticket required |

Low-level helpers do not become safe because their normal caller is checked.
Before claiming closure, Grok must enumerate all configured/preprocessed call
sites and exported function-table/embedding entries. This table certifies the
reviewed entrances above, not all compile-time configurations. Standard free is
void but mutex/condvar/OS cleanup can fail; initialized/destroyed masks must remain
monotone. Known local busy retains descriptor/pin for later service. Partial
teardown cannot reopen OPEN; retain DESTROYING/quarantine and resume only known
unfinished destructor units. Unknown shared synchronization state takes the
independent terminal policy. Never reconstruct ownership from a half-reset VM.

## Model evidence and its limits

`models/gambit/admission_lifetime_aba.qnt` checks one boundary pipeline: stable
lookup, gate acquisition, reservation->resource conversion, close, derived
service/reader, payload publication/use, independent last releases, exclusive
destruction, same-address generation reuse and stale replay. Three candidates
cover current token, stale VM token and stale entry. Nine mutants cover lookup
protection lost, last-use gap, raw destructor bypass, stale VM acceptance, stale
entry acceptance, OWNED before payload, count wrap, reset with a live reader and
late root enrollment after close. Mutants encode explicit illegal transitions;
reaching them establishes why the precondition matters, not that C performs it.

This boundary refinement complements the prior 28-control two-VM/repeated-epoch
finalizer composition. It does not syntactically merge every old transition or
prove scheduler liveness, arbitrary C11 executions, root maps, all consumer
classes, or destructor totality. Do not add test counts and call them a single
native proof. C11 happens-before arguments above and targeted native cases below
are still implementation obligations.

## Grok implementation order and focused native acceptance

1. Freeze a coherent final source/configuration/generated-C/archive/gsi manifest.
   Fix source materialization drift by reviewed provenance, not changing HEAD or
   a historical lock to satisfy a run. Latest boundary receipt never ran join.
2. Introduce stable registry cells/tokens, bounded generations, packed gate and
   checked unit helpers. Initialize bootstrap explicit VM/P0 identity before
   opening admission. Add compile/preprocessed checks for actual lock-free word
   and ticket grant acquire/release. Do not nest lookup and slot locks.
3. Migrate every unit in the table, including asynchronous handoffs. Give
   reservation->pin and parent->child transfer a single audited linearization;
   retain caller units through all errors, nonlocal escapes and last accesses.
4. Implement CLAIMING/payload/OWNED and entry-reader grace; thread complete K
   through all APIs. Funnel every destructor above through constructor or
   destruction authority; status-bearing internal calls and resource masks.
5. On the SAME relinked producer, use bounded deterministic barriers to pause:
   token lookup before acquire vs close; enrollment conversion vs cleanup;
   resource drop with service/scan reader still active; close vs last producer;
   SAME-address VM reuse then old token/entry/handle delivery. Require rejection
   before VM dereference, no wrong-generation decrement, no callback after free.
6. Exercise each raw exported cleanup/function-table entry with a held unit:
   zero destructive calls until denial/drain; private setup partial failures
   free only initialized private resources. Exercise EBUSY and unknown unlock:
   retained local ownership vs independent terminal stop, never common-barrier
   wait under an uncertain lock. Exact-once destruction counters must cover the
   nested P0 cleanup route. ASan/TSan when supported are supplementary, with the
   same source/config manifest and retained diagnostics.
7. Verify roots during actual moving GC with pending still/RC + live marker,
   callback escape and final service reader. Require writeback, continued root
   coverage, no recycled carrier until grace, and unchanged real deadline.
8. Run p1/p11 boot and narrow join/request/fault controls as separate native
   receipts under their existing caps. Record full K, gate before/after, unit
   class, owner, last-use event, actual join return, ticket and destructor mask.
   A total count alone is insufficient to diagnose a leaked unit.

Commands for the evidence verifier are `PYTHONPATH=src python3
 evidence/research/smp-retirement-study/verify-admission-lifetime.py` and the
existing `verify-finalizer-registry-composition.py`, each using registered audit.
These are model commands, not invented native harness commands. The native
barrier/fault cases above are implementation requirements to add to the existing
focused harness; no unsupported command is presented as already executable.
Formal 9/12 lifecycle campaigns remain separately gated by contract review;
pending is not an OS errno, and no observer/history/recipe is changed here.

## Cost and sufficiency judgment

A root admission costs stable-cell lookup synchronization plus a checked SC RMW;
last release costs an SC RMW; child service/reader adds an RMW pair. Existing
parent capability avoids repeated global lookup. Collective probes never block.
Bounded stable native cells consume fixed capacity; retained faults can exhaust
that capacity rather than recycle live storage. No performance numbers are
claimed. Measure matched producer request throughput, GC pauses and resize tail
latency only after native correctness closes.

This is a concrete implementable ownership protocol, but not yet a sufficient
proof of 9/12: C callers/destructor coverage, generated roots, real synchronization
edges, callback containment and a source-bound native producer still need the
listed checks. The present source snapshot demonstrably lacks a unified funnel;
reporting closure now would be wrong.
