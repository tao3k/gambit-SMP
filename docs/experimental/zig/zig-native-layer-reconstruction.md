# Reconstructing Gambit's Native Layer in Zig

Reviewed: 2026-10-20. Design hypothesis, not an implemented rewrite, admitted
backend/runtime, performance result or positive-net conclusion. This extends
the [real map design](map-scheme-zig-design.md) and
[fully costed comparison](map-scheme-zig-cost-matrix.md).
The user proposes complete native-layer reconstruction, beyond a build bridge.

**Position: it is coherent to retain Gambit's Scheme compiler and language
semantics while reconstructing its native generation and runtime implementation
in Zig, with a deliberately supported C-facing interface and C ecosystem.
Zig's lack of automatic GC does not remove Gambit's GC. C also has no automatic
GC; Gambit's existing collector is implemented in C.**

## Scope, Responsibility and End State

FN01. The intended destination can include all Gambit-owned native responsibilities:
native product generation; object/frame layout; allocation/GC implementation;
VM/processor state and scheduling support; FFI/native entry; module setup;
OS/device/resource lifecycle. This is a direct reconstruction candidate, not
a prerequisite modern-C rewrite followed by another Zig rewrite.
Scheme owns compiler/language meaning and algorithm specifications; Zig may
own their native implementation. Keeping GC semantics Gambit-owned does **not**
require keeping its implementation in C forever.

