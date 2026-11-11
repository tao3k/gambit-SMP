# Observation Boundaries and Caller Evidence

Date: 2026-10-20. Static reads/source searches only; no instrumentation, native
command, configure/package query or performance validation was run. Companions:
[independent evidence plan](independent-equivalence-evidence-plan.md) and
[caller/replacement dependencies](native-caller-retirement-plan.md).

## Source Coverage

| ID | Exact inspected source | Evidence supported / limit |
| --- | --- | --- |
| O1 | Materialized Gerbil compiler/driver.ss:100-176,242-461,463-589,765-815,844-884,924-1113,1190-1206 | Actual semantic/native callers, separate lexical stubs, static-false inner object, loader reset, Darwin source/object/bundle/alias boundary, native invocation and delivered errors |
| O2 | Vendor gsc/_gsclib.scm:155-161,164-264,265-593 | Public/internal compile seams, two direct gambuild/params call pairs, module/exe callers, target-derived driver, env transport, cwd/name/temporary/status semantics |
| O3 | Vendor bin/gambuild-C.unix.in:62-283,333-411,412 onward; materialized .unix preserves extra literal/portable substitutions | Conditional/metadata/query/tty order and final eval; info/dump residual consumers; command text is before final native argv parsing |
| O4 | Vendor lib/gambit/process/process.scm:76-150 | ##run-subprocess process options, environment additions appended before inherited entries, directory, output capture and process-status continuation; actual environment selection/encoding still needs observation |
| O5 | Materialized Gerbil compiler/base.ss:455-481 and driver.ss:401-457 | Output registration/publication and dependent callbacks; existing Darwin all-object submission and failure barrier remain owned by Gerbil |
| O6 | Vendor configure.ac:2978-3045,3246-3332,3485-3608,3854 onward | Ordered policy before SH/MF/BAT encoding, ordinary/runtime-object recipe distinction, generated output/header registration; no new typed producer exists |
| O7 | Vendor bin/makefile.in:97,113,132-140,586-590; lib/makefile.in:321-366; gsc/makefile.in:293-305; gsi/makefile.in:207-219 | Actual installed-name .unix copy, partial config.status regeneration and bootstrap native template consumers; prevents deleting legacy outputs after post-generation migration |
| O8 | Vendor gsi/main.scm:501-592; lib/_module.scm:610-680 | CLI compile/executable/module helpers, ._must-build_ automatic module subprocess and gsc-script Scheme expression reaching ##build-module |
| O9 | Parent d1510-object-request-cost.md, Excluded Attempts | Environment-changing phase/output controls invalidated old timing comparisons; scope warning for recorder calibration, not new evidence or a speedup |
| O10 | Prior native-request-migration-evidence.md R7-R9; compilation-unit-artifact-contract.md | Semantic link/module/FFI/GC/control and native/runtime gates remain independent; old receipts do not qualify this proposed profile |

Links: [Gerbil driver](../../../../../.data/ci-source-patch-check/src/gerbil/compiler/driver.ss),
[Gerbil executor](../../../../../.data/ci-source-patch-check/src/gerbil/compiler/base.ss),
[Gambit native producer](../../../vendor/gambit/gsc/_gsclib.scm),
[native shell template](../../../vendor/gambit/bin/gambuild-C.unix.in),
[process API](../../../vendor/gambit/lib/gambit/process/process.scm),
[configure](../../../vendor/gambit/configure.ac),
[bin make rules](../../../vendor/gambit/bin/makefile.in),
[runtime make rules](../../../vendor/gambit/lib/makefile.in),
[GSC make rules](../../../vendor/gambit/gsc/makefile.in),
[GSI make rules](../../../vendor/gambit/gsi/makefile.in),
[command-line helpers](../../../vendor/gambit/gsi/main.scm),
[module subprocess](../../../vendor/gambit/lib/_module.scm),
[historical rejected controls](../../../../../patches/gerbil-v19-darwin/receipts/d1510-object-request-cost.md),
[retained semantic/runtime ledger](native-request-migration-evidence.md),
[artifact qualification](compilation-unit-artifact-contract.md).

## Identity and Inventory Limits

