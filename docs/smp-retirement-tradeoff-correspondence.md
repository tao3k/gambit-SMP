# Retirement protocol correspondence and bounded QNT value demonstration

Date: 2026-10-22. Work item: repair-9-12. Research only.

The implementation worker was not messaged, signalled, sampled, debugged or restarted. Its lease was not acquired or cleared. No runtime, compiler, existing model, source lock, Recipe, timeout or native build product was changed. This document and the new QNT experiment are independent registered audit outputs. The four remaining contracts are lifecycle failure/rollback, complete GC/FFI, Gerbil correctness and release performance; no canonical ordinal mapping is inferred from that order.

## Evidence vocabulary

- **Confirmed source/evidence defect:** the inspected retained text demonstrably permits incorrect attribution or loses a distinction; this does not establish that a native crash used that path.
- **Conditional source hazard:** an unsafe consequence follows if the specified branch is reachable. Reachability or exclusion must be established against the actual producer.
- **Model assumption:** an abstract event or entry premise supplied to the checker, not implemented or authenticated by checking.
- **Unbound correspondence:** source and model have related concepts, but their populations, state or ordering have not been shown equivalent.
- **Proposal:** a change to representation or protocol to evaluate; not a runtime repair receipt.

Source anchors below refer to the pinned baseline or the explicitly named retained cumulative patch, not an assertion about the other worker's current executable. Exact input hashes are in receipt.json. The prior native observation has producerIdentity UNKNOWN and nativeCauseEstablished false; its fault addresses cannot be attributed to a newer producer.

## Source operation — state transition — last consumer — model premise

