# Root Transfer Boundary: Source and Primary Evidence

Reviewed: 2026-10-20. Research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; vendor Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Whole-file hashes and source
spans are bound by the [trace map](root-transfer-receipt-traceability.json).
Selected working source and candidate patch text are not installed runtime or
native qualification. No compiler/model/prover/solver/engine/native test ran.

## Source Ledger

| ID | Inspected span | Fact and qualification boundary |
| --- | --- | --- |
| RF-S01 | [`_kernel.scm:44--74`](../../../vendor/gambit/lib/_kernel.scm#L44), [`2029--2070`](../../../vendor/gambit/lib/_kernel.scm#L2029) | Inline allocation and explicit GC paths store RA/write registers around collection and reload afterward. not-interrupts-enabled appears on a synchronous GC primitive; it is not a no-GC contract. Existing Scheme completion/physical maps remain necessary evidence. |
| RF-S02 | [`mem.c:1637--1666`](../../../vendor/gambit/lib/mem.c#L1637), [`setup.c:880--914`](../../../vendor/gambit/lib/setup.c#L880) | Still allocation invokes garbage_collect; VM resize can call garbage_collect_pstate directly for space. Transfer admission must cover both, not only one exported function. |
| RF-S03 | [`setup.c:1010--1040`](../../../vendor/gambit/lib/setup.c#L1010), [`1050--1151`](../../../vendor/gambit/lib/setup.c#L1050), [`1182--1201`](../../../vendor/gambit/lib/setup.c#L1182), [`setup.h:63--67`](../../../vendor/gambit/lib/setup.h#L63), [`setup.c:715--730`](../../../vendor/gambit/lib/setup.c#L715) | GC sync dispatch/on_all_processors and sync loop; BARRIER is empty in a single-threaded VM or uses barrier_sync_noop. A barrier is a rendezvous in this machinery, not a root-transfer or physical-user certificate. |
| RF-S04 | [`mem.c:3969--3989`](../../../vendor/gambit/lib/mem.c#L3969), [`3490--3537`](../../../vendor/gambit/lib/mem.c#L3490), [`3570--3652`](../../../vendor/gambit/lib/mem.c#L3570), [`783--829`](../../../vendor/gambit/lib/mem.c#L783) | RC scanner caches next and marks &h->data; mark_array writes the actual root cell after forwarding. addref/data/set_data are ordinary operations. Root cell location, collector writes and native list users are separate obligations. |
| RF-S05 | [`mem.c:6813--6936`](../../../vendor/gambit/lib/mem.c#L6813), [`6986--7046`](../../../vendor/gambit/lib/mem.c#L6986), [`7073--7086`](../../../vendor/gambit/lib/mem.c#L7073) | Strong roots/reachable scan, weak wills/scan, continuation move, cleanup foreign releases, resize/barriers and prepare_mem_pstate. Return status is overflow, also handled by kernel raise/retry paths; it is not a transfer/physical-drain certificate. These phase distinctions do not prove collector/termination correctness. |
| RF-S06 | [`mem.c:6677--6771`](../../../vendor/gambit/lib/mem.c#L6677), [`3440--3459`](../../../vendor/gambit/lib/mem.c#L3440), [`3270--3306`](../../../vendor/gambit/lib/mem.c#L3270) | Queue publication/signalling, per-phase scan_workers_count initialization and stealing/idle waits. Strong/weak phases index different counters. Count zero alone does not attest every phase, future producer, waiter or cached user. |
| RF-S07 | [`candidate patch:3385--3452`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3385) | Candidate synchronizes queue endpoints, rechecks queues before yielding active-scanner ownership and makes mark_rc per processor. Credit existing C fixes; no new native result or complete root proof is adopted. |
| RF-S08 | [`candidate patch:3160--3234`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160), [`4360--4385`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4360), [`4482--4505`](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L4482) | Donor transfer documents successful join/GC/borrow drain prerequisites, splices still/RC lists and clears donor; callers check join before transfer/cleanup. Receiver discovery and generic live-boundary admission still require separate proof. |
| RF-S09 | [`os_dyn.c:744--785`](../../../vendor/gambit/lib/os_dyn.c#L744), [`c_intf.c:6509--6550`](../../../vendor/gambit/lib/c_intf.c#L6509) | RC-backed C closure stores Scheme proc in data; callback marker allocation precedes data/proc use and retains explicit TODO concerns. A general closure/marker profile is not qualified by this handoff study. |
| RF-S10 | [`mem.c:4736--4750`](../../../vendor/gambit/lib/mem.c#L4736), [`4928--4971`](../../../vendor/gambit/lib/mem.c#L4928), [`683--701`](../../../vendor/gambit/lib/mem.c#L683) | Allocation/scan synchronization setup, destructive VM cleanup ordering and force-free residual RC cleanup. The new facade must impose proven admission/drain preconditions or split this body; a moved destroy line alone is insufficient. |
| RF-S11 | [`setup.c:4572--4606`](../../../vendor/gambit/lib/setup.c#L4572), [`4831--4885`](../../../vendor/gambit/lib/setup.c#L4831), [`os_setup.c:3224--3237`](../../../vendor/gambit/lib/os_setup.c#L3224) | Pstate/VM memory-before-OS cleanup; global cleanup closes interrupts and resizes, then performs pstate/VM cleanup, holding vm_list_mut in multi-VM branch; module order follows. New root/collector drains cannot depend on a disabled service or held registry lock. |

These are actual caller/phase families, not a claim of exhaustive generated
safepoint/FFI reachability. The earlier [root-custody ledger](shared-runtime-root-custody-evidence.md)
and [payload ledger](rc-payload-custody-evidence.md) retain wider object/alias/
registration context. Source physical writes do not themselves prove PA03/PA04.

## Primary Literature and Backend Boundary

| ID | Primary reference / inspected mechanism | Use and limitation |
| --- | --- | --- |
| RF-P01 | [Herlihy and Wing, Linearizability (1990), abstract and sections 1--2](https://cs.brown.edu/people/mph/HerlihyW90/p463-herlihy.pdf) | Separating a pending operation from a legally committed one motivates Permit versus Receipt and the authoritative publication cut. It supplies no implementation, failure-recovery or progress proof for these gates. |
| RF-P02 | [LLVM Garbage Collection Safepoints, Overview & Core Concepts](https://www.llvm.org/docs/Statepoints.html#overview-core-concepts) | Machine-state parsability and runtime coordination are different meanings of safepoint; relocation needs all required pointer copies and their allocation relation. Use for backend adapter obligations, not proof that arbitrary generated C can be transparently statepointed. |
| RF-P03 | [LLVM Garbage Collection, Goals and non-goals](https://www.llvm.org/docs/GarbageCollection.html#goals-and-non-goals) | LLVM provides map/poll/barrier support; runtime collector, root/map registration and other lifecycle services remain language-runtime responsibilities. Thus LLVM can contribute artifacts without issuing this runtime ownership receipt. |
| RF-P04 | [Sivaramakrishnan et al., Retrofitting Parallelism onto OCaml, ICFP 2020, section 4.4](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf) | Separate domain synchronization, parallel forwarding and work sharing are explicit. This supports distinguishing quiescence from relocation-writer work; neither their collector algorithm nor measured results are transferred to Gambit. The paper is evidence identity, not a claim about every current OCaml implementation. |
| RF-P05 | [Zig reference 0.15.1, Lifetime and Ownership](https://ziglang.org/documentation/0.15.1/#Lifetime-and-Ownership) and [errdefer](https://ziglang.org/documentation/0.15.1/#errdefer) | Ownership remains programmer responsibility; private ordinary-error cleanup may be shorter. No runtime root/collector handshake, affine permit, automatic cross-thread custody or postcommit rollback law is provided. |

The LLVM sources were read online for this study; their current wording is not
an installed LLVM/provider ABI qualification. Reference release numbers identify
the inspected documents, not architectural generations. The protocol uses the
selected mechanisms as constraints, with project deductions explicitly marked.

## Evidence Class and Remaining Gap

RTP/RTA/RTO/RTF/RFS describe a proposed runtime protocol. RTPR arguments are
handwritten conditional deductions; RTX rows are logical interleavings, not
model-checker/native witnesses. In particular, Prepared manifest != registered
future root, root receipt != epoch completion, and epoch completion != old
facility retirement. The cost matrix evaluates equally capable C/Zig designs;
no language choice discharges the caller, root, queue or all-exit premises.
