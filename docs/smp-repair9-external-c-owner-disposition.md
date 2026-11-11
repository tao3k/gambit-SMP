# External C interrupt admission and accepted-request disposition

2026-10-23. Research only; native acceptance remains **8/12**. No runtime/header/compiler/Recipe modification, native execution, full inventory, signal/sample/debugger action, peer operation, staging, commit or push. This extends [abort fault/lifetime research](smp-repair9-abort-fault-lifetime.md).

## Result

An external interrupt must present an actual VM storage owner before a target-instance borrow can be acquired. A nonnull pstate, matching numeric processor ID, or TLS binding is insufficient. Enqueue acceptance must be distinguished from notification success: a request already linked to a queue cannot become caller-owned again when its wake fails.

The source also exposes a concrete callback-error branch defect: `service_procedural_interrupts_pstate` unlocks before calling execute_fn, breaks on a non-NO_ERR result, then reaches an unconditional unlock without reacquisition. This is an invalid unlock attempt on that branch; it is not a recovered native crash or the missing flood request's proven cause. Cleanup additionally calls release callbacks under the queue mutex. Whether that deadlocks depends on callback reentrancy; no callback-body contract in this source cut establishes nonreentry.

The minimum under the existing joined-owner contract is to preserve the real owner lifetime and correct callback-error lock discipline; no concurrent-admission API is automatically required. Typed refusal and detached reentrant finalization are a separate contract extension, not mandatory edits for the currently supported owner discipline. Scheme mailbox/acquire/park obligations remain distinct. No new collector or global owner registry is justified.

## Evidence and active production boundary

Source audit `6b62a88020144a0789ebf7c1dbbee7bb/outputs/external-c-source-audit` reuses the immutable d53671cb source cut for setup.c, generated header/template and thread/kernel Scheme. Its extract hashes and static non-NO_ERR lock path are retained. A separately identified read-stable c_intf.c supplement covers marker construction. It is a source supplement, not same-producer object or native qualification.

The real task lock inode630123644 was held by parent27204, descendants27223/27230 and final consumer gsi28333; kernel PID/start identities were read without operating them. That consumer is in the c86dff86 producer tree, while these source claims bind the named4463d6b5 frozen cut. They must not be conflated. Static research and registered metadata publication proceed; QNT execution waits for the production lease's natural release. No lock was taken over, process signaled, or native route rerun. Model verification status is stated separately below.

## Existing joined-owner native witness: reusable, not rerun

The repository already contains [procedural retirement source audit](../evidence/research/processor-interrupt-collective-wait/procedural-retirement-audit.md), [native observation](../evidence/research/processor-interrupt-collective-wait/procedural-retirement-observation.md), and `procedural_interrupt_retirement.qnt`. Source lock7a031c22…, cumulative patch8e6d68b0…, native program688de26d… and model328c7874… still match the recorded SHA256 identities. The portable model receipt remains separate from native launch receipts. No native reproduction or model rerun was performed here.

That existing schedule holds a detached callback, observes an empty queue, enqueues from11 capacity-derived external producers, joins them, releases/joins the consumer (including its post-callback relock), then cleans the child with a global broadcaster still enabled. It executes12 callbacks and releases11 remaining items. This is a real joined-owner witness on its bound generation, not a reachable valid-program concurrent-destruction bug or qualification of our different frozen cut.

The actual native release callback checks op==FAL and procedural_interrupts_ready, not mutex ownership. All callbacks return NO_ERR. The older observation text says releases observed an owned/live mutex, but only readiness/liveness is asserted in that callback; mutex-held execution is a source fact, not a native ownership assertion. This discrepancy is recorded here without rewriting the historical observation. The witness does not cover the non-NO_ERR double-unlock branch. Moving release callbacks outside the mutex is not thereby proven to fail this fixture, nor is it qualified as preserving the first eight gates. Do not alter the fixture to manufacture either conclusion.

