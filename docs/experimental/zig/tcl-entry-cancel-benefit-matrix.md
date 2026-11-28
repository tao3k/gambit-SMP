# Entry Gate and Completion Guard: Modern C and Zig Value

Compare the same semantic policy, handler context/domain, entry kinds, raw/managed
outcomes and failure/GC requirements. Source-preserving refusal and a normalized
capability are different products; neither may be substituted as the other's cost
baseline. No person-days, native timing, invented cycles or percentage gains.
[Design](tcl-entry-cancel-design.md), [arguments](tcl-entry-cancel-arguments.md)
and [evidence](tcl-entry-cancel-evidence.md) state the assumptions.

GV01. Twelve necessary support families:

| Necessary family | Modern generated C | Optional Zig | Real retirement / retained cost |
| --- | --- | --- | --- |
| Policy and role schema | Scheme-derived typed gate/guard plan | Same plan and receipt policy | Per-adapter silent choices can retire; semantic policy remains necessary |
| Source ordering and handler context | Existing dispatcher or declared cancellation-first core class | Same native machinery/domain | Duplicate executors avoided; timing/context/priority qualification stays |
| Prepared payload and target lease | Core immutable payload ownership and generation check | Same core lease/storage or added bridge | C-held callout paths retire only after actual core producer migration |
| Callout-free publish/install | Private C core transaction and deferred reclamation | Same transaction and no-callout contract | Wrapper-only integration cannot retire legacy core paths |
| Entry/acceptance decision cut | Common target/owner generations under C/A | Same cuts and source hooks | Stale permit recipes can retire; contention, lock initialization/build qualification and evidence work remain |
| Owned rejection/diagnostics | Frozen cause/outcome and outside-lock materialization | Same snapshot and callback obligations | Result/code inference can retire; payload/result custody stays |
| Early guard registration | Generated all-route pre-registration | Equivalent guard registration | Post-readiness-only cleanup can retire after closure |
| NRE/coroutine/native completion | Durable logical guard plus actual-return/grace | Same ledger/roots/grace | Lexical/schedule-return shortcuts can retire; suspended custody stays |
| Generation-owned reset writers | One core clear contract and all caller migration | Same core contract and migration | Unqualified inline resets can retire only when every real writer is covered |
| Exactly-once settlement and failure | Issuer generation, dependencies and sealed partial-failure states | Same protocol | No rollback of handler effects or newer requests |
| Shared root/outcome/image support | Reuse Gambit and common native services | Same Gambit/common services | No new language eliminates GC roots or returned-C validity |
| Private-core upgrades and native qualification | One facade/source policy owner plus full caller coverage | Same plus added language/toolchain/ABI mapping if used | Sharing reduces duplicate owners, not source or native admission obligations |

GV02. Structural quantities and bounds:

| Measure | Result | Qualification boundary |
| --- | --- | --- |
| Explicit entry policies | 3 | ObservedSource, OrderedEntry, CancellationFirstEntry |
| Explicit completion policies | 2 | NaturalSource and NormalizedComplete; no silent mixing |
| Necessary support families | 12 | Semantic/ownership/ABI families, not lines of code |
| Conditional arguments / inert cases | 11 / 37 | Includes one positive normalized control; not executed |
| Unrelated callbacks at cancellation-first gate | 0 by proposed contract | Deliberate order change; later ordinary service remains |
| Readiness repair for selected target removal | One O(H) scan when inactive; retain outer scan when active | No forced recursive dispatch; ready-count alternative not credited as free |
| New native profiles / paths retired | 0 / 0 | Documentation only |
| Support families eliminated solely by Zig | 0 established | Incremental positive benefit unresolved |
| Speedup / tail latency / memory percentage | Unknown | No performance validation |

GV03. Let E be entry attempts, R cancellation preparations/publications, P owned
message/outcome bytes, Q actual gate handler invocations, H maximum registered
handlers, J guard settlements/retries, W admitted reset writers/events, A logical
activation/suspension events and B native scope events. Charge:

