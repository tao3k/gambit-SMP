# Native Layout and Provider Evidence

Reviewed: 2026-10-20. Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
vendor Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Local references bind working-copy bytes. This is source/platform/literature
research only, with no compiler/preprocessor query, native test, performance
measurement or ASCENT execution. Concurrent work is preserved.

## 1. Current Source Premises

| ID | Directly read anchor | Finding / limit |
| --- | --- | --- |
| LP01 | [_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm):471-520 | Map bits, 32-bit chunks, actual internal-frame size and out-of-line selection are explicit Scheme algorithms. LLVM type sizing cannot discover their semantic inputs. |
| LP02 | [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):9208-9269,9300-9321 | Return-kind values, alignment/reserve, bitfield packing and normal/internal map decoding establish a runtime-specific format. Template constants are not a fresh observation of the installed Darwin profile. |
| LP03 | [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):2398-2425,11775-11820 | Fake-word/host representations depend on configured widths; label fields depend on label-value support. A service-host struct is not a complete target ABI manifest. |
| LP04 | [setup.c](../../../vendor/gambit/lib/setup.c):1560-1618 | Baseline fixup marker precedes version/selected-size checks; those checks are explicitly partial. New product readiness needs its real validation/publication protocol. No new runtime failure is reproduced. |
| LP05 | [setup.c](../../../vendor/gambit/lib/setup.c):4066-4176 | Fixup classes distinguish code-relative, Scheme-object, global/primitive-cell and helper values; later architecture-specific patching includes THUMB2. This is not arm64/arm64e admission or an all-symbol relocation scheme. |
| LP06 | [_t-cpu.scm](../../../vendor/gambit/gsc/_t-cpu.scm):161-180 | Assembled bytes/fixup vectors use one direct `compile-file-to-target` packaging call at the inspected site. This is a replacement target, not an executed compiler-process count. |
| LP07 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):1934-2017,2047-2064 | Three inspected out-of-line predicate call sites serve label output, OFD output and counting. They call one shared predicate, not three distinct maintained algorithms. |
| LP08 | [mem.c](../../../vendor/gambit/lib/mem.c):3910-3977 | RA dispatch chooses internal/normal map decoding, adjusts the frame, gets the link and invokes marking. Ordinary object/LLVM struct layout is not root completeness. |

The [HostGraph contract](hostgraph-generation-contract.md), [D1-H edge gates](d1h-edge-admission.md)
and [replacement matrix](gvm-native-replacement-matrix.md) supply project design
premises for one common physical plan and actual caller retirement. Their
existing distinctions between baseline, proposed protocol and native admission
remain intact. None is counted as proof of an implemented Zig backend.

## 2. Primary Provider and Language Premises

These are short reviewed notes, not pinned upstream-byte downloads. LLVM 21.1.0
headers, Zig 0.15.1 source and rolling MLIR/LLVM documentation are separate
reading identities. They do not identify an installed or jointly compatible
provider cohort. Published documentation examples are not tests run here.

**PP01 — Target layout queries exist through C.**
[LLVM 21.1.0 Target.h](https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-21.1.0/llvm/include/llvm-c/Target.h)
exposes `LLVMABISizeOfType`, `LLVMABIAlignmentOfType` and
`LLVMOffsetOfElement`. These answer target-layout questions for supplied IR
types. Our deduction is to reuse them after binding runtime ABI facts; they
cannot infer missing configured C fields or Gambit semantic layouts.
The current generated Target.h page did not return the offset symbol in a
targeted lookup; the versioned header supplies this claim instead.

**PP02 — Object production is a provider operation.**
[LLVM 21.1.0 TargetMachine.h](https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-21.1.0/llvm/include/llvm-c/TargetMachine.h)
exposes target-machine layout creation and file/memory-buffer object emission
from LLVM modules, with explicit errors. Our inference is to delegate selected
ordinary object mechanics; module semantics, supported relocations and runtime
qualification remain. This is not proof every target/capability works.

