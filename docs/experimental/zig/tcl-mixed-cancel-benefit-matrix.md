# Mixed Cancellation: Modern C and Zig Net-Benefit Matrix

The useful extension is recovering qualified mixed histories from permanent raw
taint while preserving raw effects and declared managed outcomes. Compare the same
producer/entry domain, raw-takeover policy, next-script contract, native roots and
result custody. No person-days, invented cycles, native benchmarks or percentages.
[Design](tcl-mixed-cancel-design.md), [arguments](tcl-mixed-cancel-arguments.md) and
[evidence](tcl-mixed-cancel-evidence.md) define the assumptions.

MV01. Eleven necessary support families:

| Support family | Modern generated C | Optional Zig | Retirement / retained obligations |
| --- | --- | --- | --- |
| Raw pending selection and payload ownership | Existing Tcl core plus source-owned provenance | Same core/provenance, through facade | Raw path retained; no alternate queue/flag union |
| Origin and admission contract | Common Scheme-derived schema, typed conflict outcomes | Same schema and outcomes | Per-adapter origin guessing can retire after all callers migrate |
| Install/C/U/message provenance | Shared native ledger at callback and descendant sites | Same ledger and source hooks | Request-only identity assumptions can retire; per-install support remains |
| Destructive check/reset history | Actual Canceled caller site and inline-reset records | Same records and core sites | Return-code/flag/string guesses can retire; history collection remains |
| Owner phase and real evaluation identity | Common actual-entry/return ledger, synchronized reservation | Same ledger and reservation | numLevels-as-owner-oracle shortcuts can retire; complete entry coverage remains |
| Raw idle debt and consumption | Source-complete next-real-evaluation/control history | Same history and consumption rule | Permanent taint relaxes only for qualified histories; dummy eval not allowed |
| Discharge receipt generation | Core-issued cut and monotone invalidation under L,C,A | Same C/Tcl issuer or an equivalent qualified native core | Copied-Boolean reuse can retire; issuer/serial/provenance support remains |
| Managed pending/reset/publication | Existing common targeted plan composed with raw receipt | Same plan and core commit | Per-adapter unlock-before-reset paths can retire after migration |
| Unknown/failure/custody | Reserved records, refusal, roots/marker/bytes/image grace | Same failure and Gambit support | No GC or native activation obligation disappears |
| Source/ABI and loaded closure | One private C facade plus actual installed producer qualification | Same facade, plus any added Zig mapping/toolchain | Centralization shares review; private-core upgrades remain |
| Shared record storage and reclamation | Common native outcome/ledger services with generated types | Equivalent storage plus optional language helpers | Amortizes shared representation/policy, not per-event records or leases |

MV02. Quantities established at design level:

| Quantity | Result | Evidence boundary |
| --- | --- | --- |
| Mutable cancellation planes distinguished | 4 | Pending, token, installed state, check/control |
| New proposed receipt kind | 1 RawHistoryDischargeReceipt | No new existing private stub/API claimed |
| Necessary support families compared | 11 | Independent policies/representations, not source lines |
| Conditional arguments / inert cases | 9 / 27 | Handwritten; not model-checked or executed |
| Source-known reusable mixed histories | Conditional classes, no runtime count | Real recovered frequency unknown |
| New native profiles admitted / paths retired | 0 / 0 | Design only |
| Necessary support eliminated solely by Zig | 0 established | Positive Zig increment unresolved |
| Percentage speedup or memory reduction | Unknown | No native workload/measurement |

MV03. Charge events rather than only raw requests. Let A be accepted raw/managed
requests, J callback installations including replays, K destructive checks, Z
resets including inline/descendant resets, E actual entry/return events, F affected
frontier size, P retained payload/outcome bytes, U reuse attempts and N the subset
of formerly tainted histories now discharged. J can exceed A because re-marks can
reinstall retained payload; K can exceed J because U is persistent. E and Z include
all actually admitted nested/event/exceptional paths, not only top-level Scheme
calls. Unknown histories and refused attempts still incur collection cost.