Existing source establishes these responsibilities, not a completed Zig port:
the [map source ledger](map-scheme-zig-evidence.md) covers generic call, closure,
control, roots, maps and modules. Additional actual anchors are
[GC entry](../../../vendor/gambit/lib/mem.c#L6938), lines 6938–6977;
[VM lifecycle](../../../vendor/gambit/lib/setup.c#L4773), 4773–4828;
[exported runtime services](../../../vendor/gambit/lib/setup.c#L5898), 5898–5918
and 5950–5977; [processor fields](../../../vendor/gambit/include/gambit.h.in#L11607),
11607–11644; [VM fields](../../../vendor/gambit/include/gambit.h.in#L11947),
11947–11980. PSTATE currently combines hp/fp/registers/root storage and handlers;
VM state combines processors, OS/memory state and VM globals. Their separation
and replacement need real ownership contracts, not field-for-field renaming.

FN02. “Complete” describes responsibility closure and deletion of redundant
Gambit-owned legacy mechanisms. It does not require rewriting external C
libraries, libc or user C source into Zig. A small target-specific assembly/C
adapter is an explicit retained dependency if needed, with its cost and users
recorded; it cannot silently retain the old runtime behind a new facade.
Removing every such adapter is a separate target-support constraint and must
be costed. The scheme compiler need not be rewritten in Zig to emit Zig hosts.

![Full native reconstruction with managed and native memory](zig-native-runtime-reconstruction.svg)
[D2 source](zig-native-runtime-reconstruction.d2).

## The GC Does Not Disappear

FN03. Separate language implementation from language memory management:

| Domain | Allocation/lifetime authority after reconstruction | Critical boundary |
| --- | --- | --- |
| Scheme pairs, vectors, closures, continuation data and other managed objects | Gambit managed heap and admitted collector, whose implementation can be Zig | Allocation, root scanning, relocation, barriers and safe points remain explicit runtime work |
| Native compiler buffers, product tables, task/resource records and OS wrappers | Zig allocator and explicit ownership/cleanup | A native buffer containing Scheme references still needs the admitted root/handle protocol; allocator ownership alone does not make it visible to GC |
| Native code, frame maps and module metadata referenced by continuations/callbacks | Explicit image/VM binding and user-lifetime protocol | Holding a managed continuation must retain the native metadata/code it can resume through |
| Foreign C-owned memory and callbacks | Declared C-facing ownership, blocking/reentry and finalization contract | Scheme references, thread/VM ownership and nonlocal control cannot be inferred from a C pointer |

FN04. Three different changes require separate decisions:
(1) reimplement the selected collector algorithm in Zig while preserving its
admitted behavior and representation; (2) replace implicit GC/compiler/FFI/VM
couplings by explicit contracts; (3) change collector algorithms, generation/
region policy, concurrent/parallel phases or worker organization. Only the first
follows from a complete C-to-Zig implementation migration. The second is a
central modernization objective. The third needs its own scientific motivation
and correctness/cost argument. Zig supplies neither an automatic moving GC nor
automatic participation of foreign threads.

Existing [active/captured frame scanning](../../../vendor/gambit/lib/mem.c#L3667),
3667–3805, 3900–3955 and 4096–4148, and
[root arrays](../../../vendor/gambit/lib/mem.c#L6511), 6511–6538, show concrete work
that must be retained or jointly replaced. Source-compatible structure layout
alone does not prove the GC edge. [LLVM relocation rules](https://www.llvm.org/docs/Statepoints.html)
reinforce the need for valid post-safe-point references.
[OCaml parallelization research](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf),
§§1.1–1.3 and 4.4, illustrates how collector and C-interface choices constrain
each other; it does not select Gambit's collector algorithm or implementation language.

## Retaining C's Useful Capabilities

FN05. The C-facing contract must be declared separately from the internal Scheme
host/GC ABI. The
[Zig reference](https://ziglang.org/documentation/0.15.1/#Exporting-a-C-Library)
documents C ABI exports, C-compatible aggregate layouts and object-file mixing.
These mechanisms support a C-friendly runtime implemented in Zig.
They do not prove compatibility of all old macros, structures, nonlocal jumps
or compiler targets. Ordinary C ABI compliance alone cannot encode Scheme
closure/continuation/root semantics.

| ID | Capability / responsibility | Concrete reconstruction | What needs independent admission |
| --- | --- | --- | --- |
| NR01 | Link C libraries and export a callable runtime | C-compatible exported functions/types, headers, objects and native error/ownership contracts | Actual target ABI, link/load behavior, aggregate/variadic cases and ownership |
| NR02 | Preserve Scheme-to-C and C-to-Scheme FFI | Generated argument/result conversion plus roots, owner state, blocking and reentry | All actual conversion/callback/error/cleanup users; not a new wrapper per ordinary Scheme call |
| NR03 | Native object and GC machinery | Zig implementation of tagged words, headers, allocation, scanners, relocation and collector coordination | Whole representation/root/barrier/check/helper/failure domain; no Zig-local-root assumption |
| NR04 | Frames, closures and continuation | Common explicit call/frame/point product and admitted capture/restore/dynamic-state runtime | Proper tail and non-tail edges, multi-shot replay, value protocol, saved roots and code users |
| NR05 | VM/processors and multi-core behavior | Explicit context/collector/resource owners and participation/drain contracts | Actual scheduling/GC/resize/cancellation/stop interleavings; language alone does not solve races |
| NR06 | Modules, products and toolchains | One typed image/module/native product source with qualified C and native consumers | Unique globals, init/cycles/reentry, target profile, frame/role binding and lifetime |
| NR07 | Existing user C source and embedded C regions | Support declared C inputs through a C compiler/native island, or explicitly migrate affected interfaces | Source macro/config assumptions and nonlocal control; C translation is not universal |
| NR08 | Retire legacy construction | Replace C-scanner-only semantics, macro label/layout discovery and hidden module control | Zero remaining callers in the declared rebuilt cohort; no permanent forwarding into the old implementation |

FN06. Preserve external C ecosystem capabilities through NR01/02/07 while
rebuilding internal cohorts to the chosen new runtime protocol. Historical
binary/layout/macro compatibility is a separate scope choice; it must not be
silently assumed or allowed to dictate every new internal representation.
Arbitrary setjmp/longjmp across live Zig frames remains outside the admitted
path; keep a bounded C control island or redesign that boundary explicitly.
The [map trace](map-scheme-zig-design.md) demonstrates why normal call return,
Scheme continuation transfer and foreign native escape are different operations.

## Conditions, Refuters and the Decision

FN07. Conditional reconstruction argument: if every selected language operation,
root, constructor, call/capture/FFI edge, VM owner, resource and module user has
one complete implementation contract; if Zig realizes those contracts and the
C facade realizes its declared ABI/ownership domain; and if every deleted old
mechanism has no remaining users, then implementation-language replacement can
preserve those admitted Scheme and C capabilities. The source/primary evidence
makes this a researchable architecture, not proof that those premises hold.

Refuters include: using native allocator free for a live Scheme object; retaining
a movable Scheme reference only in a Zig local; reusing a captured one-shot
native resource; crossing Zig with unqualified C longjmp; exporting a function
with correct symbol name but wrong ownership/value protocol; keeping the old
collector behind a facade while claiming its implementation retired; or dropping
required targets/extensions without reporting a reduced capability domain.

FN08. The positive case can be **lower full reconstruction and maintenance
cost**, shared necessary services and genuinely retired legacy work, plus valued
capabilities such as independently admitted LLVM providers. It need not be a
unique runtime feature impossible in C. Use the map study's three ledgers:
modern C versus current, direct Zig versus current, Zig versus fully costed C.
Include the substantially wider GC/VM/OS/FFI migration surface in this full-layer
candidate; do not transfer a small planner's benefit estimate to a whole runtime.

If preserving the required C surface costs more than the necessary support Zig
eliminates, incremental economics fail. If the required target/control/GC domain
cannot be admitted, full replacement is not qualified. All five full runtime,
semantic/provider, retirement, total-cost and Zig-increment questions remain
unresolved. No automatic-GC removal, proven speedup, wholesale native feasibility
or accepted positive net follows from C interoperability alone.

## Generational GC as a Modernization Requirement

FN09. Chez and OCaml provide useful explicit reference designs. The
[Chez storage-management manual](https://cisco.github.io/ChezScheme/csug10.0/smgmt.html),
§13.1, describes age-based generations, promotion/collection scheduling and a
static generation. The [OCaml parallel runtime manual](https://ocaml.org/manual/5.3/parallelism.html),
§3, describes domain-local minor allocation, stop-the-world parallel minor
collection and concurrent major mark-and-sweep. These are distinct engineering
choices, not one universally best collector. Generational policy, copying versus
mark/sweep, and parallel versus concurrent execution are separate dimensions.

| ID | Requirement worth studying for Gambit | Source-backed reason / complete obligation |
| --- | --- | --- |
| GR01 | Fast young-object allocation and selective promotion/collection | Chez/OCaml demonstrate the mechanism; Gambit must define object ages, actual young/old spaces, promotion and old-to-young reference tracking. Scheme barrier policy and every generated/FFI writer must agree. |
| GR02 | Parallel collection with explicit participants and work ownership | OCaml's minor design is a reference, not a ready Gambit worker. Gambit must close mutator participation, safe-point roots, copying/forwarding, capacity and termination for actual workers and contexts. |
| GR03 | Concurrent collection with a stated memory/barrier model | OCaml's major design motivates latency research; barriers, phase transitions, weak/finalization behavior and all mutator/foreign access must be justified independently. A change of implementation language supplies none of those invariants. |
| GR04 | Capturable/replayable Scheme control under movement and aging | Current map and captured-frame scan sources establish real users; roots in active/captured frames, closure cells, points/code lifetime and restored owners must remain complete across generations. |
| GR05 | Explicit foreign roots, blocking participation and cleanup | Current root/VM/native-control sources and the OCaml paper show interface constraints; foreign callbacks/destructors and shutdown cannot be treated as no-effect leaves or ordinary allocator cleanup. |

The inspected Gambit memory comment names MOVABLE0 as generation 0
([mem.c](../../../vendor/gambit/lib/mem.c#L141), 141–147), and the C target has
SSB support. Neither alone establishes the full effective generational policy,
minor/major separation, barrier closure or current parallel/concurrent profile.
Those require the configured collector's complete producer/writer/scanner
evidence. This study therefore does not label the current Gambit collector as
either fully modern generational or wholly nongenerational from those clues.

GR01–05 are semantic/runtime modernization obligations whether implemented in
C or Zig. If selected, their algorithm and migration costs enter the full-layer
ledger in addition to language reconstruction. Native Zig auxiliary memory can
remain explicitly managed while the Scheme heap has a sophisticated GC.

## Evidence Index

| ID | Selected working-source scope |
| --- | --- |
| NS01 | mem.c generation tag comment, active/captured frame/root scanning and GC entry; exact spans in traceability |
| NS02 | setup.c VM lifecycle, published native service pointers and module fixup |
| NS03 | gambit.h.in PSTATE/VM fields and Scheme generic transfer macros |
| NS04 | Actual public map, continuation reification/winding and C scanner transfer construction |

| ID | Primary reference scope |
| --- | --- |
| NP01 | Zig reference: C ABI export/layout/object mixing and translation limits; no whole-Gambit port guarantee |
| NP02 | LLVM safepoint relocation constraints; explicit collector integration still required |
| NP03 | OCaml parallelization paper: semantic, cost, pause and C-interface design obligations |
| NP04 | Chez storage management manual: generational policy and collection controls |
| NP05 | OCaml parallel runtime manual, section 3: minor/major allocation and collection architecture |

The [local trace](zig-native-layer-traceability.json) records source identities
and handwritten design dependencies, not registered engine/native evidence.

## Source-Mechanism Resolution and Complete GC Design

The [current collector audit](gc-current-mechanism-audit.md) now resolves the
earlier effective-generation uncertainty for the selected working-source
scope: movable objects undergo full tracing/copying with unchanged generation
headers, still objects are marked/swept, and parallel STW machinery exists in
conditional source branches. The separately materialized Darwin sample is
single-threaded with a default processor maximum of one; it does not identify
the current vendor's loaded runtime. This refines FN09's source question without
rewriting prior evidence or admitting a native profile.

The [complete GC candidate](gc-native-runtime-design.md) specifies local young
spaces, direct survivor promotion, nonmoving mature/pinned spaces, typed
mutation/root/publication protocols and coordinated minor/concurrent-major
phases. The [benefit matrix](gc-native-runtime-cost-matrix.md) separately charges
algorithm modernization, full C/Zig realization and the incremental language
choice. GC remains an explicitly implemented Gambit runtime responsibility in
either language. All full-runtime and net-benefit requirements remain open.
