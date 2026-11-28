# NJS Reuse Costs and Gambit Modernization Matrix

Reviewed: 2026-10-20. [Detailed contract](njs-executor-storage-cleanup.md),
[source/paper ledger](njs-executor-evidence.md). Theory/source design; no
implementation, native experiment, timing or maintenance-hour measurement.
This adds modernization acceptance criteria to the NJS portfolio comparison.

## 1. What the Comparison Controls

S = typed Scheme direct execution with current runtime ownership. C-G = modern
C native service with qualified platform support or mature C library reuse.
C-ZT has the **same C core**, with the selected common downstream Zig driver;
it has no new storage/cleanup advantage inside NJS. Z = Zig service using the
same request, capabilities, storage policy and deployment as C. W worker costs
apply to both C/Z; S must be compared separately before adopting W. C-G is not
charged a fresh platform library if existing reusable support meets the domain.

Q captures stdout only with inherited stderr/stdin under the selected baseline;
B inherits stdio. Initial bounded BS1 storage is feasible under an admitted limit
in all languages. Neither two-stream capture nor geometric growth is mandatory.
Narrowing the necessary domain removes those hypothetical Zig-only savings.

## 2. Reuse / Residual-Code Matrix

Each RS row is a **responsibility**, not an observed code unit or line count.
Several can share one controller. All new adapters remain proposed.

| ID / duty | Existing Scheme reuse | Mature C reuse: C-G/C-ZT | Zig reuse | Project code still owned / potential delta |
| --- | --- | --- | --- | --- |
| RS01 child launch/status | Process ports and runtime status already present | libuv spawn/exit or qualified simpler platform adapter | Selected process primitives, or same C library | Plan/env/cwd/tool/status mapping; platform mechanics can be delegated, not semantic adaptation (X02/X04/P01/P02) |
| RS02 wait/control owner | Existing Scheme I/O wait and child reaper | Independent worker loop or integrated single-owner protocol | Same owner requirement | Gateway and launch/terminal/observation controller remain; no second in-process reaper (X04/X06) |
| RS03 stdout bytes | Existing u8vector/byte-port operations | Caller-provided buffer to library reads | Exact allocation/read primitives | Used/limit/probe/EOF/aggregate-budget policy; no mandatory native grower (X03/P01/P02) |
| RS04 inherited stdio/TTY | Current process settings and compiler reset path | fd/stdio options plus worker-forwarding adapter | Selected stdio options plus same forwarding contract | Q/B policy and controlling-terminal equivalence; capture helper cannot replace it (X01/X02) |
| RS05 query interpretation | Scheme string/byte operations reusable | Ordinary bounded views/decoder routines reusable | Slices/library operations reusable | Shell normalization, package flags, ordering and rejection semantics remain (X01/P05) |
| RS06 rich diagnostics | Existing exception/error values plus new envelope | Selected storage/format support | Error propagation plus selected byte support | Catalog/origin/fallback/caller error precedence stay; no external protocol deletion |
| RS07 resource cleanup | Ports/runtime plus controller dynamic actions | One owner/acquisition state and backend close callbacks | Scope cleanup for local resources plus explicit escaped owners | Completion/close/transfer laws stay; possible local wiring saving only (X05/P01/P02) |
| RS08 async lifetime | Existing runtime-managed port/device lifetime | Stable owner through pending callback/close completion | Same when using asynchronous API, including a C backend | Callback quiescence/ID-generation rules remain; not discharged by scope exit |
| RS09 result bytes/ack | Scheme-owned result under GC plus native gateway if chosen | Explicit backing-store transfer | Owned slices or same explicit buffer owner | Fallible decode/copy/ack ordering and delayed release remain |
| RS10 failure/shutdown | Existing status/timeouts are primitives | Reap/close primitives, not a project recovery protocol | Same; kill/defer is not tree recovery | FT01-FT10 controller, unknown outcome/orphan policy; no automatic retry |
| RS11 profile/output/invalidation | Gambit semantic/configuration authority retained | Shared canonical profile/recipe and product protocol | Same | Mode/root/alias/path/dependency rules retained; language cannot retire semantic laws |
| RS12 build/dependency maintenance | Current Scheme/runtime support, plus real new adapter work | Actual compiler/library/platform support | Marginal language/stdlib/import/build support | Versioned affected-use review and coexistence/exit costs; shared driver cancels only when truly common |

No reviewed current C native runner/storage/cleanup family is shown globally
deletable because of Zig. NJR01-NJR05's managed shell/compiler-path replacements
remain real **shared reconstruction targets**, conditional on caller/E closure.
Generic Scheme process support, public APIs and legacy users remain.