| ID | Actual operation / anchor | Necessary semantic transition | Resource and actual last consumer | Existing model premise / missing bridge | Classification and proposed decision |
| --- | --- | --- | --- | --- | --- |
| J1 | Retained handler-quiet-while-pending-cumulative.patch:4653-4704, recover_retired_processors | Exited/unjoined -> OS joined -> ownership transferred -> slot clear | OS thread handle is consumed by successful join; donor memory is separately consumed by transfer/cleanup | joinable_error_same_owner has joined and transferred separately; C join_pending spans both | Conditional source hazard: success followed by quiet=false retains pending, so later entry calls join again. Prove quiet=false impossible after successful join on this path, or represent JoinedAwaitingTransfer and never join twice. No native duplicate join observed. |
| J2 | Same patch:4640-4650,4684-4694,4868-4869, lifecycle fields | Error(A,g,owner) -> supported success(A,g,owner) -> recovery claim | Per-worker error identity must survive until its own resolution, not any VM join | One-worker model cannot expose A-error/B-success substitution | Confirmed evidence-attribution defect in retained representation: VM-wide errno plus VM-wide success cannot identify the recovered worker/incarnation. Use a per-incarnation result/token; QNT cross-worker control demonstrates the loss. Not a proved memory-corruption cause. |
| J3 | Same patch:4781; handler_quiet release before ___thread_exit | Local exit effects done -> OS exit -> joined observation | This processor's local exit effects versus remote VM/TTY/code users | quietWhileOwned directly sets oldHandler=false/hostQuiet=true; actual store does not enumerate all host invocations | Unbound correspondence. Rename/limit the witness to the resources it proves; derive broader quiet from a supported population protocol. A processor flag is not universal OS signal drain. |
| J4 | Same patch:5420-5470, ___cleanup_owned_vmstate; existing root sticky cleanup contract | Entry admitted with legal owner; either supported recovery or terminal retained error | Parent/child VM container and retained failed resources | Current recovery model enables joinOk after an abstract failure; child/root callers have different legal entry premises | Model assumption and API-contract decision. Classify actual supported errors. Terminal retained failure is safe but is not successful cleanup/recovery. Do not require a manufactured EDEADLK cycle as runtime recovery evidence. |
| J5 | Slot clearing/reinitialization and per-slot fields in retained patch:5500-5521 | Reclaimed(g) -> initialized(g+1), invalidating old error/owner tokens | Any old consumer/error/result naming the reused slot | One worker/one generation cannot expose ABA | Proposal: explicit incarnation identity and ownership; stale-generation QNT control rejects carrying a valid old result into a new slot. Actual current-source reuse audit remains required. |
| H1 | setup.c registry enter/leave/flush retained source; handler-return-resource-order.md:29-53 | Close admission -> drain admitted VM users; flush must readmit | VM list/root dereferences inside each lease | handler_admission_window separates counted interval from whole call | Existing source counterevidence: flush reacquires a lease. A live function tail alone does not prove an unleased old-VM dereference. Preserve this mechanism; audit its exact intervals rather than add blanket waits. |
| H2 | Baseline os_tty.c:8699-8733,638-700; os_base.c:1817-1844 | Disposition attempt, outstanding invocation, TTY alias completion and code lifetime are distinct | SIGWINCH probe/next links, mode restoration aliases, callback code | VM reader census does not count these consumers; OS delivery epoch in model is ghost state | Unbound source population/exclusion contract. No native overlapping callback/free proved. Separate per-resource lifetime; no blocking mutex in the signal handler follows from this audit. |
| H3 | Baseline os_io.c:1625-1670,183-193; os_tty.c:7570-7610,8161-8199 | Group removal/stage closed -> actual close outcome -> final release -> free | Surviving device, group pointer, mode chain, final refcount owner | A void cleanup or closed stage cannot instantiate all-consumers-done | Conditional error-path hazard. Propagate/retain actual partial outcomes. Do not convert retained/unknown ownership to successful cleanup. |
| G1 | Retained patch:3301-3353, ___transfer_mem_pstate | Donor-owned still/RC chains -> receiver-owned chains under memory lock | List heads, links, receiver scanner and interpretation metadata | WorkAccounting requires a complete producer inventory; root models require actual traced slots | Confirmed implementation scope: these lists/counters are moved. Complete root/private-work transfer is unproved, not disproved. Build a field/consumer census before extending transfer. |
| G2 | Baseline mem.c:3251-3307, end_heap_chunk | Private copying -> published chunk/link -> observed queue entry | Local scan/allocation frontiers and remote chunk scanner | Empty public queue excludes hidden work only with producer lifetime premise | Source fact: completion/publication can create work. QNT makes a finishing producer create work after an empty snapshot. Transfer must exclude future producers and drain the resulting work. Do not call this GC-phase mutator from arbitrary cleanup. |
| G3 | Baseline mem.c:3900-3966,6508-6576; saved-stack root/arena models | Publish or transfer each live frame/root and its interpretation before origin reuse | RA/link/body readers, GVM/saved/cache roots, non-consuming captured continuations | Logical Rooted does not enumerate generated maps or persistent raw aliases | Unbound source correspondence. Add explicit origin/consumer ownership only for actually live paths. A new long-lived carrier is justified only if existing owner lifetimes cannot cover these legal consumers. |
| G4 | Retained collective dispatch/aggregation documented in native-failure-producer-handoff.md:414-434 | Callback return -> old-cohort upward aggregation -> resize/reuse | All actual members of that same collective cohort | Normal-return bridge exists; foreign/nonlocal users are separate premises | Existing source counterevidence to a blanket missing-barrier theory. Reuse normal closure; model exceptional/nonparticipant edges only where applicable. |
| F1 | Baseline setup.c:3294-3422; c_intf.c:6511-6570; SFUN macros | Root/result handoff, marker invalidation, catcher restoration, foreign return | Origin OS C activation, catcher, generated code and separately live result | killMarker in one composition abstracts full exit effects; source marker death precedes some error propagation | Unbound correspondence. Preserve origin-owned cleanup for normal and nonlocal paths. Retaining heap bytes cannot resurrect an expired C frame. General host migration needs separate architecture design. |
| D1 | repair-9-12-native-observation.json; structure_type_lifetime.qnt | Initialize -> publish -> relocate/overwrite/reuse -> consumer read | Actual object/type/binding producer and loaded image | Cause-selecting record actions assume a diagnosis; mechanism read predicate derives validity but safeRead is guarded | Cause remains unknown for retained native failures. Need independent producer-bound observations; QNT retirement controls cannot prove the first faulty writer or cure all Gerbil errors. |
| C1 | Current numeric grouping and Gerbil -o/-e repair retained in Current Work | Semantics-preserving host grouping / correct CLI parsing | Generated compilation units and module completion witnesses | Numeric completion and cost are measured events, not GC/root theorem conclusions | Independently evidenced compiler/CLI issues; not explained by retirement. Full Gerbil timeout and full inventories remain open. |

## The bounded refactor being evaluated

