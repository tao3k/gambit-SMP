# Selected RFD Component: Evidence and Limits

Reviewed: 2026-10-20. Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
vendor Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Local source/note hashes are bound in the research declarations. No native
test, implementation, compiler probe, timing or research-engine run occurred.

## 1. Why This Component Is Necessary

| ID | Directly reviewed source | Finding and exact limit |
| --- | --- | --- |
| F01 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):825-905 | Root/return construction finds ret-var, extends/reverses slots and applies alignment/internal saved-state rules. Saved GVM registers plus protocol return slot are mandatory roots. This is existing semantic/physical coupling to extract, not a trivial native arithmetic port. |
| F02 | [_t-c-3.scm](../../../vendor/gambit/gsc/_t-c-3.scm):471-530 | Map building/all-live, chunks, actual/internal frame size and two alignment helpers have concrete definitions; the inline limit uses minimum word bits. Scope has eight named helper definitions, not eight retirements. |
| F03 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):1690-1706,1940-2019,2047-2064 | Label output, OFD output and counting call the same selector; map chunks are rendered in grouped macro calls. Shared stored decisions can replace selected reconstruction; three sites are not three independent policies. |
| F04 | [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):9208-9267,9300-9319 | Return-kind values, alignment/reserve, IFD/OFD field packing, 32/64 map assembly and normal/internal decoders define the actual consumer format. The IFD map extraction budget is 32-based even on the wider-word branch. |
| F05 | [mem.c](../../../vendor/gambit/lib/mem.c):3817-3909,3918-3968 | Frame scanning consumes map words across word boundaries; continuation walking selects RA kind and reads link+1. A metadata producer is necessary, and its independent correctness gate cannot be replaced by a planner hash. |
| F06 | [_t-c-1.scm](../../../vendor/gambit/gsc/_t-c-1.scm):31-48,92-105,206-218; [header](../../../vendor/gambit/include/gambit.h.in):1371-1385 | Generator defaults/constraints, four/eight-byte portability range and frame parameters correspond to configured runtime quantities. Defaults/template branches are not installed/cohort admission. |
| F07 | [_t-c-2.scm](../../../vendor/gambit/gsc/_t-c-2.scm):175-186,212-229 plus F01 | CFUN stack adjustment uses alignment and its return has an all-live map. Global deletion of helpers is not justified by ordinary return-planner migration. |
| F08 | [setup.c](../../../vendor/gambit/lib/setup.c):1592-1615 | Version and selected structure-size checks are partial. They do not prove generator/decoder register counts, bitmap coordinates or full profile agreement. |

The caller search was bounded to `_t-c-1.scm`, `_t-c-2.scm`, `_t-c-3.scm` and
the cited consumers. It establishes the listed callers/uses, not a complete
repository-wide deletion denominator. The source's Scheme integer map can
represent more than one word; the chunk-based native design must preserve the
required variable length without claiming Scheme bignum support disappears.

The internal-extent and chunk equations in the design are algebraic readings
of F01/F02/F04. The 20-slot inline-limit derivation follows the inspected
four-byte minimum and formula; it is not a native experiment or a declaration
that every admitted future protocol has that limit. Sparse/cross-module IDs,
new frame roles, target manifestations and all valid baseline cases still need
their actual closure. No source bug or repaired runtime result is inferred.

## 2. Primary Implementation Mechanisms

These are short reading notes; upstream bytes were not downloaded/pinned.
Versioned sources are not local installed binaries or a jointly qualified
provider cohort. Published examples/tests were not executed here.

| ID | Primary source | Supported mechanism and boundary |
| --- | --- | --- |
| P01 | [Zig 0.15.1 math.zig](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/math.zig), checked add/mul/sub/shift/cast | Reusable explicit arithmetic results exist. Target widths, frame rules and correct rejection conditions remain local. |
| P02 | [GCC overflow builtins](https://gcc.gnu.org/onlinedocs/gcc/Integer-Overflow-Builtins.html) | Serious C control can reuse checked primitive mechanisms; no handwritten overflow detector/generator per field is presumed. Actual compiler profile qualification remains separate. |
| P03 | [Zig 0.15.1 reference](https://ziglang.org/documentation/0.15.1/), error unions/propagation/cleanup and build modes | Private expression/propagation mechanisms support a possible local advantage. They supply neither rich public diagnostics nor affine ownership/root proofs; no all-build implicit overflow recovery is credited. |
| P04 | [Zig 0.15.1 ArrayList source](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/array_list.zig), ownership/invalidation | Generic storage is available, but a component with known output sizes need not use it. The selected exact-allocation C control is not charged a fictitious container implementation. |
| P05 | [Zig 0.15.1 main.zig](https://raw.githubusercontent.com/ziglang/zig/0.15.1/src/main.zig), input cases near 1785/1882 | IR/bitcode driver inputs exist in source. That downstream tool role is separate from the RFD core language, and current installed target behavior is unqualified. |
| P06 | [Zig 0.16.0 release notes](https://ziglang.org/download/0.16.0/release-notes.html), C translation migration | Selected API/version use carries maintenance work. Pure RFD need not import LLVM/runtime headers; do not charge all ecosystem migrations to it or assign an annual frequency. |

[Feeley and Miller's Gambit PVM paper](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf),
section 2, was reopened for the negotiated logical/backend boundary. It supports
keeping logical slots/target agreement explicit. RFD's schema, homogeneous
arrays, sizing pass, native chunk storage and C/Zig cost model are our design;
the paper provides no Zig preference, modern ABI result or transferred timing.

## 3. Report Attribution and Historical Timing Boundary

The [Darwin first-compile boundary](darwin-first-compile-boundary.md) retains
historical first-log/cold-build distinctions and the order of expander/interface
work before later consumer C compilation. It was reread as a source-bound prior
report, without replaying its workload or requalifying its historical numbers.
BM15's zero-credit statement concerns directly eliminated earlier operations
with those phases held fixed; it is not a new elapsed-time observation.

The [existing effective configuration design](effective-configuration-darwin-gcc.md)
separates materialized Darwin/GCC evidence from installed-profile admission.
RFD uses explicit profile facts and does not rerun configure/compiler queries.

RF01-RF07, FM01-FM06 and BM01-BM18 are project disposition/accounting records.
The R/S/T bounds are proposed algorithm/storage bounds; two output roles are
not measured allocations; no source-site count is a speedup. Matrix verdicts
distinguish shared mechanisms, local conditional value, zero attribution,
unknown magnitudes and added/substituted maintenance. No weighted ROI, native
pass, theory witness or existing-code retirement is issued.