## 3. Cost Ownership / Scaling Matrix

| ID / account | Pay once / share only where actually used | Still scales with | Admission / attribution rule |
| --- | --- | --- | --- |
| CA01 backend acquisition/integration | One chosen runner backend for Q/B | Host ABI/capability changes and affected adapters | Credit existing support; compare libuv and simpler C control; RFD has no runner edge |
| CA02 observation/storage support | One BS1 policy/primitive adapter for Q | Active captures and real size/probe budgets | B inheritance does not use query bytes; optional dual capture/spill is separate demand |
| CA03 custody/cleanup controller | One lifecycle mechanism across Q/B | Distinct resources and failure transitions, actual callbacks | No saving counted once per FT row, disposer or generated mode |
| CA04 public semantic adapters | Some common records/status framing | Each query format, caller, mode/TTY/output/error obligation | Meanings do not amortize away; same physical layout is not same protocol |
| CA05 boundary/deployment | One selected worker/gateway introduction | Starts, submissions, copying, waits, failures and shutdowns | S-versus-W decision independent; no daemon/K<N assumption |
| CA06 library/language upgrade | Shared actual update owner | Changed API use sites and platform qualifications | Assign each task to one account; don't also charge it as CA01/CA03 work |
| CA07 migration/coexistence/exit | Shared policy/caller plan where genuinely common | Each real caller replacement, residual old support and exit change | Managed bypass does not remove installed legacy/info/runtime maintenance |
| CA08 modernization acceptance | One explicit target model/contract vocabulary | Each protocol's independent source/semantic/native/cost evidence | Source docs/model consistency are not runtime correctness or quantified ROI |

For genuinely demanded consumers D={Q,B}, let `s_local_i` be each disjoint
C-to-Z local work saving and `s_shared_j` each unique shared-artifact saving
**after reuse**, all in compatible cost units over horizon H. They can be
negative. Let I collect incremental migration/coexistence/deployment/coordination/
language/exit work **excluded** from those saving accounts. Then:

```text
Net_Z-C(D,H) = sum_i s_local_i + sum_j s_shared_j - I
positive certificate: lower_bound(sum_i s_local_i + sum_j s_shared_j)
                      > upper_bound(I)
```

A new necessary consumer k helps only if its disjoint incremental saving exceeds
its new cost, without re-claiming already shared support. An optional L LLVM
adapter or RFD worker placement cannot be added to D merely to lower F/n. RFD
does not fund runner maintenance; B does not fund unused capture machinery.
Both C and Zig share once; comparison is against the best **admitted** reuse
control, not a hypothetical unsupported library with zero integration cost.

BS1 and single-stream Q remove an alleged mandatory growth/dual-drain support
advantage. Remaining Zig-positive mechanisms are bounded local propagation,
selected platform/library glue and cross-adapter helper reuse that C/S reuse
does not already remove. None has a defensible positive aggregate cost interval
yet. Conversely a small C/library/S controller meeting the same domain with no
extra private bodies, plus positive Zig migration cost, is a nonpositive model.

## 4. What Gambit Modernization Means

Modernization means increasing **capability, semantic clarity and sustainable
evolution** with explicit correctness/resource boundaries and defensible costs.
It is not a feature count, a language age, a no-GC label or an imported compiler.
OCaml's history makes the cross-layer obligations visible: evolving parallel
execution involved collector/C-interface/sequential-behavior constraints, not
just replacing syntax [O01-O03]. Retained semantics and rollout costs are design
inputs; they are not a demand to preserve every legacy C emission mechanism.

The following are proposed acceptance criteria, not a claim current Gambit lacks
all of them. Its existing parameterized backend, byte APIs, root writeback and
configured parallel collector paths are concrete assets [X03/X06-X09].

