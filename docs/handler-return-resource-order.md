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

## Outer Cleanup, Device Aliases And Failure Returns

This continuation follows the callers before interpreting the inner cleanup
order. All baseline anchors still refer to the pinned Gambit revision above;
patch anchors name the retained reconstruction, not another thread's binary.

### Actual Entry And Counterevidence

The retained `___cleanup_checked` calls `___cleanup_all_interrupt_handling`
before `vm_registry_seal`, processor/VM teardown and `cleanup_os_and_mem`.
Baseline `os_setup.c:518-523` shows that the first call already invokes
`___cleanup_user_interrupt_handling`. Therefore the later inner order
`___cleanup_io_module` then `___cleanup_tty_module` at `os_setup.c:3224-3235`
is **not** evidence that global cleanup never attempts to disable the TTY
handler before destroying devices. Inferring a race solely from that inner
order would omit the actual caller and should be rejected.

The distinction that survives this countercheck is narrower:

- `os_tty.c:8804-8834` attempts disposition reset and unblocks four signals;
  neither it nor the void `___set_signal_handler` wrapper reports success or
  completion of already executing callbacks. This audit observed no failed
  syscall and asserts no new OS delivery/drain guarantee.
- `os_thread.c:874-894` selects `pthread_sigmask` in the POSIX thread profile,
  otherwise `sigprocmask` where available. The user-interrupt masking helpers
  at `os_tty.c:8837-8868` do not enumerate or acknowledge all possible host
  receiver threads. Their presence is not an OS-wide completion witness.
- The wrapper's VM registry admission protects VM delivery, not the outer
  TTY chain traversal or mode restoration. The supported receiver population
  and host exclusion contract remain required source premises.

### Per-Resource Consumers And Error Paths

| Resource / alias | Concrete consumer and retirement boundary | Remaining source obligation |
| --- | --- | --- |
| Process-static callback fields | `tty_signal_handler` reads `___tty_mod.user_interrupt_handler` or `terminate_interrupt_handler`; setup assigns them at `os_tty.c:8874-8895`. | Static field storage is not itself a freed VM object. Establish callback code lifetime and reinitialization ownership rather than claiming a dangling VM pointer from a field read. |
| TTY record and `mode_save_stack_next` | SIGWINCH loads `probe`, writes `size_needs_update` and follows links at `os_tty.c:8716-8727`; SIGCONT calls `___device_tty_mode_restore` at :8731-8732. | The local `probe` / `curr` / `prev` / `next` aliases must finish before their record is freed or repurposed. A changed head alone cannot revoke them. |
| Mode-save chain | `___device_tty_mode_restore` at `os_tty.c:638-700` reverses and restores links and may return an error; it finally assigns `mode_save_stack`. | Treat restoration as mutation, not just a read. Map every exit and surviving alias under the selected signal/host contract. A final head store is not a concurrent-reader acknowledgement. |
| Group membership versus device storage | `___device_cleanup` at `os_io.c:1625-1670` removes group membership before close/select; non-EAGAIN errors return before `___device_release`. The latter frees only when refcount reaches zero at :1602-1623. | Removing a device from a group is not successful close, TTY-chain unlink, zero refcount or free. Classify each actual outcome separately. |
| Cleanup failure and retry state | `___device_tty_close_raw_virt` at `os_tty.c:7570-7610` marks both stages closed before calling `___device_tty_cleanup`; :8161-8199 can return on mode-restore or handle-close error. | Closed stage bits alone do not witness successful mode unlink or close. This identifies an error-path proof obligation, not an observed cleanup error or authorization to retry an unsupported entry. |
| Group carrier | `___device_group_cleanup` at `os_io.c:183-193` breaks on a device cleanup error, then frees the group; `io_module_cleanup` at :11895-11906 does not return a per-device result. | Do not interpret a void global cleanup return as an enumerated all-device success witness. Establish the surviving devices' actual ownership, group pointers and last consumers before proposing a change. |

There is no native proof here that a TTY callback overlaps those operations,
that the error paths occurred, or that they caused a GC/TFIB/pipe failure.
Conversely, a root-VM lease count cannot exclude those possibilities. A
supported exclusion witness can legitimately discharge an empty callback
population; an unrecorded population is not such a witness.

### Existing QNT And Lean Correspondence

No duplicate model or fictitious native action is needed for the distinctions
already represented. The qualified model and proof bytes remain unchanged:

| Existing owner | Exact reusable result | What this source audit still cannot instantiate |
| --- | --- | --- |
| `handler_admission_window.qnt`, `noPostReleaseTail` negative control and `tailHasNoCountedLease` | A successfully admitted interval can end before invocation return. | Neither property proves that a TTY consumer participates in the VM lease, or that an OS disposition change completes an invocation. |
| `saved_stack_last_access.qnt`, `lastAccessSafe` / `completeCensusSafe` | Registered-root completion and a separate in-flight consumer have distinct last-use obligations. | This model's root/GC actions concern saved stacks. A TTY-chain alias is a structural countercheck, **not** a newly source-refined instance of those GC transitions. |
| `RepairConsumerInterfaces.lean`, `declaredAndPrivateConsumersCompose` / `omittedPrivateConsumerDefeatsPublicCompletion` | Completion composes only with coverage of every actual consumer; an omitted live consumer defeats the universal conclusion. | Actual device/host consumer enumeration, incarnation, and exclusion/last-use witnesses are source premises. The theorem cannot manufacture them from a zero VM census. |
| Same proof, `lastResourceAccessCanPrecedeInvocationReturn` | Nonempty resource use can finish before the enclosing invocation returns. | Whole-handler drain is sufficient only under its stated complete population, and is not necessary for every process-static resource. |

Rechecking unchanged formal bytes would not answer these source questions.
The registered DSL therefore exposes an additional **unbound source-census
premise**, not a new proof or native completion. A model extension is warranted
only if the supported source contract supplies an actual mechanism not captured
by these interfaces; a general callback/host-generation redesign remains in
Experimental.

### OCaml's Concrete Acknowledgement Countercheck

The pinned OCaml source supplies a narrower reusable mechanism than "join every
thread": `terminate_backup_thread` at `runtime/domain.c:1262-1275` publishes
`BT_TERMINATE` and wakes the backup thread; it does **not** wait for return.
The backup thread release-publishes `BT_INIT` immediately before returning at
:1218-1221. `backup_thread_running` acquire-loads this message at :405-408;
`caml_free_domains` at :2479-2500 waits for the acknowledgement before freeing
the carrier's mutexes/conditions. New backup installation also waits at
:1233-1240, then creates a detached thread at :1250-1259.

This demonstrates the precise distinction between a stop request and observed
last use of a retained synchronization carrier. It relies on no further carrier
access after the acknowledgement, stable carrier storage, the actual release /
acquire pair and the supported thread population. The installer explicitly
blocks signals around thread creation (:1242-1257); Gambit cannot inherit that
receiver-population premise merely by borrowing the message pattern. The TSan
comment at :2503-2508 also explicitly limits what this source claims about
termination observations; this audit does not declare OCaml globally race-free.

Chez provides a complementary lifetime split: `c/thread.c:283-298` closes
thread-local allocation work; :324-330 retains/recycles `thread_gc` because
segments can still name its creator. The TC is freed at :331 before updating
the distinct Scheme thread record and broadcasting termination at :333-336.
A retained carrier therefore needs an explicit surviving consumer, not simply
"keep all old state". None of these contracts changes Gambit's C backend,
continuation representation or FFI calling convention.

The current QNT post-release tail and Lean resource-use-before-return witness
already distinguish these boundaries. They do not prove an OCaml-style atomic
acknowledgement exists in Gambit. Introducing one requires its own actual
publisher, stable carrier, read-side ordering and no-later-use correspondence;
it is a Recipe alternative, not an accepted source repair.

### Coordinated Small-Refactor Recipe

The implementation lane can evaluate a single bounded package without changing
C generation, multi-shot continuations, TLS or FFI semantics:

1. Bind the supported cleanup caller, configuration and signal receiver set;
   retain the early `cleanup_all_interrupt_handling` counterevidence. Audit a
   direct lower-level cleanup caller separately rather than granting it the
   global entry's preconditions.
2. For each resource/incarnation, identify actual last aliases and the event
   that excludes later access. Keep disposition outcome, admitted-VM drain,
   TTY-chain retirement and code lifetime separate. No new blocking lock in a
   signal handler follows from this research.
3. Preserve success/error distinctions through the relevant cleanup boundary:
   attempted disposition change, stage-closed, group-removed, last-reference
   release and storage-free are different observations. A proposed internal
   status propagation must specify the supported failure retention/exit policy.
4. Handoff the exact source delta and original acceptance obligations to the
   native lane. Its necessary falsifiers include an already entered callback,
   a legal no-callback branch, a close failure before release, and a final
   successful last-use boundary. Do not repeat its unchanged bootstrap here.

This is a source-correspondence Recipe, not an asserted current bug fix or a
mandatory Agent workflow. Passing an interface check does not close item 9,
complete GC/FFI, Gerbil correctness or release performance.
