# Session consumption, owner claims and commit receipts: full locked call paths

2026-10-24. This is an implementation and conditional-model handoff for Grok. It does not edit or admit a runtime. Source authority is `scan-diag-prepare.lock.json`, main7c490c3, patch e8b39380; vendor HEAD is not substituted. Source reconstruction checks every one of the26 locked files. The generated call index retains every textual reference to the selected symbols within that exact boundary, including declarations and function-table exports. It is not a whole-program call-graph proof for arbitrary external hosts or generated objects absent from this lock.

## Actual call paths and required hooks

| Locked entry/exit | Current path | Required proposed order |
| --- | --- | --- |
| Global `___setup` setup.c7724, public header15086 | cleanup admission -> parameter validation -> cleanup_phase reset7749 -> global observations/reset -> P0 interrupts -> global OS/memory -> modules -> VM setup7886 -> TLS -> ___run | Consume the diagnostic session after valid admission/parameters and before resets. An invalid parameter return before that point consumes nothing. Do not infer a concurrency lock from cleanup_phase. |
| `setup_os_and_mem` / prepare5705 | ___setup_os success -> ___gc_diag_prepare_process3914 -> ___setup_mem | Prepare once, with no Scheme allocation or VM identity. READY publication follows complete mapping/header setup. Failed preparation is terminal diagnostic refusal even if ordinary setup succeeds. Repeating setup must not reopen state2 or3. |
| Main VM | ___setup -> ___setup_vmstate6059 -> ___setup_pstate6168 | Use explicit vms and selected VM identity; zero local capability before claim and before processor memory setup. |
| VM API and function table | header13569/15108, setup7453..7454 | Foreign callers use the same VM constructor and claim hooks. A child VM with id0 gets no diagnostic authority from VM-local0. External caller/context validity remains an API premise. |
| Growth and direct pstate API | resize calls ___setup_pstate1488; exports1044/5813, header13575/15114 and table7459..7460 | One common claim hook in ___setup_pstate covers both P0 and worker construction. Claim uses explicit vms after vmstate assignment and local resets5846..; it cannot map/wait or allocate Scheme data inside resize. |
| Partial constructor failure | claim may precede setup_os_and_mem_pstate and later object setup | Both CLAIMED-without-READY and READY-then-constructor-error remain consumed. cleanup_failed_pstate or a caller retry must not clear the process-native claim array. A retry initializes local eligibility to0, then refuses the used slot. |
| Accepted global cleanup / setup errors | ___cleanup_checked may reject before destruction, or retain after failed resize; setup can fail before setup_state1 | Diagnostic close happens only after cleanup admission is accepted, plus explicit setup error paths following session consumption. Rejected cleanup retains the live recording session. Pre-state1 failures cannot rely solely on ___cleanup_checked. Published storage remains mapped; closing is not drainage. |
| Scanner entry | mark_array_body -> gc_diag_bind_owner3994/4186 -> depth/coverage -> publication | Acquire process session-open and immutable native owner READY; match local capability/session/slot, then adopt. Cached attached cannot bypass revoked session checks in arm/publish. Refusal skips diagnostics only and preserves actual GC flow/barriers. |
| Both publication sites | gc_diag_publish4045 called for CELL4212 and HEADER4234 | Both use the same return-token protocol. No separate “header succeeded because cell succeeded” shortcut. HEADER records the actual already-read word and computed header address. |
| Cut arm | ___gc_diag_arm4124 has no caller among the26 locked source files | Existing runtime-control fixture/generated C must be bound separately on the final producer. Add the actual internal declaration/connection required by target macros; do not assume dlsym finds a static/hidden symbol or copy the helper into a stand-in fixture. |
| Cut reads/writes and normal exit | arm4134; snapshot4187; partial cuts4102/4108/4116/4120; mark_array exit clears cut4389; constructor clears5847 | Replace cached-cut authority with the returned receipt. Normal scan exit explicitly cancels an unmatched one-shot request with NOT_REACHED; do not silently carry it into another invocation. A consumed cut is not cancelled twice. Constructor reset invalidates local requests but never resets process claim history. |

The exported APIs are part of the boundary: covering only the direct global caller misses them. Conversely, the lock contains the exported declarations, not the external host's complete call chain. No claim of supporting invalid pointers, recursive global runtime setup or concurrent host setup is made.

### Return-path checklist on this exact setup.c