Represent ExitedUnjoined, JoinedAwaitingTransfer, Transferred, Reclaimed and TerminalRetained distinctly. The lifecycle is not one total ordering of every resource: destination root publication, destination observation, private producer completion and borrower return can occur independently. OS join must not imply those completions. Transfer requires the relevant cut; resource release follows the actual last access. All results refer to a slot, incarnation and exclusive owner.

There are two legitimate failure policies: a specifically supported retry can resolve the same incarnation, or a terminal outcome retains ownership and refuses destructive progress. A safe terminal retention is not a successful cleanup. The proposed explicit phase protects operations; it is not a new universal runtime state-machine framework.

A transferred root is modeled as published and then observed. The latter action is an abstraction of a real collector publication/acquire/registration contract that still needs source refinement. It is not a proof of C atomics, moving GC, root maps, FFI or signals. The borrower and producer start live even though the target OS worker has exited: they denote remote users of retained resources, not additional threads inside pthread_join.

## QNT experiment and falsifiers

The new retirement_handoff_refinement model is a focused two-slot extension of the distinctions absent from joinable_error_same_owner; it does not replace or mutate that model. Its manual correspondence to the earlier model is listed above; no machine-checked simulation/refinement theorem is claimed. In the cross-worker and stale-generation controls, claimed denotes a prospective recovery attribution attached at join success. The retained C publishes its aggregate success only after transfer. These short QNT traces expose loss of identity, not a one-instruction-for-one-instruction C trace: the B transfer/cleanup suffix must also be source-reachable to instantiate the native attribution fault. No native suffix execution is claimed.

Initializers exercise:

- initFixed: successful joins and complete per-resource closure.
- initRetained: A reaches a terminal retained error while independent B completes. Completion means every worker has a safe final outcome, not every cleanup succeeded.
- initConditionalRetry: a hypothetical supported recoverable error on A resolves at A. This is explicitly conditional, not a claim that Darwin runtime EDEADLK supplies it.
- initReuse: completed slot A is reused once; the old error/result is revoked.
- initRepeatJoin: collapsed pending state permits a second join after success.
- initCrossWorker: VM-level evidence attributes A's error to B's success.
- initStaleGeneration: old error evidence survives slot reuse.
- initEarlyReclaim: OS join permits reclaim without a full resource cut.
- initRootGap: source root is dropped before destination observation.
- initForgotProducer: current work is empty but a producer can still create work.
- initWrongOwner: a join is attributed to an owner that lacks the original ownership.

The field calls counts the successful join consumption and any forbidden later join attempt; pre-success failed attempts are represented by error and do not consume that right.

All negative controls use the same transition body and safety definition as the corrected policy. A counterexample must be decoded and checked for its distinguishing violating state, not just a nonzero exit. Positive checks include safety plus final temporal completion and must exhaust their finite queues. The bounds are two slots and at most two incarnations; they are not processor limits. An exact successful native implementation might prove some modeled paths unreachable; in that case the exclusion proof replaces the proposed added state for that path. The model starts after worker exit and cohort withdrawal and does not prove those entry premises. Progress assumes the finite modeled consumers can return and work can drain. Arbitrarily stuck foreign calls or collectors are not proved live.

What this establishes if the checks pass: specific collapsed-state/identity/census policies admit invalid schedules; a feasible explicit protocol excludes those schedules while retaining safe success, terminal retention and bounded reuse. What it does not establish: that the live runtime executed a negative trace, that all native consumers were enumerated, that any current crash has this cause, unbounded liveness, C weak-memory refinement, or completion of any of the four native gates.

## Decision before runtime implementation

1. Bind this table to the implementation worker's selected immutable source/producer, not its changing checkout. Retire rows that are already discharged there; preserve independently applicable evidence.
2. For J1, prove the quiet-false-after-join branch unreachable or introduce JoinedAwaitingTransfer. For J2/J5, use exact worker/incarnation/owner results. Decide J4's supported failure policy before demanding recovery evidence.
3. Enumerate each applicable root, private producer and raw borrower at the legal retirement boundary. Establish absence, retained owner or observed transfer for each row. Existing normal collective closure is reusable where its premises hold.
4. Add a separate carrier only when a legal consumer necessarily outlives the current container. Otherwise repair the missing transition/order within the present ABI. Preserve C backend, multi-shot continuations and FFI semantics.
5. Qualify small source-bound cases that discriminate these edges, then the original complete native/Gerbil inventory. Model PASS is not that qualification. Do not rerun an unchanged failing native route to test a model assumption.

