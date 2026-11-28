# Cancellation Writer Modernization: Benefit and Cost Matrix

Decision criterion: semantic capability, avoided work, state duplication and
runtime/qualification cost. No person-day estimate, synthetic speed percentage or
native measurement is used. [Design](tcl-cancel-writer-design.md),
[arguments](tcl-cancel-writer-arguments.md), [evidence](tcl-cancel-writer-evidence.md).

WV01. Thirteen necessary support families survive either language choice.

| Necessary family | Modern generated C support | Zig support | Work eliminated exclusively by Zig |
|---|---|---|---|
| 1 Contract/policy identities | Scheme schema -> typed C tables/records | Same schema -> Zig types/tables | None established |
| 2 Target/owner/native lifetime | Handles, generation validation, lease functions | Same handles/generations/lease operations | None |
| 3 Immutable byte ownership | Allocator wrapper, protected ref acquisition, retire holders | Allocator use, protected ref acquisition, retire holders | None |
| 4 Slot/token publication | C/A commit, ready/active protocol | Same native locks/token protocol and C facade | None |
| 5 Installed contributors/subtree | Cell transitions, coverage/progress records | Same transitions and coverage | None |
| 6 Destructive check/diagnostics | C-before-filter order, result ABI and leases | Same order, Tcl result ABI and leases | None |
| 7 Durable completion guards | Native/NRE/coroutine ownership records | Same durable ownership; lexical defer insufficient | None |
| 8 Source clear/owned reset | Scope requests, predicates, dispositions | Same requests, predicates, dispositions | None |
| 9 Trace snapshot domain | Whole-word source event or separate owned cell | Same explicit policy and writer migration | None |
| 10 Reentry/failure/delivery | Generated cleanup states and nonlocal-exit boundary | Error/defer plumbing plus same boundary/state machine | Only local syntax reduction is plausible |
| 11 Deletion/drain/image lifetime | Detach/grace join/reclaim | Same join and allocator/image lifetime | None |
| 12 Public/private ABI and ingress | Thin raw/stub facade, single state authority | C facade/stubs and imported ABI/layout qualification | None; possible extra boundary |
| 13 Closure/evidence/debug | Writer inventory, receipts, policy-matched controls | Same semantic obligations plus provider/toolchain evidence | None |

Thirteen is a declared architectural inventory, not a measured code size or a
lower-bound theorem. Six families cover the runtime core (2–6 and 11), while
the others support specification, completion, control, interfaces and evidence.
The prior twelve-family inventory did not separately charge the newly exposed
trace snapshot domain. Both providers must now charge it; this is not a cost
saving. [WD01–WD18, WP03, WP09]

WV02. Source-derived work counts identify real savings and added work.

Let M be explicit native message bytes, S the displayed prefix selected by the
source's -1 string path, I actual installations of that retained pending payload,
E displayed error materializations, K distinct live payloads, D visited
descendants, H async handlers and Q ready re-marks. Counts below exclude object
conversion internals, allocator rounding, result-string caching and extra copies
in Tcl result/errorCode APIs. They are not wall-clock estimates.

