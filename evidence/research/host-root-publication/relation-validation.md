# Host Root Source Relations And Preserved Integration Failure

## Exact Research Data

| Input | SHA-256 |
| --- | --- |
| `facts.json` | `5f604751cacdd64698081b43c25d837eeef2931fd9cc3b4349cd79c706855fdc` |
| `tests/test_host_root_publication_evidence.py` | `9eec810423efe65eb2980e5b95c823dea515cd2216244839c982f41c7fcdbb23` |
| Existing `evidence/scenarios/parallel-gc/design.ss` | `498b644760d58de3c22bbb72e7a3eb3e537e76605ac56f65a79a96b6158e28e9` |
| Existing `evidence/scenarios/parallel-gc/components.json` | `6cb0291e2d4afea0665d5420f7cde7a9331ce77c9e3b0527073ff6981fc7cf2d` |
| Unchanged preceding `repair-and-redesign/facts.json` | `805da79e4f3f7da1aed61d3d34c9a35943119119f29dec1e9222a8f445dea4a5` |

Command:

```sh
.venv/bin/python -m unittest \
  tests.test_host_root_publication_evidence tests.test_repair_redesign_evidence -v
```

Final result: five tests passed in 12.576 s. This includes the guarded Lean
recheck and the preceding research's three relation tests; the earlier fifteen
TLC checks were not rerun. All declared source identities were checked before
and after the new relation evaluation. The new Lean receipt is
`host-root-publication/lean-9o8x8y79`, includes the final test source identity,
exits 0 without timeout and reports `group_quiescent=true`.

## Real Existing Scheme Inference

The existing `make-parallel-gc-review` constructor derives both transfer
conditions and exactly three explicit gaps:

| Research interface | Derived gap |
| --- | --- |
| `root-census-and-observed-publication` | `source-composition-unbound` |
| `collector-and-host-last-use` | `source-composition-unbound` |
| `general-host-registry-root-epoch-closure` | `model-interface-unbound` |

The first two have checked abstract QNT/Lean interfaces, not an actual candidate
source refinement. The third is a future mechanism not covered by the existing
Experimental models. These three research interfaces are not native gate IDs.
All three research obligations remain owed; the input has no `satisfies` or
`composition_binding` rows. Current-repair model paths stay in `models/gambit`;
unchanged future mechanism models stay in `models/experimental`.

Removing any source used by the declared sections exposes a missing transfer
premise without deleting obligations or composition requirements. Restoring the
same sources restores the result. No inference was moved to Python, and no
production Scheme rule, framework entry, Session or registry was changed.
This is a direct research evaluation, not proof of a registered Clue first hit
or entire-framework/native acceptance.

## Initial Failure And Executable Replay

The initial five-test run failed the new relation test and took 7.893 s.
The existing Scheme rules returned:

```text
architectural-host-registration: gambit-design-missing
current-host-root-boundary: gambit-design-missing
```

The facts associated `gambit-baseline` only with the marker source, while the
actual transfer targets were collector and host-call sources. The correction
adds those two explicit design/source associations in the DSL data. It changes
no inference rule, budget, QNT source or native code.

The final regression reproduces both original missing-design results by
withholding exactly those associations from the otherwise corrected input,
and confirms that obligations remain. This preserves the failure as an
executable relation control rather than silently changing the expected result.
The initial Lean recheck also passed; its receipt remains
`host-root-publication/lean-4nq5d662` rather than being relabeled as the final
test-source run.

## Exact Limits

The [formal validation](validation.md) retains all six TLC results, both
completion witnesses, the independently safe imported-protocol states in the
last-use counterexample and the five conditional Lean declarations. Host phase 3
means this record's final access, not a universal C-call/OS-exit deadline.

The [current Recipe](../../../docs/host-root-publication-recipe.md) still needs
actual supported caller, physical root/descriptor census, publication edge,
post-GC reload, per-record last consumer and terminal admission correspondences.
The [Experimental study](../../../docs/experimental/host-root-registration.md)
does not inherit those finite results as a general registry/carrier/epoch design.

No runtime source, imported model algorithm, native fixture, qualification lock,
bootstrap, original pressure test or another lane's acceptance state changed.
No native progress is awarded and the owner's 9/12 is not recounted here.
