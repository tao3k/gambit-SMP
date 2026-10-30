# Trace State Separation: Modern C and Zig Net-Benefit Matrix

No person-days, invented cycle counts or native speed percentages. The objective
is eliminating inappropriate cancellation ownership while preserving explicit
trace behavior and accounting for added runtime/interface work.
[Design](tcl-trace-cancel-design.md), [arguments](tcl-trace-cancel-arguments.md),
[evidence](tcl-trace-cancel-evidence.md).

TV01. The thirteen necessary support families remain shared.

| Necessary support | Modern generated C | Zig provider | Exclusive Zig elimination |
|---|---|---|---|
| 1 Scheme contract/policy schema | Typed records/tables and transition metadata | Same schema and generated types | None established |
| 2 Target/owner/native lifetime | Generation handles and leases | Same identities and leases | None |
| 3 Immutable message bytes | Allocator/ref/retirement support | Same ownership protocol | None |
| 4 Pending/token publication | C/A generation commit and ready/active rules | Same ABI and synchronization | None |
| 5 Installed/subtree history | Canonical cell and contributor coverage | Same cell and coverage | None |
| 6 Checks and diagnostics | Actual destructive filter/result behavior | Same Tcl ABI behavior | None |
| 7 Completion guard | Invocation/dispatcher/parent dependencies | Same durable dependencies | None |
| 8 Source-point/owned reset | Same-policy scopes and frontier receipts | Same reset authority | None |
| 9 Trace snapshot domain | Saved legacy projection; per-record/I scopes; selected policy | Same state split and scope protocol | None |
| 10 Failure/reentry/delivery | Generated cleanup states and local native exit handling | Error/defer syntax plus same nonlocal-exit contract | Local syntax only plausible |
| 11 Deletion/drain/image | Reference/cursor/callback/image joins | Same joins | None |
| 12 Raw/private/public ABI | Common authority with thin facade; writer closure | Same C facade plus provider/import qualification | None |
| 13 Evidence/debug | Exact source, fixtures, policy-matched observations | Same evidence plus provider drift | None |

This refines family 9 and the trace dependencies in family 7; it does not add a
second collector or charge shared support as thirteen independent new libraries.
Family count is an explicit design inventory, not code size or a maintenance
lower-bound theorem. [TD08, TD15–TD18, TP10]

TV02. Mechanism-derived work and state counts are bounded claims.

Let N be callback-bearing TraceExecutionProc invocations, D trace-dispatch
entries requiring a guard, A the maximum simultaneous live trace scopes, W a
legacy flag-word size and G uncovered cancellation generations. These are
symbolic workload counts, not measured parameters.

| Quantity | Old path | Separated candidate | Net boundary |
|---|---|---|---|
| Trace whole-word cancellation overwrites | One per callback-bearing invocation, N | Zero in separated trace restoration | Eliminates replay authority, not necessarily a CPU instruction |
| Legacy save/restore operations | One save and restore per such invocation | Still required for admitted legacy projection | No guaranteed saved memory traffic; machine word may remain W |
| Live trace snapshot storage | Up to O(A*W) source stack words plus existing records | Legacy projection plus identity/dependency records O(A) | Smaller semantic domain does not imply smaller physical word |
| Callback execution/list scans | Real callbacks, directional scans and active cursor repair | Retained | No asymptotic callback/scan speedup claimed |
| Cancellation check lookup | Packed-word macro/direct read | Canonical cell projection/access | Inlining/layout may help or add indirection; unmeasured |
| Guard bookkeeping | No new protocol receipts | O(N+D) transitions in finite admitted history, O(A) live scope records | Added required work; reservation/capacity explicit |
| Contributor history | Shared bits without managed provenance | Up to O(G), unless separately proven compression | No automatic history/metadata elimination |
| Message copy mechanism | Prior installation copying | Prior immutable payload opportunity unchanged | Do not count that earlier saving again as trace-specific |

N excludes call==0 and busy-skip paths; D may include setup-only or no-callback
dispatches. No blanket zero-guard fast path is established for those entries.
The old packed save/restore can also overwrite other non-cancellation flags;
this proposal does not count fixing those as an achieved benefit. [TX02–TX09]

TV03. Structural gain and total runtime gain are different objectives.

```text
avoidedTraceCancelWriters(h) = N(h) in the fully separated profile
remainingSourceSnapshotWriters(h) = 0 is an admission condition, not a receipt
addedScopeWork(h) = reserve + enter/exit + closure accounting over N(h),D(h)
addedLiveState(h) = identity/dependency state for A(h) plus required history
```