Two contracts must remain distinct. **A, existing joined-owner:** host stops and joins all direct producers and the detached consumer before cleanup; no new rejection or per-call handle API is necessary solely to make an unsupported concurrent cleanup safe. **B, optional concurrent admission:** owner requests retirement while producers may still enter, so explicit target borrow, typed refusal and finalizer reentry policy must be added coherently. The new admission model specifies B and helps reject bad B implementations; it does not prove current A is defective.

## Actual exported entries and ownership preconditions

| Entry | Source behavior | Existing owner / missing premise |
|---|---|---|
| `___raise_interrupt(code)` | Registry enter/deliver/leave; pending flags replay if admission closed | Existing registry reader protects its delivery scope; flags have no heap node to return. Keep it through nested abort/retry/outcome work. |
| `___raise_interrupt_vmstate(vms,code)` | Uses supplied vms and current processor count directly | Explicit caller owner is required. Being called by the guarded global wrapper does not guard every possible direct C use. |
| `___raise_interrupt_pstate(ps,code)` | Writes intr_flag and may touch OS wake resources | Valid outer VM storage, matching pstate instance and a borrow before mutable resource access. Flag coalescing is not result-mutex completion. |
| `___raise_procedural_interrupt_pstate(ps,intr)` | Writes h.next=NULL, locks procedural mutex, links native header, unlocks, raises OTHER | No admission/refusal/instance token at entry. An eventual guard must precede h.next and mutex access. Header/callback lifetime belongs to the caller until link acceptance, then to the receiver/batch/active callback. |
| `___raise_high_level_interrupt_pstate(ps,intr)` | Processor lock, mutates Scheme vector next/head/tail, unlocks, raises OTHER | VM lifetime alone is insufficient: caller must hold the SCMOBJ root and legal GC-participant context. A foreign nonparticipant cannot mutate moving Scheme heap state merely because its pstate is live. |
| Kernel `##raise-high-level-interrupt` | Derives pstate from processor-id and current VM; calls C; returns VOID | Current Scheme context/arguments are relevant existing evidence. VOID erases admission/notification outcomes, so a typed migration must update bridge and Scheme caller coherently. |
| SFUN entry macros | Bind ps=___PSTATE, construct marker, TRY/call/kill marker/propagate | This cut's BEGIN_SFUN has no sfun_frame_enter lifetime lease. Marker roots procedure/return context, not arbitrary VM or target-instance admission. A historical separate P implementation with more guards cannot be imported into this cut's proof. |

A pure native procedural node can legitimately be enqueued from a foreign thread with no TLS binding when that caller has a valid host-owned VM scope and admitted target borrow. Conversely, TLS alone does not grant that ownership. The high-level Scheme-vector entry has the additional root/collector contract, regardless of which native thread calls it.

### Where a valid outer owner comes from

For a runtime processor, use its actual executing VM/cohort lifetime and legal generated activation. For a global signal delivery, use the existing registry reader. For an embedding host, an owner acquired during setup and retained until all its direct calls/callback obligations end is the required source of a valid VM reference. `___cleanup_owned_vmstate` comments that the owner joined direct users, but its count1 check is not an implementation of that external-user proof.

Acquire a target borrow from that already valid scope, with `(VM scope, processor slot, expected instance)`; release only after enqueue/refusal plus wake outcome is published. An embedded counter is dereferenced too late to make a dangling VM pointer safe. The raw pointer-only signature also cannot distinguish an old request from a newly reopened instance at the same address. Avoid interpreting “pin whatever instance is currently there” as validation of the caller's expected instance.

This is a normal C lifetime precondition, not adversarial pointer authentication. The minimal implementation can use an owner-local borrow record and the existing VM/cohort/registry scopes; it does not require a new global handle registry. The embedding acquisition/release API and every actual external caller still need source refinement. A caller inventory that finds no callback bodies is not proof all external callbacks are harmless.

## Refusal versus acceptance: the linearization contract

