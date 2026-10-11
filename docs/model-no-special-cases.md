# No Result-Specific Models Or Repairs

## Admission Rules

1. Runtime repairs must express a protocol valid for every supported package,
   processor identity and legal configuration. No package names, test paths,
   issue numbers, measured durations or fixture values may select a success path.
   Hardware concurrency comes from the existing host/configuration interface,
   not a copied benchmark-machine core count.
2. Finite model bounds are permitted only as disclosed verification bounds, not
   claims of correctness at arbitrary scale. A two-processor model is not a
   twelve-processor runtime configuration. Label permutations, zero/one/multiple
   users, resource failures and relevant sizes need coverage or explicit pending
   obligations before source admission.
3. Fault/old/fixed selectors are negative-control mechanisms, not evidence by
   themselves. Reject `fixed or safe`, unconditional success assignments, assumed
   quiescence that is the property under investigation, and hand-selected paths
   that remove the failing interleaving without a realizable source guard.
4. Derive safety from pointer contents, ownership, initialized resources,
   participants and transitions. Sticky violation flags may record a bad event;
   they must not replace modeling the resource operation that can cause it.
5. A positive abstract contract may deliberately forbid an unsafe action. It is
   not a source repair until a source operation enforces that guard and its
   progress, failure, memory and ownership costs are checked.
6. Mutations must reproduce the intended counterexample, with a meaningful
   transition trace. Merely asserting an expected exit status or a PASS string
   is not model validation. Native results must come from the actual selected
   binaries, original assertions and complete test inventory.
7. Deterministic source-unit constants are explicit injected schedules, not
   runtime tuning values. Keep `diagnosticOnly` and `runtimeAdmitted: false`;
   bind actual extracted source, tool and fixture hashes and preserve negative
   outcomes. Do not call a matched expected failure a correct runtime.
8. Paper assumptions are hypotheses, not acceptance rules. If a community report,
   source path or identity-bound native result contradicts the abstraction, retain
   the failure and repair the abstraction or source correspondence. Never exclude
   that execution merely to recover a model PASS. Likewise, passing real tests
   does not erase untested configurations or establish universal correctness.

## Current Audit Debt

`continuation_link_handoff` is a one-link, two-actor sufficient contract. Its
six-state positive result does not satisfy a parameterized chain or source
refinement review. Publication is guarded by producer completion in the model;
implementability and queue eligibility remain open. The source-unit retirement
fixture likewise has one sender and two scheduling checkpoints, not all possible
threads or native pthread behavior.

The four prior composition models disclose bounds and exclude native admission.
They must not be promoted solely because TLC exhausted those bounds. Extend
only the dimensions needed by a concrete source change, with explicit matrix
coverage and mutation traces; do not mechanically add arbitrary constants or
larger state spaces to imply stronger proof.

Working owns the runtime implementation. The audit session reviews the positive
protocol and negative controls together, and records unproved assumptions rather
than rewriting concurrent work or manufacturing a green status.
