# Shared Runtime Proof: Source, Literature and Limits

Reviewed: 2026-10-20. Research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Working-source digests bind the
selected seams in the tracking record. No installed-profile/native qualification.

## Selected Source Reads

| ID | Exact source scope | Evidence for the argument and limit |
| --- | --- | --- |
| PF-S01 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):344-455; [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):85-149 | Heap checks call frame materialization; live/closed-dependent dirty slots/registers are written. Supports final safe-point descriptors rather than request-time fixed locations. Does not prove all target/FFI/checkpoint exports complete. |
| PF-S02 | [mem.c](../../../vendor/gambit/lib/mem.c):3817-3862,3910-3970,6511-6541,6813-6890,6938-7084 | Actual frame-map decoding, register/saved/global/continuation roots, separate strong/weak phases and collector barriers. Contributor completeness exceeds parked RC handles. Existing frame decoding is not automatically a canonical flat root-location index. |
| PF-S03 | [mem.c](../../../vendor/gambit/lib/mem.c):6573-6667 | VM roots and sym/key tables are distinct; global roots are partitioned using processor id/count, by sublists or array intervals. A separate GC worker team needs its own complete root assignment; unchanged processor-count dispatch cannot be assumed correct. |
| PF-S04 | [setup.c](../../../vendor/gambit/lib/setup.c):544-719,1014-1110 | Tree collective and synchronized count/operation handling remain tied to processor membership. G/request/member redesign must preserve operation semantics; the abstract proof does not qualify current C synchronization. |
| PF-S05 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6511-6570; [setup.c](../../../vendor/gambit/lib/setup.c):3276-3424 | Marker allocation/rooting and matching foreign return/unwind expose pre-allocation and all-exit obligations. No generic epoch token supplies those roots or control semantics. |
| PF-S06 | [candidate patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch):3160-3234,3439-3465,4352-4395; [prior evidence](shared-runtime-contract-evidence.md):RP-S11 | Successful joined RC/still transfer and root-phase repairs are credited. Pending storage and safe enumeration remain separate. No paper trace is a reproduced fault in that candidate. |

## Primary Readings

| ID | Reading / inspected scope | Supported distinction |
| --- | --- | --- |
| PF-P01 | [Herlihy and Wing, Linearizability, 1990](https://www.cs.cmu.edu/~wing/publications/HerlihyWing90.pdf), sections 1-2 and abstract-specification discussion | Concurrent histories can be related to a legal abstract specification. This motivates a G refinement obligation; it does not prove our mutex/atomics or provide an implementation progress guarantee. |
| PF-P02 | [LLVM statepoints](https://llvm.org/docs/Statepoints.html), explicit relocation and Base & Derived Pointers | Potentially moved SSA values require relocated uses; derived references carry base relationships. Epoch equality alone cannot replace alias/reload completeness. No selected LLVM/target adapter is qualified. |
| PF-P03 | [LLVM atomics guide](https://llvm.org/docs/Atomics.html), atomic/volatile and Acquire/Release | Memory visibility needs real matching synchronization. Abstract case ordering is not a weak-memory implementation proof. |
| PF-P04 | [OCaml 5.3 C interface](https://ocaml.org/manual/5.3/intfc.html), section 22.12.2 | Released native intervals cannot access OCaml data; ownership acquire/release may invoke callbacks or raise. Establish an effect frontier rather than trust a function name. Different runtime and API, not an equivalence claim. |
| PF-P05 | [Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf), section 4.4 | Minor collection synchronizes mutators before movement, with separate promotion/work-sharing concerns. Supports distinguishing acknowledgement, movement and worker mechanics; no performance result is transferred. |
| PF-P06 | [ORCv2](https://llvm.org/docs/ORCv2.html), How to remove code | Provider resource release is a mechanism. The runtime must supply actual code/continuation/map/native-return last-use closure; no ORC operation proves PA05. |

Public rolling provider pages are read-time references, not pinned installed
tool/library/target artifacts. The named publication/manual identities remain
separate from current local runtime builds. Selected reads, not whole-paper or
whole-source verification. No quoted benchmark or model/prover execution is used.

## What Was Derived Here

The split between contributor enrollment and final root-cut closure, transition
relation, PA/PT/PX proof units, resource-indexed Users(r) and economic countermodels
are project reasoning. Their citations support mechanisms and constraints, not
the truth of those new theorems for existing code. PX traces are logical
counterexamples to insufficient design rules; they are not tool-generated or
native execution receipts. PT01-PT05 retain explicit unproved premises; PT06
and PT07 deny unconditional progress/economic conclusions.

The previous SysML root-cut predicate and global reclamation condition were
insufficient projections. The current draft expresses separate contributor/root
cut predicates and a target-resource dependency condition. Those fields still
need independent interpretation/refinement; assigning them true is not evidence.
