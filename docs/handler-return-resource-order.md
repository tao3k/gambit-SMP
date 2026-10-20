# Handler Return, Last Access And Resource Reuse

## Source Identity And Scope

Current repair, not a runtime implementation or a new host API. Gambit baseline:
`vendor/gambit` at `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
The retained mutex-return lock and its exact cumulative patch remain the
candidate reference, not a claim about a successor binary. Baseline line ranges
below are explicitly distinguished from named functions added by that patch.
Chez is pinned to `41d5ffca7a07cbfc8807e719dedcc70ed74811cd` and OCaml to
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`; both source trees were clean.
These match the published PR's submodule pins. No runtime,
fixture, native checkpoint or acceptance budget changes in this investigation.

## The Missing Distinction

An OS-delivered invocation, a counted registry lease, the last access to a
particular resource, and the C function's return have different boundaries.
Neither direction of the following equivalence may be assumed:

> zero admitted readers = every handler returned = every resource reusable.

The prior model was intentionally conservative about a whole invocation. Actual
source mapping must separately establish object/storage safety, code lifetime
and event-generation semantics. Requiring whole-call return for every resource
could impose unnecessary retention; accepting a zero counter for every resource
could omit pre-entry or post-release consumers.

## Actual Handler Path

| Source boundary | Observed mechanism | What remains unproved |
| --- | --- | --- |
| Baseline `lib/os_base.c:1817-1844`, `___set_signal_handler` | Attempts disposition changes with `sigaction` or `signal`; the void wrapper ignores the result and produces no invocation-completion receipt. | Actual disposition success, host delivery/return and generation contract. No syscall failure was observed by this source audit. |
| Baseline `lib/os_tty.c:8699-8733`, `tty_signal_handler` | Reads `___tty_mod` callback fields for SIGINT/SIGTERM; SIGWINCH traverses TTY records; SIGCONT has a different restoration path. | These resources and signal families cannot inherit a root-VM-only lease proof. `USE_signal` also rearms before dispatch. |
| Retained patch `lib/os_setup.c`, `user_intr` | Calls `___raise_root_user_interrupt`; no old VM pointer is captured by this wrapper before registry entry. | A delayed old event is not by itself an observed old-pointer dereference. Event association with a later runtime still needs its supported contract. |
| Retained patch `lib/setup.c`, `vm_registry_enter` | CAS admits a counted interval only while neither closed nor sealed. | Earlier delivery and callback-field reads are not in this census. The QNT first-instruction count remains a generous abstraction, not this CAS's exact refinement. |
| `vm_registry_deliver` and its admitted callers | Reads the VM list/root and calls interrupt delivery inside the counted interval. | All paths, configurations and reentrant callers must obey that interval; a model check alone cannot enumerate them. |
| `vm_registry_leave` | Decrements the count, then reads the static pending word and may call `vm_registry_flush`. | Counter zero is not function return. A source audit must identify which resources the remaining tail actually accesses. |
| `vm_registry_flush` | Each VM delivery first enters a fresh lease; a closed/sealed gate returns without that delivery. Its raw release avoids recursive leave/flush. | This is evidence against inferring an unleased old VM dereference merely from a live flush tail. It does not prove old handler/code or TTY-record quiescence. |
| `___vm_registry_close`, `vm_registry_seal` | Close admission and observe admitted count drain. | They do not establish completion of every OS invocation or every non-VM consumer. |

The gate/pending words are process-static in the retained patch. Their memory
does not share a reclaimed VM object's lifetime, but delayed reads/writes or
reacquisition can still matter to generation/event semantics. Do not turn a
possible cross-generation event into a proved memory-corruption cause. Likewise,
the model's ghost delivery epoch is not a token C can observe at OS delivery.

Applicability must be explicit: `USE_SIGNALS`/`USE_WIN32`, `USE_signal` versus
`USE_sigaction`, and `___SINGLE_VM` versus the registry path. The single-VM direct
root path has no registry lease and needs its own supported host exclusion
contract. No Windows callback teardown or unrestricted host reinitialization
capability is established by this Unix/root-handler research.

## Last Consumers And Reuse

