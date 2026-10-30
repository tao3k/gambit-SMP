# Foreign Release and Shared Device Cleanup: Evidence Ledger

Reviewed: 2026-10-20. Research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Working-file hashes are bound by
the trace map/receipt. No installed Darwin/OpenSSL configuration or native
execution is qualified by these reads.

## Source Evidence

| ID | Exact selected source anchors | Observation / limit |
| --- | --- | --- |
| FR-S01 | [gambit.txi](../../../vendor/gambit/doc/gambit.txi):19006-19045; [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):3869-3896 | Release-function ABI, pointer no-op vs copy cleanup/C++ destructor, at-most-once per foreign object, GC and explicit release semantics; explicit error raises after normal return. This passage is not an effect/thread certificate; no blanket callback permission inferred. |
| FR-S02 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):1683-1727,5156-5223 | release_foreign clears ptr/function before calling and returns its error; pointer-to-Scheme allocates/publishes foreign wrapper. Sequential flag behavior is not a concurrent per-resource claim. |
| FR-S03 | [mem.c](../../../vendor/gambit/lib/mem.c):4389-4450,4928-4937,6998-7040; [setup.c](../../../vendor/gambit/lib/setup.c):4572-4580 | GC/shutdown invoke release and ignore status before freeing wrapper; GC cleanup precedes barrier/resize; per-processor memory cleanup precedes OS cleanup. No finalizer-executor drain contract follows from that order alone. |
| FR-S04 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):5284-5383; [_ptree2.scm](../../../vendor/gambit/gsc/_ptree2.scm):2614-2658; [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):10008-10031 | STRUCT/UNION/TYPE failure calls direct release_fn and ignores its result; Scheme already caches/generates default release adapters; generated macro delegates deletion then returns no-error. Do not claim those generated adapters as necessary handwritten C support. |
| FR-S05 | [os_io.c](../../../vendor/gambit/lib/os_io.c):183-245,1568-1681; [os_io.h](../../../vendor/gambit/lib/os_io.h):74-103 | Shared group/link/stage/refcount service. Cleanup unlinks first; closes RD/WR with EAGAIN/select loops, then release. Last ref calls virtual release and frees storage regardless of its error. Group shutdown loop stops on error; the group is freed. Not a proven resource-drain protocol. |
| FR-S06 | [os_io.c](../../../vendor/gambit/lib/os_io.c):930-1024,1468-1497; [mem.c](../../../vendor/gambit/lib/mem.c):760-794 | Select/poll borrow implicit PSTATE fdset/abort state; RC release/addref mutate plain count/list fields. Thread-neutral-looking signatures conceal ownership dependencies; platform branches unqualified. |
| FR-S07 | [os_io.c](../../../vendor/gambit/lib/os_io.c):10162-10176,10458-10472,10526-10542,10615-10625,10758-10772,10910-10924,10952-10966,11046-11060,11375-11388,11453-11467 | Ten textual registration expressions use one device-cleanup adapter. Most inspected failure paths call cleanup; process-stream conversion failure scope differs. Count is not installed-target coverage, ten independent implementations or ten savings. |
| FR-S08 | [os_io.c](../../../vendor/gambit/lib/os_io.c):3948-3973,4550-4565,5124-5140,6050-6066,6107-6122,7099-7145; [_io.scm](../../../vendor/gambit/lib/_io.scm):8487-8510,8582-8605 | TLS wrapper release includes RC strings/SSL_CTX/RC; TCP client release includes SSL_free; server native wrapper borrow and normal Scheme psettings retention; event release is RC. Library/alias/lock effects need actual profiles, not assumptions from a short body. |
| FR-S09 | [os_io.c](../../../vendor/gambit/lib/os_io.c):1907-1935,2011-2042,2070-2110,2299-2301,2428-2502,11895-11907 | Pump wait/ref/close/cleanup and group shutdown demonstrate real native task users and lifecycle convergence. Windows-only pump branches must not be relabeled Darwin behavior. |
| FR-S10 | [os_io.c](../../../vendor/gambit/lib/os_io.c):5831-5860,6622-6658,7209-7264,9718-9747 | Concrete socket/directory/file close effects and raw device pointer extraction for force-output/close. Stage change can precede OS error; implicit Scheme reachability alone does not describe a native borrow. |
| FR-S11 | [candidate patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):3160-3234,4352-4395 | Joined donor storage transfer and retained failed joins are existing repairs. Storage may change custodian; no allocation-thread destructor guarantee follows. No native rerun or newly reproduced failure here. |

