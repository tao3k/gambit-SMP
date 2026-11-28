# Conditional Arguments and Distinguishing Histories

These are handwritten source-composed arguments. No model, prover, compiler or
native scenario was executed. IDs are trace references, not test results.
[Design](tcl-cancel-writer-design.md), [evidence](tcl-cancel-writer-evidence.md),
[inert cases](tcl-cancel-writer-cases.json), [trace](tcl-cancel-writer-traceability.json).

WP01. Publication linearizes only with complete ownership preparation.

Assume a lifetime lease remains valid across conversion, all commit records and
locks are prepared, C/A order is respected by every admitted producer, and no
commit callout occurs. C serializes target/token validation, slot exchange and
generation assignment; A binds that publication to the proper mark. A successful
operation therefore selects exactly one pending generation at its commit cut,
and unsuccessful preparation cannot alter the slot. Supersession remains a
terminal service obligation rather than a fabricated observation. This is a
conditional linearizability argument for the declared operation, not equivalence
of arbitrary legacy object hooks or a lock-free progress claim. [WD04–WD06, WX02, WL01, WL02]

WP02. Immutable storage is safe only if reference acquisition is protected.

Assume every pending, installed, claim, output, delivery and retirement holder
owns a counted lease; acquisition occurs under C/owner exclusion or an existing
lease; counts cannot overflow; final release uses the correct allocator and no
new acquisition can begin after detachment. Then a live holder prevents final
reclaim, and a payload can be read without mutation after publication. Slot
replacement releases only that slot's reference. The storage theorem says
nothing about whether installed U was observed, a reset was legal, or the target
itself is alive; those require separate identities/leases. [WD04, WD07, WD08, WL02]

WP03. The source writer catalog exposes a missing reset-only premise.

The 350 exact blobs have the cancellation-name inventory and broad 99-line
whole-flag/constructor audit. The latter identifies trace's save/eval/restore,
with actual direct and callback-pointer inbound routes. Thus an argument whose
only destructive writers are Tcl_Canceled and named reset sites is incomplete
for this pinned source. Within the textual boundary, WD02 maps the identified
effects, but arbitrary aliases, generated code and loaded extensions remain
outside this method. No absence-of-writers theorem follows from word search.
[WD01, WD02, WD09, WX01, WX08]

WP04. A final guard cannot retroactively preserve inline behavior.

At TEOV_Exception, old flags are cleared before NRCommand's later cancellation
check. Suppose that clear is delayed while result is TCL_OK and U remains set:
the later check can produce ERROR. At the bytecode site, object decrement follows
clear; its permitted cleanup/reentry domain can distinguish old and delayed
state. Therefore a final-only reset is not generally equivalent. A source-point
guard request preserves the original mutation location only if its disposition
has the same predicate and actual effect there; the later final receipt proves
actual completion separately. [WD10–WD12, WX04, WX05]

WP05. Owned clear protects later generations only under a changed-or-restricted policy.

Assume complete contributor identity, no untracked snapshot writer, fixed target
and token generations, a qualified whole-frontier C/A cut and no partial clear.
If all contributors are covered, the owned clear can retire that set without
deleting a newer contribution; otherwise state is retained and reuse sealed.
But source-compatible unconditional clearing at an inline site could have erased
the new contribution. The protection and source equivalence cannot both be
inferred for that distinguishing history. Restrict such histories before entry,
or declare the normalized semantics and prove its continuation/error behavior.
Deferral after acceptance retains obligations; it does not make the history
disappear. [WD09–WD12, WX03, WX05, WX08, WL01]

WP06. A cancellation-neutral trace domain requires all state writers to agree.

If cancellation is separate from the legacy flag word, every check/install/reset
uses the owned cell, and no private client writes a shadow projection, restoring
legacy trace flags cannot resurrect or erase cancellation. If any writer still
uses old bits, the cell and word disagree. Exact legacy whole-word restoration
instead remains a source-snapshot event with real cancellation effects, not a
normalized clear. Neither selective masking nor a saved U bit reconstructs the
lost contributor history. [WD03, WD09, WD15, WX08, WX11]

WP07. Reset status, bit consumption and epoch neutrality are distinct.

TclResetCancellation can return OK without clearing when depth is nonzero;
Tcl_Canceled with UNWIND-only filtering can clear C and return OK; bit clearing
does not remove pending payload or ready token. Consequently no single OK,
zero-bit read, or reset return establishes neutral reuse. A valid next-epoch
publication additionally covers future installers, raw history, active claims,
logical/native completion and the same selected writer policy. [WD03, WD11, WD12, WX04–WX06, WO01]

WP08. Deletion safety needs admission closure and a callback grace join.

Assume deletion first closes target admission under the same validation authority,
preparers have lifetime leases, unclaimed token unlinking follows owner/A rules,
selected callbacks retain clientData, and reclamation waits for all holders after
unlocking. Then a later preparer fails generation/lifecycle validation and no
live claim references freed record/payload/image. If callback return or a foreign
destructor never happens, drainage does not complete; this is not a lock-free or
bounded-time termination proof. A native-frame or Scheme continuation escape
outside the boundary invalidates the completion premise. [WD08, WD13, WD14, WX09, WL03, WE01]

WP09. Required support remains shared by modern C and Zig.