- Global returns7743 (cleanup admission) and7747 (invalid parameters) precede the proposed consumption hook; they must not claim or close a new session.
- Return7814 is after consumption but before global mapping preparation: close diagnostic eligibility even with no mapping. A retry must not initialize a new diagnostic session merely because binding state remains0.
- Return7830 follows global OS/memory failure and return7852 follows init_symkey_glo2 failure. The latter is a direct return after setup_state1, not the final ___cleanup branch. Both need explicit diagnostic close/retention, without changing ordinary runtime error propagation.
- Breaks7864/7880/7888/7899 (module, arguments, VM, native thread initialization) and an error returned by ___run converge on the existing final cleanup/return7941. Close diagnostic admission before that error cleanup, idempotently. A successful global return leaves closure to accepted cleanup.
- Pstate returns5863/5873/5937 (interrupts, OS/memory, sync setup) invalidate only the failed local capability and pending cut; the native one-use claim remains consumed. Successful return5942 keeps it. A worker failure must not globally disable diagnostics on other already-running owners.
- VM returns6152/6161 precede its P0 claim. Publication success6173 preserves the claim; failure cleanup/return6187 after a P0 claim keeps its diagnostic history consumed. The global caller, not a child VM failure, decides whether the whole process session closes.

In particular, resize can fail and retry a slot **within the same global setup epoch**. A global epoch check cannot distinguish that local incarnation. The common constructor must clear its local capability before the one-use claim attempt; refusal keeps that capability zero while another already-ready owner remains usable. The QNT LocalRetry control and LocalStaleCapability mutant isolate precisely this path.

## Concrete state and ordering to implement

Keep the bounded one-session/no-slot-reuse design from [the implementation handoff](scan-session-cut-handoff.md). Add sticky process setup consumption; separate prepared mapping state from session-open; add native one-use per-slot EMPTY/CLAIMED/READY and immutable owner/session payload; add a zero-initialized local capability in pstate. Use an explicit selected-VM check, not just an id or reused address. Publish native READY with release after payload; scanner/arm/publish acquire it. A claim left incomplete is rejected, not waited for or stolen. First accepted session may use two different slots; a later initialization of either slot is refused even at the identical address.

Function sequence for a constructor is:

```
explicit vmstate assignment
 -> clear local diagnostic eligibility/request/receipt
 -> acquire first-session permission
 -> selected-VM and slot bounds validation
 -> one CAS EMPTY->CLAIMED
 -> validate fresh parent slot; install native owner payload
 -> release READY
 -> install local capability
 -> existing processor OS/memory/object setup
```

A failure after any claimed state leaves that state consumed; ordinary cleanup may release its runtime resources but not diagnostic history. State3 prepare refusal is sticky for the process. Repeated accepted global setup consumes no new diagnostic session and does not reset seq/footer/owner bytes. Reentrant helper invocation while PREPARING or already READY returns unavailable; it does not repeat mapping or overwrite payload. This helper behavior does not make recursive execution of the rest of ___setup safe.

For publication, use nonzero returned seq plus an immediate cut/stage receipt from the **same** invocation. Initialize refusal output to0. Revalidate at publish, because successful arm can be followed by close, coverage loss or exhaustion. Clear a refused request so it cannot fire later. A mismatched stage preserves it only until the end of its declared scan invocation; unmatched exit produces NOT_REACHED. No receipt pointer outlives the native caller; it contains no relocatable Scheme value.

```
validate session/local owner/coverage/capacity
 -> preserve only a known-complete previous record
 -> reserve nonzero seq; consume the matching one-shot request
 -> invalidate footer=0; enforce ordering before payload mutation
 -> payload prefix [cut4 is before prefix; cut5 after prefix]
 -> payload rest + commit_seq [cut3 before footer]
 -> release footer=seq + ordering before original GC load
 -> [cut6: committed exit] or return seq/stage/committed-cut
 -> caller checks this exact receipt, then cut1/2 may fault
```

Cuts3/4/5 bind to an eligible in-progress transaction, not a completed token. Cut6 and cuts1/2 require complete commit. The source-derived cut5 witness starts with matching old footer/commit and a complete old payload; partial overwrite must invalidate acceptance before changing any field. Otherwise a postmortem reader can accept stable hybrid bytes even after all writers exit.

Close after publication entry may revoke later writers, but the admitted writer may finish into retained storage. A close before publication entry must refuse and cancel the pending cut. The parent's snapshot remains post-quiescence only; this is not a live seqlock reader protocol. Actual compiler/CPU ordering requires inspection of the final target object; QNT phase ordering alone cannot prove C atomic behavior.

## QNT scope and discriminating controls

Model: `models/gambit/scan_session_commit.qnt`. Replay: `evidence/research/smp-retirement-study/verify-scan-session-commit.py`. Existing registered audit and Quint/TLC backend are reused, with30 seconds per model check. No native budget changes.