| Work/storage term | Pinned path | Immutable owned-cell candidate | Boundary |
|---|---|---|---|
| Explicit pending byte copy | M per accepted non-NULL request | M per successfully frozen explicit payload | No automatic ingress-copy saving |
| Target installed-message copy | Up to M per non-default installation | Zero payload-byte copy on reference installation | Avoids approximately I*M copy bytes for such installs; metadata/leases added |
| Displayed output construction | At least S bytes for each nonempty explicit result construction | Retained at Tcl result boundary | At least E*S remains; no lossless-output claim |
| Source reset destinations | Five named body/caller destinations plus trace restoration | Shared clear authority, necessary source points retained | Duplication of authority can retire; semantic work remains |
| Raw pending buffer allocation | ckrealloc may reuse storage across requests | Immutable replacement may allocate each distinct payload | Allocation frequency and peak bytes can increase |
| Payload retention | Pending buffer + installed Tcl object strings | Sum of K distinct live payload sizes plus lease/contributor records | Sharing saves duplicate bytes; stale views/slow clients can retain many K |
| Contributor metadata | Installed shared bits contain no generation provenance | Up to O(G) uncovered generation metadata | Compression requires a separate proof; capacity decided before acceptance |
| Descendant propagation/reset | O(D) visited target operations | O(D) plus coverage/progress bookkeeping | No asymptotic tree-work elimination proved |
| Async ordering/readiness | Repeated ready search and callbacks | Selected prior gate policy retained | Ordered finite bound O(H*(Q+1)); no new whole-dispatch saving here |
| Commit callouts | Conversion/decrement/message object work under C | Zero such callouts in admitted commit | Requires core rewrite; moves work outside lock rather than erasing all work |

An install for an empty/default message has distinct behavior; M=0 does not
establish a positive copy benefit. A pending record may reinstall without a new
accepted request. Descendant messages are not copied by the source callback, so
I*M must not be multiplied by D. All terms are equally available in modern C
and Zig. [WX02–WX07, WX09, WX12, WO01]

WV03. Explicit net-benefit conditions replace invented ratios.

For a matched semantic policy and admitted history h, define resource-specific
vectors rather than adding unlike units:

```text
DeltaCopy(h) = I*M - extraCopyBytes(h)
DeltaAlloc(h) = oldAllocationWork(h) - immutableAllocationWork(h)
DeltaRetained(h) = oldPeakBytes(h) - newPeakBytes(h)
DeltaCommit(h) = oldLockedCalloutWork(h) - newCommitMetadataWork(h)
DeltaAuthority(h) = retiredIndependentStateWriters(h) - newIndependentAuthorities(h)
```

For multiple payloads the opportunity is the sum of I_j*M_j; extraCopyBytes
includes failed/retried preparation that the old path did not perform.
The copy mechanism is positive if I*M exceeds additional copies; a total
runtime benefit additionally requires allocator/lease/contributor/guard costs
and retained-memory costs to be acceptable under the chosen workload objective.
If explicit payloads rarely reinstall, allocator reuse was effective, or K is
large, copy reduction may fail to pay for immutable ownership. Lock exclusion of
callouts is a capability/deadlock boundary improvement even without a latency
number; progress still depends on owners and callbacks returning. Weighted totals
need declared units/objectives and real coefficients; none is supplied here.
[WD04–WD14, WP01, WP02, WP08]

WV04. Retirement is eight conditional bundles, zero completed retirements.

| Bundle | Old support potentially removed | Support that remains or is added | Retirement condition |
|---|---|---|---|
| R1 | Mutable parallel pending fields and ambiguous replacement ownership | Immutable payload/slot/leases | All ingress and repeat-install policies migrate |
| R2 | C-held conversion/decrement/reallocation logic | Preparation and post-commit cleanup | Failure ownership, target lease and hook boundary qualified |
| R3 | Mutable installed Tcl message buffer/copies | Diagnostic refs and output construction | Default/stale/child/byte behavior preserved or changed explicitly |
| R4 | Unattributed direct cancellation mutations | Shared check/install contributor logic | All check and set writers, filtered ordering and scopes covered |
| R5 | Independent inline/private clear bodies | Exact source requests and final guard | Completion and source-point behavior independently proven |
| R6 | Separate subtree/parser clear accounting | Per-target traversal and source predicates | Real caller coverage including stubs/aliases |
| R7 | Whole-word restoration authority over cancellation | Source snapshot tracking or owned domain | No mixed shadow writers; changed trace semantics admitted |
| R8 | Immediate C-held resource destruction | Deferred retirement/drain/image joins | No surviving claim/native scope/foreign resource dependency |

