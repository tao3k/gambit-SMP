# Review of delivery-service-roots runnable implementation

2026-10-24. Evidence-only review of `patches/fixtures/delivery-service-roots-cumulative.patch`, SHA256 `621449cf1888592864293c2f79c1f4ce4cf1aa91f9ce7e8a69ee49fa7c101112`, based on lock main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. This reviews the supplied patch bytes and existing landed record; it does not run, inspect, signal or modify the peer producer. It does not re-run existing tests, QNT or compilation.

## Implemented versus certified

The patch now contains the ordinary-C native try-release and bounded scheduler-select deadline. This is actual implementation progress, not another proposal. Generated bridge maps/object call graphs are still uncertified; the scanned wait capsule/P-reacquire split is not implemented. Native P reacquire remains a separate open service dependency. Concurrent shrink is a refusal path while delivery pins remain, not a completed queue/root handoff.

The existing `delivery-service-roots-landed.json` names gsi `bef5468fd3079337748dd93e88fab1676fa1d9061dbf00548135d3f61a133841` and gsc `be9dc33152bd2dcdc9650878eab3c68c6bf14a8b57aea2c8f26c786ce1fb9c4e`. This review verifies the patch SHA and reads that record, but has no independent on-disk binary/generated-C identity certificate. Treat runtime observations as reported by the existing landed record. That record distinguishes the 200-interrupt run (0 failures, exit0, includes termination) from the one-interrupt run (returns41, then a subsequent already-terminated-thread join raises and the process exits70). Do not flatten both into two clean exit0 runs. Original stress was not run.

## New concrete source finding: retained Active is still dispatchable

Patch-coordinate anchors (these are **patch line numbers**, not reconstructed source/GSI offsets):

- `##thread-intr-try-release!`2001; SYNC retry before another native call2009..2015.
- `##thread-intr-execute!`2080; its dynamic-wind entry accepts phase2 and executes the thunk2093.
- `##thread-intr-drain!`2105; a result request is left on its thread queue2107..2109. For the result branch it unconditionally writes phase2 at2126, unlocks and calls execute2128. There is no Queued-only claim check or Active skip.
- Resume path2479 calls drain before the saved resume-thunk2480. Unlocked service2153 also calls drain.

Consequently, an executing request A remains queue-reachable for termination, but a nested drain sees A as executable again. Source path to test: A thunk yields or migrates; `##thread-resume-execution!` resumes through drain; the same head A is set to2 and entered again. `##thread-intr-execute!`'s phase2 check does not reject this because drain has just supplied that same value. A nested hint/service can expose the same path. A terminal-phase3/4 window before physical unlink also must not be turned back into Active.

This is a source-visible missing guard and a reachable-path hypothesis needing the same-B fixture. It is not a captured native double-execution or an assertion that it explains the historical hanging R. The 200-interrupt summary does not establish the yield/migration/reentrant-thunk control.

## Finite fix retaining the termination benefit

Do not revert to unrooted dequeue-before-execute. Separate dispatch eligibility from termination reachability:

1. Under target T lock, the drain scans for **phase1 Queued** result requests. It performs the single1→2 transition while claiming that request. Active2 and terminal3/4 are skipped; phase5/unknown retains fault ownership and is not executed. Procedure hints retain their distinct existing representation/dispatch rule.
2. Do not merely return when the head is Active. Scan beyond Active nodes for a later Queued request, otherwise a running thunk waiting for a nested sender can starve its eligible suffix. Keep Active nodes in the queue so termination still finds them. If there is no eligible node, return to the saved continuation, not spin on the Active head.
3. Each invocation owns only its claimed A. After yield/GC/reentry it re-finds A by rooted object identity under T; it must not use stale `prev/next` or a saved queue-head interior pointer. Remove only that exact terminal A; preserve neighbors and tail under T. A may no longer be head after nested completion/termination.
4. The1→2 state guard prevents ordinary re-dispatch. Re-entry into an *already captured continuation* is a different case: phase2 alone is not a unique activation capability. If multi-shot/nonlocal continuation entry into an Active thunk is supported, bind an execution incarnation/capability to the dynamic-wind entry and specify its once-only claim; otherwise reject unsupported reentry before running the thunk while retaining cleanup ownership. Do not claim the queue guard solves arbitrary continuation cloning.
5. Termination detaches all queued/Active requests under T, roots the detached list, drops T, then settles through the native release path. The currently executing invocation and termination may both reach cleanup; request phase, actual M owner and the existing unit CAS must ensure exactly one outcome/pin consumption. SenderFinal still cannot release target R.
6. Normal return, exception, target termination, notification failure and partial-retention are distinct dispositions. Do not drop an ambiguous Active/Retained entry merely to make the queue empty. Keep the original no-lock SYNC and native complete lock-set contract.

