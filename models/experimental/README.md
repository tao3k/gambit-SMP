# Experimental Models

Future protocols and refactor hypotheses live here, separate from the current
SMP repair/qualification models. These models are executable, but their passes
do not close current native obligations or advance the milestone count.

## Retirement Handoff

- [QNT composition](retirement_root_handler_composition.qnt) reuses the existing
  public retirement model after successful exclusive-owner/cohort preflight.
- [Lean contracts](lean/RetirementHandoff.lean) reuse existing `WorkAccounting`;
  they do not introduce another Lean package or root ABI.
- The same composition distinguishes a synchronization object's independent
  keepalive from VM teardown and release of the joining consumer. Six omission
  controls include last-root loss/finalization and early consumer release.
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