| Resource | Last-use/order evidence | Invalid shortcut |
| --- | --- | --- |
| Old raw frame bytes | Existing root Recipe: receiver break traversal and `mark_captured_continuation` read RA/link/body; another origin may still require old metadata. | Retargeting one slot is not closing all aliases or consumers. |
| Copied target chunks | Baseline `mem.c:3667-3810` publishes captured-frame work under the collector's memory-lock protocol; the existing Recipe maps the retained candidate ranges. | An old-frame last read is not target tracing completion. |
| GC half/arena | Baseline `mem.c:7002-7038` orders setup, strong, weak, cleanup and resize with barriers. Existing arena/root models separate slot cleanup, VM backing and next-half reuse. | Strong-work drain alone is not whole-cycle completion or permission to overwrite every old origin. |
| Native activation and generated code | Must use the actual C/FFI call/return and loader lifetime contract. | A live Scheme continuation or preserved VM arena cannot extend an exited C activation or unloaded code. |

The current source handoff must identify a last consumer **per resource and
incarnation**, plus the publication/acquire or collective edge permitting reuse.
An empty census is legal with a scoped absence witness. Neither unconditional
GC on shrink nor indefinite retention follows from these remaining obligations.

The barrier name alone is not a C-order proof. Baseline `lib/setup.h:62-67`
makes `BARRIER()` empty for `___SINGLE_THREADED_VMS`, otherwise calling
`barrier_sync_noop`. The selected cohort and actual wait/return protocol must
cover every relevant producer; an arbitrary host borrower is not automatically
a member. `include/gambit.h.in:11015-11027` maps the GNU synchronization profile
to `__sync` operations and `__sync_synchronize`; other profiles differ. These
source definitions are configuration premises, not a refinement theorem for
the C memory model or permission to infer quiescence from a macro name.

## Chez And OCaml Counterchecks

Chez `c/thread.c:261-341` closes allocation/dirty work, migrates guardians,
recycles a preserved `thread_gc` carrier and frees the TC under its thread
protocol. The function still updates the separate Scheme thread record and
signals termination after `free(tc)`. Thus a C function can remain active after
its final access to one reclaimed resource; this is not proof that Gambit's tail
has the same ownership. Chez `c/schsig.c:728-745` routes signals to its main TC,
with a same-thread queue contract at :687-690. Import neither a universal
signal-drain guarantee nor that ownership assumption into Gambit.

OCaml `runtime/domain.c:2357-2424` explicitly forbids further access to a reusable
interruptor while retaining a different domain lock through teardown. It has
resource-specific frontiers, not a single global "thread done" fact.
`major_gc.c:1589-1619` claims/scans a continuation and release-publishes marking;
`fiber.c:641-668` synchronizes consumption with that marker. The relocation path
at `fiber.c:510-552` updates all matching C stack links, including callback
aliases, before freeing the old stack. These are explicit obligations to check,
not justification to replace Gambit's multi-shot continuations with OCaml's
one-shot take operation.

## Existing Model Refinement And Handoff

`handler_admission_window.qnt` now separates a post-count-release stage from
actual invocation return. Its added negative control reaches a live tail with
zero counted readers after successful admission, not a rejected-entry path;
its positive counter property and conditional completion
remain independently checked. It deliberately does not invent a VM pointer or
declare that the tail accesses an old one. The unchanged last-access/root/arena
models continue to own their resource-census and reuse conditions.

`RepairConsumerInterfaces.lean` adds a nonempty-use witness showing that all
resource accesses can finish while the invocation is not returned. Together with
the existing conditional census-composition lemma, this prevents conflating a
whole-call census with each resource's actual last-use census. It is not a proof
that any particular C instruction is the last native access.

Implementation handoff remains conditional, not an instruction to add a lock:

1. Establish each supported handler entry, actual disposition-change outcome
   and pre-admission reads. A call to the void wrapper is not a success witness.
2. Map VM dereferences to admitted intervals and every release/flush/reacquire
   tail; classify process-static, VM, TTY and code resources separately.
3. Map saved/raw origins, private tracing work and foreign activation tails to
   their own last accesses and the relevant reuse/publication edges.
4. Supply exact-source correspondence or a supported exclusion witness, then
   discriminate the original producer's failure. This research does not run it.

A general signal generation token, host-attachment API, new root ABI or collector
organization still belongs in Experimental, not an unreviewed current fix.
