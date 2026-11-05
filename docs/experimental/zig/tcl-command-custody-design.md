# Tcl Command Publication, Revocation and Foreign Cleanup

Design research only. No implementation, native/compiler test, performance
experiment or model execution. Continue the
[native callback study](native-callback-continuation-design.md) through its
actual Tcl lifecycle callers. Read the [arguments](tcl-command-custody-arguments.md),
[net-benefit matrix](tcl-command-custody-benefit-matrix.md),
[source ledger](tcl-command-custody-evidence.md),
[caller inventory](tcl-command-custody-callers.json) and
[trace](tcl-command-custody-traceability.json).

## Findings That Change the Design

TC01. Distinguish the native command's identity, Gambit's RC client data,
the still vector containing proc, invocation roots/marker, interpreter
activation, result bytes and release-function image. Their owners and last
uses differ. The real paths are `define-procedure`, exported Scheme procedures
embedded in widget command arguments, Tcl invocation, `rename name {}`,
explicit cleanup/setup, and the event-loop thread's `Tcl_DoOneEvent`. The
quoted alternate event-loop definition and commented `Tk_MainLoop` binding are
not active callers. A map/capture callback remains a source-composed scenario,
not an executed sample. [TE01–TE03]

TC02. Tcl's API permits deletion on replacement and interpreter destruction.
Its Preserve mechanism addresses storage still used by reentrant operations.
Treat command revocation and storage reclamation as separate events; do not
infer application client-data lifetime from a Tcl command token. [TX01–TX03]

TC03. Three decisive source details are now available from the reviewed
`core-8-6-branch` reading: failed create can return NULL before installing the
new client data; delete invokes `deleteProc` before the command structure's
final refcount cleanup; the string wrapper frees temporary argv only after
the callback returns. Replacement can also discard a command recreated by
the old delete callback using direct structure free. Therefore ordinary
return, replacement reentry and arbitrary nonlocal escape need different
contracts. These are source deductions, not reproduced failures. This remote
branch is not byte-pinned to an installed Tcl binary. [TX04]

## One Interpreter Owner and Explicit Lifetimes

TC04. All operations on one interpreter run on its creating OS thread.
Gambit's Scheme event thread is not evidence of OS-thread affinity on an SMP
scheduler. A candidate `InterpreterOwner` provides a dedicated or explicitly
pinned service context and an execution permit for the associated VM. Other
contexts submit owned requests; they do not call Tcl behind a mutex from a
different thread. The existing event mutex controls Scheme scheduling, not a
complete interpreter ownership contract. No queue/root gate is held across a
Tcl call or while waiting for its owner. Reentrant owner calls use a scope
stack, not synchronous self-queue/wait. [TE03, TX05]

TC05. Proposed declarative state, not code:

```text
CommandRecord {
  command_identity, generation, interpreter_identity, creating_thread,
  token_if_live, registration_state, delete_seen,
  carrier_identity, root_descriptor, module_lease,
  builder_hold, publication_hold, active_invocations,
  pending_deliveries, queued_users, scan_and_log_users,
  revoke_frontier, preexisting_library_scope_users
}
LibraryScope {
  parent, interpreter_lease, owner_execution_permit,
  native_frame_frontier, rooted_pending_outcome, result_custody,
  active_callbacks, deferred_releases, closing_state
}
CreateReceipt = adopted(command_identity, generation, token)
              | rejected_before_adoption(owned_candidate)
              | revoked_during_operation(retained_record)
              | unresolved_quarantined(retained_record)
```

One physical RC/still carrier may back several logical holds. Do not add an
unnecessary vector or refcount increment for every hold. The record retains
the registration's original root ownership until all its relevant users drain;
invocations have their own precise roots/reloads. A positive still refcount
stabilizes the vector, not its movable descendants. This record cannot be
freed by the old unconditional `scheme_delete_cmd`; that responsibility must
move to a qualified last-user path. Existing RC scanning/donor patches are
reused, not counted as a new repair. [TE01, TE04–TE06; ND01]

## Creation and Replacement Are Not Atomic Transactions

TC06. The builder protects proc/name and retains the candidate's carrier,
descriptor and image before allocation or any Tcl reentry. Install a builder
hold before publishing a pointer to Tcl. Execute create on the interpreter
owner with a library scope that survives reentrant delete callbacks. Reconcile
the returned token with the same record identity/generation and `delete_seen`
while the builder hold remains live. Only then issue `CreateReceipt`.