| ID / modernization criterion | Gambit design target / user value | NJS direct contribution and limit | C-G/C-ZT / Zig relevance | Evidence / future acceptance |
| --- | --- | --- | --- | --- |
| MG01 explicit semantic authority | Scheme semantics, G3 roots/control and backend negotiation remain coherent while emitters change | Native plan/recipe boundary reduces hidden shell decisions; does not complete G3 extraction | Shared architecture, language choice independent | X08/X09; one owner per rule and source/consumer correspondence |
| MG02 composable resource ownership | Native calls/jobs can coexist without stealing status, fds or lifetimes | One reaper owner, byte/result custody and close completion | All implementations must satisfy it; Zig local syntax may help | X04/P01/P02; FT and owner transitions qualified independently |
| MG03 parallel runtime semantics | Define independent VM, processor participation, shared-object publication and synchronization guarantees | Worker removes one native reaper collision domain; no Scheme memory model or scheduler redesign | C/Z atomics/types do not supply Scheme semantics | X07/O02; explicit memory-order/VM admission, not worker throughput |
| MG04 collector/compiler/FFI co-design | Allocation, roots, barriers, capture and callbacks evolve under one runtime protocol | Native-owned job bytes avoid escaping moving pointers; gateway still participates in runtime wait/control | Zig no-GC is compatible only through explicit ownership/root boundary | X06/X07/O01/O03; trace root/reload/blocking obligations |
| MG05 structured concurrency and control | Lifetime of jobs, failure propagation and shutdown remain defined under exceptions/continuations | FT table exposes pending/unknown custody; full subtree cancellation and task scheduler remain separate | Library/defer reuse does not define cancellation or continuation policy | X05/P01/P02; bounded supported lifecycle and no unsafe retry |
| MG06 predictable resource/latency behavior | Bound native memory and define waiting/collection latency objectives | BS1 controls retained bytes; no time bound follows from byte limit | Exact bounded buffers work in Scheme/C/Zig | X03/O01; separate peak storage, sequential cost, pause and throughput gates |
| MG07 explicit, evolvable FFI | Data/handle/control/effect boundary permits later GC/representation change | No raw movable-pointer retention; status/bytes stable at chosen facade | C import eases declarations, not semantic/ownership migration | X06/O03; release/reacquire/callback/root design specific to Gambit |
| MG08 pluggable native/LLVM services | Reuse target/IR engineering without coupling language semantics to provider internals | Same executor for admitted external driver; optional provider adapter owns its handles | C APIs/common Zig driver keep tool/language choices separable | Prior provider ledger; versioned profiles and independent mixed-tail/object gates |
| MG09 correct incremental/AOT reuse | Skip actual repeated work only with complete identities/dependencies | Sealed plan/result provenance is a prerequisite; no cache HIT or earlier interface-instance saving shown | Shared contract, neither Zig cache nor C build switch proves closure | Existing artifact/E contracts; exact invalidation and caller behavior acceptance |
| MG10 observability and failure attribution | Distinguish launch/tool/bytes/cleanup/delivery; diagnoses survive failure | Structured ExecutionRecord and FT cases improve fault localization | Reusable transport plus component-specific meanings in all controls | X01-X06; independent argv/env/cwd/status/byte evidence, gaps explicit |
| MG11 sustainable replacement and upgrades | Retire obsolete rule owners; contain changes without indefinite wrapper stacks | NJR managed callers can replace shell protocol; legacy/runtime support remains accounted | CA06/CA07 include C and Zig maintenance, migration and exit | Caller/E/source evidence; no old reachable owner in retired scope |
| MG12 language evolution with economic discipline | Preserve Scheme strengths while admitting useful new optimization/runtime capabilities | NJS is enabling infrastructure; higher-order/region/continuation work has separate semantic path | Zig adoption needs net increment over modern C, not borrowed LLVM/OCaml prestige | All MG/CA claims and theory gate; no weighted score or automatic adoption |

OCaml 5.3 documents domain-local minor allocation with parallel stop-the-world
minor collection, concurrent major collection and a memory model [O02]. Those
are runtime choices, not services a new NJS or Zig automatically installs.
Its C runtime access rules also show why blocking/callback boundaries must be
designed explicitly [O03]. This study does not transfer OCaml guarantees,
benchmark ratios or APIs to Gambit.

The modernization acceptance vector has separate semantic, concurrency, resource,
evolution and economic obligations. A favorable row cannot compensate for a
broken root/control contract. Passing these architectural objectives in C would
still modernize Gambit; choosing Zig additionally requires the cost certificate.
NJS advances MG02/MG10 and portions of MG01/MG06/MG11 by design, enables parts of
MG07-MG09, and leaves core MG03/MG04/language semantics as separate work. No
runtime criterion is marked passed by these documents.

![Gambit modernization targets and NJS scope](gambit-modernization-contracts.svg)

[D2 source](gambit-modernization-contracts.d2).

MG03/MG04/MG07 now continue into the
[Gambit core runtime contract](runtime-root-participation-contract.md), with
[root/participation/VM evidence](runtime-root-participation-evidence.md) and
[matched C/Zig cost and migration matrices](runtime-modernization-cost-matrix.md).
This is core-runtime work distinct from NJS: existing root reload, RC/still,
collective service and configured VM machinery are retained, while new detached
participation/attachment require explicit source/semantic design. No runtime
criterion or language-value gate is marked passed by that extension.