The value is a falsifiable design constraint, not a promise that one retirement refactor closes all of 9–12.

## Mature-runtime mechanisms and the selected trade-off

The pinned sources give concrete engineering choices, not merely analogies:

| Reference mechanism | Why it is stable under its stated preconditions | Gambit design decision and cost |
| --- | --- | --- |
| Chez c/thread.c:261-341 processes remembered data, closes local allocation segments and transfers guardians before freeing tc. It retains/recycles thread_gc because segments can still name that creator. Creation/recycle at :58-108 uses the TC mutex and resets collector fields. | Collector metadata lifetime is not identified with execution-context lifetime. Surviving users retain a valid interpretation carrier. Closure/reuse is synchronized. This is not proof of every Chez consumer or concurrent-mutator GC. | Separate logical retirement from physical resource reclamation. Initially retain Gambit's existing owning container for unresolved consumers; do not manufacture a new raw-root ABI. A carrier can later permit earlier context release only after every backreference and collector consumer is mapped. Cost: delayed memory/slot reuse and a retirement record. |
| OCaml runtime/domain.c:2262-2364 drains work, orphans ephemerons/finalizers, rechecks newly created work and leaves the STW population under all_domains_lock after checking incoming requests. | Termination cannot treat the first empty work snapshot as final. Participant withdrawal is serialized with new collective requests. | Require actual producer closure and resulting-work drain at Gambit's legal GC/cohort boundary. Reuse its existing collective-return bridge where applicable. Cost: more work at termination; no new universal barrier or reduced VM parallelism is implied. |
| OCaml runtime/domain.c:1132-1146,1346-1455 roots callback/term_sync independently, publishes the result, tears down the domain, unlocks joining consumers, then removes the last global root. stdlib/domain.ml:291-303 waits on that result contract. | Publishing a language result does not free its synchronization object or release joiners before teardown. The independent owner outlives the destroyed execution domain. | Separate language completion, OS join consumption, resource handoff and joiner release. Keep the actual synchronization container alive through last unlock/use. Cost: extra slow-path ownership and slightly later release; no direct transplantation of OCaml Domain.join into pthread_join. |
| Chez c/thread.c:209-244 reverses the exact activation effect; schlib.c:217-289 retains C-chain jump targets and return code ownership. | A nested entry does not destroy an outer owner's context; relocated closure and still-needed return code have different lifetimes. | Preserve Gambit origin-owned FFI/catcher semantics and reverse only acquired effects. Cost: explicit acquired-effect cleanup, rather than pretending retained heap memory makes a foreign C return target live. |

**Selected first implementation hypothesis:** conservative retirement with explicit per-incarnation ownership, consumed-join state and per-resource discharge. Keep ordinary scheduling/allocation fast paths intact. Logical withdrawal stops new obligations under the existing supported protocol; physical reclaim waits for the actual last relevant consumer. Do not reuse a slot while its old incarnation is still owned. If a terminal outcome cannot discharge resources, retain them and reject further operations that would require unsafe reuse. Apply a bounded retired-resource inventory/backpressure policy rather than timeout-driven freeing or unlimited accumulation. The exact bound and API response are design decisions, not measured here.

This is preferable as a first step to extracting all pstate data into a new universal carrier: retaining the current correctly rooted container initially preserves more of the existing GC/FFI representation. Independent carrier extraction is a second, resource-specific optimization when its backreference and root contracts are proved. Neither option requires permanent rooting of every field. A minimal carrier that does not include the actual consumer's interpretation state is unsafe despite being alive.

| Alternative | Benefit | Cost/risk | Decision |
| --- | --- | --- | --- |
| Immediate cleanup after result/join/count zero | Earliest memory reuse | Conflates distinct consumer and producer frontiers | Reject as a general protocol; allow only when an exact source exclusion proves the remaining census empty. |
| Retain existing owning container until a complete resource cut | Lowest representation change; clear failure containment | Delayed release/slot reuse; needs explicit partial outcomes and bounded backpressure | Preferred first source-refinement target. |
| Independent retirement carrier; free execution context earlier | Can preserve metadata and synchronization while releasing larger context | Backreference rewrite/census, moving-root registration and ABI work; more proof burden | Evaluate per resource after the conservative path is mapped. New carrier QNT proves conditional value, not native readiness. |
| Serialize all VM execution/GC or permanently retain everything | Simplifies some interleavings | Discards intended concurrency or permits unbounded retention | Not selected. |

