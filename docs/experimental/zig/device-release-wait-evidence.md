# Device Wait, Delivery and Drain: Source and Primary Evidence

Reviewed: 2026-10-20. Research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Working-source hashes are bound
in the trace map/receipt. Source paths below are selected reads, not installed
Darwin configuration, transitive-call completeness or runtime qualification.

## Source Ledger

| ID | Inspected source anchors | Fact / boundary |
| --- | --- | --- |
| DW-S01 | [os_io.c](../../../vendor/gambit/lib/os_io.c):1603-1681,183-245 | Last ref calls virtual release then frees device regardless of returned error; cleanup unlinks group first and loops RD/WR close with infinite select on EAGAIN. A returned error is not a payload-disposition certificate. |
| DW-S02 | [os_io.c](../../../vendor/gambit/lib/os_io.c):930-1083,1160-1340; [os_io.h](../../../vendor/gambit/lib/os_io.h):116-157 | Stack-local device-select state plus PSTATE fdsets/abort handles; select/poll/time conversion and heartbeat masking; bounded arrays and readiness output. New native WaitContext cannot be a borrowed alias to this mixed state. |
| DW-S03 | [os_io.c](../../../vendor/gambit/lib/os_io.c):42-154,856-905 | Two/optional-third native fdset allocations with existing C failure funnel; collective fdset growth and unchecked-at-leaf index writes. Reuse construction discipline; new context needs explicit target capacities and exclusive resize lifetime. No universal target limit inferred. |
| DW-S04 | [os_io.c](../../../vendor/gambit/lib/os_io.c):1396-1553; [setup.c](../../../vendor/gambit/lib/setup.c):70-92 | Native readiness check plus abort consumption, EINTR result and nonblocking write/event notification ignoring errors; interrupt raise wakes processor. A wake is not task cancellation or release completion. Windows branch is distinct from Darwin. |
| DW-S05 | [os_io.c](../../../vendor/gambit/lib/os_io.c):11493-11589; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):4505-4533; [_thread.scm](../../../vendor/gambit/lib/_thread.scm):2534-2563,6230-6248,6881-6893 | Managed condvar extraction, queue unlock/relock and readiness publication; register/RA save/restore; processor wait enrollment/abort and scheduler wake. This adapter carries Scheme/raw-pointer obligations not present in a native-only release task. |
| DW-S06 | [os_io.c](../../../vendor/gambit/lib/os_io.c):1907-1935,1938-2009,2428-2502,4848-4918,4966-5024 | Native pump wait/ref users and TLS close/readiness work illustrate multistep effects and conditional platform users. No claim every source return/readiness path matches a selected modern SSL profile. |
| DW-S07 | [os_io.c](../../../vendor/gambit/lib/os_io.c):10162-10176,10458-10472,10526-10542,10615-10625,10758-10772,10910-10924,10952-10966,11046-11060,11375-11388,11453-11467; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):1683-1715,5284-5383 | Ten registration expressions share one cleanup callback; caller rollback varies; explicit invalidation and typed conversion cleanup have different result behavior. No deferred task implementation exists in these paths. |
| DW-S08 | [os_io.c](../../../vendor/gambit/lib/os_io.c):11760-11830; [candidate patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):3617-3630,3840-3918 | Existing abort resource setup/cleanup; candidate adds publication readiness, partial setup cleanup, fdset release and direct-user/registry-drain preconditions. Credit this C repair; ready load alone is not a complete lifetime/wakeup proof. |
| DW-S09 | [os_thread.c](../../../vendor/gambit/lib/os_thread.c):493-594; [candidate patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):4352-4395 | Thread create/join/exit wrappers and retained failed joins. Successful join concerns target exit; task/descendant/pin closure is a separate obligation. No wrapper error mapping or cancellation correctness is qualified. |
| DW-S10 | [os_io.c](../../../vendor/gambit/lib/os_io.c):183-194,11895-11957; [os_setup.c](../../../vendor/gambit/lib/os_setup.c):3137-3151,3224-3235 | Group cleanup stops on error and frees group; I/O module tears down child-interrupt/Windows platform state and group, then SSL globals; global OS cleanup orders I/O/TTY/dynamic/files/shell/time/thread/base. Existing synchronous order is not proof that proposed deferred jobs can outlive it. |
| DW-S11 | [setup.c](../../../vendor/gambit/lib/setup.c):4572-4580,4599-4630,4830-4884 | Memory/OS cleanup composition and main runtime processor shutdown/pstate/VM cleanup. Deferred task discovery, roots and executor dependencies need explicit migration; no blanket reordering is authorized/proved. |
| DW-S12 | [os_time.c](../../../vendor/gambit/lib/os_time.c):950-976,1055-1084 | Heartbeat masking helpers vary by platform configuration, including no-op and signal-mask paths. Native executor signal policy requires exact selected build; names alone do not establish effect neutrality. |
| DW-S13 | [os_setup.c](../../../vendor/gambit/lib/os_setup.c):203-223; [os_io.c](../../../vendor/gambit/lib/os_io.c):7209-7264 | Existing close_no_EINTR retry loop and file close stages. Preserve/qualify selected leaf behavior; no generic replay of an entire destructor or cross-platform close retry law is inferred. |

