# Device Release Synchronization: Source and Primary Evidence

Reviewed: 2026-10-20. Local research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; vendor Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Bindings identify selected working
files, not installed platform or native execution. This study read source and
primary literature, authored conditional arguments and reviewed diagrams.
No implementation, native test, parser/model/solver/prover/engine run occurred.

## Source Correspondence

Links below are relative to this research checkout. Line ranges identify the
reviewed span; the [trace map](device-release-sync-traceability.json) binds the
whole selected files by SHA-256. Candidate patch text is not installed-source or
runtime acceptance evidence. The earlier [wait ledger](device-release-wait-evidence.md)
and [foreign-release ledger](foreign-release-worker-evidence.md) retain broader
TLS/pump/registration/source context.

| ID | Source span | Observation and inference boundary |
| --- | --- | --- |
| SY-S01 | [`os_io.c:1625--1669`](../../../vendor/gambit/lib/os_io.c#L1625) | device_cleanup unlinks first, retries RD then WR close through device_select on EAGAIN, returns wait/error or final release. This establishes the need for stage/partial-effect custody, not cancellation rollback or arbitrary replay. |
| SY-S02 | [`os_io.c:950--1008`](../../../vendor/gambit/lib/os_io.c#L950), [`1468--1537`](../../../vendor/gambit/lib/os_io.c#L1468), [`11760--11830`](../../../vendor/gambit/lib/os_io.c#L11760) | PSTATE fdsets/abort fd, post-wait drain and readiness/error handling, pipe nonblocking setup and close. Evidence for explicit storage/wake ownership; it does not prove WST01 for an extracted native executor. |
| SY-S03 | [`setup.c:70--92`](../../../vendor/gambit/lib/setup.c#L70) | Interrupt publication sets intr_flag and stack-trip before shared barrier and device_select_abort. Existing durable-state-before-notification pattern, with distinct interrupt policy. |
| SY-S04 | [`os_io.c:1540--1558`](../../../vendor/gambit/lib/os_io.c#L1540) | POSIX abort writes one byte and ignores error; Windows calls SetEvent. New N/error/endpoint protocol is necessary for its stated guarantee; no current lost-wake bug is claimed. |
| SY-S05 | [`c_intf.c:1683--1716`](../../../vendor/gambit/lib/c_intf.c#L1683) | release_foreign saves fn, clears pointer/fn and invokes it. Acceptance/disposition cannot be inferred merely from wrapper invalidation or returned status. |
| SY-S06 | [`_kernel.scm:3869--3897`](../../../vendor/gambit/lib/_kernel.scm#L3869), [`os_io.c:9720--9748`](../../../vendor/gambit/lib/os_io.c#L9720) | foreign-released? observes pointer; explicit release can raise a Scheme error. Force-output/close extract raw foreign pointer fields. ResourceControl integration must cover these observers and managed root/control paths. |
| SY-S07 | [`mem.c:4389--4455`](../../../vendor/gambit/lib/mem.c#L4389), [`4928--4939`](../../../vendor/gambit/lib/mem.c#L4928) | Sweep releases unreachable foreign objects, but free_still_objs also releases remaining foreign objects at memory teardown. cleanup_mem_pstate calls free_still_objs then cleanup_rc. Last tracing GC alone cannot close release producers. |
| SY-S08 | [`mem.c:683--701`](../../../vendor/gambit/lib/mem.c#L683), [`760--782`](../../../vendor/gambit/lib/mem.c#L760) | cleanup_rc resets head and frees every list header; ordinary release_rc uses the refcount. An ordinary addref does not exempt remaining payload from pstate teardown. This refutes naive asynchronous deferral, not the existing synchronous cleanup. |
| SY-S09 | [`setup.c:4572--4582`](../../../vendor/gambit/lib/setup.c#L4572), [`os_setup.c:3224--3237`](../../../vendor/gambit/lib/os_setup.c#L3224) | Per-processor memory cleanup precedes per-processor OS cleanup; global OS cleanup proceeds through IO/TTY/DYN/files/shell/time/thread/base. New task/callback/library custody must finish or actually transfer before dependent teardown. |
| SY-S10 | [`candidate patch:3160--3234`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160), [`3617--3631`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3617), [`3868--3895`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3868) | Joined-donor memory transfer splices still/RC lists with borrower/GC preconditions; ready/drain fixes require reader drain/direct-user join before endpoint cleanup. Credit existing C support; no asynchronous extension or new native qualification follows. |
| SY-S11 | [`os_io.c:183--194`](../../../vendor/gambit/lib/os_io.c#L183), [`11493--11588`](../../../vendor/gambit/lib/os_io.c#L11493), [`_thread.scm:6230--6246`](../../../vendor/gambit/lib/_thread.scm#L6230) | Group cleanup frees group after error; managed condvar adapter unlocks/waits/relocks and publishes readiness; Scheme scheduler broadcasts readiness. These are real replacement/participation boundaries, not a generic service signature. |

The ten actual wrapper-registration expressions in the earlier ledger converge
on one existing helper. They do not imply ten copies of a new queue or ten
simultaneously admitted Darwin device families. Four release origins remain
GC, explicit Scheme release, conversion rollback and shutdown; their observation
and error contracts differ. This study does not claim a complete alias census.

## Literature and Platform Evidence

| ID | Primary source | What is used / what is not established |
| --- | --- | --- |
| SY-P01 | [Herlihy and Wing, Linearizability: A Correctness Condition for Concurrent Objects (1990), author-hosted paper](https://cs.brown.edu/people/mph/HerlihyW90/p463-herlihy.pdf), abstract and sections 1--2 | A concurrent operation can be related to a legal sequential specification at a point between invocation and response. This motivates explicit accept/cancel/delivery cuts. Our transition tables need their own refinement; the paper does not prove native mutex code, managed reentry or progress here. |
| SY-P02 | [Dijkstra and Scholten, EWD684: Termination detection for diffusing computations](https://www.cs.utexas.edu/~EWD/transcriptions/EWD06xx/EWD684.html), stock/deficit reasoning and termination theorems | The argument includes work decided but not sent and outstanding obligations. This motivates counted child preparation and issued root permits. Our single-process identity ledger is not their distributed algorithm; finite-work and complete-census premises remain explicit. |
| SY-P03 | [Apple archived pipe(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/pipe.2.html) | Descriptor pair and buffered byte communication. Does not qualify installed Darwin behavior, endpoint lifetime, shared-reader discipline or the proposed service. |
| SY-P04 | [Apple archived write(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/write.2.html) | Byte-count result, nonblocking EAGAIN and failure cases including EINTR/EPIPE inform the status split. EAGAIN coalescing and SIGPIPE policy need profile-specific qualification; any fatal error cannot be treated as a successful wake. |
| SY-P05 | [Apple archived select(2)](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/select.2.html) | Read readiness, modified fd sets, bounds and interruption inform WSO03--04. The installed target/backend and descriptor-lifetime law remain unresolved. |
| SY-P06 | [Zig language reference 0.15.1, errdefer](https://ziglang.org/documentation/0.15.1/#errdefer) and [Lifetime and Ownership](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership) | Lexical error cleanup can simplify private builder rollback. Pointer lifetime/ownership remains programmer responsibility. No automatic task cancellation, affine custody, GC roots, child-credit conservation or cross-thread deferred destruction is supplied by these features. |

The publication/tool/manual identifiers above are evidence identities, not names
for an architectural generation. Platform manuals are archived interface
references, not current installed-kernel receipts. No native trace or timing is
inferred from them. Claims here paraphrase only the selected mechanisms.

## Evidence-to-Argument Boundary

- WST01 is a case argument over a serialized persistent predicate, private
  retained wake and live notifier. It is not proved by copying the legacy
  self-pipe drain or by finding an acquire/release operation in a candidate patch.
- WST02/03 assume a complete migrated ResourceControl/AttemptRecord cohort.
  Native serialization does not prove wrapper alias invalidation, managed root
  safety, callback suppression after a delivery claim or leaf idempotence.
- WST04/05 use induction on the stated ledger operations. SY-S07/S08 add a
  mandatory teardown producer and actual payload-custody gate. No checked
  conservation theorem, complete release census or donor-transfer extension is issued.
- WST06 explicitly separates accounting safety from termination. Logical
  interleavings WSX01--14 are reviewer countermodels, not executed witnesses.
- C and Zig must satisfy the same premises. SY-P06 offers a candidate local
  support reduction; it supplies no positive cost bound for the whole service.
