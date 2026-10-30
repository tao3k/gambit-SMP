# Darwin Patch Evidence: The Five-Second First-Compile Boundary

Date: 2026-10-19. Design/source-evidence review only. No new workload, profile,
compiler, runtime patch or performance validation is run.

## 1. Correct Problem Statement

The parent gerbil-bazel repository contains the relevant **Darwin patch and
execution evidence**. The user's reference to that repository is not a request
to optimize Bazel's action scheduler. The target here is real macOS compiler
startup/import/expansion work before the first genuine compilation message,
alongside complete-build and complete-test costs.

The retained D1510 evidence uses a **five-second first-log ceiling**, not a
documented five-second sleep, cooldown, timer backoff or mandatory OS wait.
For one historical retained profile the first logs are
4.850866 / 4.573628 / 4.592897 seconds; complete cold builds are separately
47.771713 / 47.824226 / 47.927094 seconds. The referenced reports retain
5 / 50 / 112-second gates, and later strict test DENYs remain unresolved.
Other candidates have different profiles and historical limits. These are
reported observations, not current-head requalification.

The [host-exit review](../../../../../patches/gerbil-v19-darwin/receipts/d1510-host-exit-branch-boundary.md)
checks that the original `std/make` message path already forces output. Moving a
log earlier, adding progress, delaying the watchdog or importing a different
candidate's timing does not solve this work boundary.

## 2. Distinct Costs and Causal Ordering

![Darwin first-compile execution boundary](darwin-first-compile.svg)

Distinguish Scheme/Gerbil expansion **execution**, compilation of the compiler's
own generated C, and compilation of a consumer's generated C. An already native
compiler can spend seconds executing imports, transformer code, context lookups,
allocation and GC before it starts a consumer C compiler. Making that later C
compilation faster cannot directly remove earlier work.

The [terminal-driver evidence](../../../../../patches/gerbil-v19-darwin/receipts/d1510-terminal-driver-exec-not-admitted.md)
explicitly states that terminal compiler exec occurs after the first compile
message. Its observed first-log improvement cannot be attributed to that mechanism;
the candidate's test evidence is incomplete and it is not admitted. The same
causal restriction applies to claims that replacing that later invocation with
`zig cc` will remove the pre-log prefix.

The [preparation/register review](../../../../../patches/gerbil-v19-darwin/receipts/d1510-preparation-and-register-boundary.md)
finds millisecond-scale Gambit evaluator preparation in its diagnostic probes,
while distinguishing Gerbil lowering, macro execution and live interface work.
The [evaluation split](../../../../../patches/gerbil-v19-darwin/receipts/d1510-gambit-eval-platform-boundary.md)
does not equate load-module time with dyld time. These instrumented components
cannot be summed into an exclusive budget for the whole first-log interval.

Likewise [D1609](../../../../../patches/gerbil-v19-darwin/receipts/d1609-current-first-window-cpu-and-exact-map.md)
records only 0.401846 seconds of trace despite a larger attachment-to-first-line
interval. Its GC-heavy burst is not a full prefix decomposition. The
[native-load audit](../../../../../patches/gerbil-v19-darwin/receipts/d1731-first-window-native-load-boundary.md)
maps real instructions, but sampled load/source-macro weights are not exclusive
instruction latency, cache-miss rates or removable wall time. No single dominant
macro/GC/register bottleneck is established by those records.

## 3. Required Artifact Distinction: Code Versus Fresh Instance

The [interface architecture review](../../../../../patches/gerbil-v19-darwin/receipts/d1510-interface-architecture-transfer.md)
records these retained source boundaries:

| Reported source boundary | Existing behavior | Design consequence |
| --- | --- | --- |
| `compiler/driver.ss:844`, separate `compile-phi` path | Emits `.ssi` interface forms; phase runtime code has separate artifacts | Existing native phase reuse does not imply `.ssi` construction is eliminated |
| `expander/module.ss:139` | Reads interface, creates module context, expands/quotes body, registers context; evaluation uses atomic promise | Imported interface is a program creating live state, not only immutable declarations |
| `expander/top.ss:273` | Installs runtime bindings/properties and context-bearing syntax | Fresh contexts, binding identity and mutation must remain correct |
| `expander/top.ss:327` | Evaluates syntax bindings at the next phase and installs values | Phase execution and initialization cannot be dropped on a code-cache HIT |

These anchors are source observations retained by that report; this update does
not claim to have re-read the exact historical Gerbil checkout. Native provider
reuse, compiled transformer code and a live instantiated interface are different
products. Caching another process's initialized bindings/lexical marks is not
equivalent to reusing immutable code.

Select **a separate research product category**: an immutable interface-construction
program with dependency/phase/effect contracts, which, if soundly generated, runs
against current imported instances and creates fresh valid context/bindings.
This could avoid repeated textual reading or generic expansion while preserving
required construction. It is a hypothesis requiring coverage and equivalence,
not a validated optimization or an instruction to serialize a live VM.