```text
W_history = accept_records(A) + install_records(J) + check_records(K)
          + reset_records(Z) + scope_records(E) + owned_bytes(P)
W_discharge = sum_over_U(frontier_validation(F) + coverage_check
                      + lock/receipt/invalidation + retirement_dependencies)
W_total_added = W_history + W_discharge + changes_to_existing_target_commit
```

An uncompressed ledger uses space proportional to outstanding A+J+K+Z+E plus P and
identity/lease/frontier records. Compression may retain only sufficient summaries
when control/outcome evidence remains reconstructible; this requires an invariant
and cannot be inferred from a last-message hash. Journaling at every instruction is
not proposed: charge the actual admitted acceptance/install/check/reset/entry sites.
No fixed per-record time, constant hash lookup or bounded mutex latency is assumed.
[MD04–MD16]

MV04. A worked symbolic break-even criterion:

```text
recovered_runtime_gain_positive iff
  sum_over_N(equivalent_creation + Tcl/Tk_init + state_reconstruction_avoided)
    > W_total_added + additional_failure/quarantine/retained_state_cost
```

N is not the count of raw requests or ERROR returns. It counts histories with
complete terminal raw coverage, real idle consumption when required, neutral
persistent state, no future installer and permitted outcomes. A source-known class
is not a measured N. If a required application state cannot be reconstructed by
a fresh interpreter, recovered reuse may be a necessary capability rather than
comparable construction savings; report that capability separately. [MP09]

MV05. Value boundaries and refutations:

| Potential value | Positive condition | Refutation / cost |
| --- | --- | --- |
| Relax permanent raw taint | A meaningful set of actual completed histories satisfies discharge | N=0, persistent U, frequent idle debt, missing check/entry coverage |
| Avoid recreation | Equivalent fresh creation/init/replay actually avoided | Already cheap creation or new ledger/storage/locking costs exceed savings |
| Better diagnosis and admission | Proven origin/install/control coverage replaces return-code guesses | Metadata overflow, indirect callers or installed ABI mismatch still require refusal |
| Consolidate native policies | One Scheme schema/core facade replaces real per-adapter rules | Old rules remain alongside new system; duplication increases |
| Bounded shutdown | Actual producers and derived scopes cooperate and terminate | No finite progress follows from receipts; hostile extensions can stall |
| Zig-specific increment | A necessary maintained support family disappears or required capability uniquely qualifies | Same Tcl hooks/history/GC obligations persist; none eliminated here |

MV06. Previous targeted settlement's zero unrelated callbacks at the barrier and
one O(H) readiness scan are retained. They are not new savings from this history
extension. Raw consumption may require a real application evaluation and its
ordinary event/callback work; the barrier must not run an arbitrary evaluator or
drain to create a receipt. The added discharge logic improves admissible histories,
not the complexity of all evaluation or Tcl's raw callback executor.

MV07. Sharing the record allocator, generation issuer, outcome custody and facade
can spread policy/representation maintenance across RootRegistry, release services
and Tcl integration. It cannot remove A/J/K/Z/E events or F/P lifetime obligations.
Scheme-generated types can centralize the data/operation schema in modern C;
optional Zig may use the same services, but its build/import/language qualification
is additional until an actual existing support path retires. LLVM/MLIR remains
independent of issuer authority, cancellation consumption and GC roots.

MV08. Decision: continue the common generated C architecture and make mixed-history
admission conditional on source-owned evidence. This study narrows when
rawInterference can clear without changing raw behavior; it does not establish
universal raw/managed equivalence, native correctness or positive runtime gain.
The incremental Zig balance remains:

```text
actual necessary C support retired + separately admitted required capability
  - retained Tcl/C support - duplicate representations/bridges
  - added toolchain/ABI/invalidation/qualification obligations
```

No positive exclusive balance has been demonstrated. A language change alone does
not solve the destructive-check, next-evaluation or real native-return problems.
