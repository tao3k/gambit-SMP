# Stage-One Integration Validation

Local checks of the [whole-package design](stage-one-integration.md). No runtime
lock/TLS change, native build, stress test or other-lane checkpoint was changed
or executed. Historical receipts retain their original hashes and negative
observations; the new policy requires a full matched repaired rebuild, not
backward support for defective SMP or old inline object code.

## Bound Inputs And Source Boundary

| Input | SHA-256 |
| --- | --- |
| `docs/experimental/stage-one-integration.md` | `dbfad863395c62c286be70327fc2e775854a82895bd3f583021169ac60a7af16` |
| `models/gambit/runtime_metadata_vm_publication.qnt` | `16c68335bbbf956e75cbabeb2b4348e037491dc173e2fbd1e153a31ad7144d3f` |
| imported `runtime_metadata_allocation.qnt` | `5dc6cb210c866d6e583c60f0cfa40465bf8de9bbb33a892c090848df8c867ee3` |
| imported `vm_constructor_root_publication.qnt` (unchanged) | `85ae70be31d8a2b9f482f0131c28341bad49caf2f9503424d00f3f1176dee5e5` |
| `models/gambit/lean/RuntimeEntryContracts.lean` | `0f54142e2505d777d099c8e94ca34cf3a655e7959a812808c25f7241defa5a25` |
| `models/gambit/lean/controls/RuntimeEntryFalseClaims.lean` | `287ba6448126b4330ece8299b4f5f391f2d96ef96f6034968a812c2b95abfe37` |
| `evidence/scenarios/parallel-gc/runtime-entry.manifest.json` | `7938437608440b03150e950390c0a1c5a9c1b1c763e530238a054e44c5b9239e` |

The existing overlay lock/patch remain respectively
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b` /
`8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
Source audit confirms this overlay already catches up and publishes a VM under
one registry interval; the package must preserve that guarantee, not recreate
its old split defect. Global binding/range correspondence is a separate join.
No native failure is attributed to an abstract negative control. The review
does not silently substitute this source for the other lane's newer candidate.

## Actual Composed Counterexamples

The final composition imports existing actions and checks both observer joins.
Its two expected counterexamples and positive safety/weak-fair completion passed
over **168 distinct states, 387 generated**. The traces were inspected:

- **Binding before registered range:** five states end with an already-running
  VM, `globals={0}`, `roots={0}`, nonzero processor count and no local constructor
  errors. The record has `prm=true`, binding/visibility true and an actual
  completed record observation with `badRecord=false`; count/slots for new index
  1 remain absent. Reading that binding gives `badRange=true`. Thus the missing
  bridge is not hidden by a not-yet-running VM or a never-executed record reader.
- **Split constructor publication:** twelve states end with initialized/published
  record and range, `globals={0,1}`, but an enabled VM whose roots are `{0}`.
  A binding read gives `badChild=true`. The imported split-link/enable policy
  permits registration while its processor count is zero; the fixed registry
  history excludes this schedule.

The positive composition also explores writer failure before structural commit,
private constructor failure and catchup allocation failure. It does not prove
actual C weak memory, all writers, real root relocation, OS waits, full FFI
unwind/generation or performance. Its one new slot/constructor is a finite witness,
not a machine resource limit. The source's correct catchup protocol is reused.

Final receipt:
`.cache/runtime-entry-models/binding-vm-observed-local-coverage/receipt.json`,
SHA-256 `62caab283e4168b1e876cfab6822871f5fc7412de3fa7e426f678dcc8a469a60`.
It reports stable context/source, no timeout, native `not-run`, and false runtime
and release admission. Formal campaign: 14.489 seconds, not a runtime benchmark.