| Observed outcome | New candidate ownership | Other consequences |
| --- | --- | --- |
| No interpreter / native RC allocation failed | Builder keeps inputs; release only initialized support | No Tcl adoption occurred |
| Still-vector allocation failed | Builder releases the allocated RC exactly once | Proc remains donor-rooted through failure handling |
| Reviewed NULL path before new data installation | Builder reclaims new still/root/RC/image holds | Prior command deletion, namespace changes or other reentrant effects are not rolled back |
| Non-NULL token, identity still registered | Transfer publication hold to command registry; drop builder hold after reconciliation | Invocation/deletion uses record generation, not textual name |
| Candidate revoked before reconciliation | Drop builder hold only after revocation and other users settle | Do not return a stale token as live or free via a second failure cleanup |
| Jump/unknown external side effect prevents adoption decision | Stable operation ledger keeps candidate quarantined | No invented success/failure receipt or speculative double release |

The inspected Gambit code converts create's token to Boolean and has no final
NULL cleanup in that branch. This identifies a required replacement path under
the reviewed Tcl contract; it is not evidence that an installed run leaked.
Process-fatal Tcl allocation failure is not a recoverable NULL branch. [TE01,
TE04, TX01, TX04]

TC07. Same-name replacement has two identities: old record O and new record N.
Deleting O can invoke traces/native deletion code before N is adopted. Keep
both builder and operation state alive; O's active callbacks cannot be charged
to N even if Tcl reuses an address or name. For this controlled profile, either
the old command and its delete/trace behavior are fully described, or a fresh
owner-reserved internal identity is used after a no-reentry collision check.
Never assume `_pN` is globally collision-free just because Gambit increments a
counter: Tcl code can create that name too.

The direct-discard replacement branch in TX04 prevents a universal claim that
every intermediate foreign command receives its delete notification. Arbitrary
recreating delete callbacks, imported-command mutation and externally replaced
command info remain separate admission obligations. A generation registry
alone cannot supply a missing notification. Do not fix this by blindly freeing
the old record whenever create returns NULL. [TE01, TX04]

![Creation and replacement custody](tcl-command-publication.svg)
[D2 source](tcl-command-publication.d2).

## In-Flight Deletion and Drain

TC08. Before the first managed effect at native callback entry, acquire a live
invocation claim on the selected CommandRecord on its interpreter owner.
Preserve source carrier/module, establish input roots and create the independent
marker under the earlier pre-allocation contract. A callback already admitted
keeps its carrier and root extent even if it deletes its own command. A nested
callback acquires a separate invocation; it cannot borrow an occupied saved
slot or reselect a global carrier after allocation. [TE01, TE05, ND01]

An invocation count alone does not protect a dispatcher which has selected
client data but has not reached the adapter prologue. Conservatively retain
revoked records until every library scope active at the revoke frontier has
returned, including enclosing and nested event/eval scopes. A late prologue
can then safely observe revoked state and refuse managed entry. Post-frontier
scopes cannot select the deleted registration under the qualified Tcl lookup
contract; arbitrary extensions retaining raw client data require explicit
additional claims. This grace period may retain many records behind one long
event scope and must be charged as space/progress cost.

The inspected `scheme_call_cmd` reads cd before `tcltk_call` and does not read
it again after return. Thus immediate deleteProc is not itself a proof of a
current use-after-free in this function. The added protection is required by
the proposed record users, delayed outcomes and complete dispatch/custody
contract; it is not a reproduced baseline bug.

TC09. The proposed delete callback performs **logical revoke only**: record
`delete_seen`, invalidate the publication capability, close new adapter entry,
drop the publication hold, schedule an owner-side last-user check and return.
It does not wait for active invocations and does not immediately free the RC
carrier/root storage. Repeated notification/recursive removal is idempotent
for this identity. Tcl traces may run before this hook: registry-driven removal
can revoke before invoking Tcl, while externally initiated deletion may admit
reentry until the hook is reached. Those entries must be counted, not falsely
described as already excluded. A stricter before-trace cutoff needs a separately
qualified trace integration. [TX02–TX04; proposed protocol]

TC10. CommandRecord reclamation requires all of the following:

```text
builder_hold = publication_hold = 0
active_invocations = pending_deliveries = queued_users = 0
preexisting_library_scope_users = 0
scan_and_log_users = 0, root storage retirement acknowledged
no retained native user or callback pointer outside the declared cohort
```

Update counters only on the interpreter owner; cross-thread requests use
release-published/acquire-consumed owned messages. Collector/root operations
use the earlier serialized native-root access and relocation cut. Final native
release runs in the qualified owner context after root/log grace; it does not
race raw RC/still refcounts or force `cleanup_rc` early. A pending delivery may
hold an independent root and release the command earlier only after a recorded
transfer. Unknown users retain quarantine rather than pretending drain ended.
[TE05–TE06, ND01]

