# Effective Configuration: Source Mapping and Evidence Limits

Date: 2026-10-20. Companion to the
[Darwin/GCC effective model](effective-configuration-darwin-gcc.md).
Source reading and documentation checks only.

## 1. Identities

Research repository HEAD is `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
vendor Gambit HEAD is `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Inspected
vendor files have no tracked diff. Materialized Gerbil at parent
`.data/ci-source-patch-check` has HEAD
`1cfb032c7a1612637da6205f5f8a15683eba3ba0`; its driver retains local changes
of 270 added / 43 deleted lines. These are distinct source identities, not a
combined configured binary or current SMP qualification.

## 2. Direct Source Coverage

| ID | Inspected source | Relevant exact behavior |
| --- | --- | --- |
| D1 | Vendor `configure.ac:2655-2705,2978-3045,3246-3271,3296-3332` | PIC/bundle versus dynamiclib selection; configured/per-mode flag composition and runtime override references; absolute runtime-library link branch; object/runtime-object/dynamic/executable templates; placeholder BUILD_LIB |
| D2 | Vendor `bin/gambuild-C.unix.in:1-55,285-410` | Unset-only C/LD defaults; per-mode CC override clears FLAGS; object/dynamic/exe all resolve metadata/packages; mode substitutions and command eval |
| D3 | Same template `:176-283`, conditional-expression sections retained in [earlier audit](native-request-migration-evidence.md) | Each package queries cflags then libs; common resolver accumulates CC, LP, LT; path additions prepend; package/metadata/explicit order preserved |
| D4 | Vendor `gsc/_gsclib.scm:308-488` | File/output normalization, source-to-C boundary, module/linker names, native cwd, relative input/output paths; compile metadata source and executable native request are distinct fields |
| D5 | Gerbil `src/gerbil/compiler/driver.ss:952-1113` | Phase/debug/static filtering, raw direct-link space split, generated symbol encoding, runtime-C/static-C copy, object dynamic/PIC and bundle alias stages |
| D6 | Same Gerbil driver `:365-390,533-587` | Direct dependency/stub executable argv, rpath position, runtime library arguments, Darwin's source default-library branch and separate object/link steps |
| D7 | [Migration source ledger](native-request-migration-evidence.md), R7-R9 | Previous semantic-link/FFI/runtime/process audits constrain retained M10-M12 responsibilities; not new native evidence |
| D8 | [Historical cost ledger](zig-system-layer-evidence.md), H1-H3 | Reuse component successes, request-coordinator regression and interface observation limits remain historical, separate from this profile |

Source links: [configure](../../../vendor/gambit/configure.ac),
[native driver template](../../../vendor/gambit/bin/gambuild-C.unix.in),
[Gambit producer](../../../vendor/gambit/gsc/_gsclib.scm),
[materialized Gerbil driver](../../../../../.data/ci-source-patch-check/src/gerbil/compiler/driver.ss).
The materialized-tree link depends on the local source checkout.

| Input | SHA-256 |
| --- | --- |
| Vendor `configure.ac` | `2a62dade3dd7174d9c091df7ed1018cb376619163c1e0ac1185dee923d874fc5` |
| Vendor `bin/gambuild-C.unix.in` | `bdd99a03bb24206e348bdc6ae760a02c04573694090e21cc0a9b748dc8522b4c` |
| Vendor `gsc/_gsclib.scm` | `c4068e8d8c34135354d26c8a6e79adcac73bf34f432b857961bdb4932da94dd0` |
| Gerbil `compiler/driver.ss` | `07a175646c90b16c690cf32d670b8368d534963966bbc84d89896f9bb8e5e300` |

## 3. What the Baseline Does Not Establish

The original bounded check of three `gambuild-C` locations was incomplete.
The [configured-input follow-up](darwin-configured-input-evidence.md) finds
materialized `src/gambit/bin/gambuild-C.unix` and its config.status/log/header.
It supplies actual configured flags and a recorded compiler/sysroot, with
content hashes. SDK content, current tool/specs/linker/runtime identities and
deployment policy remain incomplete. That generated file belongs to a different
Gambit revision and local patch set from D1-D4; it is not evidence of a qualified
managed toolchain or the historical frozen D1510 driver.

Source paths and suffixes do not establish an artifact role. D1 distinguishes
Darwin module bundle flags from dynamic-library flags. D1's library recipe is
still a placeholder; D1's runtime-object recipe is not the D2 installed object
dispatcher. D6's direct Gerbil links are not the generic Gambit exe template.
These differences are why the design retains separate mode IDs and support states.

## 4. New Source Consequences

**Resolution actions are part of behavior.** D2 object mode invokes the same
package resolver as linking. D3 still performs `--libs` and can fail before
compiler invocation. The absence of its output from object argv does not prove
the query or its error removable. Metadata diagnostics likewise need mapping
even for parameter slots unused by that mode. No runtime probe was used to
quantify this work or generalize shell error behavior beyond the inspected path.

**Unified data does not imply uniform argv.** Generic executable has no separate
FLAGS_OPT segment, and direct Gerbil final links do not inherit the generic
template's flags or metadata scan. Native argument vectors should reproduce
the selected route, not synthesize a supposedly cleaner common command.

**Selected is not qualified.** The first profile deliberately defers runtime
construction, archive/dylib, alternate toolchains, cross/universal targets,
fully static native executables and unadmitted MLIR code objects. Literal
vectors/typed metadata still require producer emission and decoder coverage.
No claim is made that existing string options already satisfy that boundary.

## 5. LLVM Upgrade Evidence

The [MLIR C API](https://mlir.llvm.org/docs/CAPI/) and
[bytecode documentation](https://mlir.llvm.org/docs/BytecodeFormat/) were reread
on 2026-10-20 for API stability and dialect-versioning scope. Opaque C access
does not freeze provider internals, and bytecode compatibility does not establish
project semantic compatibility. The [preceding ledger](native-request-migration-evidence.md)
retains primary pass/conversion/code-generator evidence.

The stage-specific invalidation matrix is an architectural selection under
complete dependency records. It is not derived from an implemented cache or
evidence that an LLVM upgrade already avoids C rebuilds. Provider dependencies,
output native libraries and any changed runtime protocol must be represented.
The broader [artifact contract](compilation-unit-artifact-contract.md) remains
authoritative for request/content/compatibility/admission distinctions.

## 6. Documentation Verification

At this checkpoint 276 local file references resolve and 116 Markdown tables
have consistent column counts. Both new D2 sources render with D2 0.9.0
(`dagre`, theme 0); their SVGs were rasterized and visually inspected. These
are document checks only. No generated profile, native command, package query,
semantic/model validation or timing workload was executed.
