# Conditional Proofs and Inert Counterexamples

These are handwritten source arguments, not checked proofs, executable models,
native tests or retained-fixture results. See the [design](tcl-coro-invariants-design.md)
and [evidence](tcl-coro-invariants-evidence.md).

IP01. A reserved NRCommand is not yet a credited command.

Premises: selected TclMarkTailcall and TclNREvalObjv branches, no intervening
unclassified environment/deferred mutation. Mark reserves a callback and sets
deferredCallbacks without changing n. The next evaluator clears that pointer
and adds one to n without allocating another NRCommand; its eventual callback
subtracts one. Therefore one credit pairs with one retirement, while queue
length alone overcounts depth between reserve and evaluate. TclPushTailcallPoint
is a different immediate-credit producer. Counterexample: moving a reservation
to another environment or allowing private code to leave it unconsumed violates
the premises and needs rejection/qualification. [ID02, ID03, IX02, IX03, IX08]

IP02. Resume/yield is an affine round trip, not an absolute restoration.

Premises: same activation, same stored caller b, actual net in-activation deltas
s, no unknown writer/overflow. Resume maps (n=b,aux=a) to (n=b+a,aux=b).
Yield maps that to (n=b,aux=a+s). Algebra proves preservation of the current
caller depth and storage of the new relative offset. It does not prove a+s>=0
for all histories or fit in a signed integer; those need resource/credit/debt
invariants. A different current caller b' correctly resumes at b'+a, as the
retained floor fixture intends. [ID04, IX04, IX12]

IP03. Balanced root termination repays one debt after cleanup.

Premises: canonical root staging and its one credited NRCommand, one creation
discount, no additional relative leases at terminal bottom, proper exit/caller
callbacks and finite nonescaping cleanup. Initial relative depth is zero;
retiring the root produces n=b-1. Exit later adds one and restores n=b. It
asserts the right caller callback but still performs callouts before completion.
Queued exit callback, popped in-flight exit, destroyed ExecEnv and freed
CoroutineData are separate stages. Debt accounting and resource completion
therefore cannot be reduced to an empty queue. [ID05, ID10, ID11, IX02, IX03,
IX07, IX08]

IP04. Direct deletion defeats the universal positive-depth premise.

Premises: owner-live suspended coroutine created with root yield, a=0, no extra
traces/hooks/cancellation/errors, and sufficient finite resources. Public
deletion invokes DeleteCoroutine and direct rewind staging; neither supplies
an ordinary evaluation increment. With idle caller b=0 the source sequence is
0->0 activation, root retirement ->-1, exit compensation ->0. It is a public
API/source composition, unexecuted; it does not assert a defect or observed
installed negative depth. With an older trace h and ordinary nested command,
b>=h+1 gives terminal >=h; a direct deletion callout at b=h has only >=h-1.
No legal old-trace/reset-hook composition is supplied by this arithmetic alone.
Counterexample to an overstrong safety check: trapping or unsigned-wrapping
every negative transient before root compensation changes this selected path.
[ID06, ID14, IX02–IX04, IX07, IX09, IX11]

IP05. Successful yieldto transfers a list obligation rather than completing it.

Premises: valid namespace/coroutine, correct empty unmarked caller NRCommand
slot, correct list reference ownership and successful active-yield stack match.
The emitter installs list into caller slot and records yieldPtr before yield.
Success clears yieldPtr but preserves caller slot ownership. Caller restoration
precedes ordinary caller NRCommand's list scheduling; that callback clears its
slot before scheduling TclNRTailcallEval. The tail evaluator releases on a
non-OK/namespace failure path or arranges release around ordinary target
evaluation. The source remains suspended. Hence yieldPtr==NULL and target
result cannot certify no old source activation/transfer remains. This proof
requires both object and bytecode emission routes; their reference operations
must not be conflated. [ID07, ID08, IX03, IX05, IX06, IX10]

IP06. Failed yieldto must cancel its prepared splice under identity premises.

Premises: C stack mismatch, original caller environment and slot/list still
live and unique. The failure branch selects caller environment, finds matching
data[1], clears it, releases reference, clears yieldPtr and returns to coroutine
environment before ERROR. No successful n/aux swap happens. Thus no duplicate
target dispatch follows from that slot under these premises. If the scan cannot
find the slot, source does not manufacture a successful rollback proof; slot
uniqueness/lifetime and all mutation paths remain admission obligations.
[ID09, IX04–IX06, IX10, IX12]

IP07. Runner completion requires a paired environment return, not sentinel equality.

Premises: admitted callback chain with preserved exclusive sentinel, valid
environment generations, activation/caller edges and native-call lifetime.
The runner follows current TOP_CB, so it can legitimately move between
environments. A callback already popped remains live during execution. A
matching sentinel marks the end of this traversal only if the paired return
environment/context is restored and all in-flight callbacks have returned.
Two empty environments both compare equal to a null sentinel; pointer equality
alone cannot establish which environment is current. An ABA-reused pointer
similarly needs generation/native-boundary identity. Source root asserts are
requirements, not a whole-program proof. [ID10, ID11, IX02, IX04, IX07, IX08]

IP08. Rewind drains a selected lifecycle without proving arbitrary cleanup liveness.

Premises: suspended object with paired caller environment/root; valid rewind
activation and finite nonescaping cleanup. Direct delete schedules saved-result
restoration and runs the activated coroutine to caller root. Active delete
first marks the command; after suspension caller callback notices deletion and
schedules rewind. Ready and bytecode rewind checks prevent ordinary continuation
as if this were a fresh resumed computation; resources still unwind. Proper
exit/caller callback pairing discharges selected state. User/native cleanup
that loops, reenters an unknown producer or escapes its stack invalidates the
liveness premise. Neither plain ERROR, cancellation nor a reset response is
equivalent evidence. [ID06, ID11, ID12, ID17, IX07, IX09, IX10, IL01, IL02]

