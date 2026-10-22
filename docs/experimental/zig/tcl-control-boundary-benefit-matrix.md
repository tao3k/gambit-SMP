# Tcl Control Boundaries: Modern C and Zig Net-Benefit Matrix

Design-only comparison under the [semantic contract](tcl-control-boundary-design.md)
and [conditional arguments](tcl-control-boundary-arguments.md). No timings,
implementation, native test, invented coefficients or human-day estimates.

BV01. A shorter exception adapter is not positive value if it changes
continuable raise, wind order, Tcl catch/finally, event destination or shutdown
behavior. Compare providers under the same declared behavior and admission
domain. A smaller declared result API is a capability choice, not proof that
general Gambit FFI has been modernized without semantic loss.

| Necessary support | Modern Scheme-generated C | Optional Zig provider | Real gain / added cost and falsifier |
| --- | --- | --- | --- |
| Control classification before winding | Scheme derives source/destination domains and effects; generated C invokes common runtime rules | Consumes same plan and guard coverage | Can remove duplicate policy decisions only after every actual producer migrates; no saving from missing an internal path |
| Handler/wind execution | Reuse Gambit dynamic environments, graft/return and hook ordering | Same Scheme semantics and runtime support | Preserves a core capability; neither language eliminates hook calls or their reentry costs |
| Result policy | Shared typed outcome, Tcl code/result/options, declared authority and payload roots | Tagged unions can express variants; C shell/control obligations remain | May consolidate real adapters; extra roots/metadata and changed API burden must be priced |
| Nested event delivery | Owner-scoped identities, parent/sink routing, acceptance receipt and queue ownership | Same identities, ordering, rooting and recipient lifetime | Prevents misdelivery; added bookkeeping/retention, no source-derived throughput claim |
| Tcl catch/try/finally and cancellation | Reuse qualified library machinery; preserve options/provenance, distinguish cancel-unwind | Same Tcl library and compatibility/upgrade surface | Cancellation can enable declared quiescence; cannot count skipped user behavior as optimization |
| Native control corridor | Qualified C entry/marker/exception island retained | Also retained for any unsupported Zig-crossing jump corridor | Existing marker checks cannot retire; another language boundary may add work |
| Control-aware shutdown | Count actual child scopes/hooks/outcomes, cancel users, background errors, root/image grace | Same dependency graph and owner-thread progress | Avoids premature free/self-wait; memory retention and nontermination remain real costs |

BV02. Quantify disjoint marginal work on one fixed admitted execution history:

```text
saved_time = sum_i(actual_repeated_work_removed_i * comparable_unit_cost_i)
added_time = control_guard_cost + outcome_rooting_and_snapshot_cost
           + routing_and_receipt_cost + cancellation_check_cost
           + drain_and_retirement_cost + provider_boundary_increment
net_time_gain = saved_time - added_time
```

Count existing required handler/hook/conversion/trampoline work in both sides
so it cancels, unless a separately proved optimization truly removes it.
Earlier mature-graph/root scan savings remain separate terms and are counted
once. Do not turn “reject more transfers,” “skip finally” or “discard an event
error” into saved_time. No positive numerical lower bound is established here.

BV03. Space and latency have separate bounds. At time t let O(t) be unsettled
outcomes, L(t) active scopes and R(t) outstanding root/image/recipient claims.
Account the union of retained payload graphs plus distinct native record,
Tcl snapshot and queue storage; shared payloads are not charged once per alias.
Acceptance may release producer support only after the receiver really owns
the needed roots/resources. Conservatively retaining a pre-frontier library
scope can retain many revoked records/outcomes. Cancellation reduces neither
that retention nor latency until actual quiescence is observed.

BV04. A finite drain bound requires finite admitted descendants, bounded work
per descendant, cooperative native/Tcl checks, fair owner service and an
acyclic dependency graph. Source-level DONT_WAIT, variable-set, queue-empty
or cancellation-accepted does not establish those premises. Without them the
defensible bound remains unbounded; this is distinct from no memory safety
violation while retaining state. A new cancellation API's smaller behavior
must be evaluated as its declared behavior, not as faster arbitrary call/cc.

BV05. Potential retirements are policy duplication, not semantics: per-API
ad hoc outcome classification, global pending-error slots and independent
callback/drain ownership recipes could retire after their actual users migrate
to one Scheme-derived plan. No such old path retires in this research. Graft,
wind, exception-handler behavior, marker validity, GC root enumeration,
Tcl-owned cleanup and interpreter thread ownership remain necessary mechanisms.

BV06. Incremental Zig value requires evidence that the optional provider
removes a necessary maintained representation/support path or improves an
admitted runtime outcome beyond modern generated C, after C-island, ABI,
toolchain and upgrade burden. Tagged variants, error unions and ordinary defer
can improve expression but do not settle a cross-Tcl transfer or restore
Scheme dynamic context. Zero required semantic or lifetime obligation is shown
eliminated by Zig in this study. This is not a claim of equal code size or
equal performance between languages. [CL03–CL05]

BV07. Reporting matrix:

| Claim | Result supported now |
| --- | --- |
| Normal return / local continuation / original returning handler | Conditional equivalence domain specified in BP02 |
| Universal Scheme exception → result equivalence | Refuted by BC01–BC05 without stronger restrictions |
| Arbitrary cross-Tcl continuation preserved by a wrapper | Unresolved; full library/control proof absent |
| Tcl has a stronger-than-error cancellation mechanism | Yes, source/API-supported; not a Scheme transfer theorem |
| Finite shutdown from DONT_WAIT or cancellation acceptance | Not established; cooperative termination premises required |
| Existing calls/allocations retired by this documentation | 0 |
| Net runtime speedup percentage | Unknown; no benchmark or fabricated number |
| Positive Zig increment over modern generated C | Unresolved; common contract remains the modernization mainline |
