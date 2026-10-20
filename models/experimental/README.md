# Experimental Models

Architectural refactor hypotheses live here, separate from the current
SMP repair/qualification models. Each proposal needs a mechanism change and
an applicability/migration argument, not merely a missing proof or a new local
failure condition. These models are executable, but their passes
do not close current native obligations or advance the milestone count.

## Retirement Handoff

- [QNT composition](retirement_root_handler_composition.qnt) reuses the existing
  public retirement model after successful exclusive-owner/cohort preflight.
- [Lean contracts](lean/RetirementHandoff.lean) reuse existing `WorkAccounting`;
  they do not introduce another Lean package or root ABI.
- The same composition distinguishes a synchronization object's independent
  keepalive from VM teardown and release of the joining consumer. Eight omission
  controls include last-root loss/finalization, early consumer release and
  treating OS return or runtime restoration as completion of a wait call.
- [Scope, source correspondence and results](../../docs/experimental/retirement-handoff-model.md)
  distinguish proposed root/handler protocols from observed implementation.
- [Declarative Evidence](../../evidence/research/retirement-handoff/facts.json)
  uses the existing parallel-GC Scheme relations, with no native `satisfies`.

Run the explicit campaign from the repository root:

```sh
.venv/bin/python -m unittest discover -s models/experimental -p test_retirement_handoff.py -v
```

The checks use the existing QNT/TLC backend, host-derived concurrency plan and
guarded Lean process runner. TLC's local endpoint must be permitted. Receipts
and generated checker files go to the framework cache, never to model sources.
This campaign is not added to a current native qualification manifest.

Reusing the base model does not establish its preflight in the runtime. In
particular, this composition neither proves failed-join recovery nor authorizes
freeing a VM with a live same-VM root. Promotion requires source-established
ownership, root inventory, handler quiet, configuration and native witnesses,
not simply moving these files into `gambit/`.

The architecture under investigation is explicit ownership across VM retirement,
independently retained synchronization/root storage and pre-admission handler
lifetime. A generalized carrier/admission protocol or changed host attachment
contract needs a coordinated refactor milestone. The small waiter/exception
projections are checks within that proposal, not a reason to send every current
waiter bug into this directory. Current 9/12 repair reuses existing source-bound
models as described in the [current Recipe](../../docs/current-repair-research.md).

The current [exit/handoff composition](../gambit/retirement_exit_handoff.qnt)
provides lower-level omission controls for later refactors. Reuse that boundary
and its surviving-recipient assumption rather than copy its model here or infer
that it covers independent post-VM carriers and generalized host attachment.
