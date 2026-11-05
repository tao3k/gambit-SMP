# Ticket grant acquire and abort-write responsibility

2026-10-23. Research only; native acceptance remains **8/12**. This narrows two prerequisites of [the four-boundary handoff proposal](smp-repair9-mailbox-boundary-refinement.md). No runtime/header/compiler change, native run, complete inventory, peer operation, staging, commit or push is performed.

## Decision and limits

For the captured Darwin/GCC sync-builtin path, the smallest ticket change is a real completion barrier **after the normal ticket-grant wait and before returning to protected code**, in canonical `include/gambit.h.in`. Do not add a barrier on every spin iteration, replace the ticket representation or weaken unlock. Debug and successful-CAS entry already have a later synchronization operation; they are separate profiles. The emulated barrier fallback is empty, so inserting its macro cannot establish the same contract there.

The smallest abort change has two layers: retry/classify the fixed one-byte write without changing normal scheduling; then make committed-wake completion depend on the actual write/receiver outcome for the same publication incarnation. An ignored error, a nonzero old acknowledgment or merely setting an interrupt flag is insufficient. Permanent pipe failure has no recovery guarantee using only that failed pipe. The production contract must explicitly retain/report that failure; it cannot certify eventual delivery from a safety-only fault state.

These are necessary contracts and a bounded implementation plan, not an identified native first writer or a complete repair9 qualification.

## Fresh source identities and what changed since the previous study

Audit `b4150baa092140398f45b6bff3405991/outputs/acquire-abort-source-audit` captured incremental source plus the corresponding vendor template files, with full hashes and `readIntervalStable=true`. Incremental identities include:

| File | SHA256 | Relation to previous frozen cut |
|---|---|---|
| include/gambit.h | 15f39cfda23d945d393b10786a9b7030899de75cc98467989cd3cfe6fffd4802 | unchanged |
| include/gambit.h.in | 9162379484717e1863170d4c21b2cc5c8f5a41e1cc71ad3066fdda864f4a40e5 | newly captured template |
| lib/setup.c | 65a4ea48c338268949a7fe4a3b04df45fc4aeb46770300eece3c808364566998 | changed source |
| lib/os_io.c | 22c2634f2dfae6e55a53e00f45d0e0cf986e017fb23e433f034986a5546dab37 | changed source |
| lib/os_io.h | 7e39f1c3c4df776b997a9f28624a1d4d5e71522935075f7411fc551d444b28c0 | changed source |

Thread Scheme and kernel Scheme retain f987f557… and a1b95d8b…; os_thread.c retains4aeb80cc…. Fresh setup adds OTHER→`___device_select_abort_if_blocking`; os_io adds blocking begin/end and a pre-select pending check. The ultimate write still ignores its outcome. These changes were observed read-only, not authored or executed by this study. No new object/gsi producer binding is claimed. Prior setup.o disassembly belongs to the prior setup.c9d028d74 generation; it must not be reused as proof of current setup65a4ea48 instructions.

The retained caller census has29 matching lines across native files/header macros and the generated kernel abort call; it is deliberately not a complete inventory of every generated primitive-lock expansion. It includes allocation/misc locks, GC heap-chunk scan locks, processor/VM setup, VM synchronization and condvar-device reacquisition. Thus the raw lock is not a private high-level-interrupt mechanism.

## Ticket contract at the actual macro boundary

| Path | Actual sequence / synchronization point | Smallest action | Evidence boundary |
|---|---|---|---|
| Normal `___TICKETLOCK_LOCK2` | Reserve next with full-barrier F&A; volatile-read current until equal; return. No grant-completion barrier. | Add existing *effective* `___SHARED_MEMORY_BARRIER()` immediately after while, once per acquisition, in the canonical template. | Confirmed normal source gap; old object demonstrates corresponding ordinary load wait on ARM64. No actual stale-tail occurrence recovered. |
| `___DEBUG_TICKETLOCK` | Same wait, then atomic history-index update/history stores and completion barrier before returning. | Preserve existing debug completion ordering; no duplicate fence needed merely for parity with normal branch. | Corrects an overbroad reading of the preceding study. This profile differs from release/nondebug and is not its performance control. |
| `___TICKETLOCK_TRYLOCK2` | Read current, successful CAS on next, then protected code. | Preserve successful-CAS acquisition semantics; no blind extra fence on every Scheme helper retry. | Scheme thread/P helpers use this path; failed CAS does not grant ownership. |
| Unlock | Atomic fetch-add current, already full-barrier under GCC sync builtins. | Preserve release/publication ordering. Do not substitute an ordinary store in the same patch. | New acquire proof still depends on this publication premise. |
| GCC builtin backend | `__sync_synchronize()` is a real full barrier; F&A/CAS use sync builtins. | Initial implementation comparison can use this existing backend with no ABI/layout change. | Source and prior actual ARM64 object support this target; no other compiler profile is thereby certified. |
| Win32 sync backend | `MemoryBarrier()` / interlocked operations. | Keep implementation unchanged pending platform-specific acquisition review. | Source correspondence, no Windows native evidence here. |
| Emulated sync | Hash-mutex-protected emulated atomic helpers, but `___emulated_shared_memory_barrier` (os_thread.c788ff) is deliberately empty. | A macro-only fence insertion is insufficient; need a real ordered load/barrier or separately proven fallback protocol. | No claim that hash mutexes for different words create the required grant edge. Do not silently remove this profile from declared inventory. |
| Sequential/no-thread / mutex-backed spinlock | No-thread excludes concurrent ticket paths; optional native mutex replaces SPINLOCK, not every PRIMLOCK. | Preserve configurations; distinguish their actual expansion. | Not evidence that the SMP raw ticket path is ordered. |