IP09. Epoch reuse has a conditional cut after local completion and producer closure.

Premises: all ID16 predicates, complete admitted producer/domain mapping,
preserved result/reset observations, and exclusive owner publication protocol.
Every old effect is either completed or explicitly transferred to an
independently isolated owner outside the clean epoch. No old native/trace
writer or admitted producer can publish an effect after this cut. Issuing
ReusableReceipt there is consequently consistent with the declared clean
epoch boundary. An old suspended coroutine with shared interpreter cancellation
does not satisfy isolation merely by having its own ExecEnv. Reopen producer
admission only as part of publishing the next epoch. This is a conditional
design argument, not a verified implementation or an all-session semantic
equivalence theorem. [ID13–ID17, IX04–IX13, IL01, IO01]

IP10. Language syntax changes neither the cut nor its necessary support.

Premises: equal admitted scope and generated contract in modern C and Zig.
Both need signed credit/debt events, tagged aux state, callback/environment
identity, list/reference transfer and producer settlement. Zig defer does not
run on arbitrary foreign stack escape or make suspended state terminal; C
cleanup generation can share ordinary structured failure paths. Net redesign
benefit is common until actual retired obligations are identified. Separate
Zig gain requires uniquely removed C support to exceed its residual provider
cost with preserved runtime bounds; that inequality is unresolved. [ID18,
IV01–IV07]

| Case | History / proposed claim | Required classification | Evidence |
|---|---|---|---|
| IC01 | MarkTailcall reserves NRCommand without evaluating | Uncredited reservation; queue length is not n | IX02, IX03 |
| IC02 | Next EvalObjv consumes deferred reservation | One n increment and one eventual retirement | IX02, IX03 |
| IC03 | Deferred reservation crosses unknown ExecEnv switch | Reject unexplained mapping; no global pairing theorem | IX03, IX08 |
| IC04 | Resume suspended a from current b | n=b+a and active aux=b | IX04 |
| IC05 | Yield after net local delta s | n=b and suspended aux=a+s | IX04 |
| IC06 | Resume at different caller nesting | Relative offset survives; creation depth is not restored | IX04, IX12 |
| IC07 | Assert aux is nonnegative because type is int | Invalid inference; root/lease proof needed | IX04, IX08 |
| IC08 | New canonical root staging | +1 ordinary credit, -1 root discount | IX02, IX03 |
| IC09 | Root terminal callback before exit compensation | May observe b-1 with cleanup outstanding | IX02, IX07 |
| IC10 | Idle C deletion of root-yield coroutine, a=0 | Conditional public source path may expose -1 then restore 0 | IX02, IX04, IX07, IX09, IX11 |
| IC11 | Ordinary nested coroutine beneath trace h | b>=h+1 under wrapper and pairing premises | IX02, IX04, IX13 |
| IC12 | Direct rewind at base h | No wrapper credit; h-1 cannot be excluded by prior floor | IX04, IX07, IX09 |
| IC13 | Object-command yieldto emits caller task | Account list/slot before yield success | IX05, IX06 |
| IC14 | Compiled yieldto emits caller task | Independently account bytecode reference path | IX05, IX10 |
| IC15 | Successful yield clears yieldPtr | Caller slot may still own queued list | IX04, IX05, IX06 |
| IC16 | Tailcall evaluator receives non-OK result | Releases list; target command is not dispatched there | IX06 |
| IC17 | Tailcall namespace disappears | Preserve namespace-error release and result | IX05, IX06, IX12 |
| IC18 | Yieldto C-stack mismatch | Roll back splice; ERROR without successful aux/depth swap | IX04, IX05, IX12 |
| IC19 | Unknown mutation removes rollback slot | No fabricated rollback receipt; unresolved/reject profile | IX04, IX06 |
| IC20 | All NRCommands marked/skipped, no splice slot | Source panic branch; cannot claim ERROR-only adapter | IX06 |
| IC21 | Runner reaches null TOP_CB in another environment | Sentinel equality alone cannot issue paired return receipt | IX02, IX08 |
| IC22 | Exit sees empty coroutine callback queue | Popped exit/native and caller callback still live | IX02, IX07, IX08 |
| IC23 | ExecEnv freed and CoroutineData still retained | Caller callback must finish final free | IX07, IX08 |
| IC24 | Deletion of already active coroutine | Later suspension/caller callback triggers rewind | IX07, IX09, IX12 |
| IC25 | Rewind meets bytecode catch/finally | Do not equate with ordinary ERROR or promise normal handlers | IX09, IX10 |
| IC26 | Trace resumes different suspended coroutine | Active-yield mismatch check is not blanket resume prohibition | IX04, IX13 |
| IC27 | Trace's child yielded and returned locally | Old whole-flags/native writer still requires actual return | IX04, IX13 |
| IC28 | Unsupported inject adds suspended callback | Actual source entry; reject or separately admit | IX09, IX12 |
| IC29 | Foreign stack escapes before callback cleanup | Retain/reject; defer cannot prove native-return closure | IE01, IL01 |
| IC30 | Application intentionally keeps a suspended coroutine | Local return allowed; no clean independent epoch inferred | IX11, IL01, IO01 |
| IC31 | Source reset at transient zero | Preserve exact source observation; does not imply reusable | IX01, IX07, IO01 |
| IC32 | All ID16 predicates and closed producers hold | Conditional clean reuse cut; not currently qualified | IL02, IO01 |
