# Native Job Service: Benefit and Shared-Cost Matrix

Reviewed: 2026-10-20. [Design](native-job-service-design.md),
[evidence](native-job-service-evidence.md). Theory/source report only; no native,
performance or implementation evidence. C-G is the modern C worker/control;
C-ZT uses the same C core plus the selected common downstream Zig driver;
Zig implements the matched service in Zig. The cheaper typed-Scheme topology
must also be considered before selecting any worker.

## 1. Benefit Matrix

S = shared architecture mechanism; L = local conditional implementation benefit;
U = unresolved capability/magnitude; A = added/substituted support;
Z = no attributable Zig-only credit, not measured zero seconds. No weighted ROI.

| ID / dimension | C-G | C-ZT | Zig | Finding / evidence |
| --- | --- | --- | --- | --- |
| JB01 necessity / scope | Existing compile/link/query demand | Same | Same | S: source calls are necessary; resident daemon/parallel scheduler not required (J01-J04) |
| JB02 request/configuration authority | Typed producer + one resolver | Same | Same | S: retire managed shell transport only after M5-M8/E closure; configure semantics retained |
| JB03 command reconstruction | Direct sealed argv removes selected shell substitutions/eval | Same | Same | S: NJR01-NJR04 genuine conditional route replacement; not language-only deletion |
| JB04 child ownership | Worker isolates child waiter from Gambit reaper | Same | Same | S/U: J06 hazard identified; independent worker or integrated owner required, no observed failure |
| JB05 platform process mechanics | Qualified POSIX/platform layer or reused C library | Same | Reusable selected std process layer or same C library | L/A/U: plausible private support avoidance, mature C option real; NJR07 not proven retirement |
| JB06 variable-sized query bytes | Reuse library/storage or bounded spill policy | Same | Selected library storage/I/O support | L/U: stronger actual need than exact RFD arrays; no mandatory homegrown C grower or unbounded-lossless claim |
| JB07 error/cleanup expression | Explicit status plus one ownership/cleanup path | Same | Private propagation/scope cleanup | L/U: possible reduced wiring; resource laws and rich diagnostics remain |
| JB08 query/TTY correctness | Ordered queries and mode-specific stdio adapters | Same | Same | S/U: capture helper cannot substitute inherited stdin/tty; J02/J03/P01 |
| JB09 component reuse | One runner for Q and B; envelope may serve R/L | Same | Same reuse graph | S: no saving multiplied by modes/jobs; pure RFD never uses runner |
| JB10 LLVM engineering | C API or independently selected external provider | Same driver role as Zig if selected | Same API/tool options, easier private C declarations possible | S/L/U: API access/provider algorithms not exclusive; adapter and cohort remain |
| JB11 failure isolation | Separate worker address space | Same | Same | S/A/U: extra provider fatal containment matters only if in-process provider demanded; startup/IPC/crash recovery cost |
| JB12 output/artifact delivery | Explicit result/roles and caller error sequencing | Same | Same | S/U: no implicit atomic multi-file publication, cleanup rollback or runtime load admission |
| JB13 C compile / macro work | Same admitted compiler inputs | Same unless separately selected driver changes them | Same unless backend product changes | Z/U: direct execution alone removes no C preprocessing or Gambit semantic generation |
| JB14 invocation / transport work | Can remove selected script/helper dispatch; worker adds start + messages | Same | Same | S/A/U: structural edges only; elapsed time and amortization magnitude unknown |
| JB15 caching / AOT | Explicit plans and dependency closure enable reuse design | Same | Same | S/U: no HIT without valid closure; no demonstrated new hit or removal of earlier Darwin interface work |
| JB16 GC / multicore | Worker keeps native job buffers outside Scheme heap; gateway remains | Same | Same | S/Z/U: no GC/scheduler algorithm change; no parallel-VM throughput benefit established |
| JB17 platform / upgrade | Target recipes plus host runner/library qualification | Same plus common driver | Same plus marginal language/stdlib/import qualification | A/U: host runner support not target ABI coverage; version changes may affect every using adapter |
| JB18 aggregate net value | Share support once; cheaper Scheme/library controls retained | Common Zig tool cost not charged twice | Share support once, pay actual marginal burden | L/A/U: stronger conditional domain than RFD, no justified positive bound yet |

## 2. Shared Support Ownership / Amortization Matrix

R = RFD; Q = package/metadata resolver; B = native operation executor;
L = optional future LLVM emitter. Q/B are source-present; R native placement/L
are design proposals. Each row is one cost owner, not one new implementation.