This extends the earlier foreign-release ledger, which retains default adapter
and explicit-release semantics. Scope is the necessary shared service and its
actual wait/shutdown consumers. Public custom C/C++ callbacks and native raw
pointer hosts remain an unclosed external boundary. All dynamic-root, profile,
weak-memory and borrower premises remain explicit.

## Primary Literature and Platform References

| ID | Read source / scope | Used distinction and limit |
| --- | --- | --- |
| DW-P01 | Apple archived [select](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/select.2.html), [close](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/close.2.html), [pthread_cond_wait](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_cond_wait.3.html), [pthread_join](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_join.3.html), descriptions/returns | Wait readiness/error, descriptor lifetime, atomic unlock-and-wait and target-thread termination are separate mechanisms. Archived platform manuals are not installed SDK/kernel qualification; they do not prove this wake protocol or close disposition on every error. |
| DW-P02 | [Dijkstra and Scholten, Termination detection for diffusing computations, EWD684, archive transcription](https://www.cs.utexas.edu/~EWD/transcriptions/EWD06xx/EWD684.html), setup, engagement/deficit argument and two theorems | Work/acknowledgement conservation and bounded diffusion motivate descendant/in-flight accounting. Our service is not an implementation/refinement of that distributed algorithm; its native synchronization, failure handling and liveness remain unproved. |
| DW-P03 | [Boehm, Destructors, Finalizers, and Synchronization, author POPL slides](https://www.hboehm.info/popl03/slides.pdf), pages 8-13 | Shared cleanup can need locks; finalization can race handle use; stopping dependencies or assuming all finalizers drain at exit is unsafe as a general rule. Java-oriented talk, not Gambit semantics or a full-paper read. |
| DW-P04 | [Sivaramakrishnan et al., Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), section 4.4 | Stop/relocation/work-sharing coordination motivates retaining distinct memory-epoch and native-release frontiers. No OCaml collector algorithm, performance result or generational policy is transferred. |
| DW-P05 | [Zig language reference](https://ziglang.org/documentation/0.15.1/), errdefer, Lifetime and Ownership | Ordinary scoped rollback can be expressed lexically; pointer/lifetime policy remains programmer-owned. Asynchronous task custody, late wake writers and shutdown are not supplied by defer. Reference identity is not an architecture generation name. |
| DW-P06 | [OpenSSL SSL_shutdown](https://docs.openssl.org/3.4/man3/SSL_shutdown/), lifecycle and nonblocking shutdown | TLS protocol completion/readiness can require repeated progress and is separate from TCP connection disposal. Selected Gambit/library policy may differ; the modern manual is not a qualification of installed library or current source return handling. |

The current Open Group endpoints returned forbidden. Apple archive pages were
used for the limited platform claims above. The EWD PDF fetch timed out; its
readable archive transcription was inspected instead. No unseen contents or
native observations are claimed. Direct source reads and literature mechanisms
support proposed obligations, not completed runtime correctness or net benefit.

## Evidence Boundary

RWC rows identify source correspondence; WCT/DLT/WCN/RSD rows specify proposed
records, transitions and obligations. The conservation/drain paragraph is a
handwritten conditional argument. Support-unit/change matrices describe required
maintenance, not measured effort or generated code. A rendered D2, matching hash
or acyclic trace relation does not establish task delivery, cancellation,
shutdown success or positive Zig economics. No model/engine/native evaluation
was performed and no old path is retired.
