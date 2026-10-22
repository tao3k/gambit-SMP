# Zig and MLIR Feasibility for Gambit

Research date: 2026-10-19. Status: architecture assessment; no implementation,
benchmark, native qualification or change to the SMP milestone.

The current research direction is the broader
[Zig system engineering architecture](zig-system-engineering-architecture.md),
with an [annotated literature review](zig-system-engineering-sources.md).
Zig's long-term role is studied before choosing an MLIR integration or a
validation workload. This note retains the narrower backend assessment.

## Decision

Zig is a plausible C-toolchain driver and MLIR C-ABI client. Neither role
automatically translates Gambit semantics into MLIR. Separate three proposals:

| Proposal | Assessment | Required evidence |
| --- | --- | --- |
| Compile existing generated C using Zig's C toolchain | Toolchain integration option; compatibility and speed unknown | Matched source/configuration, compile/link/load/execute results, cold and warm timings |
| Compile selected typed numeric kernels through MLIR | Plausible incremental research direction | Explicit subset, independent semantic oracle, safe runtime boundary, measured total cost |
| Replace the general Gambit backend with MLIR through Zig | Substantial compiler/runtime project | Complete lowering and runtime contracts, bootstrap and full supported semantic/native coverage |

There is no evidence here for negligible engineering cost, automatic GPU
acceleration, elimination of C compilation cost, or inherent superiority over
C or Rust. Define the engineering layer's responsibilities independently of
the choice of compiler service.

## Local Source and Evidence

The research checkout HEAD observed was
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`, with existing local changes.
The vendor Gambit HEAD was `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
These identities do not identify a qualified current runtime overlay.

- `vendor/gambit/gsc/_back.scm:17-65` describes target representations,
  GVM instruction translation, initialization and the `dump` interface. Its
  `c-intf` argument includes embedded C declarations, procedures and initializers.
- `vendor/gambit/gsc/_t-c-1.scm:249,337` registers and implements the C
  target's dump procedure. This is a concrete backend boundary to investigate,
  not a claim that a second target can reuse every target-specific decision.
- `vendor/gambit/include/gambit.h.in:6801-6815` defines cached-state
  read/write macros and host procedure entry with processor state.
- [Compiler cost boundaries](../../compiler-cost-boundaries.md) records an
  earlier diagnostic with 30.818 seconds of Scheme-to-C and 152,462 generated
  C lines; C-to-module exhausted the remaining budget after 59.250 seconds.
  Execution did not begin. This is a historical DENY, not a current benchmark
  or evidence that Zig would improve the result.
- [C backend compatibility](../c-backend-compatibility.md) records the existing
  architectural objective of preserving portable generated C and supported
  continuation/FFI semantics. An optional MLIR experiment can coexist with it;
  a general replacement would change that objective.
- [Foreign call and moving GC boundary](../../ffi-gc-frame-protocol.md) identifies
  writeback, return-address rooting and relocation reload obligations. Its
  finite model and extracted-source tests do not establish whole-runtime safety.

The registered `trajectory clues` interface was consulted. Initial factor
queries exposed observation vocabulary but did not identify compiler/MLIR
claims; expansion using these document paths returned unknown claims. Unknown
identifiers establish no absence of repository evidence. The documents and
source above were inspected directly for this assessment.

## What Zig Changes

The Zig build system can orchestrate generated files, C compilation and cached
artifacts. A cache hit avoids repeated work only when all semantic inputs are
represented correctly. It does not remove parsing, macro expansion, optimization
and code generation for a cold or invalidated generated-C unit. Replacing a
build driver and changing the C compiler are separate experimental variables.

Compiler selection and build-system migration need distinct research decisions.
Preserve target, SDK, headers, defines, runtime generation, threading
configuration and effective optimization policy. GCC-only options or extensions
need explicit handling; successful compilation alone does not qualify modules.
Cross compilation additionally needs matching target runtime libraries and
platform dependencies.