No new scheduler queue or broad protocol is needed for ordinary nested drain: phase-aware scan plus exact-request unlink is enough to keep a retained request non-dispatchable. The activation-capability caveat is explicit rather than hidden in a phase Boolean.

## Targeted same-B control before large stress

Keep existing focused30s caps. Use the same linked helper, original topology/heap and bound B identities; no separate surrogate runtime.

- A thunk increments a side-effect counter once, explicitly yields twice, returns41. Assert A counter1, sender result41 and once-only R/S settlement. Capture actual request identity/phase at claim, resume-drain and completion.
- Repeat with supported migration and nested service; active A stays rooted and cannot be reclaimed. Enqueue B behind active A while A waits for B's effect. B must run once without rerunning A; a simple “skip head and return” is insufficient.
- Pause after native result commit but before queue unlink, trigger legal nested service. A's terminal phase is not reset and thunk is not called again.
- Terminate target while A is active/yielded. Detached requests and active cleanup settle once, preserving abandoned semantics. Test exception and supported continuation reentry separately; unknown/unsupported continuation entry is explicitly refused, not counted as normal completion.
- Keep the existing device-return/P-contention/SYNC capsule and generated-map/object certificate as independent outstanding controls. The new guard does not fix that lock wait or prove no-GC/frame maps.

Once these and actual codegen/ownership controls pass on one final B, follow the existing two8-round flood and original interrupt stress plan; no full inventory or changed timeout is justified by this review. QNT controls from earlier designs do not certify this newly implemented dispatch loop. Qualification remains8/12; TFIB, lifecycle, Gerbil and release remain independent.

## Guard added after this review

The same cumulative patch was replaced. New SHA256 `a303931266e5773a9b089d7dec9ad094c112ac9fb776945288e41b4adaa1e625`. `git apply --check --whitespace=error` passed on `7c490c3`. The claim is only phase 1 to phase 2 while the target lock is held. The scan leaves Active, terminal, and phase 5 nodes in place and continues. Completion removes that request object only after phase 3 or 4, walking again from the queue root. Slot 6 is armed at the claim and consumed by the first dynamic-wind entry; a later entry is refused and the request stays queued. Same-tree gsi `f016292e644b3833a0379cb872d72bc50268333b998ec093ac2e0db919cc0245`: yield result 41 with one entry and one later request ran once; termination while yielding abandoned once; continuation reentry was refused; 200 interrupts exited 0. The generated-map certificate and the P-reacquire capsule remain open. Count remains 8/12.

## R settlement and retained root after that guard

The cumulative file was replaced again. SHA256 `35387b60dad77e6af5bf78fc7e4dc3cf7adc10ffcf12e4fb24cba7542294ccd9`. The `a3039312` bytes and gsi `f016292e` stay the previous guard, not this run. Unlink now also requires settled target R. Termination publishes an unsettled or retained request on VM slot 2 through R-unit slot 2 before clearing the detached link, and keeps walking the saved successor. The mutex payload is written inside `___thread_intr_try_release` after the owner and grant checks. A wrong-processor migration is moved back onto its target queue before restore. Gsi `066f07d2849faef91e4d25b624aee00530d0fd28c9dcc89257791fdc27f5ce3a` ran the minimal yield, nested, and migrate fixture at `-:p11` with a 30 second cap: yield once, nested once, and migrate 20 times printed CONTROL-PASS and exited 0. The generated-map certificate and the P-reacquire capsule remain open. Count remains 8/12.

2026-10-24 follow-up: [Active dispatch and exact unlink](active-request-drain.md) binds reconstructed candidate source lines,16 QNT controls and an unexecuted minimal fixture. Preserve the existing identity rescan, but gate unlink on actual R settlement/rooted handoff, not only terminal phase; failed termination cleanup needs a persistent scanned suffix owner.

2026-10-24 follow-up: [Active dispatch and exact unlink](active-request-drain.md) binds reconstructed candidate source lines,19 QNT controls and an unexecuted minimal fixture. Preserve the existing identity rescan, but gate unlink on actual R settlement/rooted handoff, not only terminal phase; failed termination cleanup needs a persistent scanned suffix owner.