The retirement_carrier_handoff QNT experiment checks the conditional value of the second-stage carrier: a context can be destroyed while a carrier consumer and a locked synchronization object remain, provided an independent owner retains the carrier and no consumer follows a backreference into the dead context. Negative controls separately remove storage retention, drop the independent owner before unlock, retain a stale context backreference, or release the joiner before teardown. It does not model Chez/OCaml code as Gambit code. Together with the first model, this compares a conservative retained-container protocol with the additional premises required to split the storage safely.

The native SIGSEGV and Gerbil type/binding failures still require producer-specific discrimination. These mature mechanisms constrain a stable architecture and eliminate named classes of lifetime mistakes; they are not evidence that retirement is the unique cause of those failures or that all four remaining contracts are solved.


## Actual check results (retained, not upgraded)

All checks used the existing Quint/TLC backend and unchanged 30-second per-check budgets, with final temporal validation on positive checks.

| Model | Initializer | Result | Distinct states | Seconds |
| --- | --- | --- | --- | --- |
| retirement-handoff-refinement | initFixed | Exhaustive safety + conditional completion PASS | 1444 | 30.174 |
| retirement-handoff-refinement | initRetained | TIMEOUT / not verified | unknown | 30.854 |
| retirement-handoff-refinement | initConditionalRetry | TIMEOUT / not verified | unknown | 31.032 |
| retirement-handoff-refinement | initReuse | Exhaustive safety + conditional completion PASS | 3572 | 27.226 |
| retirement-handoff-refinement | initRepeatJoin | Expected counterexample, decoded | 73 | 20.055 |
| retirement-handoff-refinement | initCrossWorker | Expected counterexample, decoded | 50 | 18.459 |
| retirement-handoff-refinement | initStaleGeneration | Expected counterexample, decoded | 2135 | 22.575 |
| retirement-handoff-refinement | initEarlyReclaim | Expected counterexample, decoded | 72 | 15.127 |
| retirement-handoff-refinement | initRootGap | Expected counterexample, decoded | 14 | 15.881 |
| retirement-handoff-refinement | initForgotProducer | Expected counterexample, decoded | 372 | 15.555 |
| retirement-handoff-refinement | initWrongOwner | Expected counterexample, decoded | 2 | 14.54 |
| retirement-carrier-handoff | initFixed | Exhaustive safety + conditional completion PASS | 10 | 18.571 |
| retirement-carrier-handoff | initFreeWithContext | Expected counterexample, decoded | 6 | 19.733 |
| retirement-carrier-handoff | initDropOwnerBeforeUnlock | Expected counterexample, decoded | 12 | 23.07 |
| retirement-carrier-handoff | initStaleBackreference | Expected counterexample, decoded | 9 | 22.678 |
| retirement-carrier-handoff | initReleaseJoinerEarly | Expected counterexample, decoded | 12 | 24.375 |

The first model has two retained 30-second timeouts (terminal retention and conditional retry). Its aggregate remains incomplete; no timeout was widened or converted to a pass. The normal and reuse positives are independently verified. The carrier model separately checks its own conditional completion and its explicit safe early-context-release trajectory; that does not fill the first model’s timed-out cases.

The seven first-model negative controls and four carrier negatives were decoded and their distinguishing last-state conditions independently asserted. Negative searches stop at a counterexample; their nonempty queues are expected and are not positive exhaustive completion. Initial QNT parse/name failures and the missing old TLC-jar path are retained in earlier audit attempts. No native run occurred.

Compiled and raw results:

- `.cache/tasks/repair-9-12/processes/audit/runs/d80b558a9c124df1807b3c92a289aa9f/outputs/retirement-handoff-refinement/receipt.json`
- `.cache/tasks/repair-9-12/processes/audit/runs/65e0a09a21bf43eba7e517315127fb51/outputs/retirement-carrier-handoff/receipt.json`

The carrier positive has 10 distinct states; its safe trajectory reaches contextLive=false while consumer=true, locked=true and carrierLive=true. This demonstrates conditional early-context release, not zero-cost reclamation or a measured speedup.