Research HEAD rechecked: `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`.
Vendor Gambit source identity remains the prior audit's
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`;
materialized Gerbil `1cfb032c7a1612637da6205f5f8a15683eba3ba0` has local
patches. Their inspected file digests below bind content. The existing
[configured-input ledger](darwin-configured-input-evidence.md) separately binds
materialized Gambit's generated .unix/status/header and its distinct revision.
No new combined installation or source-runtime acceptance is asserted.

Bounded text searches found three direct gsc-cc-options call contexts plus the
inner executable-object call: G:282,317,550,1056; one gsc-ld-options caller
G:1057; three gcc-ld-options callers G:284,552,1104. Definitions are excluded
from these counts. There are two direct ##gambuild/params pairs in the vendor
GSC producer at :370/375 and :472/477. These are static occurrences, not actual
runtime work counts. Lexical owner and branch guards are required identities.
Upstream command/module and make paths were opened from their exact references.
A missing guessed compiler/main.ss path did not establish caller absence; no
conclusion depends on that failed lookup. External/dynamic callers remain open.

| File | SHA-256 read this turn |
| --- | --- |
| `.data/ci-source-patch-check/src/gerbil/compiler/driver.ss` | `07a175646c90b16c690cf32d670b8368d534963966bbc84d89896f9bb8e5e300` |
| `.data/ci-source-patch-check/src/gerbil/compiler/base.ss` | `0ac4b2f61d39a46f6640075417f04ce215a94d968f318a7ed7611039f268f79a` |
| `.data/gambit-smp/vendor/gambit/gsc/_gsclib.scm` | `c4068e8d8c34135354d26c8a6e79adcac73bf34f432b857961bdb4932da94dd0` |
| `.data/gambit-smp/vendor/gambit/gsi/main.scm` | `e18acd8d77e49f4970c45f5bb95c2fdcea039c6f4c389708fc26124a5013b387` |
| `.data/gambit-smp/vendor/gambit/lib/_module.scm` | `09e78679ce17213823ffe092c8e09831f1c05ac7dfeeee7b29fc2401f8cb52ae` |
| `.data/gambit-smp/vendor/gambit/bin/gambuild-C.unix.in` | `bdd99a03bb24206e348bdc6ae760a02c04573694090e21cc0a9b748dc8522b4c` |
| `.data/gambit-smp/vendor/gambit/bin/makefile.in` | `2c908a0149eb3ce84011eafe99ba0faf0e9b6bcded078629cc12028e2e4e5332` |
| `.data/gambit-smp/vendor/gambit/lib/makefile.in` | `d8728874f871680c8bd6b03f7641b2a2d0a357fc49e59f8e7da6f041382a5606` |
| `.data/gambit-smp/vendor/gambit/gsc/makefile.in` | `36d5b50006eb30a516cd8467238b07ef0fca018116dfd034a56e4269373cf342` |
| `.data/gambit-smp/vendor/gambit/gsi/makefile.in` | `f9b1eb09b00644262275071836dd29200a7655a741c98cf16ad0598f658bf053` |
| `.data/gambit-smp/vendor/gambit/lib/gambit/process/process.scm` | `31029718e7798ad764a3895ceccb10d4a8b29d2a41ea4558e9cfe2b859dfe17c` |
| `.data/gambit-smp/vendor/gambit/configure.ac` | `2a62dade3dd7174d9c091df7ed1018cb376619163c1e0ac1185dee923d874fc5` |

## Proposed Evidence Acquisition Is Not Existing Capability

L1 leaf recorders, L2 transparent/native process-boundary acquisition, calibration,
framed receipts, fixture families and negative controls are design obligations.
No available Darwin facility was assumed to deliver full argv/env/cwd/status,
and no source observer was implemented. Missing L2 coverage keeps original-native
parity unresolved. No compiler or package result was fabricated to fill the gap.
The 32-row plan distinguishes observational equivalence, restricted admission,
new manifest/invalidation requirements and mapped-only runtime support.
No E row, native acceptance gate or M2-M8 retirement gate is passed by these reads.

## Documentation Verification

381 local file references resolve; 138 Markdown tables have consistent columns.
The per-row evidence table contains E01-E32 exactly once each, with no missing
IDs. Both D2 sources render with D2 0.9.0 (dagre/theme 0); rasterized SVGs were
visually inspected for readable labels and clipping. These document checks
provide no executed fixture, observer calibration, E-row pass or native result.
