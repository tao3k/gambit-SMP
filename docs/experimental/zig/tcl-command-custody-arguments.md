# Tcl Lifecycle: Conditional Arguments and Counterexamples

Handwritten design arguments only. No prover, model, analyzer, native test or
implementation. IDs resolve in the [source ledger](tcl-command-custody-evidence.md).
The [design](tcl-command-custody-design.md) supplies the proposed contracts.

TP01. Creation custody. Assume protected inputs before effects, an owner-thread
library scope, a builder hold that survives reentry, a qualified create routine
whose adoption points/failures are known, and no raw escape across library
frames. Before adoption, the builder owns initialized support. After adoption,
the publication hold owns it while the builder remains until reconciliation.
If deletion intervenes, `delete_seen` removes publication ownership while the
builder still retains the record. Failure before adoption releases only the
candidate. These cases partition normal returns without a gap or duplicate
release. They do not roll back old-command deletion or namespace/trace effects.
[TC05–TC07, TE01, TX01, TX04]

TP02. Revocation safety. Assume all Tcl calls on the creating OS thread,
pre-effect invocation accounting, retirement-frontier tracking for selected
but not yet entered dispatches, no unsupported external cached client pointer,
and the root/writeback protocol. Delete is serialized with entry on that owner:
an invocation either enters before revoke and owns a counted claim, or sees
revoked state and performs no managed work. Pre-frontier library-scope grace
keeps its record address valid in the latter case. Retaining root/carrier until
all claims and scanner/log users drain keeps movable descendants reachable;
consumers reload forwarded roots. This proves a conditional lifecycle safety
property, not a finite return/GC-pause bound or arbitrary-thread safety.
[TC04–TC10, ND01]

TP03. Drain progress. Delete callback returns without waiting for its own
invocation or library scope. The coordinator closes independent requests but
keeps services needed by accepted work alive. A derived task acquires custody
before its producer releases its last hold; no decrement-to-zero gap is allowed.
The drain predicate includes builder, publication, invocation, pending outcome,
queued work, preexisting library scope and scanner/log obligations. If every
accepted activity terminates under a fair owner scheduler and the dependency
graph has no cycle, the predicate eventually reaches zero. A non-returning Tcl
loop, self-join, stopped owner or foreign escape falsifies those premises.
Safety through retained storage does not prove progress. [TC10, TC12, TC14]

TP04. Resource-specific completion. Command reclamation, marker invalidation,
result-byte release, interpreter deletion and module-image release are separate
receipts. A retained k can keep the cleared marker alive without making its
C return valid. Result bytes already transferred to Tcl need the allocator and
release image, not necessarily k's graph or the CommandRecord. Last interpreter
release happens after owned result extraction and Tcl-dependent work; resulting
delete callbacks still have root/runtime access. Last image release follows the
free callback's return. These ordered transfers avoid both premature free and
unnecessary transitive graph retention, conditionally on all users being known.
[TC08–TC12, TC14, TE05–TE06, TX03, TX06–TX08]

TP05. Ordinary cross-library return. Restrict to a declared cohort whose
callbacks return normally or handle their Scheme exceptions locally. Each
managed scope settles conversion roots and marker, returns through Tcl, and
only then allows library-scope retirement. Under that premise Tcl's normal
cleanup is not skipped by a Scheme transfer. A nested call repeats the argument
with a child scope while the parent holds remain. This is not a claim that
any current arbitrary Scheme proc satisfies the restriction; admission needs
an explicit effect boundary or a separately justified effect analysis.
[TC12–TC13, TE04–TE05, TX04]

TP06. General escape remains unproved. A catcher outside Tcl cannot run the
stack/object/NRE cleanups skipped inside Tcl by raw longjmp. Returning an error
allows library cleanup to run but may be caught, cause additional Tcl actions,
change dynamic-wind timing or fail to terminate. Saving interpreter result/state
does not reconstruct abandoned C frames or arbitrary library invariants. A
typed pending outcome is therefore a proposed explicit service contract, not
a proof of observational equivalence to general Gambit continuation escape.
OCaml's deliberate C-frame boundary is a useful prompt to specify effects;
its restrictions are not silently imported into Scheme. [TC13, TX04, TX10,
TL01–TL03]

## Counterexamples

| ID | Schedule or missing premise | Consequence and boundary |
| --- | --- | --- |
| CX01 | Treat command structure refcount as application client-data hold; deleteProc releases cd during callback | Tcl's structure lifetime does not prove extension storage lifetime; inspect actual later reads before claiming a baseline UAF |
| CX02 | Delete callback waits for active count to become zero while that active callback called delete | Self-deadlock; logical revoke returns and owner drain completes later |
| CX03 | Dispatch selected cd, then reentry deletes command before adapter increments active | Active count alone misses the gap; retain pre-frontier library scopes or prove a stronger no-reentry dispatch segment |
| CX04 | create returns NULL; builder assumes deleteProc must have released the new candidate | Candidate ownership can be orphaned; require rejected-before-adoption receipt |
| CX05 | Old delete callback recreates a same-name command; replacement bypasses that intermediate command's delete notification | Registry cannot infer an unobserved release; arbitrary recreation cohort remains unqualified |
| CX06 | Success/failure cleanup and deleteProc both free candidate during reentry | Builder hold plus identity-based adoption/revoke reconciliation prevents double settlement |
| CX07 | Scheme event thread migrates to another processor/OS thread while still using global interpreter | Scheme mutex does not establish Tcl thread affinity; pin/marshal to creating thread |
| CX08 | Callback escapes through Tcl wrapper to outer CFUN catcher | Gambit conversion cleanup can run while Tcl argv/NRE state remains abandoned; outer catcher is insufficient |
| CX09 | Encode pending Scheme transfer as TCL_ERROR; Tcl catch consumes it then mutates state or loops | Raw escape equivalence and finite drain fail; explicit changed boundary needs its own contract |
| CX10 | Last interpreter lease released before borrowed result is converted | Result pointer may dangle; obtain an owned native/Tcl-object snapshot first |
| CX11 | Command deleted, module unloaded, Tcl later frees its custom string result | Release callback points into unloaded image; result-image last-return lease is independent of command |
| CX12 | Drop parent work before publishing a derived release; shutdown sees zero | Lost custody/false drain; accept child claim before dropping parent |
| CX13 | Capture k, callback returns, then resume k through original native return | Live managed graph does not revive dead marker; preserve existing C-return error |

TP07. Proof scope. The protocol above improves the architectural closure for
the controlled owner-confined lifecycle and normal-return cohort. A broad
fallback scan cannot fix missing command adoption, C resources skipped by a
jump, unsupported interpreter thread access, or stale release-function code.
These are independent admission dimensions, not GC tuning parameters.

TP08. Still unresolved: installed Tcl/Tk source/binary correspondence; a pinned
remote Tcl commit; full command trace/import/recreation/SetCommandInfo users;
Tk event and platform affinity; all pre-dispatch reentry sites; unrestricted
Scheme/native control equivalence; native cancellation/signals; all resource
and module last users; finite owner/GC/shutdown progress; actual generated
equivalence and runtime costs. No full acceptance gate is promoted.
