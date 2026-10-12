# Lifecycle Redesign Review

## Decision Before Implementation

The checked cleanup API is an error-reporting boundary, not a complete lifecycle
design. Retaining resources after a failed join is necessary to prevent unsafe
destruction; it does not prove recovery, safe unload or safe later setup.
Preserve the legacy ABI while evaluating explicit failure policy. Do not select
that compatibility policy as a substitute for auditing the underlying protocol.

The path is worth investigating for correctness, with no estimated speedup.
Existing drain, retirement and cleanup models cover parts of this path; the new
linker-generation model addresses an actual native failure not previously
represented. Do not rerun unchanged failed native routes.

## Paper To Design Obligations

The repository's reviewed [GHC paper notes](papers/ghc-parallel-gc-2008.md),
sections 3.1-3.5, and [HotSpot notes](papers/hotspot-parallel-gc-2001.md),
sections 3.1-3.3, distinguish pending/private work from global termination.
For Gambit retirement, the design question is which participant can still
produce work or dereference a resource after population changes. This is an
application of those accounting principles, not a paper-provided Gambit repair.
Neither paper specifies Gambit's global linker or embedding reentry contract.

Check these separate milestones in a combined lifecycle protocol:

1. Close new admission, without stranding already admitted work.
2. Drain Scheme callbacks, foreign calls, GC work and publication tails.
3. Obtain actual worker exit and join witnesses, distinct from population count.
4. Reclaim each resource only after its own users have drained.
5. Define whether another global generation is supported and how metadata is
   rebuilt, or return an explicit unsupported-operation outcome.

Errors must preserve ownership and identify unfinished milestones. A rejected
operation is not successful cleanup. Progress claims require explicit scheduling
and OS-error assumptions; no unconditional successful join is assumed.

## New Native Boundary And Model

On the locked checked-cleanup candidate, the C embedding observer completed
generation zero and then crashed in the second global setup. The matching
privacy-minimized stack is in
`evidence/source-results/fixtures/checked-cleanup-retained-error/embedding-worker-report/crash-summary.json`.
`linker_to_mod_or_lnk` destructively converts linker-table entries into module
descriptors. Reinterpreting those entries as functions matches the observed
data-as-code fault. Earlier generation-zero callback exit 71 remains a separate
open failure, not explained by the second-generation stack.

`global_linker_generation.qnt` checks two serialized generations. The destructive
reuse control produces the callable-target counterexample (six distinct states).
A hypothetical linker-only reset produces a stale-fixup-generation counterexample
(seven states). The latter is a source audit obligation, not an observed native
stale-pointer crash. Complete abstract reconstruction or explicit unsupported
reentry passes safety and fair completion (12 distinct / 14 generated states,
3.696 seconds). Receipt and counterexamples are under
`evidence/model-results/fixtures/checked-cleanup-retained-error/linker-generation/`.

These alternatives are not implemented or selected runtime repairs. Complete
reconstruction abstracts all fixup metadata; the model does not implement its
allocation, rollback or root ownership. Refusal is safe in this model but may
not satisfy the intended embedding API. Audit that contract first.

## Verification Required For A Redesign

Bind a candidate to pinned submodule source and a semantic source lock. Model
interactions, including failed partial initialization and retained cleanup,
before changing runtime code. Source audit must map each abstract ownership and
publication step, including C memory ordering and fatal-hook behavior.

Then run exact-source atomic controls, real embedded lifecycle cases, SMP/GC
suites, two-pass bootstrap and Gerbil correctness checks. Only after correctness
qualifies should the retained build/startup/test performance gates be applied.
No blanket reentry denial, single-flag reset or passing component model counts
as full SMP qualification.