The [concrete construction-program design](interface-construction-aot-design.md)
now selects producer-side metadata staging, current-instance allocation and
two-stage completion. Its [evidence ledger](interface-construction-evidence.md)
also incorporates the later reached-predicate control: unguarded reuse of a
resolved head binding is observably incorrect. Compile stable scaffolding while
retaining live dispatch unless a stronger semantic profile is proved.

The [reader-budget evidence](../../../../../patches/gerbil-v19-darwin/receipts/d1510-interface-reader-budget.md)
and earlier joint accounting already constrain simpler reader/import-cache ideas.
Do not rerun the same census or call the full nested import interval a pure
reconstruction budget. The interface report's make/json residual intervals
include internal work and observer overhead; they are not an upper bound on
savings from a compiled constructor.

## 4. Architecture Implications for Zig and MLIR

| Mechanism | Can address the pre-first window? | Boundary |
| --- | --- | --- |
| Reuse completed project build | Skips the build, rather than accelerating actual cold startup | Useful reuse, but does not answer the user's Darwin cold-execution question |
| `zig cc` on consumer C | No direct removal of work that precedes its invocation | Could affect later build cost; matched evidence missing |
| AOT compiler/transformer code | Can affect executed code, but much of the retained path is already native | Native code alone does not eliminate phase instantiation/context construction |
| Qualified interface-construction product | Potentially removes repeated parsing/generic expansion while retaining fresh construction | New semantic/effect/dependency contract; benefit and full coverage unmeasured |
| Direct high-level MLIR backend for consumer | Removes later generated-C frontend work for covered code | Does not automatically remove imports/expansion needed before export |
| MLIR optimization of compiler/expander implementation | Potentially changes the native execution of that implementation | A separate self-hosting/producer project with complete closure/control/GC proof obligations; not inherited from consumer backend support |
| Zig service/packaging | Carries immutable constructor/code products and dependencies and process boundaries | Does not infer or reuse live Scheme state; no independent expander semantics |

The [unit/artifact contract](compilation-unit-artifact-contract.md) therefore
needs both generation/native products and this explicit code/instance distinction.
The smallest correct unit for interface reuse is the authoritative phase/context
construction program plus dependencies, not an arbitrary `.ssi` file or a native
object containing part of a transformer. Instantiation identity remains per
current module/phase/runtime rules.

Any constructor design must preserve import order, phases, dependency identity,
delayed evaluation, reload/cycle/error behavior, lexical marks, mutable properties,
roots, continuation behavior and demand initialization. Compile-time effects
that cannot be captured forbid skipping that execution. This contract is generic
to language implementation; a Darwin-only deployment policy does not prove a
Darwin-specific root cause.

## 5. Selected Direction and Evidence Limit

Prioritize the **executed pre-first work** when reasoning about the five-second
boundary. Separately retain the generation/native-build unit design for later
build costs. Reuse existing reached evidence rather than treating a new cache or
tool name as a causal explanation. AOT immutable code and required live
instantiation must be accounted for independently.

The design does not yet identify a sound transformation with a quantified saving
large enough to close the first-log/build/test goals. No fixed sleep has been
established, and no compiler replacement, header flag sweep, warmed substitute,
log change or threshold extension is selected. Root attribution and the complete
interface-constructor specification remain required research work.

## 6. Retained Report Identities

Documentation checks: 152 local file/heading references across the collection
and Markdown table widths passed. The new Darwin boundary diagram and the unit/
invalidation diagram rendered with D2 v0.9.0/dagre and were visually inspected
after rasterization. No native source, build rule or historical receipt changed.

These SHA-256 values bind the parent-repository reports actually read. Their
source anchors and observations retain the original report scope and are not
new live source or timing qualification.

| Parent receipt filename | SHA-256 |
| --- | --- |
| `d1510-host-exit-branch-boundary.md` | `1552f166db7901b1cd4af805fce65dfaa62e0d9d889ca3e839de49614b2019bf` |
| `d1510-terminal-driver-exec-not-admitted.md` | `1945f57c951009bda07a3e77d4d1cbf2bd423e8c33490c2edfe6a6563c0347ed` |
| `d1510-preparation-and-register-boundary.md` | `658a1436bbbd459fd6f59cfe6128d6a425e9072c11a3e9c487599c55179f31aa` |
| `d1510-gambit-eval-platform-boundary.md` | `3dd6ced4c58ae55fe4cc957c40f650967a8ef0dc37977043fca7dff3b6f18ea3` |
| `d1609-current-first-window-cpu-and-exact-map.md` | `a7240848cb62a49f88b3d1186b1a0684d4a61489e99d4b5ce7b7e893d63af76b` |
| `d1731-first-window-native-load-boundary.md` | `f57c0c3f1dbda5bbbcb298036d6ab205e4a414a5cfc6cbe0e5b46cd8d3e14503` |
| `d1510-interface-architecture-transfer.md` | `88fa4275c0c6f2fa41309b61f5d3f5b9e51c23faf61c115160f689e18c16120e` |
| `d1510-interface-reader-budget.md` | `b65ab19e4f0aa7d6a6c8f313be4d8e0b80907ff52980d316a881c28ed4e2075b` |