These are replacement groups, not eight eliminated semantic responsibilities.
The public C ABI and private stubs cannot retire from a source-only inventory.
No runtime path has retired in this documentation study. [WD12, WD15]

WV05. Modern C and Zig share architectural benefits; incremental benefit is unproved.

| Dimension | Existing pinned path | Modern generated C | Zig provider |
|---|---|---|---|
| Cancellation state authority | Pending/installed bits, mutable message, snapshots, independent clears | Single policy-owned cell with audited source/normalized modes | Same cell and modes |
| Trace safety | Whole restore can overwrite C/U | Explicit source event or cancellation-separated trace domain | Same redesign required |
| Deadlock boundary | Some object work/cleanup under C | Callout-free commits and deferred cleanup | Same protocol required |
| Byte copy opportunity | Recopy at installation | Immutable installed refs | Same saving |
| Failure ownership | Lookup vs success reference decrement differs | Explicit raw/managed dispositions | Same dispositions and C ABI adapter |
| Completion correctness | Source callbacks do not cover every early path | Early durable guard and exact source-point requests | Same records; defer helps only local lexical exits |
| LLVM/MLIR integration | No ownership contract supplied by LLVM | Effectful native service ABI independent of backend | Same ABI; Zig not required to access LLVM |
| Additional qualification | Existing behavior not thereby qualified | New generator/native protocol proof and measurements | Same obligations plus Zig toolchain/ABI/provider drift |

No necessary support family is shown to disappear uniquely with Zig. The C
mainline receives the modernization benefit without a second language provider.
This does not prove Zig is always worse: a later shared-provider/toolchain benefit
could outweigh its added boundary, but it must be independently demonstrated for
equal capabilities, not counted again from this shared redesign. [WD16, WP09]

WV06. Countable theory progress is not implementation acceptance.

| Evidence quantity | This study | Meaning |
|---|---|---|
| Pinned committed C/H/M blobs reread | 350 (324 recaptured, 26 reused) | Byte/tree-bound text coverage |
| Cancellation-symbol matching files/lines/occurrences | 10 / 104 / 114 | Includes non-call text; not semantic call count |
| Broad flag/constructor matching lines | 99 | Exposes trace whole-word restoration |
| Named reset body/caller destinations | 5, plus a separate trace writer | Scoped source migration inventory |
| Necessary support families in each provider | 13 / 13 | Same semantic work inventory |
| Exclusive Zig support families eliminated | 0 established | Incremental theory gate remains open |
| Conditional arguments / inert cases | 10 / 37 | Handwritten, 2 positive controls, unexecuted |
| Old runtime paths retired / native profiles qualified | 0 / 0 | No implementation/admission claim |

WV07. Modernization should retire state authorities before adding providers.

First bind the full writer profile and choose source versus normalized trace/
reset behavior. Then share payload/handle/transition/receipt schemas, migrate all
ingress and checks, replace independent source-point clear bodies, and close
deletion drainage. Retire old authoritative representations only after caller
and lifetime closure. The resulting native service is a reusable modernization
asset for FFI, roots, release coordination and backend boundaries; cross-component
reuse must be measured without counting one support module as several savings.
Add a Zig provider only if its incremental advantage survives the equal-policy
C baseline. [WD15–WD18, WP09, WP10]

WV08. Decision remains conditional and falsifiable.

The concrete positive mechanism is eliminating mutable duplicate message state,
locked object callouts and independent reset/snapshot ownership. The concrete
counter-costs are immutable allocations/leases, contributor history, durable
guards, partial-subtree custody and broader ABI closure. Trace snapshots may
force a deliberate semantic modernization rather than transparent replacement.
This supports continuing modern generated C as the mainline; it establishes no
positive incremental Zig net benefit and no total runtime speedup. A failure to
close raw/private writers, preserve declared source controls, or bound retained
payload/debt would falsify admission of either provider. [WP01–WP10]