**PP03 — Required-tail representation is not Zig-only.**
[LLVM 21.1.0 Core.h](https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-21.1.0/llvm/include/llvm-c/Core.h),
`LLVMTailCallKindMustTail` and `LLVMSetTailCallKind`, explicitly supplies a C
entry for mandatory-tail representation. The rolling
[LLVM dialect call attributes](https://mlir.llvm.org/docs/Dialects/LLVM/#llvmcall-llvm-callop)
also name `TailCallKind`. This supports builder feasibility; it proves neither
selected pass preservation nor legal/final mixed GCC/LLVM tail edges.

**PP04 — LLVM layout has a target consistency requirement.**
[LLVM Language Reference, Data Layout](https://llvm.org/docs/LangRef.html#data-layout)
requires the layout to match code-generation expectations. Our design inference
separates target ABI type layout from Gambit frame/GC encoding and rejects a
host-default layout as a cross-target shortcut. No current C/runtime ABI
agreement is established by reading this page.

**PP05 — MLIR lowering and translation are distinct.**
[LLVM IR Target](https://mlir.llvm.org/docs/TargetLLVMIR/), Overview and Translation,
describes conversion to translatable dialects followed by LLVM IR translation
and registered extension support. Our deduction is to retain language lowering
and admission before delegation. Its generic memref conventions are not assumed
to be Gambit's stack or continuation protocol.

**PP06 — There is a C-facing translation boundary.**
[MLIR LLVMIR.h reference](https://mlir.llvm.org/doxygen/LLVMIR_8h.html) and
[CAPI LLVMIR.cpp](https://mlir.llvm.org/doxygen/LLVMIR_8cpp_source.html),
`mlirTranslateModuleToLLVMIR`, show a C-facing conversion from a qualifying MLIR
operation into an LLVM module. The implementation transfers the resulting
module out of its temporary owner. Our inference is that a C or Zig caller
can use a selected matching provider boundary; registration, failure, ownership
and version compatibility still need explicit handling. The attempted versioned
raw MLIR header URLs failed, so no LLVM-21/MLIR-version pair is certified.

**PP07 — Zig CLI recognizes LLVM input artifacts.**
[Zig 0.15.1 main.zig](https://raw.githubusercontent.com/ziglang/zig/0.15.1/src/main.zig):
the input branches around lines 1785 and 1882 include `.ll` and `.bc` in the
source-input path. This is acceptance logic, not proof of an installed compiler
or final target behavior. Our deduction is that a Zig external-driver candidate
need not require generated Zig source or a Zig-written planner. Serialization,
parsing, provider/target support and process costs remain.

**PP08 — Zig layout operators apply to their compilation target.**
[Zig 0.15.1 reference](https://ziglang.org/documentation/0.15.1/), extern struct,
packed struct, alignOf and offsetOf, describes target C-ABI layout and field
coordinates. Our inference is to use explicit target facts in cross-target
services. A host compiled type is not a runtime query of an arbitrary output
profile or proof of Gambit descriptor semantics. Plain private structs remain
unsuitable as a public wire contract.

**PP09 — Custom MLIR semantics have a support cost.**
[ODS](https://mlir.llvm.org/docs/DefiningDialects/Operations/), Generated C++ Code,
describes generated declarations/definitions. The
[MLIR C API](https://mlir.llvm.org/docs/CAPI/) is intentionally minimal and has
no stability guarantee. Our inference is to charge needed dialect/pass support
or a bounded provider island under either implementation language. C API access
alone does not supply Gambit-specific rewrite or effect laws.

**PP10 — Credit declarative dynamic alternatives fairly.**
[IRDL dialect](https://mlir.llvm.org/docs/Dialects/IRDL/), Basics/Principles and
`irdl.c_pred`, describes dialect definitions and dynamic-registration intent,
with an explicit runtime restriction for C++ predicates. This prevents a blanket
claim that every definition requires project C++. It does not establish that
the selected Gambit effects, transformations and lowering fit that domain.
The first attempted IRDL documentation path and raw C-header access failed;
the reachable dialect documentation supports this bounded finding only.

## 3. Paper Connection and Evidence Limits

The previously reviewed [Gambit PVM paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf)
and [functional LLVM backend paper](https://arxiv.org/html/1805.08842v2) remain
context through the [differential paper notes P08/P09](zig-vs-modern-c-evidence.md).
They motivate negotiated semantic/target boundaries and explicit runtime control;
their bytes were not reread in this refinement. No new finding or benchmark is
extracted from them here, and neither paper selects Zig over equivalent C.

LD1-LD4, NP01-NP12, DescriptorDecision, reference partitioning and PR1-PR3 are
project architecture deductions. Their quantitative boundaries count source
sites or proposed shared decisions, not elapsed time, engineering hours or
native success. TG4/TG5 and the existing semantic/ABI/product gates receive no
witness from this reading.