For the same admitted histories, both providers require all 13 support families
in WV01. Generation validation, native callback lifetime and source-point reset
accounting are runtime semantics, not syntax. Zig may reduce some handwritten
cleanup plumbing only if the common Scheme generator cannot provide the same
reduction at lower total cost. Its allocator/error/defer facilities do not
establish cross-thread reference safety, NRE lifetime, nonlocal exit cleanup or
Tcl ABI closure. An extra backend is beneficial only when a measured or derived
incremental reduction exceeds its additional ABI/toolchain/duplicate-proof
obligations, with equal capabilities and behavior. [WD15–WD18, WV01–WV08]

WP10. Conditional positive controls need every premise, not just a working lock.

Under a finite admitted target tree and payload-holder set, reserved bookkeeping,
valid object-hook domain, all-writer closure, chosen source or normalized policy,
actual terminal callback/native/logical returns, and no new post-close producers,
publication, installation, source-point dispositions, final settlement and
reference drainage can form one acyclic custody chain. Removing any premise
below yields a distinguishing history. This is a proposed composition argument,
not a formal termination/refinement proof or native qualification. [WP01–WP09]

## Inert Counterexamples and Conditional Controls

| ID | History | Required conclusion |
|---|---|---|
| WC01 | Request A begins preparation first; B commits first; A commits last | A is last pending; preparation time cannot order acceptance |
| WC02 | Read pending pointer; replacement frees it; then increment its count | Use-after-free; acquire lease before unlocking |
| WC03 | Replace pending A with B while A is installed/output-leased | Release only pending A reference; A bytes remain live |
| WC04 | U from A persists; normal B installs a different diagnostic | U origin and diagnostic origin differ |
| WC05 | Parent cancellation sets child flags with child old diagnostic | Parent message must not be fabricated as child's message |
| WC06 | Source reset clears bits but an attributed mark remains pending | Not epoch neutrality; later callback may install again |
| WC07 | Same retained pending record is marked after a prior install | Reinstallation is not a new accepted payload request |
| WC08 | Trace saves C/U=0; nested eval installs U; whole word restored | New U can be erased; guard must account for trace writer |
| WC09 | Trace saves C/U set; nested eval consumes/resets; word restored | Old bits can resurrect; old payload identity may already be retired |
| WC10 | Replace trace whole restore by only restoring trace bit | Changes other flag restoration; no general equivalence claim |
| WC11 | TEOV clear moved after NRCommand; OK result and U survives | Later check can turn OK into ERROR |
| WC12 | Bytecode clear delayed until after object decrement/reentry | Cleanup can observe different state; hook domain must qualify |
| WC13 | Apply private depth-zero reset at TEOV's pre-decrement depth | Wrong no-op; source scope must authorize the original clear |
| WC14 | Private reset returns OK at depth nonzero | No applied-clear witness |
| WC15 | UNWIND-only check clears normal C then returns OK | Destructive filter is not a nonmutating query |
| WC16 | ChildEval resets descendants; caller treats child itself as cleared | False subtree coverage |
| WC17 | Parser readiness fails before nested eval; reset branch still runs | Guard must represent attempted entry, not invent nested completion |
| WC18 | New raw U installed before old inline source clear | Source clear may erase it; owned deferral changes later behavior |
| WC19 | Keep modern cell but private trace/extension restores old flag word | Dual authority; reject owned-domain profile |
| WC20 | Raw NULL/missing target plus owned argument | Pinned failure does not decrement; no implicit managed rule |
| WC21 | Message conversion reenters and deletes/replaces target | Revalidate lifetime/generation after conversion |
| WC22 | Success cleanup reenters and publishes another cancellation | First request already accepted; two independent custodians |
| WC23 | Raw NULL message replaces non-NULL pending buffer | Pinned assignment drops that pointer without a visible free there; new storage retirement must be explicit |
| WC24 | Copy/convert/decrement or lazy lock allocation occurs under commit lock | Callout-free/non-failing commit premise fails |
| WC25 | Callback selected before token unlink; record freed immediately | Callback clientData lifetime violation |
| WC26 | Deletion waits synchronously for the same active callback | Self-wait; defer join outside callback/locks |
| WC27 | Partial descendant install then lost progress record | Uncovered children retain effects without a custodian |
| WC28 | Clear bits; then allocating its receipt fails | Destructive effect unrecorded; reserve metadata before write |
| WC29 | Stored explicit bytes contain an embedded NUL | Pinned -1 output path is not lossless-byte delivery |
| WC30 | Guard reports native completion on NRE scheduling or coroutine yield | Logical/native frontier remains open |
| WC31 | Native callback escapes across Tcl frames; rely on Zig defer | No cleanup proof for forbidden nonlocal escape |
| WC32 | Finite source-policy history; exact source clear points and whole trace snapshots recorded | Conditional source behavior witness only; no owned-clear qualification |
| WC33 | Finite owned-domain history; complete writers, leases, source-policy changes, actual completion and drain | Conditional normalized control only; not native/prover execution |
| WC34 | Payload refcounts reach zero but raw idle cancellation debt has not been consumed | Storage drainage cannot authorize interpreter reuse |
| WC35 | OOM converted into managed ERROR but advertised as unchanged raw behavior | Failure contract changed; qualify separately |
| WC36 | Generation/count wraps or retired target address is reused without lifetime identity | ABA/history mismatch; deny admission before exhaustion |
| WC37 | Every named reset is migrated but whole saved flags are not | Writer closure incomplete despite a final guard |

WX01–WX11 bind these source-composed schedules. WC32/WC33 are conditional positive
controls, not executed successes. WC08/WC09 are distinguishing bit histories
composed from actual save/eval/restore statements; their full script/native
reachability and outcome classification have not been tested.
