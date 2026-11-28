# Roots, Blocking and VM Ownership Evidence

Reviewed: 2026-10-20. Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Local working-copy
bindings are distinct from overlays, installed SDKs and historical native receipts.
No runtime edit, implementation, configuration query, model/native test or timing.

## 1. Gambit Direct Reads and Bounded Findings

| ID | Source anchor | Finding / limit |
| --- | --- | --- |
| RG01 | [_back.scm](../../../vendor/gambit/gsc/_back.scm):17-145; [ForeignPlan](foreign-plan-contract.md):sections 1-3 | Existing target negotiation and proposed semantic capture provide issuer boundaries. Complete native root/effect export is not implemented or proved by this reading. |
| RG02 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):4505-4524; [header](../../../vendor/gambit/include/gambit.h.in):6580-6587,6802-6803; [mem.c](../../../vendor/gambit/lib/mem.c):6511-6538 | Existing RA store, W_ALL, select, R_ALL, RA fetch and register/saved scanning are real mechanisms to preserve. Source branch does not prove every host/profile or wait closure. |
| RG03 | [mem.c](../../../vendor/gambit/lib/mem.c):278-306,674-827,3969-3986 | RC storage has refcount/data, list registration/removal and marking of the header data slot. List head is pstate-associated; arbitrary payload bytes are not registered roots. Plain native RC operations are not a cross-thread scanner/mutation protocol. |
| RG04 | [mem.c](../../../vendor/gambit/lib/mem.c):3490-3600,6667-6755,6839-6863 | Moving mark updates root cells; configured parallel scanning exists. Inspected strong phase calls mark_rc in processor-zero branch. This creates an actual applicability audit, not proof that all RC callers are broken or admitted. |
| RG05 | [os_io.c](../../../vendor/gambit/lib/os_io.c):11493-11584 | Current baseline select body stores C arrays, unlocks device queue around device_select, then relocks. No direct collective-GC service call in this body; full transitive/OS/callback reachability remains unresolved. Earlier overlay line ranges are not these baseline ranges. |
| RG06 | [setup.c](../../../vendor/gambit/lib/setup.c):65-91,770-801,1012-1150 | Interrupt sets stack trip and aborts select; synchronous loop executes GC/resize and acknowledges requested operations. Terminating processor execution still services future collective operations. This is not generic native-wait deactivation support. |
| RG07 | [header](../../../vendor/gambit/include/gambit.h.in):8622-8627,8690-8734,6755-6772 | PSTATE getter/setter/binding and erased/explicit arguments depend on configuration. Single-threaded VM selection uses VM0/P0; multi-VM global cells use owning VM glos. Template possibilities are not installed ABI qualification. |
| RG08 | [setup.c](../../../vendor/gambit/lib/setup.c):4665-4705,4773-4865 | Pstate VM association and VM/P0 setup/cleanup exist. Allocation/setup and resize are not arbitrary host attach, parallel eval/load or lifecycle exclusion proof. |
| RG09 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):6511-6562; [setup.c](../../../vendor/gambit/lib/setup.c):3276-3424; [header](../../../vendor/gambit/include/gambit.h.in):10041-10063 | Marker construction/invalidating native return, ___call frames and configured trampoline/nonlocal control are explicit. Source TODO about protecting proc_or_false across allocation is an unresolved effect/root obligation, not a newly reproduced defect. |
| RG10 | [mem.c](../../../vendor/gambit/lib/mem.c):1730-1817; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):1683-1710 | Still/permanent allocation and refcount lifetime restrictions exist; foreign release clears fields before callback and error. Stable address and error return do not imply immortal storage, current aliases or rollback. |
| RG11 | [NJS refinement](njs-executor-storage-cleanup.md):sections 2-6 | Native-only result/custody and Scheme gateway are prior design premises. Worker isolation does not establish runtime ownership or parent wait progress. |
| RG12 | [frame/GC boundary](../../ffi-gc-frame-protocol.md), [host roots](../host-root-registration.md), [entry contracts](../runtime-entry-contracts.md), [participant exit](../participant-exit-publication.md), [VM cells](../vm-cell-ownership-contract.md) | Prior conditional mechanisms/models and source/candidate distinctions constrain composition. Their native/refinement exclusions remain. No historical success/failure or current candidate flag is reissued here. |

The RC registration/scan finding requires a complete profile/caller/transfer
argument. The marker TODO requires tracing actual allocation/effect behavior;
make_vector is a still/permanent constructor with its own restrictions. Neither
finding justifies an immediate patch, current native failure claim or blind
application of an old fix already present in the wrapper.

## 2. Pinned OCaml 5 Source Comparison