The structural safety benefit is positive when trace restoration is removed as
an unauthorized cancellation writer and no shadow writer replaces it. A runtime
benefit would require avoided repair/replay/qualification/runtime work to exceed
new cell access, scope, receipt and retention costs under a declared workload
objective. No coefficient or evidence establishes that inequality here. With
little cancellation and many traces, bookkeeping may dominate; if old traces are
unused, this redesign has no trace-work speedup to claim. [TD07–TD13, TP04, TP10]

TV04. Preservation and deliberate change must be reported separately.

| Behavior | Preservation target | Necessary change / unresolved boundary |
|---|---|---|
| Per-record suppression, nested I restoration | Same source set/restore points and prior values | No hardcoded zero or early busy flag |
| Other-command direct nested trace | Remains possible while interp traces are suppressed | Global trace-off simplification rejected |
| Ordering, result state and trace error propagation | Existing directional scans and caller folds retained | Cancellation changes may intentionally change later branches |
| Non-cancellation word projection | Saved old projection restored at same point | Not equivalent to restoring only I; DELETED safety unresolved |
| Cancellation installed/consumed during trace | No trace snapshot replay in separated cell | Differs from SourceSnapshot histories with changed K/provenance |
| Private/loaded writers | One authoritative cell | Unknown legacy layout writers block profile |
| Completion/reset | Exact source points plus actual full guard | Child/callback return cannot authorize target reuse |

No full observer-equivalence claim is supported, even though the projection
identity is exact. Native ABI/lifetime and mixed cancellation semantics still
require qualification. [TD02–TD14, TP02–TP09]

TV05. Retirement candidates are four linked responsibilities, zero completed paths.

| Candidate | Replacement | What cannot disappear |
|---|---|---|
| Whole saved word's future cancellation write | Legacy projection snapshot + canonical CancelCell | The source snapshot/restore point and declared noncancel behavior |
| Trace-specific implicit cancellation replay history | No replay authority in admitted separated profile | Raw installer/check/reset provenance elsewhere |
| Implicit completion from busy/list/bit state | Trace invocation and dispatcher closure dependencies | Actual callbacks, record references and physical returns |
| Writable cancellation aliases/shadows | Generated native accessors and one cell | Public/private ABI facade until true caller closure |

These refine the preceding writer study's R4/R5/R7/R8 bundles and are not four
extra independent retirements to add to its eight. Unknown source/private/loaded
clients or an active SourceSnapshot frame prevent the corresponding retirement.
[TD08, TD09, TD11–TD15, TO01]

TV06. Modern C is sufficient for the demonstrated architecture mechanism.

| Value question | Modern C | Zig | Current conclusion |
|---|---|---|---|
| Can exclude cancellation from trace snapshots? | Yes, generated layout/accessors | Yes | Shared benefit |
| Can preserve nested trace scope/result behavior? | Yes, explicit records/native cleanup | Same explicit protocol | Shared proof obligations |
| Can avoid foreign native-frame cleanup work? | No | No; defer handles qualified lexical exits only | No language shortcut |
| Can retain C integration and feed LLVM/MLIR? | Same native effect/ABI contract | Same contract plus Zig interface | Zig is not required for this decoupling |
| Does another provider add qualification work? | Common C baseline | Toolchain, ABI/import/layout and provider parity | Extra cost must earn separate benefit |
| Positive exclusive Zig support elimination? | Baseline | Zero established | Incremental Zig gate remains unresolved |

TV07. Evidence quantities report research progress only.

| Item | Quantity / status |
|---|---|
| Retained pinned C/H/M blobs rehashed/searched | 350 |
| New trace-symbol matching files / lines / occurrences | 5 / 52 / 53, including non-call text |
| New pinned manual/fixture captures | 2, API Git-blob reproduced |
| Conditional arguments / inert cases | 10 / 32, with 2 positive controls |
| Necessary support families per provider | 13 / 13 |
| Trace-split source-specific speedup / native profiles / runtime paths retired | Unmeasured / 0 / 0 |

TV08. Continue the C modernization mainline with an explicit semantic decision.

The worthwhile architecture change is removing trace snapshots' authority over
cancellation while retaining real nested native control and ownership. It needs
a deliberate separated-cancellation contract, all-writer migration and qualified
guard handoff. The present evidence establishes a structural mechanism and its
counterexamples; total runtime gain and extra Zig net benefit remain unproved.
Failure to close a writable shadow, preserve the declared recursion/error domain,
or retain an outstanding native dependency defeats either provider's admission.