Canonical generation is explicit: `include/makefile.in:368–369` regenerates gambit.h from gambit.h.in through config.status. A future change must flow through the registered producer and invalidate dependent artifacts, rather than edit an installed header or reuse the old completed producer identity. Compare canonical normal macro bodies across vendor template, incremental template and generated header before implementation. No generation command is run here.

The captured multi-VM setup.c also has a compile-time requirement for native GNU word atomics (`VM registry reader-lease candidate requires native GNU word atomics`). Thus the emulated profile is a portability limit, not evidence that this current multi-VM candidate executes that fallback. This study changes neither that guard nor the declared configurations.

A post-grant full fence is the smallest conservative change within the existing compiler-extension scheme. It is not a proof that mixing legacy atomic operations and volatile loads is strictly ISO C11 portable. A broader atomic-load abstraction may improve formal portability but adds backend work. An acquire load on current is an alternative only with width/alignment/fallback and release pairing established; it is not supplied by naming an ordinary load “acquire”.

[GCC sync-builtin semantics](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fsync-Builtins.html) explains the current operations and full barriers. The reservation barrier occurs before an arbitrary predecessor wait, so it cannot substitute for the completion synchronization. The source-shaped QNT stale-tail schedule retains that explicit weak-visibility premise; it is not a complete ARM memory-model execution.

## Abort callers, their contexts and last responsibility

Fresh source call chain:

1. `___raise_interrupt_pstate` setup.c66–93 stores intr_flag. If enabled, it stack-trips, issues the existing barrier and calls abort. For masked OTHER, it now calls `___device_select_abort_if_blocking`.
2. `abort_if_blocking` os_io.c1606–1616 checks processor owner plus an acquire-read blocking flag, then calls the same abort function. On the select path1193–1210, blocking_begin publishes a flag, pending is rechecked, and blocking_end runs on the explicit early return and normal select return.
3. Scheme ready insertion releases P before `##wait-abort!`2659ff; that removes idle registration under V, releases V, then calls `##wait-abort-no-remove!` → kernel `##device-select-abort!`4520ff → abort. The generated bridge currently returns VOID, erasing outcome.
4. `___device_select_abort`1619–1640 performs one nonblocking byte write, or Win32 SetEvent, ignoring error. Both direct and conditional paths converge here.
5. Device select drains the read end1499ff, retrying interrupted reads; on a normal consumed abort it reports EINTR. There is one read surface in this path. Runnable state must be checked after draining before sleeping again; the byte is not the request node or the result reply.
6. Setup12059ff opens the pipe and makes both ends nonblocking; cleanup12096ff closes both. Abort itself takes no fd-use reference. Valid processor/VM incarnation and no concurrent close/reuse remain lifetime premises. An in-flight abort is a last consumer of the fd pair even though it contains no Scheme root.

New blocking visibility does not make an unsuccessful write successful. It also is not automatically the candidate's same-P runnable/park protocol: its pending check observes OTHER/head, not the full target-owned mailbox/runnable contract. Do not count it as repair9 or as a validated native handoff. Only the captured select branch is bound here; no poll/Windows/alternate branch parity is assumed.