```text
W_common = identity/guard(E) + prepare/publish_lease(R,P)
         + final_decision/owned_outcome(E) + reset_provenance(W)
         + logical/native_closure(A,B) + settlement/dependencies(J)
OrderedEntry_work = W_common + dispatcher_scans + callbacks_and_derived_work(Q)
CancellationFirst_work = W_common + target/frontier_validation
                      + inactive_readiness_scan(H) + later_required_ordinary_service
```

For finite H and Q at one invocation, existing repeated head scans have an
O(H*(Q+1)) scan upper bound plus callbacks; continuous re-marks can make Q unbounded.
Cancellation-first avoids those unrelated callbacks at entry, but changes priority
and can shift required work to later service. Immutable ownership may move payloads
instead of duplicating representations only after an actual ownership invariant
is proved. Do not claim fewer copies just because Zig has explicit allocators.
Lock hold/wait time and retained diagnostic/guard/lease storage remain costs.
[GD02–GD18]

GV04. Break-even criteria:

```text
same-policy runtime_work_gain_positive iff
  actually avoided equivalent recreation/state reconstruction
  + duplicate runtime work actually retired
    > added gate/guard/provenance/ownership/closure/failure work

new normalized capability value requires
  a required behavior + complete changed-semantics/native qualification
  + comparison with an equal-capability modern C alternative
```

Reduced entry callback exposure is useful only under the chosen control semantics;
it is not proof that total application work vanished. A stronger preemption policy
may be valuable independently of speed but must not be sold as source preservation.
No empirical event frequencies or per-operation costs are invented. [GP10]

GV05. Refutations and decision matrix:

| Proposed gain | Positive condition | Refutation / retained cost |
| --- | --- | --- |
| Handler-order preservation | Same dispatcher rule and qualified context at the selected service point | Earlier service changes timing/context; cancellation-first changes relative priority |
| Earlier reliable preemption | Chosen normalized policy and complete final cut/cause/entry coverage | Active nested dispatcher, legacy callback domains or continuous marks prevent qualification |
| Fix early U cleanup | Guard armed before readiness and true completion plus all reset writers migrated | Final guard alone cannot repair an earlier unqualified reset or clear new raw state |
| Reentrant native safety | All relevant core commits callout-free with leases and failure ownership | Old raw core callers remain; recursive mutex does not prove invariants |
| More reuse | Required histories actually become neutral with complete outcomes | All-or-defer frequently blocks, retained state costs dominate, or equivalent recreation is cheap |
| Zig-specific value | A necessary maintained support path disappears or required capability qualifies independently | Same twelve families persist; no exclusive positive increment established |

GV06. Sharing generation issuance, native storage, outcome/root/image custody and
schema generation amortizes policy representations across RootRegistry, release
coordination and Tcl integration. E/R/W/A/B and each live lease/guard remain distinct
work. An all-route guard plus unchanged unqualified old reset macros is additional
support, not retirement. Actual migration must remove duplicate reset/policy owners
before claiming maintenance reduction.

GV07. Incremental Zig balance remains:

```text
necessary C support actually retired + independently admitted required capability
 - retained Tcl/C islands - duplicate policy/context/receipt representations
 - added toolchain/ABI/invalidation/native qualification obligations
```

Zig cleanup syntax cannot supply actual post-return evidence, migrate Tcl reset
writers or preserve handler semantics. Modern Scheme-generated C can own the same
core transactions, guard state machine and common native plan. LLVM/MLIR remains
decoupled from cancellation issuer, Scheme GC and continuation authority.

GV08. Present design decision: make policy selection, callout-free native commits,
early logical guards and reset ownership part of the common modernization contract.
Retain ObservedSource as the evidence reference; admit normalized behavior only
under its explicit requirements. Full/native/callback/progress qualification and
positive total or Zig-specific net benefit remain unresolved. This is substantive
C/runtime architecture work, not justification for adding a language wrapper.