| ID / support owner | Actual incidence / reuse | Can be spread / saved | Cost that remains |
| --- | --- | --- | --- |
| SA01 envelope/validation gateway | Q/B; R/L only if same service selected | One transport/schema implementation across admitted requests | Per-component records, validators, root/control/copy delivery; IPC integration not free |
| SA02 child runner | Q/B; L only external-driver mode; R never | One selected backend and shared lifecycle review, not one per operation | Per-tool env/stdio/status capabilities; C library or Scheme reuse can remove prospective C-body saving |
| SA03 variable byte I/O/storage | Q capture; B only if capture demanded; L diagnostics if selected | Shared library primitives | Query decoder, quotas, truncation/encoding policy and success ownership; no reuse of nonexistent B capture need |
| SA04 diagnostics/error transport | R/Q/B/L when admitted | One bounded storage/serialization/transport layer | Origins, catalog, mapping and error precedence differ; one rule is not one saved helper per error exit |
| SA05 allocator/cleanup mechanics | Native R/Q/B/L resources actually allocated | Common allocation policy/library and some propagation support | Distinct lifetime graphs: process, output bytes, RFD plan and provider handle are not interchangeable |
| SA06 effective profile / recipe graph | Q/B; profile identity used by R/L | One canonical configuration source and managed resolver | Generation/installation coherence, target facts and actual per-mode laws; shared C/Zig reconstruction |
| SA07 artifact/result owner | B/L; R plan is separate product owner | Common result framing and selected output validation mechanics | Output path observations, multiple outputs, provider mutation/errors and runtime admission |
| SA08 language/library/build support | Every component that actually uses it | Truly fixed introduction/build/upgrade owner charged once | Each changed use site, platform branch, incident and review; C and Zig can both share support |
| SA09 provider/tool cohort | B tools; L provider; R only through bound profile/product dependencies | One selected tool acquisition/distribution owner | Capability/ABI/upgrade impact at actual consumers; C-ZT shared driver versus Zig language/library costs separated |

`F/n` is a reporting allocation of one real fixed cost. It does not create n
savings, remove F, or make negative marginal work positive. Coexistence costs
cannot be assumed to vanish before NJR/caller retirement. Existing maintained
C support must be compared by incremental work, not charged again as a rewrite.

## 3. Maintenance Change Matrix

| ID / concrete change | Common retained work | Differential/support boundary | Evidence needed for net argument |
| --- | --- | --- | --- |
| NC01 change mode/metadata/package rule | Producer/resolver rule + independent E/caller controls | No language deletion credit for semantic rule | Named rule owner and no second shell/native decision table; NJR02/NJR03 |
| NC02 host spawn/fd/status change | Runner normalization and relevant Q/B adapters | C backend/libuv versus selected Zig library work | One shared backend event plus actual affected use sites, not event multiplied by all jobs |
| NC03 query output size/format or TTY policy | Separate capture/terminal contracts and failures | Storage/propagation body reuse may differ | Required bytes/quotas/decoder domain, bounded residuals, independent acquisition gaps retained |
| NC04 worker loss/shutdown/transfer failure | Custody, status, orphan/output uncertainty and delivery | Same state law; cleanup syntax does not solve process tree | Explicit supported shutdown domain and no unqualified retry/cancellation promise |
| NC05 LLVM provider/IR-driver update | Facade/cohort, registrations, object/runtime/control qualification | Common C-ZT driver work versus marginal Zig imports/library work | Actual bound-input invalidation; no pure-RFD LLVM call requirement invented |
| NC06 core language/library/build update | Using components reviewed against selected API profile | C library/compiler events versus Zig language/stdlib events | P02/P03 demonstrate both dependency lifecycle and concrete Zig API-change surface; no invented frequency |
| NC07 migrate/retire a caller or leave Zig | Caller/E controls, install activation and result ownership | Migration, coexistence and exit costs paid once per real change | NJR01-NJR08 actual reachability evidence; no whole-file deletion with residual callers |

## 4. Portfolio Decision Matrix

| Question | Positive condition | Counterevidence / stopping condition | Current result |
| --- | --- | --- | --- |
| Is NJS a useful system boundary? | Actual managed callers stop shell/native reconstruction and share one owner | New service just invokes old gambuild or duplicates configure/metadata policy | Necessary old service identified; replacement designed, not implemented |
| Does a native worker beat typed Scheme? | Required ownership/provider isolation or support saving exceeds IPC/TTY/control burden | Existing Scheme direct runner meets requirements more cheaply | Open; native independent-reaper hazard favors an ownership boundary, not necessarily native migration |
| Can multiple components justify Zig? | Disjoint local + unique shared saving lower bound exceeds all incremental costs | Shared C reuse erases saving; optional components inflate denominator; negative marginal additions | Plausible domain with actual Q/B consumers; cost/retirement bounds missing |
| Which retirement counts? | NJR caller routes absent, old support owner no longer maintained in admitted scope | Legacy/info/non-C/semantic users still require it | Shared managed-route candidates; actual retirements none |
| Does LLVM force Zig? | Independently demonstrated Zig-specific adapter/support value | C APIs/common Zig driver provide equal provider capability | No language necessity proof; provider service remains useful |

The recommendation is to deepen SA02-SA05 on Q/B against both reusable C and
typed-Scheme controls, with NC event bounds. RFD remains a separate small-core
case. The report issues no positive percentage/engineering-hour estimate,
weighted score, performance result or adoption witness.

## 5. Concrete Support and Modernization Follow-Through

The [RS01-RS12/CA01-CA08/MG01-MG12 matrix](njs-support-cost-modernization-matrix.md)
refines JB05-JB08 and SA02-SA05. Source-required Q captures only stdout and B
inherits stdio; an admitted exact-capacity policy can avoid a generic grower in
Scheme, C and Zig. Library reuse still leaves the plan/stdio adapter, ownership
controller, byte/decoder policy and result/exception gateway. This narrows the
earlier variable-output opportunity without claiming every legacy input is
bounded or current C support is retired. Modernization has explicit semantic,
concurrency, resource and evolution criteria; a language-specific cost decision
is a separate gate. [Detailed contract](njs-executor-storage-cleanup.md) and
[source/OCaml evidence](njs-executor-evidence.md) state the remaining conditions.