The shared service is grounded in device consumers, not all foreign functions.
The selected symbol census covers the registrations in `os_io.c`, the three
conversion helpers, kernel explicit release and mem cleanup. Public custom
release functions, downstream C/C++ native users and actual installed library
callbacks are not a closed world. Ten registrations do not prove that all ten
rollback paths, effects or resource lifetimes are complete.

## Primary Research / Platform Evidence

| ID | Reading and inspected scope | Used distinction |
| --- | --- | --- |
| FR-P01 | [Boehm, Destructors, Finalizers, and Synchronization, author POPL 2003 slides](https://www.hboehm.info/popl03/slides.pdf), pages 8-13; [author publication entry](https://www.hboehm.info/pubs.html) | External cleanup may require synchronization; invoking while a relevant thread holds a lock can deadlock; a field/handle can remain in use when a wrapper is unreachable; shutdown finalization has dependencies. Author slides, not a claim of reading the full paper. The talk assumes Java unless noted; no Java rule or timing is imported into Gambit. |
| FR-P02 | [OCaml 5.3 C interface](https://ocaml.org/manual/5.3/intfc.html), custom finalizers and runtime-lock sections | Custom finalizers forbid managed allocation/callback; runtime release/acquire can invoke managed asynchronous code. Supports explicit effect frontiers and executor admission; not a Gambit restriction by analogy. |
| FR-P03 | [OpenSSL SSL_CTX_free](https://docs.openssl.org/3.4/man3/SSL_CTX_free/), description/warnings | Refcounted library cleanup may call configured session-remove callbacks; enclosing Gambit wrapper lifetime is separate. Local OpenSSL build/configuration not identified or qualified. |
| FR-P04 | [Sivaramakrishnan et al., Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), section 4.4 | Mutator quiescence, relocation and work completion are distinct requirements. Supports separating collector completion from native release progress. No finalizer algorithm, generational policy or benchmark is transferred. |
| FR-P05 | [Zig reference](https://ziglang.org/documentation/0.15.1/), errdefer, Lifetime and Ownership | Lexical ordinary-error cleanup is a language facility; pointer lifetime remains the programmer's responsibility. It does not discharge native asynchronous drain or make a callback no-throw/no-GC. Reference version is a source identity, not an architecture generation name. |
| FR-P06 | [LLVM ORC resource removal](https://llvm.org/docs/ORCv2.html#how-to-remove-code) | Provider code removal is a mechanism after real image/return/callback use drains. It does not discover a pending foreign destructor or qualify an executor. |

The Boehm full-paper publisher endpoint returned forbidden, its linked lab report
timed out, and two indexed mirrors could not be read. Only the directly read
author slides/publication entry are used. The OCaml research paper and primary
manuals were read at the listed scopes. No quotation or published runtime number
is used as a forecast for this proposal. Rolling pages are read-time references,
not pinned installed tool/library artifacts.

## What Is Newly Reasoned, and What Is Still Missing

FRO/FRE/FRU tables are source correspondence and effect/lifetime deductions.
FRA admission, DeviceControl/ReleaseAttempt/ReleaseOutcome/WaitContext, separate
memory/release completion, the unique-claim paper argument and cost comparison
are proposed architecture. They are not properties discovered automatically by
a table, a hash, a model field or an effect annotation.

Necessary missing evidence includes: all transitive custom destructor effects;
actual lock/affinity and wait dependencies; borrower/alias issuers; selected
Darwin C profile and library callbacks; synchronization/ABA; origin-preserving
error/timing semantics; no managed allocation in unsafe phases; native queue and
shutdown correctness. No full architecture requirement is newly satisfied.
