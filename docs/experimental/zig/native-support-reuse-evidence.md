# Native Support Reuse and Handoff Evidence

Reviewed: 2026-10-20. Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
vendor Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Working-copy source bytes are bound in the research references. No compiler,
native test, performance measurement or ASCENT evaluation was run.

## 1. Source Premises

| ID | Direct reading | Finding / limit |
| --- | --- | --- |
| RE01 | [_utils.scm](../../../vendor/gambit/gsc/_utils.scm):263-332 | Scheme stretchable vector stores backing vector/default/length and grows/copies storage. It is existing frontend support, not a native C generic container. |
| RE02 | [_utils.scm](../../../vendor/gambit/gsc/_utils.scm):340-371 | Ordered table combines a Scheme table with indexed storage/counter; caller chooses equality. Reusing only a native container does not preserve that equality or ownership contract. |
| RE03 | [_utils.scm](../../../vendor/gambit/gsc/_utils.scm):854-881 | Queue operations use Scheme pairs/mutation. Their existence does not establish an independent native job queue requirement. |
| RE04 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):429-444,648-783 | Object/procedure discovery uses Scheme tables/queues with identity/numeric policies. Keep semantic identity issuance here; native address maps are not equivalent. |
| RE05 | [_gvm.scm](../../../vendor/gambit/gsc/_gvm.scm):194-239; [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):276-301 | Existing vector accessors and proc/return payload producers are Scheme interfaces. They do not demonstrate an already reusable C ADT emitter. |
| RE06 | [HostGraph contract](hostgraph-generation-contract.md):149-178,193-227 | Proposed deterministic ID assignment and semantic/physical split motivate a dense snapshot-table refinement. Density/validation and transport are new design, not current ABI facts. |
| RE07 | [c_intf.c](../../../vendor/gambit/lib/c_intf.c):1897-1935,2106-2136,4351-4456,5170-5194 | Integer argument conversion can reject; integer/pointer results have immediate/allocating branches. Per-record native target calls do not imply cheap or GC-free whole boundaries. No configured branch or timing is claimed. |
| RE08 | [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):9958-10002; [ForeignPlan](foreign-plan-contract.md):sections 3-6 | Configured cleanup/nonlocal transfer and stage-specific conversion/lifetime duties constrain service calls. Project status-return/copy policies are design restrictions, not admitted runtime capabilities. |

RE01-RE05 establish reusable **Scheme** support only. No searched absence is
promoted to an exhaustive repository-wide claim that C libraries/generators do
not exist. C reuse remains an option with integration/support cost; Zig reuse
is not compared against an assumption that all C collections must be handwritten.

## 2. Primary Library, Language and Paper Premises

The following short notes bind reviewed local interpretations; upstream bytes
were not downloaded/pinned. Versioned URLs identify the reviewed release,
not the current installed toolchain. Published example tests were not run here.

**RP01 — Container reuse with explicit storage rules.**
[Zig 0.15.1 array_list.zig](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/array_list.zig),
`Aligned`, invalidation comments, `deinit` and `toOwnedSlice`: reusable typed
storage exists, growth can invalidate pointers, and ownership transfer is
explicit. Our deduction is to hide container representation and use stable IDs;
there is no automatic Scheme-root or whole-lifetime guarantee.

**RP02 — Allocator reuse has a specific boundary.**
[Zig 0.15.1 Allocator.zig](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/mem/Allocator.zig),
`ptr`, `vtable`, allocation/free methods: explicit native allocation dispatch
can be reused. It supplies neither semantic equality nor GC participation.
An equivalent C context/vtable or selected library remains a valid counterdesign.

**RP03 — Version work is concrete, frequency is unknown.**
[Zig 0.16.0 release notes](https://ziglang.org/download/0.16.0/release-notes.html),
`@cImport Moving to Build System`, filesystem/process and I/O migration:
the notes describe C translation moving toward build configuration and concrete
I/O/process API changes. Our inference is to isolate version-specific adapters
and charge upgrades. These examples do not establish annual cost, future
breakage, current installed support or a need to use every affected subsystem.
The attempted `ArrayList` lookup in those notes returned no match; no additional
container-migration assertion is extracted from that search.

**RP04 — Provider ownership remains outside the facade.**
[MLIR C API](https://mlir.llvm.org/docs/CAPI/), Ownership Model and Stability:
creation/destruction and ownership-transfer conventions are explicit, while
stability is not guaranteed. A facade must preserve actual ownership and version
capabilities. It cannot imply that Zig removes provider lifetime work or that
private host containers control MLIR allocation.

**RP05 — Negotiated logical/backend separation.**
[Feeley and Miller (1990), section 2](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf)
describes bidirectional calling/closure/primitive target information and logical
objects/slots. Our architecture deduction preserves Scheme meaning while
delegating physical construction. The paper supplies neither the new snapshot
format nor a C/Zig cost comparison; historical timings are not transferred.

## 3. What Is Deduced, Not Observed

The SR01-SR10 dispositions, dense-ID native lookup reduction, HT1-HT4 separation,
handoff state machine, successful crossing formulas and version blast-radius
rules are project design deductions. Each has explicit premises and limits in
the [design](native-support-reuse-and-handoff.md). They are not observations of
running service calls, verified serializers or retired runtime routes.

The supported decision is to stop counting preserved Scheme support and shared
transport changes as Zig-specific savings in the label slice. A broader positive
net-benefit claim needs another necessary support component with a justified
differential cost domain. No architecture requirement receives a witness from
source/reference bookkeeping alone.
