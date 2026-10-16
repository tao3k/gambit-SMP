# Original Group Budget Correspondence

This is a generic framework contract for retaining an original multi-file
campaign inside a larger native grid. It does not prove Gambit runtime safety.

`native_group_budget_correspondence.qnt` requires exact original group scope,
inclusion in the complete selected inventory, a non-expanded group cap and
preparation plus execution expenditure within that cap. Its bypass initializer
retains counterexamples for omission, expanded cap and ignored preparation.

The source-bound controls recipe uses the existing Python/Quint/ASCENT driver
and original 90-second budget. The verified instance exhausted 410 distinct,
1,861 generated states with an empty queue; the negative initializer produced
an invariant violation. The whole sealed invocation passed in 16.744 seconds.
This is bounded model evidence, not an unbounded scheduling or memory proof.

| Boundary | Existing Framework Implementation |
| --- | --- |
| Typed disjoint inventories and positive caps | `native_capabilities.validate_suite` |
| Group launch, preparation and command deadline | `native_capabilities.run_suite_groups` |
| Original receipt, group scope and requested cap projection | `native_review.project_review` |
| Conditional whole-group eligibility and expanded-cap refusal | `evidence/research/suite-review-rules.ss` |

All files in a group execute in one isolated invocation sharing one deadline.
The existing capacity-derived worker pool still runs other groups concurrently.
An original group is not converted into several independently renewed caps.
Overlapping groups, overlapping single-file caps and atomic-to-whole waivers
are rejected. Preparation expiry prevents process launch. Missing completion,
timeout, fixture drift and late completion remain DENY.

The current grid embeds the original six-thread-file campaign with its original
120-second cap. Native ASCENT transport controls passed four tests in 18.363
seconds, with no skips: exact group, scope omission, expanded cap and unrelated
same-regime scope omission. These are synthetic review inputs executed by the
actual sealed implementation, not four native Scheme test results.

The native correctness gate still requires complete interpreted and compiled
inventories, the additional PR and stress cases, simultaneous independent
threaded VMs, GC/FFI/lifecycle, Gerbil and release-performance qualification.
