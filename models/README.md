# Model Scope

Keep two uses distinct. A successful model check is not native acceptance.

| Use | Location and binding |
| --- | --- |
| Resolve the current 9/12 repair/qualification gaps | Existing `gambit/` models and their source-bound Evidence/manifests. Reuse or extend the relevant model for the actual failure and bounded repair, including its source assumptions and negative controls. A not-yet-implemented fix is still current repair work when it targets that existing obligation. |
| Investigate an architectural refactor | [experimental/](experimental/README.md), including its Lean companion and explicit checks. State what ownership, lifecycle, GC-participation or interface mechanism would change, its scope and migration/acceptance obligations. Do not count a speculative protocol toward current native progress. |

Pure definitions in `library/` and existing proof libraries may be reused by
both. A reference to Chez or OCaml does not determine the category: the question
is whether the work resolves a current repair or proposes a changed architectural
mechanism. Missing proof, an unknown cause or an unimplemented local fix is not
by itself a reason to move current work into Experimental. Conversely, an existing model's location does not prove that its
assumptions are established in C.

The [current repair research Recipe](../docs/current-repair-research.md) binds
reference mechanisms to the existing retention, origin-frame and work-accounting
models. It is distinct from the proposed architecture's composition checks.

[Retirement exit/handoff](gambit/retirement_exit_handoff.qnt) composes the existing
elementary callback, saved-stack and sender/resource machines with actual
marker-tail, root/work, join and external-release boundaries. Its
[Lean companion](gambit/lean/RetirementExitHandoff.lean) and
[validation](../evidence/research/retirement-exit-handoff/validation.md) include
omission counterexamples and non-vacuous success/retention witnesses. Source
refinement remains open and is exposed by the existing Scheme component.

[Repeated repair campaigns](gambit/retirement_repair_campaign.qnt) reuse that
retirement machine across cohort incarnations and check source freshness, receipt
replay, partial inventories, retained failure and cancellation. The
[test contract](../docs/retirement-repair-test-contract.md) maps current and
Experimental contracts to independent native oracles; its Lean companion proves
join-once and retention properties for arbitrary finite test-event traces.

The current milestone count belongs to source-bound native qualification, not
this directory index. The owner's reported 9/12 is not re-certified or changed
by organizing research. Historical native failures and completed stages remain
attached to their original producers.

Do not relocate models used by another thread's active manifests as part of a
research cleanup. Any later promotion of an Experimental protocol needs an
explicit source mapping, declared configuration, current-failure controls and
the corresponding native acceptance; neither a directory move nor a finite
proof supplies those witnesses.
