# ForeignPlan Producer / Consumer Evidence

Reviewed: 2026-10-20; research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`,
vendor Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
The registered view binds actual local bytes, including working-copy changes.
No native or performance experiment was performed. These are 18 selected
responsibility families, not 18 actual user call sites or exhaustive procedures.

## 1. Source-Scoped Responsibility Census

Abbreviations in the table link to [parser dispatch](../../../vendor/gambit/gsc/_ptree1.scm)
(P1), [FFI parser/generator](../../../vendor/gambit/gsc/_ptree2.scm) (P2),
[frontend](../../../vendor/gambit/gsc/_front.scm) (F),
[C target](../../../vendor/gambit/gsc/_t-c-1.scm) (C1),
[C scanner](../../../vendor/gambit/gsc/_t-c-2.scm) (C2),
[header](../../../vendor/gambit/include/gambit.h.in) (H),
[C interface runtime](../../../vendor/gambit/lib/c_intf.c) (CI),
[kernel](../../../vendor/gambit/lib/_kernel.scm) (K),
[runtime setup](../../../vendor/gambit/lib/setup.c) (S) and
[manual](../../../vendor/gambit/doc/gambit.txi) (D).
Numbers are current source lines; multiple anchors denote a selected chain.

| ID / responsibility | Producer anchor | Consumer anchor | Reuse / required change |
| --- | --- | --- | --- |
| FS01 type aliases and custom converters | P1:793-808; P2:2184-2256 | P2:2450-2558, 2839-2900 | Reuse validation and conversion laws; capture resolved graph/converter/cleanup provenance before reset |
| FS02 opaque declarations and ordering | P1:810-824; P2:2135-2139 | C1:338-346, 381; F:502-580 | Preserve bytes/order/include closure; explicit single product owner replaces vector-clearing signal |
| FS03 initialization programs | P1:826-840; P2:2146-2150 | C1:2194-2222 | Preserve ordered runtime actions; cached code is not initialized state or rollback proof |
| FS04 c-lambda named target versus body | P2:2561-2570, 3227-3338 | C2:188-216 | Capture target form and macro environment; reuse opaque body only within explicit qualified C unit |
| FS05 parameter setup and conversion program | P2:2773-2874, 2902-2932 | H:10062-10067, 10400-10402; generated CFUN/SFUN conversion macros | Preserve Scheme-object-first stable partition, nested conversion and cleanup; not arbitrary argument-order simplification |
| FS06 c-define exported callback / generated converters | P1:842-869; P2:3144-3222 | CI:2887-2940; H:10043-10060 | Preserve external identity and protocol; separate static exported entry from dynamically generated closure |
| FS07 registry freeze and reset | P2:2093-2112, 2171-2182 | F:225-250 | Capture immutable typed side record before c-interface-end; c-proc text cannot recover signature afterward |
| FS08 foreign primitive registration | P2:3227-3338 | F:828-855 | Replace list-element mutation by stable EntryId to procedure-object binding; no second semantic owner |
| FS09 interface emission ownership | P2:2161-2169; F:502-510 | C1:338-346; F:580-653 | Explicit product manifest acknowledges emission; do not emulate suppression by clearing vectors |
| FS10 Scheme-to-C frame and return points | F:828-855 | C2:123-237 | Reuse semantic shape arity+1/all-live/return obligations; move semantic frame/control plan to Scheme and physical emission to common engine |
| FS11 conversion cleanup and nonlocal exit mode | P2:2502-2524, 2902-3028 | H:9960-10002, 10326-10378 | Preserve acquired-resource scopes and configured catch mechanism; no skipped Zig lexical cleanup assumption |
| FS12 scalar result conversion | P2:2876-2900 | CI:4351-4456 | S64/U64 may allocate bignum outside fixnum range; target-leaf does not establish whole-boundary F0 |
| FS13 pointers, aggregates and function conversion | P2:2386-2450, 2526-2558 | CI:2825-2972, 5156-5277 | Preserve null/tag/lifetime/layout and dynamic closure distinctions; arbitrary nonnull C-function-to-Scheme conversion returns an error in this baseline |
| FS14 foreign release and error delivery | K:3886-3903 | CI:1683-1711 | Clear fields before release callback; preserve terminal invalidation even when callback returns error; no rollback/retry or parallel-safety inference |
| FS15 configured nonlocal transfer | H:9979-10002 | H:10375-10378; K:1019-1071 | Setjmp and C++ exception paths require explicit containment; caller-side catcher does not protect intervening Zig frames |
| FS16 callback marker lifetime | H:10043-10060 | CI:6511-6570 | Preserve allocation, processor identity and invalidation; baseline proc_or_false rooting TODO remains unresolved |
| FS17 matching foreign return destination | CI:6511-6570 | K:1019-1071; S:3276-3395 | Keep marker owner and matching catcher semantics; no swallowing another activation's UNWIND_C_STACK |
| FS18 nested foreign calls and Scheme threads | D:19935-19992 | K:1019-1071; H:10043-10060 | Documented separate continuations and nested-thread limitations constrain current protocol; no new F4/F5 entry granted |

This scope names producers and consumers inspected for the proposed redesign.
It does not prove full transitive effects of every converter/release function,
all platform closure support, complete application use, or current configured
macro expansion. Additional targets, runtime overlays and opaque bodies remain
separate scope and source identities. No family is marked implemented.

## 2. Findings That Change the Architecture

**FE01 — Capture before reset.** FS01/FS07 show why the typed contract must be
produced during parsing, not decoded from generated C or raw GVM. FS08/FS09 add
two mutation boundaries requiring stable identities and explicit emission
ownership. A frozen side record must not keep pointers into the cleared registry.

**FE02 — Preserve the wrapper program.** FS05 and FS11 show that signature-only
interop loses setup order and cleanup/failure structure. The source's stable
partition is a wrapper-generation order; it is not a license to reorder Scheme
operand evaluation or arbitrary C expression evaluation. Existing scalar/pointer
conversion branches (FS12/FS13) independently rule out signature-only F0 claims.

**FE03 — Dynamic control is a call-edge property.** FS15/FS17 show configured
nonlocal transfer and matching return markers. The inference is that a catcher
outside Zig can still be reached by skipping Zig frames. This is a design
counterexample path, not an observed crash or a complete platform unwinding
claim. Every edge needs its own control-containment contract.

**FE04 — Release failure is not rollback.** FS14 clears foreign fields before
calling a release function. The normal error return leaves them cleared. The
new adapter must preserve this ordering and subsequent Scheme error delivery;
it cannot restore ownership merely because native cleanup failed.

**FE05 — Callback support is asymmetric.** FS06/FS13 distinguish statically
exported c-define functions, dynamically allocated C closures on supported
platforms and the baseline rejection of arbitrary nonnull C functions converted
to Scheme procedures. “Function pointer” is not a complete portable capability.

## 3. Primary Platform / Paper Correspondence

Read on 2026-10-20. These local notes bind reviewed text and access scope, not
remote bytes or an installed compiler. No note supplies a native witness.

**FU01.** [Zig 0.15.1 reference](https://ziglang.org/documentation/0.15.1/),
Memory, C Pointers, Exporting a C Library and Translation failures: explicit
allocators, C-compatible interfaces and typed pointer choices are mechanisms
suited to native adapters. Ambiguous imported C pointers and translation
limits do not supply managed ownership/control laws. Our inference is to place
typed native resource ownership behind an explicit boundary rather than import
the whole Gambit macro protocol as a new source of truth. This versioned
reference does not select the project's supported toolchain version.

**FU02.** [MLIR C API](https://mlir.llvm.org/docs/CAPI/), Design and Ownership:
opaque C-accessible handles and explicit ownership conventions permit a service
interface. Stability is not guaranteed. Our inference is to isolate provider
handles and conversion ownership; neither Gambit nor callers should retain raw
provider handles as stable language values. A C++ dialect adapter may still be
required. Zig does not make these dependencies disappear.

**FU03.** [Retrofitting Parallelism onto OCaml, v3](https://arxiv.org/html/2004.11663v3),
sections 1.2-1.4 and 4.3-4.4: C-access invariants influence collector design;
the paper compares different minor-collector choices and C-API implications.
Our inference is that a staged typed foreign contract can make such decisions
visible for Gambit, but no particular OCaml algorithm, performance result or
current OCaml 5 implementation is transferred to this source tree.

## 4. Research and Native Evidence Boundaries

The view records FS01-FS18 with source-bound producer and consumer anchors.
`foreign_correspondence` joins those anchors; `foreign_gap` detects absent
declared surface/owner/anchor/source records. Zero gaps means only that this
finite responsibility map is bound. It is not whole-program call-site coverage.

Three new obligations remain open: `Q-foreign-site-census` (complete selected
call-site/input closure), `Q-foreign-plan-equivalence` (ordered conversion,
failure/resource and emission-owner correspondence), and
`Q-foreign-control-containment` (native semantic containment across selected
callback/return/unwind paths). Existing root, marker, mixed-edge, comparative
engineering, demand and net-cost requirements stay open. The census itself is
not a witness for any of these stronger obligations.

## 5. Actual Kernel Consumer Slice

The literal source interval K:3869-3908 contains two `##c-code` bodies and one
body-form `c-lambda`. The scope is exactly these three source occurrences; it
is not their transitive expansion/call closure, runtime invocation count or the
application's complete FFI denominator.

| ID | Existing consumer / direct dependency | Design consequence |
| --- | --- | --- |
| KU01 | K:3869-3882, `##foreign-released?` and its public wrapper | Reads FOREIGN_PTR_FIELD and returns Boolean; public force/type checks remain distinct. Internal interrupts-disabled declaration is not a general concurrency/leaf proof. |
| KU02 | K:3884-3894, `##foreign-release!`; CI:1683-1711 | Concrete caller of invalidate-before-release; callback error is subsequently raised in Scheme. Preserve both the mutated state and error delivery. |
| KU03 | K:3896-3908, `##foreign-address`; CI:4894-4911 and 4415-4456 | Opaque c-lambda uses `___arg1`/`___return`; size_t conversion delegates to U64 and can take a bignum branch depending on value/profile. This is conditional source behavior, not a claim that normal Darwin addresses allocate or a reproduced workload. |

These uses expose a substantive replacement opportunity: runtime-owned embedded
C can be replaced by named reviewed semantic operations with explicit layout,
conversion and lifetime contracts. Arbitrary user C stays opaque. Their presence
does not establish user demand frequency, whole-program completeness, safe
parallel release, a new leaf classification or measured savings.
