# RC / Marker Minimum: Maintenance and Net Benefit

Research-scope correction: this document specifies the **Bmin repair control**.
The [complete modernization architecture](modernization-system-architecture.md)
is now the primary Experimental candidate. Local saved0/C-shell economics and
storage choices do not constrain that candidate's runtime ABI or portfolio;
they remain a fair cost/capability control and source evidence.

Reviewed: 2026-10-20. [Design](rc-marker-minimal-contract.md),
[evidence](rc-marker-caller-evidence.md). Subaccounts of the existing OM/KC/RR
ledgers; no duplicated benefit credit, implementation or native tests.

## 1. Minimum Change / Reuse Matrix

| ID | Responsibility | Existing candidate credit | Remaining minimum design change / condition | Retained boundary |
| --- | --- | --- | --- | --- |
| MR01 active RC scan | B1 already marks every processor's RC data and adds root-phase ordering | Bind each actual registration/list/scanner to same VM/phase; retain and qualify existing change | No replacement registry/collector; no new claim of implementation |
| MR02 successful retirement | B1 splices RC/still lists after successful join, before cleanup | Close donor mutator/borrower and successor scan/lifetime argument at actual callers | MISC lock alone does not serialize all native helpers |
| MR03 failed retirement | Pending join retention, recovery and cleanup/resize guards exist | Specify next-GC root custodian or prohibit ordinary allocating resumption until repaired; recovery effects included | Retention is not enumeration; broader recovery costs separate |
| MR04 marker target root | B1 already uses GC_SAVE1/RESTORE1 | Issue MP1 saved0 reservation/no-clobber/window contract; qualify actual direct target and inputs | No new pstate ABI or heap root for admitted one-target window |
| MR05 all-exit scratch cleanup | B1 SFUN helper clears scratch on marker throw | Give common marker extent ownership or prove equivalent run/SFUN callers; clear only acquired scratch and rethrow original destination | ___run stays distinct from SFUN lifetime lease; C nonlocal rules retained |
| MR06 dynamic target | Existing RC data and platform trampoline on enabled targets | Pre-effect invocation capture and same-carrier reload/last-use, if that capability is demanded | No new TLS/trampoline merely for a disabled platform branch |
| MR07 caller/input scopes | Static export, byte RC and Tcl still-vector patterns exist | Bind CFUN/SFUN parameter/converter/error roots, pre-run startup collective and deletion/last-read facts | Target guard does not imply complete FFI root census |
| MR08 extension choice | Existing saved/RC/mapped-frame primitives credited | Only select MP3/MP4 if an actual necessary overlapping/multiple-root caller defeats MP0-MP2 | New allocation/extent/ABI/scanner/unwind work priced in every control |

B0 vendor is not credited with B1 code already installed. B1 is credited as
existing project support for comparison, without claiming its complete native
qualification. Extracting a subset of a large patch requires its actual source/
layout/phase/control dependencies; hunk size is not correctness or effort.

## 2. C-G / C-ZT / Zig Comparison

C-G uses modern/generated/opaque C, current saved/RC runtime and the same Scheme
plan. C-ZT keeps that C core plus an independently selected common downstream
Zig tool. Z retains the same runtime/control region and uses Zig for justified
private native consumers. Capabilities and caller/retirement policies must match.

| ID / dimension | C-G | C-ZT | Zig differential | Net-benefit implication |
| --- | --- | --- | --- | --- |
| RN01 nonzero RC roots | Reuse B1 scan/update/transfer | Same C core | Same collector algorithm/phase proof | Shared correctness credit, no Zig-only saving |
| RN02 one-target bootstrap | Existing fixed saved root with declared short extent | Same | Required managed operations stay C/runtime | MP1 needs no new generic C root library to avoid |
| RN03 native wrapper state | Scheme-issued target/effect/exit plan, generated or opaque helpers | Same | Tagged private product may aid necessary consumers | Only actual private construction/review work absent from C alternative counts |
| RN04 nesting | MP1 windows end before target invocation; markers preserve outer roots | Same | Same non-overlap/last-use proof | Callback depth alone does not justify a new Zig root-stack framework |
| RN05 allocation throw/run | One valid C cleanup owner with same-thread live catcher rules | Same | Retains C shell; Zig defer cannot replace it | Extra bridge/status representation can increase support |
| RN06 native retained target | Qualified RC data and carrier/callback lifetime | Same | No-GC native language grants no scanner coverage | MP2 does not save a collector implementation |
| RN07 failed join/recovery | Complete custody/admission or new enumerated carrier design | Same | Same runtime feature and native qualification | Do not amortize an optional unsupported recovery feature as language saving |
| RN08 provider/MLIR | Shared root/relocation/continuation contract constrains safepoints | Same tool role where genuinely common | Private native integration only, C runtime still required | LLVM availability is not a language-only root/GC gain |
| RN09 runtime cost | Existing slots/scans, candidate deltas and explicit checks | Same core | Imports/dispatch/marshalling may add operations | No measured allocator/GC/latency saving; no-GC Zig does not remove Scheme GC |
| RN10 maintenance/exit | C ABI/control/runtime ownership plus Scheme generator | C + common tool cost once | Additional language/import/build/debug/training/extraction | Shared tools cancel only where identical; residual language burden remains |