TC11. Result bytes are a different ownership channel. Current
`scheme_call_cmd` transfers converted string storage to Tcl through a custom
free function. That storage and the release-function image can survive command
deletion. Keep a result-release lease at the module/runtime level, or deliberately
copy into Tcl-owned storage and charge that copy; do not retain the entire
continuation graph merely because a native result string still exists. Before
the final interpreter release, take an owned result snapshot for later Scheme
conversion. Never return a borrowed `Tcl_GetStringResult` pointer after releasing
the last interpreter lease. Preserve allocator pairing; Gambit RC bytes are
not automatically `TCL_DYNAMIC` storage. [TE01, TE06, TX06–TX07]

Dropping a result-release count inside its free function does not authorize
unloading the function's own image before it returns. Last-return/image grace
is part of the runtime-level release receipt.

![Revocation and dependency drain](tcl-command-revocation.svg)
[D2 source](tcl-command-revocation.d2).

## Across the Library Boundary

TC12. Wrap **every** callback-capable Tcl entry, including create/delete,
`Tcl_Eval`, `Tcl_DoOneEvent`, setup and final interpreter release, in a
LibraryScope. An owned interpreter snapshot/generation replaces re-reading the
global `tcl_interp` after reentry. Preserve interpreter storage before an
operation can trigger deletion, then release on the same owner after extracting
results and settling Tcl-dependent tasks. Release can itself cause deletion
callbacks; the execution permit, root services, deletion hooks and code image
must still be live. Preserve keeps storage alive, not the interpreter logically
open for further evaluation. [TE01–TE03, TX03, TX05, TX08–TX09]

TC13. Three control policies must not be conflated:

| Boundary behavior | Cleanup strategy | Semantic admission |
| --- | --- | --- |
| Callback returns normally or handles its Scheme exception locally | Finish SFUN conversion/marker cleanup, return through Tcl, settle library scope | Candidate closed-return cohort, conditional on all root/resource premises |
| Explicit result-style service boundary | Capture a typed owned outcome inside the callback; return through library; inspect rooted pending outcome at the nearest declared boundary | New explicit foreign control contract; all Tcl catch/error/event/trace effects must be specified |
| General existing Scheme continuation/exception escape through Tcl C frames | Gambit-only catch/ledger cannot execute library cleanups skipped by raw longjmp | Unresolved for unchanged semantics; exclude this edge from the new qualified profile until a complete library-aware protocol is proved |

Returning `TCL_ERROR` is not an uncatchable unwind: Tcl `catch` can intercept it
and continue with side effects. `DoOneEvent` also does not expose the same
command-result interface as `Tcl_Eval`. A pending flag can block further managed
entries but cannot stop arbitrary Tcl/native activity or prove eventual return.
Do not claim that an error sentinel, result snapshot, Tcl interpreter preserve,
outer catcher, C++ destructor or Zig defer supplies general cross-library
continuation equivalence. Current CFUN cleanup selection depends on argument
types, not this complete foreign effect; the zero-argument event entry is a
particularly important caller. [TE03–TE05, TX04, TX10–TX11, TL01–TL03]

TC14. Shutdown is a dependency order: close independent create/eval/event
requests; revoke commands without self-wait; let admitted library scopes and
callbacks return/transfer under their declared control contract; drain accepted
derived tasks with counted parent custody; settle pending Scheme outcomes;
retire command roots/carriers after scanner grace; copy/drain Tcl-owned results
and run owner-thread interpreter deletion/release while hooks remain live;
complete resulting deletion/release tasks; only then allow runtime/VM/module
teardown. Independent native result leases need not retain an interpreter but
must retain their allocator and free-function image. A shutdown request from
inside its own callback returns pending rather than joining itself. If a library
never returns or a forbidden jump has already occurred, finite drain is not
proved; retaining storage is not a completed shutdown. [TE03, TE06, ND02]

This study specifies a conditional closure for owner-confined creation,
revocation and ordinary-return callbacks. Full installed Tcl/Tk source identity,
arbitrary traces/extensions, event affinity and unrestricted foreign escape
remain unresolved. The required reconstruction is shared by modern generated
C and Zig. No old path is retired here.


## Control Semantics Follow-Up

The [Tcl control-boundary design](tcl-control-boundary-design.md) refines TC13
with Gambit's native returning-handler behavior, catcher grafts and precise
dynamic-wind hook contexts. It distinguishes catchable error translation from
Tcl's stronger cancel-unwind mechanism, explicit result authority, nested
event destination and shutdown quiescence. Read the
[conditional arguments](tcl-control-boundary-arguments.md),
[net-benefit matrix](tcl-control-boundary-benefit-matrix.md) and
[source ledger](tcl-control-boundary-evidence.md). This is design-only progress;
general unchanged cross-library continuation semantics and native admission
remain unresolved.