The model explores two setup attempts, two one-use slot claims, and up to two publications. It checks failure before preparation, refusal after failed preparation, failed global setup after mapping, a partial claim, a READY claim followed by constructor failure, same-epoch local constructor retry while another owner remains READY, repeated clean setup, helper reentry in PREPARING and READY, nested publication rejection, stage matching, close before/after admission, exhaustion, stale receipt, and cut5 interruption. An explicit unmatched-scan exit cancels its pending request. Slot1 is independently claimed; record transactions are projected to slot0. Selected-VM and external-caller validity are explicit model premises; this finite projection does not prove the actual C VM identity check. It also does not prove two-bank concurrent writer behavior on both slots, live-reader safety, actual GC frame maps, memory-barrier code generation, cleanup callback termination or liveness under an unfair scheduler.

Negative variants deliberately restore one defect at a time: session reset, used-slot reclaim, prepare reinitialization on reentry, no footer invalidation, uncommitted fault, old token reuse, token before footer, old local attachment, nested writer overwrite, attachment before owner READY and stale local capability on same-epoch retry. A negative is accepted only with a parsed multi-state invariant counterexample; parser/compiler failures or timeouts never count. Positive safety checks also have reachability witnesses for intended successful/refused states, so an implementation that merely refuses everything does not satisfy the selected positive controls. Reachability is existence, not eventual completion.

The nested-writer action models refusal to overwrite an admitted publication, not the complete C nested-GC scanner. The locked mark_array depth path also makes coverage sticky0 on nested entry; that coverage downgrade must still cancel later armed cuts and disqualify full-coverage native acceptance. The model's abstract nested-publication witness must not be used as evidence that an actual nested GC preserves full diagnostic coverage. Keep that distinction in the native reentry receipt.

## Grok implementation and same-producer native sequence

1. Implement sticky session begin/close and all source-indexed setup returns first; then local capability zeroing and setup-time one-use owner claims in the common pstate constructor. Do not attach via VM-local ID equality. Keep mapping work outside scanners and collective worker setup.
2. Implement arm/refusal/cancel semantics, including mark_array exit4389; then both publication call sites and exact return tokens. Add invalidation-before-overwrite before enabling cut5 as a meaningful negative. Partial cuts retain their own declared transaction positions.
3. Bind the actual arm/control entry and generated fixture C to these helpers. Rebuild every affected header consumer into one final producer, record lock/source/header/generated C/object/archive/gsi hashes and UUID, and inspect optimized invalidation/commit/original-load ordering. A different gsi linked halfway through is a different producer.
4. On that unchanged producer run first-setup success; failure before prepare then retry; prepare failure then retry; post-mapping setup failure then retry, including the direct7852 return; CLAIMED and READY constructor failure/retry both across global setup and within the same resize epoch while another owner remains serviceable; PREPARING/READY helper reentry; clean repeated setup; second VM id0 and same-slot reuse; two distinct fresh owners. Refusal must preserve old snapshot bytes and ordinary runtime status; no private fallback is admitted as shared coverage. Use the actual producer compiler/flags, not a standalone Apple-clang object build as substitute acceptance.
5. Test arm then coverage loss, close and exhaustion; wrong-stage then matching-stage; unmatched scan exit; duplicate arm; stale receipt; nested publish. Each refusal has zero commit token, no injected null fault, and no leaked pending request. An already admitted writer completing after close remains attributable to its old retained session.
6. Establish a deliberate complete baseline record, then execute cuts4/5/3 and require invalid-current rejection with the preserved baseline. Cut6 must have exact completed seq; cut1/2 must match exact stage/session/owner/seq and preserve raw SIGSEGV rather than pretending exit0. These are null-probe survival controls, not original cell/header fault-PC proof.
7. Recover the actual historical two-worker fixture/argv/env/topology before claiming B->C comparison. Keep its original20-second command interval; require both GC and worker returns, joins, raw exit0, timeout=false, all-writer quiescence and snapshot/hash before final parent release. If original evidence remains missing, label a newly authored control separately. Do not rerun the entire inventory, change qualifier/history, enlarge90/3600/20-second limits or count model results toward9/12.

Receipt fields must identify actual helper/source generation, request/session/slot/cut/stage/seq, reached refusal or commit cut, raw status, retained resource disposition, quiescence and immutable snapshot. Finalization, repeated setup and helper refusal need distinct reasons; a blank or default coverage value is not success.


## Retained verification result

Final model SHA256 `2159be973e5752050c26a27839464a2c75a30b561aedf61a2432e4abc73bfa4c`:15 safety checks,11 parsed mutant counterexamples and15 positive reachability witnesses all matched expectations (41 controls). Every check stayed within the existing30-second model cap. Logs, immutable snapshots, traces and source call index are retained at `.cache/tasks/repair-9-12/processes/audit/runs/086d6d67f50446a192737a5fea7f1374/outputs/scan-session-commit-model`. Preliminary model versions and the initial sandbox loopback refusal remain separate retained attempts; they are not added to41. No native execution occurred. The model does not establish actual C acquire/release code generation, external host validity or original TFIB/request-hang causality.