The existing metadata profiles were checked at the corrected current digest:
**ten expected controls**, positive safety/completion, **1,008 distinct states**
(2,956 generated). Receipt
`.cache/runtime-entry-models/matched-rebuild-metadata/receipt.json` has SHA-256
`a44e9a91dbe0539d58795f5cd75f197ed1714839da32598b194c98ba5329f0da`;
stable context/source, no timeouts and no native/runtime/release admission.
Its 71.638-second campaign is checker time, not evidence of a runtime slowdown.
Existing host-auto scheduling and per-check limits were not changed.

## Retained Rejected Attempts

All three rejected formal attempts remain observations, not protocol
counterexamples. No failure was relabeled as a pass or overwritten:

| Receipt below `.cache/runtime-entry-models/` | SHA-256 | Actual rejection |
| --- | --- | --- |
| `binding-vm-composition/receipt.json` | `0571c839e54ea871ab5e1fbc3b00f592cd4e5683182e9686b7ff4719b2f4d7da` | Imported models were absent from the isolated directory because the case omitted existing `dependencies` configuration. Fixed through the existing manifest, not Python. |
| `binding-vm-composition-imports/receipt.json` | `a531ed146bdcbf3a7c415d3affbe017df578b5e853302f6a615550dacc9baf21` | Quint translation rejected a shared initializer action as used for both init and step (`QNT409`); no state exploration occurred. |
| `binding-vm-composition-qualified/receipt.json` | `d0e4c26a5c0065f38f2545e1010b18d650df90758f6a446d88c4c48b378448c0` | Renaming that action did not resolve translation; the same restriction remained. |

Pure initial-record functions with direct per-initializer assignments resolved
the translation restriction without duplicating the imported transition logic
or weakening invariants. The initial successful version is also retained at
`binding-vm-composition-pure-initial/receipt.json`, SHA-256
`ab7963103f1fdf6cfa4278dc71f77e4815b4f9b76ee9bea45a457cb4608887a9`.
The final counterexample was strengthened to require a real successful record
observation and an already-running locally rooted VM. That earlier receipt is
not relabeled as a check of the strengthened bytes.

## Lean And Existing Scheme Relations

Guarded Lean build/check passed, printing **eighteen** theorem inventories with
standard axioms and no `sorryAx`; **ten** deliberately false claims were rejected.
`bindingCoverageComposes` and `localCoverageWithoutBindingBridge` formalize the
logical join and its missing-premise counterexample, not source C instructions.

Observations under `.cache/runtime-entry-formal/run-glb80urt/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `bc3e99ed754a5e23b1568ea3974a97d77f34d64e1ddef257c8892149ff1d684c` |
| `axioms.json` | `0a271136506955b0b0ea13d3afafc6c8871cd796cda70382e81f92135efae5ee` |
| `false-claims.json` | `d5ec81a021151bb7484a2d59b9e30b5b6ab765cc1114dff6e3eb03459681681e` |

Every observation exited without timeout and left quiescent process groups.
Focused runtime-entry tests passed (three tests, 4.269 seconds), as did the
unchanged parallel-GC scenario check (0.291 seconds). Test times are not native
performance data. The final focused suite rechecked model/source/context hashes.

The existing Scheme DSL consumes the matched rebuild policy, producer choice,
source joins, imported model scope, logical bridge and whole-package acceptance
premises. Session reuse remains valid; withdrawing the integration document or
composition model source exposes missing provenance, and restoration recovers
the original answers. Earlier alternatives are explicitly superseded by the
current integration choice, not left as competing current fallback mechanisms.
All model scopes remain partial, all three native obligations remain missing,
and `satisfies=[]`. No production Python parser, inference rule or workflow was
added; Python edits are the existing focused test's theorem/control/source list.

## Reproduction

```sh
quint typecheck models/gambit/runtime_metadata_vm_publication.qnt
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case runtime_metadata_vm_publication --out .cache/runtime-entry-models/integration-recheck
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case runtime_metadata_allocation --out .cache/runtime-entry-models/matched-metadata-recheck
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

Use fresh verifier output paths; disposable cache output is not a source input
or native acceptance certificate.