Vendor OCaml HEAD `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`; its VERSION file
reads 5.5.1. This local source snapshot and the separately read 5.3 manual below
are different identities, not a claimed installed/coherent reference binary.

| ID | Source | Transferable obligation / boundary |
| --- | --- | --- |
| OC01 | [threads.h](../../../vendor/ocaml/otherlibs/systhreads/caml/threads.h):31-73 | Registration is distinct from execution lock ownership; selected register-in-domain requires a running domain and does not return holding its lock. Switching domain after unregister is unsupported in this source contract. Gambit receives no attachment API by analogy. |
| OC02 | [globroots.c](../../../vendor/ocaml/runtime/globroots.c):28-60,64-100,116-178; [platform.h](../../../vendor/ocaml/runtime/caml/platform.h):80-108 | Root list/classification and mutation coordinate, and root mutex deliberately requires a lock helper safe when domain release is forbidden. No universal release-on-every-lock rule follows. Gambit root/barrier/member algorithms remain separate. |
| OC03 | [callback.c](../../../vendor/ocaml/runtime/callback.c):387-431 | Named registration roots inputs, discards pre-wait string address, reloads from rooted value and updates/registers the stored root. Stable returned slot is not a stable unprotected heap-object pointer or Gambit VM-private cell. |

## 3. Papers and Published Interface Premises

These are upstream reading identities, not pinned downloaded bytes. No published
benchmark or API example was executed or transferred to Gambit.

**RP01.** [Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf),
sections 1.1-1.4 and 4.4, makes unified-runtime/sequential/latency objectives and
C API/collector coupling explicit. Our inference is to compare protocol choices
and full costs before choosing a new collector or native language. Historical
prototype choices/results do not qualify current OCaml/Gambit or prescribe BW2.

**RP02.** [OCaml 5.3 C interface](https://ocaml.org/manual/5.3/intfc.html),
sections 5 and 12, distinguishes rooted mutable slots, root update rules,
thread registration and runtime execution access. Release/reacquire can run
pending callbacks; released code has managed-access restrictions. The design
deduction is separate root/ownership/control states, not an equivalent Gambit
API. Several mechanisms predate OCaml 5.

**RP03.** [OCaml 5.3 parallelism](https://ocaml.org/manual/5.3/parallelism.html),
sections 3-4, describes domain-local allocation, parallel minor/concurrent major
collection and a memory model. This distinguishes real runtime modernization
from NJS worker concurrency. No collector, memory model or throughput guarantee
is imported into Gambit.

**RP04.** [Feeley/Miller PVM paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf),
section 2, supports negotiated semantic/backend object/frame/call boundaries.
V/E/R/S/P, the proposed facade and cost/migration matrices are our architecture,
not a historical ABI specification or a paper endorsement of Zig.

**RP05.** [Zig 0.15.1 reference](https://ziglang.org/documentation/0.15.1/),
error/cleanup, C interoperation and lifetime/ownership sections, supplies private
construction/propagation mechanisms while leaving pointer lifetime to the
programmer. Our inference is bounded adapter/helper value; no affine/root,
collector-participation or nonlocal-control proof follows.

The 2018 native/C interoperability PDF could not be reopened after two attempts
this turn. Earlier paper notes remain historical context; no additional algorithm,
ABI or benchmark claim is based on the failed fetch. No repeated native probe was
used to substitute for missing paper or runtime evidence.

## 4. Evidence-to-Decision and Open Gates

RT01-RT07, BW0-BW3, VE01-VE08, RB01-RB14, KC01-KC08, RR01-RR07 and RM00-RM08
are explicit proposed obligations/accounting units, not implementation counts or
native coverage. Five independent conditions are logical distinctions, not five
implemented locks, allocations or mandatory new token ABIs.

Open: actual configured/profile/caller census; RC owner/scan coverage; root slot
storage/update/withdrawal; full wait/lock/signal/service reachability; marker and
transitive converter effects; legal nonlocal control; host/VM execution and
binding; detached-member/root-carrier refinement; teardown/readers/last return;
mixed backend ABI/frame/GC; and bounded incremental engineering costs. Existing
finite/formal/historical native results are not recomposed by assertion. No
retirement, theory gate, runtime acceptance or performance benefit is issued.

## 5. Focused Owned-Entry Follow-Up

The [OW01-OW14 / OO01-OO06 ledger](owned-callback-wait-evidence.md) traces the RG03/RG04/RG05/RG07/RG09 gaps further. Actual dynamic closure allocation uses the implicit current processor and managed RC data; marker still allocation reaches GC; global closure identity and conditional TLS/binding require independent treatment. Actual wait callers and interrupt/sync service are now distinguished, with virtual-method/lock/checkpoint/OS closure still unresolved. This strengthens the source obligations without reproducing a defect or upgrading any old native receipt.
