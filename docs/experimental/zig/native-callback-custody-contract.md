# Foreign Borrow, Root Publication and Exit Custody

Proposed common runtime contract, implementable in modern generated C or in an
optional Zig provider behind the same qualified C control island. Not current
Gambit behavior, a checked memory model, or an admitted native profile. Source
IDs resolve in the [ledger](native-callback-evidence.md).

## Explicit Invocation Record

NT01. The following is declarative design data, not compilable code:

```text
Invocation {
  identity, parent, vm, context, processor_origin, native_thread,
  module_lease, execution_permit, native_return_capability,
  state, registered_root_extent, retained_carriers,
  borrows[], cleanup_ledger, unwind_destination, pending_outcome
}
Borrow {
  source_root_or_resource, kind, byte_or_slot_range, permissions,
  relocation_policy, reentry_policy, owner, generation, last_use
}
RootExtent {
  owner, stable_storage, typed_slots, membership_generation,
  policy = enumerated_mutable | cooperative_classified,
  scanner_users, pending_barrier_users, retirement_state
}
ForeignEffectSpec {
  may_allocate, may_collect, may_callback, may_block,
  may_nonlocal_exit, native_retention, required_thread,
  conversions_in_actual_order, exits_and_cleanup_owners
}
```

The record/ledger storage survives every jump it is responsible for; do not put
its only pointer or mutable phase in a changed nonvolatile automatic variable
of the setjmp function. Native ledger allocation/retention can fail: until an
acceptance receipt exists, the original caller retains ownership. No managed
argument may become unrooted while allocating that native support. Use an
already established donor root and capture its stable identity before effects.
Record identity is not a replacement for owning the recorded objects. [NE03–NE07,
NP03]

NT02. State transitions:

| State | Entry condition and permitted effects | Exit custody |
| --- | --- | --- |
| EntryHeld | Same owner/thread verified; source carrier and incoming values protected by donor; module live | Failure leaves donor responsible; no undefined marker to kill |
| Rooted | Precise extent accepted; retain carrier; convert/reload values; reserve nested-safe target protection | Ledger owns accepted resources before any callback/allocation |
| CallbackActive | Marker initialized and rooted; valid C return island; actual Scheme frame/root plan installed | Normal result, Scheme handling or nonlocal target is explicitly recorded |
| ParticipatingWait | BW1 membership retained; current C aliases bar relocation until a legal service cut | Wake returns to owner; close aliases/reload before collection service |
| Parked | Alternative design only: roots frozen/published, no heap borrows, waiter and outcome custody registered; collector membership transformed by explicit protocol | Callback/return requires reentry permission; pending tasks cannot access heap |
| Reentering | Reacquire against current GC epoch, restore owner, reload roots, register child/cleanup state before pending actions | Failure/async exit is handled by already active ledger/catcher |
| Unwinding | Target identity retained; each crossed owned scope settles exactly once; source roots kept until destination accepts | No arbitrary error conversion or dead C-stack resurrection |
| Retiring | New calls/updates closed; existing invocations, scans, logs and deliveries drain | Last receipt authorizes release; unresolved users keep quarantine |
| Retired | Marker invalid, root storage unregistered after scan grace, last users gone | Neither callback nor root access may resume |

BW1 is the inspected baseline choice. Parked is a larger replacement requiring
new membership/reentry semantics, not the default interpretation of `wait!`.
[NE05, NE08, prior owned-entry study]

![Root and execution handoff](native-callback-publication.svg)
[D2 source](native-callback-publication.d2).

## A Concrete Synchronization Choice

NT03. Choose **serialized access to native root cells**, not an unsynchronized
SCMOBJ word plus atomic dirty bit. A short root gate protects membership,
cell read/write, generation classification and collector writeback. A separate
execution/relocation admission protocol prevents minor relocation while a
foreign owner is using a loaded managed value. Acquiring a gate that may wait
is itself an effect boundary: protect inputs first, wait through an admitted
participating adapter, then reload them. Once held, the gate has no allocation,
callback, poll, foreign destructor or wait for another owner. Prepare a bounded
barrier reservation first; gate failure/queue exhaustion must not leave a
half-published mutation. If those conditions cannot be supplied, reject this
policy for that caller. [NE04, NE08, NE11, NP03]

NT04. Required happens-before relations are explicit:

| Operation | Publication and exclusion rule | Collector / consumer duty |
| --- | --- | --- |
| Register | Initialize descriptor/valid cells under exclusive ownership; gate unlock release publishes insertion | Gate lock acquire observes membership and values; no pre-insertion safepoint without donor roots |
| Root replacement | Under execution permit and root gate, reserve/commit major old-edge protection when applicable; keep location in young set before assigning a young value; unlock release | Read/classify under same gate; do not mix plain and atomic accesses to the same cell; minor cut includes all completed and in-flight writers |
| Minor acknowledgement | Close entry/update producers for epoch; finish stores/log entries and all raw borrow uses; release-publish acknowledgement | Coordinator acquire-observes every participant and producer; scanner owns disjoint locations under root gate; no concurrent foreign heap access |
| Moving writeback | Collector writes forwarded root under exclusion while relocation cut remains closed | Publish completion release; resuming owner observes acquire and reloads the root, never reuses pre-cut value/body pointer |
| Major root scan | Root gate orders cell read against replacement/deletion; retained old-edge records enter the actual major protocol | Concurrent-major termination includes root/barrier producers, phase and in-flight reservations; a queue snapshot alone is insufficient |
| Unregister | Close new operations, retain descriptor and last old edge as required, mark retiring under gate | Scanner/log/borrow/invocation grace completes before freeing storage; no address reuse until generation changes |

