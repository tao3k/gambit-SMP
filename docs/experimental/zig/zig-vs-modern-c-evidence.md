# Zig / Modern-C Differential Evidence

Reviewed: 2026-10-20. Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
vendor Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Local SHA bindings retain working-copy bytes. This is source/literature reading
and theoretical comparison only. No compiler, native small test or ASCENT run.

## 1. Current Gambit Source Anchors

| ID | Directly reviewed source | Relevance and limit |
| --- | --- | --- |
| G01 | [_back.scm](../../../vendor/gambit/gsc/_back.scm):17-145 | Target negotiates representation, primitives, calls/frames and interface emission ownership. It does not specify a target-free native emitter. |
| G02 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):338-390 | C target consumes and clears interface lists, builds module products and maps referenced objects. New product types must retain semantic identities and explicit ownership; neither language removes these duties. |
| G03 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):345-448,825-905 | Reserve/check/private-return/root-materialization behavior is part of emission. Scheme completion must expose it; native type machinery is not a substitute. |
| G04 | [_ptree2.scm](../../../vendor/gambit/gsc/_ptree2.scm):2093-2112,2902-2933 | Registry information is cleared and wrappers partition parameter handling. A shared semantic producer is needed under C and Zig alike. |
| G05 | [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):9958-10002; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):1683-1711,6511-6550 | Cleanup has configured C++/C forms and setjmp/exception branches; release invalidates before callback; marker constructor retains a rooting TODO. Neither a Zig error union nor defer changes those protocols. |
| G06 | [setup.c](../../../vendor/gambit/lib/setup.c):1592-1618 | Module version and several structure sizes are checked. They are partial compatibility checks, not complete ABI/layout/control proof. Imported types do not erase runtime admission. |
| G07 | [os_dyn.c](../../../vendor/gambit/lib/os_dyn.c):408-454 | Dynamic loader handles are retained and cleaned under configured platform/unload branches. Native resource ownership is real; lexical cleanup of each helper alone does not establish module lifetime. |
| G08 | [_gsclib.scm](../../../vendor/gambit/gsc/_gsclib.scm):498-593; [gambuild-C.unix.in](../../../vendor/gambit/bin/gambuild-C.unix.in):238-283,331-410 | Existing request/configuration/command assembly has concrete owners. One resolver and typed argv can be implemented with C as well; a new Zig build layer must replace named support rather than duplicate it. |

G08 was already studied in the source-bound native-request design. Its source
anchors are reread for this differential study; no configured script or shell
command is executed. The same caution applies to macro branches in G05.

## 2. Primary Language / Library / Platform Sources

These are reviewed local notes. Their hashes bind this note, not upstream bytes.
Versioned source URLs identify intended versions but no downloaded source-byte
snapshot is claimed. Rolling documentation and primary paper access were read
on 2026-10-20. Upstream examples/test transcripts are published evidence, not
experiments performed here.

### P01 — Bounded Zig Language Mechanisms