| Write result | Meaning for a one-byte valid nonblocking pipe | Responsibility may leave publisher when… |
|---|---|---|
| Exactly1 | Byte was published. It may already have been read by the time caller returns. | Either pipe carries the wake or receiver has taken wake/service responsibility for the same durable work. Byte availability need not persist forever. |
| -1/EAGAIN | No byte added; existing full pipe can coalesce. | Reader still has readable wake, or its concurrent drain has transferred responsibility to a receiver that rechecks ready state. EAGAIN is not a promise of future readability independent of that consumer. |
| -1/EINTR | No certified new wake byte from this attempt. | Retry succeeds/coalesces or a matching receiver acknowledgment is established. Otherwise caller/recorded fault owner still owes the wake. |
|0 / unexpected short result | Not successful one-byte publication. | Never classify as delivered without an explicit alternative witness. |
| Other negative error | Transport or lifetime failure; EBADF/EPIPE especially implicate fd lifetime. | Only an explicit failed handoff, with unresolved wake and no delivery admission. A scalar error record does not itself wake a sleeping receiver. |

[Apple's archived write(2) contract](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/write.2.html) supports checking the byte count and distinguishing interrupted, would-block and invalid/broken descriptor outcomes. It is a primary API reference, not a current-host injected-fault experiment.

### Minimal function-level implementation proposal

The reference heartbeat signal chain is os_time.c `heartbeat_interrupt_handler` → configured callback → os_setup.c `heartbeat_intr` → `___raise_interrupt(___INTR_HEARTBEAT)` → raise_vmstate/pstate → abort. This is why failure reporting must preserve signal-context constraints and errno; it cannot allocate a Scheme exception inside the writer. The exact callback setup and source hashes are retained with publication.

A. In `___device_select_abort`, perform fixed-size nonblocking write classification with an immediate errno snapshot. Retrying EINTR is justified for this one-byte operation; preserve caller errno if reached from interrupt/signal contexts. Do not add malloc, Scheme callbacks, blocking scheduler locks or GC there. Do not silently change SIGPIPE policy. Normal success/EAGAIN needs no extra write. No loop over EAGAIN; permanent errors do not enter retry-until-lucky.

B. Make the internal abort outcome observable: e.g. internal `int` status (0 for success/coalescing, positive errno/error for failure), updating os_io.h, abort_if_blocking and kernel bridge coherently. Keep the exported void interrupt-raise ABI; that path must record a non-success for the same processor/publication incarnation rather than ignore the new return. A native error record needs only scalars, not Scheme pointers. Exact publication/fault ownership and atomic pair updates belong to the park protocol; `last_errno` without an epoch is insufficient.

C. Propagate/record wake failure in `##wait-abort-no-remove!`, `##wait-abort!` and the runnable insertion callers. Some callers still hold T/M-related scheduler locks. Therefore do **not** raise a Scheme exception directly at the syscall site or leave critical sections via a new unwind. First preserve the ready entry and failed-handoff identity, release all scheduler locks, then disposition at an existing legal Scheme boundary. Returning a status that every caller ignores is not a fix.

D. The receiver's P-protected recheck discharges durable ready debt, with exact incarnation/generation matching. An old successful ack for epoch1 cannot excuse a failed epoch2 write. A consumed byte must become receiver responsibility, not disappear into another wait. Retain existing mapped Scheme frames; no raw SCM root is introduced by scalar wake/error fields.

A alone is a small transport hardening within a live-fd fault domain. A–D are the smallest **coherent delivery contract** for the structural candidate. They are not one isolated write-loop patch. Proposed names/fields are a review specification, not runtime code changes or an extra framework.

### Honest fault envelope

If the pipe is permanently unusable and target is already asleep with no other wake source, neither storing errno, returning an error to the publisher nor publishing more runnable work can force it out of select. A proof of successful recovery requires another proven wake/termination channel or a stronger live-fd assumption. This study adds neither channel nor watchdog. QNT therefore checks hard-error retention/safety **without completion**. The fault cannot be relabeled native PASS. Matching fd lifetime, cleanup and safe failure reporting are still open before unconditional production claims.

Similarly, EINTR retry has conditional eventual progress, not a fixed wall-clock bound under an unbounded signal stream. No timeout or stage budget is widened. The model bounds its transient interruption explicitly; that bound must not masquerade as a guarantee of the OS.

## First-eight impact and performance cost

| Existing gate | Exposure from this plan | Required evidence before carrying its old PASS forward |
|---|---|---|
|1 bootstrap | Header affects runtime/compiler-generated consumers and setup locks. Internal abort signature/bridge tables must agree. | Fresh registered producer, matching regenerated C/header/link bindings; no old-object shortcut. |
|2 complete-gsi | All interpreted scheduling, interrupts and I/O share primitive locks/abort. | Original complete interpreted inventory, exact error behavior and natural exit. |
|3 pr-regressions-gsi | Mutex abandonment, callbacks, nested interrupt, fd/signal/park paths. | Original PR tests; no fake replies or exception under locks. |
|4 complete-gsc | Compiled continuations/FFI include the header and primitive bridge ABI. | Matching compiler/runtime and generated maps/tables; full declared compiled inventory. |
|5 pr-regressions-gsc | Same errors/ownership changes through compiled callers. | Complete compiled PR inventory with original semantics and limits. |
|6 stress-gsi | Shared barriers add contention cost; retry/errno handling can interact with signals. No TFIB root cause is established here. | Sustained original stress, no stall/SIGSEGV, unchanged topology/deadline. |
|7 stress-gsc | GC heap scan locks and compiled scheduler contend on the same primitive. | Original compiled stress and native cost/resource measurements. |
|8 registry-lifetime | In-flight abort consumes processor/fd incarnation through cleanup; static blocking-owner state also needs VM/processor identity. | Existing declared reuse/lifetime controls and actual last-consumer proof, not just source-field nonchanges. |

All eight remain mandatory for a changed producer. None are rerun by this research.

Normal lock change adds **one completion fence per normal raw acquisition**, including allocation, GC chunk and setup/VM/condvar paths selected by configuration. It adds no field, layout, allocation or syscall and changes no ownership/fairness scheme. It is not free: barrier latency and serialization can matter in hot GC/allocation loops. Successful-CAS Scheme helpers and mutex-backed spinlock expansion should not receive redundant fences by accident. Do not optimize away the uncontended fence without a separate valid synchronization proof. Acquire-load specialization may reduce cost, but is a second implementation/portability decision.

Normal abort success still costs one one-byte syscall; full pipe still costs one failed nonblocking syscall and no retry. With k interrupted attempts, work is k+1 writes before success; there is no unconditional bound on k. Typed outcome/epoch bookkeeping is O(1) per handoff and O(P) scalar storage if a per-processor latch is selected; cache-line and syscall costs require measurement. Sender/receiver lock acquisitions belong to the earlier park plan and must not be hidden inside the claim “one write”. No global scan, timed rescue, per-request allocation, new collector or lifecycle rewrite is proposed.

## QNT and source correspondence

`result_mutex_ticket_grant_contract.qnt` refines the existing two-node visibility litmus into seven explicit profiles. Normal reservation and hoisted fence allow a stale old tail; post-grant fence, existing debug completion barrier, successful CAS and acquire-load profiles reject it under the stated effective-acquire premise. The empty-fallback profile still fails despite a syntactic barrier call. The negative retains literal last-node pop/new-node link assignments, not an arbitrary loss action. Positive controls establish the finite contract only, not ARM axiomatic validity or compiler/native equivalence.

`result_mutex_abort_responsibility.qnt` separates publisher, pipe and awake-receiver responsibility, actual outcome, ready service, admission, fault retention and epoch acknowledgment. Write success, EAGAIN/drain-before-return, one transient EINTR followed by retry, and two sequential epochs have conditional-completion controls. Hard error has safety only. Negatives ignore EINTR, drain without taking ready responsibility, accept epoch1 ack for epoch2, or admit a hard error. Both physical ownership retention and truthful delivery outcome matter.

Sixteen TLC cases (8 conditional-completion positives,1 retained-fault safety-only positive,7 decoded negatives) plus8 named TypeScript trajectories are checked with unchanged30s/check,12-worker,1GiB heap/8MiB stack limits. The previous44-check boundary receipt, prior ticket litmus and measured-failure obligation model remain immutable. New models do not claim unbounded retries, arbitrary queue nesting, fd lifetime or all-platform proof. No boolean model result upgrades native8/12.


## End-of-turn source-cut boundary

Final audit d3cca39df5c34174b8dcf6c75b058976 confirms the published24-check materials and protected history. Live setup.c/os_io.c/os_io.h changed again after the stable b4150baa snapshot; header and template still match that cut. This document binds the frozen identities above, not the later source or a current binary. No chase/rebuild/peer operation was performed. The publication-child journal check completed without a live-group rejection; its one returned token is an observed child record, not a pending process.


## Subsequent fault/last-consumer refinement (2026-10-23)

[Fault persistence, actual lock-outside boundaries and fd retirement](smp-repair9-abort-fault-lifetime.md) binds stable d53671cb source. Shrink already drains registry readers before reducing count; ordinary old-cohort Scheme calls have a scoped synchronous guarantee. Join comes after worker I/O close and cannot be its fd-consumer proof. New25-check models separate those existing protections from raw external-C and deferred-fault gaps. Three proposed scalar fields and matching retirement witnesses are specified; no runtime implementation or unconditional9/12 claim.