For optional contract B, a proposed direct typed migration has these statuses. Current contract A has a void enqueue with unconditional transfer for a valid live caller; cleanup concurrent with unjoined direct users violates A and is not a supported runtime-refusal experiment:

| Status | Ownership | Permitted caller action |
|---|---|---|
| `REJECTED_RETIRING` / `REJECTED_STALE` / `INVALID_CONTEXT` | Caller still owns the unmodified node; no enqueue or callback occurred | Caller may release, select a newly admitted target, or retry according to API policy. No runtime execute_fn(false) on a node it never accepted. |
| `ACCEPTED` | Node is owned by queue, active callback, or retirement batch | Caller cannot mutate next, free, enqueue again, or infer result reply from notification. |
| `ACCEPTED_WAKE_FAULT` | Acceptance is unchanged; queue/activation ownership and sticky fault remain | Do not return rejection, free the node or replay it. Preserve the unique consumer while fault is reported/disposed. |

Validate the owner and expected instance before touching node bytes. Link while holding the destination queue mutex/lock and a valid borrow. Cleanup closes admission, waits admitted publishers, then detaches pending work; it cannot detach a list and subsequently allow an uncounted producer to append to the old generation. A publisher overlapping the admission cut must have an explicit accepted-or-rejected outcome, never “possibly transferred”.

The current void GSTATE entries cannot communicate this B distinction; preserving A does not require replacing them. A direct migration changes the prototype, GSTATE function-pointer type/initialization, kernel bridge result and all Scheme/native callers together through one registered producer. Do not add an ignored-return wrapper and call that refusal handling. This has bootstrap/FFI ABI consequences even if a native return register looks binary-compatible; old objects do not inherit qualification. The current source-unit extractor also anchors on the void procedural-entry declaration, so B would require coordinated metadata extraction changes; A's local service-loop correction does not. A flag-only API and an owning-node API need different refusal treatment.

For Scheme result-mutex requests, the actual mutex is already linked to the target before propagate. Therefore rejection of a later processor notification is **not rejection of the Scheme request**. Preserve target/thread-mailbox ownership or target's real abandonment path. Moving the request onto one authoritative thread queue remains the recommended structural boundary; processor notifications carry no request node.

## Queue, active callback and retirement batch consumers

`___procedural_interrupt_header` has native next and execute_fn; it is not automatically a GC root record. `___init_procedural_interrupt` sets only execute_fn. On normal service, the runtime detaches under the native procedural mutex, unlocks, invokes execute_fn(intr,TRU), then continues. It does not inspect the node after callback return, allowing the callback to manage its detached node's lifetime under its contract. The return code must not trigger a second execution or release(false).

An active callback needs a consumer claim established before withdrawing the queue owner. Cleanup must account for that claim, including nested callbacks, until normal return or explicitly retained nonlocal unwind. Closed external admission does not prohibit servicing obligations accepted earlier; that is an internal owner transfer, not a new foreign admission. Do not wait for a callback that needs a mutex/admission gate while retaining that same mutex/gate.

Cleanup currently holds the mutex while invoking execute_fn(intr,FAL) on queued nodes. If B deliberately admits reentrant release callbacks, a bounded transformation would be: close external admission and drain active publishers/consumers; under queue mutex detach head/tail into a native batch owner; clear the queue; release mutex; invoke each release callback once, saving next before it can dispose its node. The batch carries the pstate/VM instance claim until its final release returns. A release callback attempting enqueue sees typed refusal before node mutation. Nonescaping and allowed GC/reentry behavior of the finalizer must be stated; arbitrary C unwind is not successful batch completion. Under A, retaining the current mutex-held release behavior is the smallest compatibility choice, conditional on nonreentrant release callbacks; there is no evidence that mutex ownership itself is a promised public contract. Calling that pattern an unconditional defect, or asserting the native witness checked lock ownership, would overstate the evidence.