[Zig 0.15.1 reference](https://ziglang.org/documentation/0.15.1/), Tagged union,
Exhaustive Switching, Error Union Type, defer, comptime and Lifetime/Ownership.
Payload capture and exhaustive branches support typed native dispatch;
compile-time types support native specialization; explicit success/error values
and lexical cleanup support ordinary-return code. Lifetime remains the
programmer's responsibility. These features motivate ZC01-ZC03. Our deductions
apply to the selected safe typed style, not arbitrary casts, raw imports,
foreign escapes, general memory safety or measured maintenance savings.

### P02 — A Concrete Allocator Interface, Not Automatic Ownership

[Zig 0.15.1 Allocator source](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/mem/Allocator.zig),
`ptr`, `vtable`, allocation/resize/remap/free operations. The library exposes
reusable native allocation mechanics with explicit dispatch. Our inference is
that Z1 can reuse such support when it replaces real project work. B1-C can
use an equivalent context/vtable and existing libraries. No performance,
ownership-proof or Scheme-root conclusion follows from the interface.

### P03 — Credit the C Alternative Its Existing Mechanisms

[WG14 N1570, C11 committee draft](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)
initially returned indexed declaration/static-assert material, but targeted
section rereads timed out. The accessible primary
[N1441 generic-selection proposal](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1441.htm)
and [WG14 C11/C17 issue 0481](https://open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0481.html)
independently describe generic selection; the issue also documents historical
qualification/array interpretation problems. Our B1-C design credits C generic
selection, generated/opaque APIs and static checks while qualifying its actual
compiler policy. Historical issues do not prove current GCC/Clang behavior.
No claim of a complete N1570 reread or installed profile support is made. The
newer [N3096 draft](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n3096.pdf)
also failed to open; no C23-specific comparison is inferred from failed access.

### P04 — C Enum Coverage Can Be Diagnosed

[GCC warning options](https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html),
`-Wswitch-enum` and `-Werror`; [Clang diagnostic reference](https://clang.llvm.org/docs/DiagnosticsReference.html),
`-Wswitch-enum`. Both primary documents describe enum-switch diagnostics.
Our inference is that B1-C can require a strict coverage policy in its managed
profile. Therefore enum exhaustiveness alone is not a Zig-only argument.
These rolling pages are not observations of the configured compiler flags or
guarantees about tag/payload correctness, extensions or every future compiler.

### P05 — Native Construction APIs Exist but Do Not Retire Owners Automatically

[Zig 0.15.1 Build source](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/Build.zig),
native build-step and `addTranslateC` entry points, supplies actual construction
mechanisms. Our inference is limited: a selected native component may reuse
them. Custom dependency closure, effective configuration, artifact identity,
retained Bazel coordination and caller retirement remain project obligations.
No implicit second build authority or cache/performance benefit is assumed.

### P06 — Charge Version and Backend Burdens

[Zig 0.16.0 release notes](https://ziglang.org/download/0.16.0/release-notes.html),
@cImport Moving to Build System, Incremental Compilation, aarch64 Backend and
LLVM 21: the notes record C-import evolution, incremental limitations and
backend/regression work. Our inference is to charge language/library/toolchain
support and isolate provider identities. These facts concern that release,
not every later release or a local installed binary. They do not forecast
Gambit build/runtime performance.

### P07 — MLIR Access Is Shared With C

[MLIR C API](https://mlir.llvm.org/docs/CAPI/), Design, Scope and Ownership,
provides a C-interoperable entry surface and explicitly does not guarantee
stability. B1-C may access it directly or use a bounded C++ service where
needed. Our inference is that “can call MLIR” is not positive differential
evidence for Zig; only an identified reduction in provider adaptation could be.

### P08 — Gambit's Paper Motivates the Contract, Not Zig Selection

[Feeley and Miller, A Parallel Virtual Machine for Efficient Scheme Compilation
(1990)](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf),
sections 1-2, especially 2.3-2.5, read as extracted PDF text. Bidirectional target
information covers calling, closure and primitive choices while the frontend
uses logical objects/frames/arguments. Our inference is to preserve negotiated
semantic authority while modernizing native construction. This supports B1-C
and Z1 equally; it supplies no modern language preference, current ABI or cost
bound. No historical benchmark number is transferred.

### P09 — A Functional LLVM Backend Still Owns Runtime Conventions

[Farvardin and Reppy, Compiling with Continuations and LLVM, v2](https://arxiv.org/html/1805.08842v2),
sections 2.2-3.5, read in HTML. The paper describes explicit allocation checks,
calling/tail and continuation/GC integration for PML/Manticore. Our inference
is that LLVM mechanics can be delegated while language/runtime conventions
remain local. Its representation, old API constraints and performance results
are not transferred to Gambit or treated as a Zig advantage.

### P10 — Paper Access Limit Retained

The [author-hosted 2018 Gambit C/native tail-call paper](https://www.iro.umontreal.ca/~feeley/papers/HuberdeauFeeleySFPW18.pdf)
again returned access denied. Prior notes remain historical context. No new
claim is extracted from that failed access; current Gambit source and P08/P09
are the explicit premises used here. A failed attempt to open an upstream
allocator implementation or compiler-error example likewise supplies no finding.

### P11 — Compile-Time Reuse Has a Compilation Budget

[Zig 0.15.1 meta source](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/meta.zig),
`stringToEnum` and its comment about compile-time map construction, supplies a
concrete type-parameterized native helper and an explicit compilation-cost
caveat. This supports considering helper reuse and charging its compilation
burden. It is not a Gambit timing result or a reason to assume all comptime
specialization is cheap.

## 3. Argument Coverage and Remaining Certificates

| Item | Evidence / deduction | Remaining boundary |
| --- | --- | --- |
| Same-capability C counterdesign | BC01-BC08 plus P03/P04 | Proposed design; not implemented or qualified |
| Typed private variants | P01 plus G01-G04; local L1 reasoning | Scheme meaning, wire imports, casts and compiler trust remain; no cost bound inferred |
| Ordinary cleanup / typed results | P01 plus G05/G07; local L2 reasoning | Only contained ordinary returns; no asynchronous or nonlocal cleanup guarantee |
| Native helper/library reuse | P01/P02/P05 plus G02-G04/G07 | A named B1-C support implementation must actually retire; no default generator/library deletion |
| Neutral/rejected broad credit | G05/G08 and P04/P06-P09 | C API, generic LLVM, no-GC and build slogans do not prove Zig increment |
| Aggregate positive sign | Paired cost-certificate conditions in the design | TG4 actual support retirement and TG5 justified bounds/accepted budget remain open |

No paper directly proves Zig cheaper for this Gambit refactor. Theoretical
support consists of reviewed source needs, primary language/library mechanisms,
a fair counterdesign and explicit deductions/counterexamples. Neither reference
counts nor conditional inequalities are a completed net-benefit certificate.

## 4. Source-to-Support Follow-Through

The [support/change certificate](native-support-change-certificate.md) follows
actual label and module-product production, rather than assuming a handwritten
C implementation exists. These additional anchors were read directly at the
same research/vendor HEADs above; no generated C or native tool was executed.

| ID | Reviewed source | Finding / boundary |
| --- | --- | --- |
| G09 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):276-301 | Scheme produces proc and return payloads, including normal/task/internal kinds, and stores class/info in mutable label vectors. This establishes semantic variants, not required native residency. |
| G10 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):648-783,1137-1211 | Scheme handles object references, ordered/identity tables, procedure queues and module counts/sections. These are existing Scheme decisions, not a census of C constructors Zig would remove. |
| G11 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):1934-2017,2047-2064 | Scheme chooses proc/return macro forms, IFD/OFD selection, separate OFD count and output traversals. Consolidating the physical decision is a shared redesign opportunity, not evidence of an existing mismatch. The return-kind else maps to normal; accepted-domain changes need producer closure. |
| G12 | [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):9224-9267,11839-11875 | C macros perform frame alignment, descriptor/GC-map packing and label record construction. New native packing must retain decoder/profile correspondence; tagged source types do not establish binary layout. |
| G13 | [_t-cpu.scm](../../../vendor/gambit/gsc/_t-cpu.scm):161-180 | Assembled code/fixups are packaged through the C backend. Direct packaging removes a selected route detour in C or Zig; no measured saving follows. |
| G14 | [HostGraph contract](hostgraph-generation-contract.md):sections 2-4 | Proposed G4 freeze, common G5 plan, FrameLayout authority and bounded amendment protocol require shared physical decisions. They do not prescribe a resident native copy of every semantic variant. This is project design evidence, not upstream implementation. |

Primary sources P01, P04 and P08 were revisited for this refinement. The
[Zig 0.15.1 reference](https://ziglang.org/documentation/0.15.1/#Tagged-union)
supports selected typed construction/capture and ordinary cleanup mechanisms;
ownership still remains explicit. The
[GCC enum warning policy](https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-Wswitch-enum)
supports crediting strict C enum coverage. The
[1990 Gambit paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf),
section 2, supports negotiated logical/backend boundaries. None establishes
engineering cost or a required native sum. WG14 N1570 again failed to open;
there is no new C-standard finding from that attempt. These are reviewed notes,
not newly pinned upstream bytes or published experiments reproduced locally.

The constructive result is conditional and local: in the specified resident
LP-C/LP-Z pair, selected Zig language operations make SC-ADT-C's project
association implementation unnecessary. The streaming counterdesign and a
stable C generator defeat a universal cost/necessity inference. The cleanup
example demonstrates no whole support-family retirement. Both findings are
architecture deductions from the paired designs, not source observations that
existing helpers were removed. TG4 has a scoped mechanism result; its global
obligation and TG5 remain open, with no witness issued.
