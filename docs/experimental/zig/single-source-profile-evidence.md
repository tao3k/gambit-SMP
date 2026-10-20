# Single-Source Profile Evidence

Date: 2026-10-20. Static reads only. Companion
[model/request design](single-source-native-profile.md) and
[E01-E32 matrix](native-argv-equivalence-matrix.md).

## Source Anchors

| ID | Inspected source | Architecture consequence / limit |
| --- | --- | --- |
| S1 | Vendor configure.ac:2655-2705,2978-3045,3246-3332 | Probe/policy-derived flags composed before encodings; repeated exe/object contributions; distinct object/runtime-object/dyn/exe recipes; absolute runtime-library branch; library placeholder |
| S2 | Vendor configure.ac:3485-3608,3759-3763 | ESC_MF/ESC_SH/ESC_BAT; ordinary references escaped versus doubled-brace references preserved for shell assignment expansion; separate encoded outputs and AC_SUBST registrations |
| S3 | Vendor configure.ac:3854-3875 | config.status output set includes generated header, makefiles and gambuild-C.unix; no new manifest/atomic dual-output implementation exists |
| S4 | Retained materialized src/gambit/bin/gambuild-C.unix:1-55; config.status:426,1138-1167; include/gambit.h:1230-1253,1447-1493 | Actual default blocks/duplicates, -O1/-O3, empty package tool and conditional header defaults; same digests as preceding audit |
| S5 | Vendor gsc/_gsclib.scm:155-161,308-488,498-593; bin/gambuild-C.unix.in:1-55,62-410 | Input normalization/cwd/LF transport, source-specific splitting/metadata/package effects, captures, override suppression and final eval |
| S6 | Materialized Gerbil compiler/driver.ss:365-390,533-587,952-1113 | Separate dependency/stub direct links; phase/debug/static filtering and direct literal-space LD split; patched Darwin source/copy/object/bundle alias route |
| S7 | Existing native-request-migration-evidence.md R7-R9 | Retained Gambit semantic link, FFI/GC/control/setup and process ownership; no new runtime qualification in this turn |
| S8 | Existing darwin-configured-input-evidence.md C3/C4/C8 | Historical macro-tracking gains, denied coordinator and candidate admission boundaries; no current speedup or profile acceptance |

Direct links: [configuration source](../../../vendor/gambit/configure.ac),
[native shell template](../../../vendor/gambit/bin/gambuild-C.unix.in),
[Gambit producer](../../../vendor/gambit/gsc/_gsclib.scm),
[generated .unix](../../../../../.data/ci-source-patch-check/src/gambit/bin/gambuild-C.unix),
[config.status](../../../../../.data/ci-source-patch-check/src/gambit/config.status),
[header](../../../../../.data/ci-source-patch-check/src/gambit/include/gambit.h),
[Gerbil source](../../../../../.data/ci-source-patch-check/src/gerbil/compiler/driver.ss),
[previous process/runtime ledger](native-request-migration-evidence.md),
[configured/historical ledger](darwin-configured-input-evidence.md).

## Identities Rechecked This Turn

Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
The vendor configuration/driver/Gambit producer hashes still match the previous
ledger; vendor and materialized Gambit are distinct revisions. Local materialized
patches and generated files are identified by content, not merely their Git HEAD.

| Inspected bytes | SHA-256 |
| --- | --- |
| Vendor configure.ac | `2a62dade3dd7174d9c091df7ed1018cb376619163c1e0ac1185dee923d874fc5` |
| Vendor bin/gambuild-C.unix.in | `bdd99a03bb24206e348bdc6ae760a02c04573694090e21cc0a9b748dc8522b4c` |
| Vendor gsc/_gsclib.scm | `c4068e8d8c34135354d26c8a6e79adcac73bf34f432b857961bdb4932da94dd0` |
| Materialized bin/gambuild-C.unix | `58a8f5938c1ae03b25c9af28d103ea41bf8cc87315bc4417109e6ea9af3f9f60` |
| Materialized config.status | `3ec142dbeeecad9aee1bab1e0517b30390bf0c640ec8d1cbd11632b0307eee83` |
| Materialized include/gambit.h | `c54139a48c7456b07e772077e5318f4f7dde12ccc392a8ec1d66cbc811fb5c58` |
| Materialized Gerbil compiler/driver.ss | `07a175646c90b16c690cf32d670b8368d534963966bbc84d89896f9bb8e5e300` |

## Evidence Versus Architectural Selection

Source supports the encoding seam, ordered values and retained behavior.
It does not provide ConfiguredNativeModel, native-profile.m4, typed projection,
manifest activation, canonical JSON serializer, request emitter or parity tests.
Those are proposed new components with real engineering cost. The examples are
abbreviated design data, intentionally incomplete and non-executable; their argv
is a manual source-based derivation, not a captured native invocation.
M4 selection avoids a target Zig/GSC/MLIR bootstrap dependency, but needs an
actual serializer/escaping audit, Autoconf regeneration checks and supported-host
acceptance before it is admitted. No claim all configure inputs can be typed.

No external paper is used to prove this concrete legacy-to-argv equivalence;
repository source and exact artifacts are the primary evidence. Earlier MLIR
literature remains relevant to service design, but cannot qualify shell decoding,
configuration publication or native command parity. No new implementation,
configure/compiler/package query, semantic/model test or performance run occurs.

## Document Verification

341 local file links resolve; 128 Markdown tables have consistent columns.
Five JSON example blocks parse as JSON text only; they are intentionally not
schema-complete or executable profiles. Both new D2 diagrams render with D2
0.9.0 (dagre/theme 0), and rasterized SVGs were visually checked for readable
labels and clipping. These checks do not satisfy any E row or retirement gate.