Here acquire/release mean the language-level mutex/atomic contract, not a CPU
fence next to racing plain stores. Sequential consistency for a flag also
cannot fix an unprotected object field. Use source identity plus generation to
prevent a late log record from naming reused storage. Lock ordering must avoid
holding the root gate while waiting for GC acknowledgement or native exit.
This is a chosen architecture with conditional reasoning; primitive choice,
all producer closure, signal safety and generated machine behavior remain open.
[NP03; NA01–NA03]

NT05. Managed heap writes and native root writes have different locations.
The Tcl vector slot, denv binding-pair cdr, captured frame slot and thread
cache use the common heap/control store protocol. RC header `data` and a native
root extent use native-root operations. A remembered **root cell** does not
remember an old vector's new young child. A retained carrier similarly does
not prevent `cleanup_rc` force-free; shutdown closes callbacks and waits for
all accepted users before transferring/removing lists. Mature concurrent
scanning requires separately valid heap field access and old-edge/init rules;
the native root gate does not prove that full collector. [NE01, NE02, NE04]

## Borrow and Blocking Rules

NT06. Each borrowed address has a terminating event, not just a lexical scope:

1. A copied string has native storage and its own refcount/release; avoid a
   redundant second copy, but retain it if the foreign API keeps it past the
   generated conversion's cleanup. RC membership still needs a valid owner.
2. `SCMOBJ_to_POINTER` unwraps a FOREIGN object's external pointer; the
   no-op `release_pointer` does not pin that resource against
   `release_foreign`. A resource-use lease must cover its last use.
3. `scheme-object` is identity conversion. A root must cover its current
   value; load again after possible relocation. A raw interior pointer needs
   no-move or supported pin/copy policy and cannot survive arbitrary reentry.
4. `os_condvar_select` caches `condvars[]` and resource pointers, unlocks the
   queue, waits, relocks and uses cached values. Retain participation and
   exclude relocation in that interval, or register every live Scheme slot,
   reload all derived values and retain device resources before moving service.
   Do not inject GC while acquiring the queue lock with stale arrays.

The actual chain is `##wait!` → kernel save/restore wrapper →
`___os_condvar_select` → `___device_select`. Wait-queue insertion is not
collector detachment. A collective wakeup requests cooperation; it does not
prove this member has acknowledged, nor a finite pause bound. [NE08, NE09]

## Nesting and Exceptional Exits

NT07. A child invocation holds its own target roots, marker, carrier snapshot,
ledger and return capability. The parent roots remain registered across child
allocation/reentry; saved[0] is a fixed scratch slot, not a root stack. Do not
overwrite it until ownership of its prior contents is ended. Same-owner entry
preserves rather than switches the binding. If a new profile permits context
switching, restoration includes prior PSTATE binding, logical fp/R0, denv and
caches according to the actual control transfer, not blind restoration of a
stale C snapshot. TLS alone neither leases a VM nor authorizes execution on an
owner already active elsewhere. [NE03–NE07]

NT08. Every exit has a disposition:

| Exit | Required disposition before propagating / returning |
| --- | --- |
| Marker/conversion allocation failure | Keep incoming donor until accepted roots exist; release only initialized support; preserve error roots; never kill undefined marker |
| Normal return to matching marker | Root/copy result as required; end borrows; settle conversion resources; invalidate marker once; release invocation-owned carrier after last read |
| Callback handles Scheme exception and returns | Ordinary callback result path, with all allocation/reentry effects still covered |
| Conversion error handler invokes Scheme | Existing SFUN loop is another managed entry; its temp1–4, marker and handler arguments remain protected |
| Unmatched marker / outer continuation destination | Existing `___call` rethrows; a proposed per-scope C catcher restores catcher linkage and settles that scope's ledger before rethrowing the unchanged target/outcome |
| Async effect during block/reentry boundary | Cleanup/custody already installed before polling; native result/error bytes and resource lease survive even if ordinary return never happens |
| Foreign code longjmp / native cancellation outside protocol | No proof of owned cleanup or root-chain restoration; reject optimized profile, do not assume defer/finally executes |
| Delete command during invocation / shutdown | Revoke new entry; retain in-flight client data, Scheme carrier, module and release callback until drain; avoid waiting for self while holding Tcl/root/VM locks |

“Exactly once” applies to each accepted **native custody claim**, not to the
number of times a Scheme dynamic-wind before/after thunk may run. A permanent
release cannot be recreated by resuming a saved Scheme continuation. An outer
catcher can settle its ledger but cannot unwind arbitrary library resources
unless their API explicitly permits that escape. C++ destructors and Zig
defer do not supply a proof for a C setjmp/longjmp path. [NE03, NE05, NE06,
NE10, NP03]

NT09. A typed result-style foreign service is useful only when its control
boundary is intentionally specified. It can expose return/error/transfer to
ordinary Zig cleanup **after** the qualified C island has settled the native
transfer. It cannot replace an existing nonlocal continuation edge by a plain
error without changing behavior. Do not place a Zig frame inside an unqualified
longjmp corridor and rely on an outer C catcher. Full Tcl cleanup-on-escape,
external thread entry, cancellation and complete major termination remain
unresolved. [NP04, NP05; NC04–NC08]