For this **specific minimal topology**, if all necessary managed entry operations
and cleanup stay in the existing/generated C shell and Zig adds only a handle/
status wrapper, no disjoint private support family has been shown removable.
The design permits S_private=0. With any positive incremental bridge/language
cost, that topology is nonpositive for Zig. This is a theoretical countermodel
and a reason to prefer the minimal shared C/runtime reconstruction for this
slice; it is not a measured project-wide rejection of Zig.

A positive Zig domain still requires necessary ordinary-return native consumers
whose **union** of private support avoided after C/Scheme/library reuse exceeds
all incremental language, bridge, migration/coexistence, qualification and exit
costs over a stated horizon. RC scanner work, marker correctness, candidate
repairs and retirement algorithms are common work, not that numerator. Sharing
NJS/planner helpers can be considered only with real consumers/change events;
this managed slice cannot manufacture their demand or recount their saving.
No bounded positive interval is established here; TG4/TG5 stay open.

## 3. Structural Cost Bounds, Not Measurements

| Measure | Source/design bound | Important limit |
| --- | --- | --- |
| MP1 target root storage | One existing saved slot borrowed during short window | No new heap allocation or pstate field for that window; extra live input roots separate |
| MP1 save/reload | Macro shape: one root store, one root load, one clear store | Source operations, not emitted instruction counts or latency; compiler/profile effects unmeasured |
| Callback depth D | Marker/storage use follows live activations; MP1 scratch windows need not overlap | Depth is not D simultaneous saved slots under the selected effect contract |
| Active RC enumeration | Per cycle visit sum_i C_i registered headers, including FAL data; B0 visible list scan is C_0 | Added source visitation scales with sum_i>0 C_i, not free parallel work or measured pause improvement |
| Retirement splice | RC list concatenation has constant pointer work; still-list concatenation walks donor still list | Join/borrower drain/receiver phase, error/recovery and native readers can dominate; not a constant-time retirement claim |
| MP3 temporary roots | K one-slot native RC carriers require K allocations/releases and header storage | Header fields are 2 native pointers + WORD + SCMOBJ before padding/allocator overhead; payload bytes are not K root slots |
| MP4 extents | Declared K slots and nested live extents need enumeration/lifetime storage | Actual growth/capacity/ABI/control protocol not selected; do not charge a large generic framework to minimal C |
| Caller count | Three SFUN result families + direct run; eleven existing primitive SAVE1 windows selected | These are source families/windows, not application frequency, native coverage or saved maintenance hours |

Cost certificate by actual change event must include: root/scanner invariant
changes; new allocating converter/input/result; nonlocal mode/profile change;
new retirement policy or caller; dynamic target provider enablement; C/Z import/
stdlib/tool upgrade; and removal/exit. Count an existing support body once and
its genuinely separate per-client change work only with a reviewed denominator.
No percentage, milliseconds, throughput multiple or person-day estimate is
invented from source counts.

## 4. Retirement and Migration Dependencies

| Stage | Required design product | Conditional retirement / stop rule |
| --- | --- | --- |
| RMS00 source/cohort | Distinguish B0/B1/installed identity; actual ABI, supported RC-C1..RC-C7 and same-owner callers | Preserve prior patch/fixture receipts; no dynamic provider redesign for an unused branch |
| RMS01 RC phase/custodian | MR01-03, active scans, successful transfer, failed-join GC policy, update/release/cleanup ownership | Retire P0-only assumption on selected RC route; retain list/scanner/collector, no new runtime implementation now |
| RMS02 root strategy | Caller target/input census; MP0-MP2 first; MP1 slot reservation and transitive effects | Reject unknown overlapping saved use; add MP3/MP4 only for necessary unsupported demand |
| RMS03 exit/nesting | MR05, RE01-RE10 and direct run included; correct catcher/root/lease/marker order and unchanged owner binding | Replace duplicated scratch-cleanup decisions with one owner; retain configured C shell and continuation behavior |
| RMS04 scope/old-path closure | Actual generators/clients fully consume chosen plan; code/module/deletion/last-read boundary | Legacy APIs and clients remain maintained until genuinely migrated; no code is declared retired here |
| RMS05 paired theory costs | Same-caller C-G/C-ZT/Z, B1 credit, support union and bounded incremental change costs | Minimal wrapper-only Zig topology can be nonpositive; choose C unless broader necessary support proves benefit |
| RMS06 later qualification | Only after a separately authorized implementation decision | Exact-profile independent native root/control/retirement safety/progress; existing fixture is reused, not duplicated or rerun here |

RMS00-RMS05 refine the earlier OS/RM design stages; RMS06 is future admission.
Architecture open premises RQ01-RQ06 and theoretical cost bounds are not filled
by historical native PASS, document checks, new tests or an engine rerun.
