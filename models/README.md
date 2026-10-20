# Model Scope

Keep two uses distinct. A successful model check is not native acceptance.

| Use | Location and binding |
| --- | --- |
| Repair or qualify a current SMP failure | Existing `gambit/` models and their source-bound Evidence/manifests. Extend the relevant model with the actual failure, source assumptions and negative control; do not duplicate it as a speculative replacement. |
| Explore an unimplemented protocol or future refactor | [experimental/](experimental/README.md), including its Lean companion and explicit checks. Keep proposed assumptions and source-correspondence gaps visible; do not count the result toward current native progress. |

Pure definitions in `library/` and existing proof libraries may be reused by
both. A reference to Chez or OCaml does not determine the category: the question
is whether the property qualifies an actual current repair or an unimplemented
design. Conversely, an existing model's location does not prove that its
assumptions are established in C.

The current milestone count belongs to source-bound native qualification, not
this directory index. The owner's reported 9/12 is not re-certified or changed
by organizing research. Historical native failures and completed stages remain
attached to their original producers.

Do not relocate models used by another thread's active manifests as part of a
research cleanup. Any later promotion of an Experimental protocol needs an
explicit source mapping, declared configuration, current-failure controls and
the corresponding native acceptance; neither a directory move nor a finite
proof supplies those witnesses.