### Confirmed non-NO_ERR unlock defect and minimum correction

Exact retained branch:

`lock -> pop -> unlock -> execute_fn(TRU) returns non-NO_ERR -> break -> unconditional epilogue unlock`.

The reported flood uses Scheme result-mutex thunks; no native procedural callback returning non-NO_ERR has been bound to that failed request. Keep this defect separate from its first-writer hypothesis.

There is no reacquire between that callback result and the epilogue. The minimum lock-discipline correction is an unlocked error return/cleanup path, or a deliberate reacquire before a shared epilogue. Prefer a structured outside-lock error return so error reporting/finalization does not move under the mutex. Preserve any remaining queued nodes and the OTHER service obligation. The current caller stack-trips and retries remaining service; it does **not** put the detached node back. A repair must not invent requeue/replay or call release(false) for the already executed node.

A C callback's non-NO_ERR is not automatically a Scheme exception value. Current source only compares it to NO_ERR, does not root or deliver its arbitrary payload, and returns FAL/stack-trip behavior in service_interrupts. The return type SCMOBJ does not prove it is an immediate native code. For the smallest scalar fault protocol, define/check immediate native status or normalize an unexpected non-success into an immediate diagnostic kind without storing the raw moving SCMOBJ. Preserving an actual Scheme exception instead requires an identified scanned receiver/root across GC; do not add an untraced SCMOBJ to the native sticky fault field.

## Legal fault disposition and termination boundaries

| Obligation | Legal source landing / authority | Excluded shortcut |
|---|---|---|
| Native callback success/non-success after claim | After execute_fn returns, procedural mutex is not held; retain tagged scalar fault and return through active-consumer cleanup | Unconditional second unlock, execute again, or release(false) after execute(true). |
| Pending native node at retirement | Detached batch outside procedural mutex, valid closed generation and batch owner | Calling arbitrary release callbacks under the same mutex they may reenter; destroying resources with an active callback. |
| Scheme sender sees notification failure | `##thread-intr!` after propagate normal unlocks and before second result lock is an inspection point; accepted request still has its target/queue/activation owner | Sender-side manual result-mutex unlock, fake rejection, fake return value or cancelling a possibly executed thunk. |
| Ordinary target's genuine termination | `##thread-end-current-thread!`1688ff locks current target, calls `##thread-end-locked!`; nonprimordial branch1755ff abandons owned BTQs; `##btq-abandon!` / abandoned-mutex resume action report to sender | Calling this on an unrelated current thread or treating a transport status as authority to kill another thread. |
| Remote request to terminate a thread | `##thread-end!` routes to thread-interrupt on the target | This depends on the same delivery mechanism and is not an independent rescue for its failure. |
| Primordial target | thread-end-locked's primordial branch unlocks and calls exit/exit-with-exception before the nonprimordial owned-BTQ loop | Cannot claim the ordinary abandon loop already ran or that sender's result mutex completed. VM exit jobs/wills and native cleanup need their separate source proof. |
| Whole-VM/native terminal error | Existing run/throw/P0 collective route, under prepared context and after required duties | Prior study proves it uses the same wake chain; it is not independent recovery for a broken pipe and sleeping peer. |

Thus actual nonprimordial target termination is an existing terminal outcome, not a new generic failure action. A fault policy must establish matching target, active traced continuation, no outstanding low-level locks and an authorized termination reason before using it. A raw throw from a foreign producer or idle processor does not supply those facts. The positive terminal model explicitly assumes this authority; it does not create it from a boolean status.

The current `_thread.scm`1700ff primordial exception is particularly important for a sufficiency claim: “target ends, so every result mutex is abandoned” is false as a universal source statement. Primordial exit is a separate VM-lifetime proof. Arbitrary callback/continuation escapes likewise remain containment outcomes, not completed sends.

## Small-refactor sufficient conditions

These are proof/admission obligations, not flags to set to true:

1. Choose contract A or B explicitly. The caller's outer VM storage owner exists before pointer resolution; raw external owners are counted or otherwise joined before cleanup. TLS/pstate identity alone is never the proof.
2. Expected I/O/pstate incarnation is validated under a valid borrow, held through enqueue and final wake/fault publication. Queued/active/batch consumers keep the generation alive afterward.
3. High-level SCM requests additionally have correct VM/root and collector-participant context; pure native enqueue does not fabricate a Scheme execution context.
4. If B provides refusal, it leaves caller node unchanged and owned by caller. Acceptance is a single queue commit; notification failure never reverses ownership or allows re-enqueue.
5. Queue withdrawal acquires a mapped/native active owner first. Normal return, callback non-success, pending release and terminal abandonment are distinct outcomes, each consumed once.
6. The concrete unlocked-error return defect is fixed. A may preserve its existing mutex-held release behavior under a nonreentrant callback premise; B needs a separately admitted outside-mutex batch contract for reentrant finalizers. Every normal/error return releases its actual borrow exactly once.
7. Fault publication is atomic and tagged to the retained instance. Store only immediate native status unless a real Scheme root owner is supplied. No fault handling or raw unwind escapes held scheduler/native queue locks.
8. Only a matching, rooted, authorized nonprimordial target exit implies owned-mutex abandonment. Primordial/VM exit, raw external error and accepted hard-wake failure need their own dispositions; no fake reply or cancellation shortcut.
9. Authoritative mailbox, pending-aware block commit, same-P runnable/park handoff and effective ticket acquisition from the previous studies are all refined to the same source generation.
10. Live-channel/fair-progress envelope is explicit. Unconditional permanent-channel recovery needs a separately proved independent carrier; existing remote termination/P0 collective are not such carriers.
11. One qualified changed producer supplies maps/headers/ABI and passes the unchanged first-eight/full native contracts. Static/model proof does not confer9/12,10/12 or12/12.

This is a bounded structural plan with localized functions, not another tail/head rescue. First-eight exposure includes the public/native ABI, callback/finalizer error behavior, GC-root representation and cleanup/reuse. Typed admission and active/batch borrowing add constant state/work; no full-processor scan, per-request extra envelope allocation or new global owner registry is proposed. Native latency and callback duration are not bounded by model state counts.

## QNT specification status

New modules `external_interrupt_admission.qnt` and `interrupt_fault_disposition.qnt` specify the cases above. Planned inventory:33 TLC profiles (13 conditional-completion,3 safety/retention-only,17 negative profiles) and11 named TypeScript trajectories. These counts are plans, not accepted checks. They cover TLS-only ownership, foreign pure-C owner, stale incarnation, Scheme root/context refusal, mutation before rejection, rejection/retry after commit, dropping the outer pin, callback second unlock, reentrant release, active-consumer destruction, replay/double disposal, unrooted/wrong target termination, primordial false abandonment and untraced moving error retention.

The retained joined-owner model/native witness already covers A under its stated premises. The new files add owner/refusal distinctions and error/terminal controls, including a conditional reentrant-release negative rather than declaring A's locked release universally unsafe. These files are authored specifications until the registered verifier actually returns receipts. During active peer production custody, the model runner is retained but not started. No typecheck/TLC/trajectory PASS is asserted for this new model pair without execution. Earlier25/29/24/44 verified controls remain immutable and do not certify new bytes. Pending verification is an explicit gate on this proposal, not permission to implement from a paper table.


## Accepted hard-failure follow-up

[Terminal consumers and minimal callback-error correction](smp-repair9-accepted-hard-failure.md) trace the caller: non-NO_ERR preserves the flag/stack-trip and returns FAL, not a Scheme error or VM-exit command. Direct unlocked return is the smallest proposed local lock correction. Remaining queue service, authorized ordinary target abandonment and primordial/VM shutdown are distinct contracts. A new small terminal QNT projection is pending natural production-lease release; no model/native PASS claimed.