Calling the MLIR C API from Zig is feasible through a C ABI. The client still
owns error handling, context/module lifetime and borrowed handle validity.
Zig's allocator does not control all allocations made inside MLIR. Importing
headers supplies declarations, not a Scheme compiler or conversion pass.
Compiling C and translating C constructs into Zig are different facilities.

## Where MLIR Should Enter

Candidate general pipeline:

```text
Scheme frontend -> audited GVM/target boundary -> explicit export format
  -> MLIR construction (Zig client optional) -> semantic lowering
  -> LLVM/object -> matched Gambit runtime
```

Keep the existing C target alongside any experimental target. Audit which
representation choices have already occurred before the export boundary.
GVM offers a source-backed candidate, but may already be too low-level for
recovering rich tensor or affine-loop structure. Typed kernels may need an
earlier, explicitly annotated representation.

The alternative `generated C -> C parser/importer -> MLIR` needs a real C
frontend. Existing work such as Polygeist makes it a valid route to compare;
see the literature review. Zig's C compilation path does not itself produce
high-level MLIR. The available structure and Scheme-level facts in Gambit's
generated C still require analysis. Additional passes cannot be assumed to
reconstruct missing facts.

MLIR's C API supports core IR construction and passes but is deliberately
low-level and has no stability guarantee. Existing dialects can be used through
available interfaces; richer custom semantics, verifiers, effects and lowering
may require extensions, commonly using TableGen/C++. Dynamic dialect mechanisms
do not remove the need to define and implement those semantics. Textual/bytecode
export and in-process construction are separate architecture choices.

## Semantic Obligations

A general backend must preserve proper tail calls, closure environments,
multiple values, numeric overflow/promotion, exceptions and continuations.
It must also specify movable object representation, roots at safepoints,
return addresses, stack maps/descriptors, relocation reloads, foreign callback
reentry, module loading and processor/VM ownership. MLIR verification checks
declared IR constraints; it does not independently prove Gambit equivalence.
Existing SMP protocol failures remain separate obligations.

Typed leaf kernels reduce this surface. Such a restricted domain can operate
on explicit unboxed numeric buffers, with defined bounds, aliasing and floating
point policy. Copied storage and explicitly stable buffer protocols are possible
lifetime designs; never retain an unprotected pointer into a movable heap.
Specify whether allocation, callbacks, polling, exceptions and continuation
capture are allowed. A long-running kernel still needs a defined interruption
and runtime participation policy.

GPU lowering additionally needs device-compatible operations, memory transfer,
buffer lifetimes and launch synchronization. General Scheme continuations,
dynamic objects and the CPU runtime do not acquire device implementations by
being represented in MLIR.

## Research before Implementation

The earlier suggestion to start with minimal experiments is superseded by the
user's architecture-first direction. The current work compares responsibilities,
native construction and runtime integration, semantic export choices, service
placement, deployment profiles and maintenance economics. The broader study's
research-decision table owns that agenda.

Any later implementation proposal must distinguish semantic correctness,
artifact/runtime compatibility and measured performance. Bootstrap and complete
native SMP acceptance remain separate from a bridge or kernel result. No
experiment is selected or scheduled by this note.

Neither `zig` nor `mlir-opt` was found on the raw shell PATH during this review.
Project-specific environments were not inventoried, and no toolchain was
installed or downstream compilation attempted. Compatibility and performance
remain unmeasured.

## Primary References

- [Zig build system](https://ziglang.org/learn/build-system/): build graph,
  artifacts and caching; this is capability documentation, not a Gambit benchmark.
- [Zig language documentation](https://ziglang.org/documentation/master/#C):
  C ABI primitives, target/flag consistency and C translation limitations.
- [MLIR C API](https://mlir.llvm.org/docs/CAPI/): deliberately minimal API,
  opaque handles, ownership conventions and lack of stability guarantees.
- [Defining MLIR dialects](https://mlir.llvm.org/docs/DefiningDialects/):
  TableGen/C++ definitions and extensible/dynamic dialect mechanisms.

These are live documentation references checked on the research date, not pinned
dependency versions. An executable experiment must record exact tool revisions.
