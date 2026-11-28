# Caller And Reader Contract Validation

## Identity And Limits

Local 2026-10-19 continuation of the [caller audit](runtime-entry-callers.md).
The [previous validation](runtime-entry-validation.md) remains an observation
of its original model hashes; it has not been rewritten as a current pass.
No runtime source, TLS, lock, producer, bootstrap or native test was changed.

| Current input | SHA-256 |
| --- | --- |
| `runtime-entry.manifest.json` in `evidence/scenarios/parallel-gc` | `973874942301b9bb5f7e825dc92ad066f5e27bbf233aef12e1e457c59e54243a` |
| `models/gambit/runtime_metadata_allocation.qnt` | `ae59329efc5f0274b41aeb98729d216de60db0302485cf669cbd7a209e6f9241` |
| `models/gambit/runtime_host_entry.qnt` | `10c21c9aaa4314beddec4e9df7eff518c8cd7ba15e7659a94e0756fa236935a4` |
| `models/gambit/lean/RuntimeEntryContracts.lean` | `ec4ddb53a2275a7a347cf5d775126e837e1f72a9c05823504acff64284377323` |
| `docs/experimental/runtime-entry-callers.md` | `172661cfaa1d28e286c9aad2372976ae0fee4bf2e737b24181015cacb2387ca7` |

The manifest binds the reviewed Gambit lock/patch, source references and proof
inputs. It cannot qualify a later native candidate automatically. Actual
reviewed candidate `mem.c`, `setup.c` and `_kernel.scm` hashes still matched
the original source lock during this audit.

## Model Outcomes And Actual Witnesses

Quint 0.33.0/TLC completed nine expected checks: two positive safety/liveness
checks, six fault-control counterexamples, and one legal reachability witness.
Positive checks exhausted the state queue and completed temporal checking.
Neither expected counterexamples nor source references award native passes.

| Check | Outcome | Checker seconds |
| --- | --- | --- |
| Metadata positive, both separate profiles | 276 distinct states, safety and weak-fair completion | 4.054 |
| Split reservation | Expected fault counterexample | 5.315 |
| Early publication | Expected fault counterexample | 5.319 |
| Unprotected rehash reader | Expected fault counterexample, six trace states | 4.233 |
| Host entry positive | 97 distinct states, safety and weak-fair completion | 4.197 |
| Lease-only same-processor entry | Expected fault counterexample | 5.569 |
| Unregistered entry | Expected fault counterexample | 5.653 |
| Lost caller binding | Expected fault counterexample | 5.963 |
| Universal serialization assertion | Expected legal parallel-state witness, five trace states | 5.945 |

The actual rehash counterexample ends with `readerPhase=2`, `found=false`,
`readerNode=-1`, `rehashPhase=2`, `nextA=-1`. It uses one writer and unchanged
head/object identities; no table publication is needed to expose the lost
lookup. It does not reproduce a native Gambit failure or prove arbitrary
hash-table behavior under the C memory model.

The actual parallel witness uses protocol `policy=0`, not a faulty policy.
Both entries have `phase=2`, registered=true and lease=true, with distinct
targets 0/1 and matching execution owners 0/1. Thus the model permits valid
simultaneous execution. This refutes universal serialization, not safety.
It makes no throughput or wall-clock improvement claim.

The verifier reported stable context and selected host-auto capacity: twelve
available processors, two concurrent control checks with six TLC workers
each, and twelve workers for a positive check. These are observed host/resource
choices, not model constants or required runtime topology.

Receipt SHA-256:
`ee11e08d02e8933af90846abab753cdc05d120b067c85d2ae1bfbec42e22e96b`.
Raw logs and traces remain in configured cache storage. This portable summary
preserves the observed identity but does not substitute for missing raw logs
where a consumer requires formal admission.

## Lean And Existing Scheme DSL

The guarded Lean consumer checked eight named theorem inventories, including
the existing reused exit-accounting result, with no `sorryAx`. The added reader
counterexample is finite and the stable-topology lemma has an explicit premise;
neither is an unbounded implementation proof. Three deliberately false claims
were rejected by `decide`, including successful lookup after clearing A.next.
No import/synthesis error was accepted as a semantic rejection.

The three focused consumers passed in 1.203 seconds: guarded Lean, document and
input consistency, and actual installed Scheme evidence relations. The Scheme
test checked every declared premise, same-Session reuse, withdrawal of caller,
reader and slow-lock sources, explicit unknowns, and restoration. The original
five-chain consumer independently passed in 0.220 seconds. Neither scenario
derived native `satisfies` or an action/mandatory investigation direction.

The existing process adapter and Lean heartbeat/recursion limits were retained;
no timeout or live descendant remained. The verifier used the existing adaptive
CPU/memory scheduler. No new Python reasoning, source parser, runtime injection
or native campaign was introduced. Commands remain the ones in the original
validation, using the current manifest and a fresh configured-cache output.

## Still Open

Actual native overlap, complete permanent-allocation caller coverage, arbitrary
reader/rehash composition, callback/snapshot allocation and GC effects, C weak
memory, failure/rollback, and current native acceptance remain open. Stage One
has bounded source-review candidates, not an approved runtime patch. Arbitrary
foreign attachment and general concurrent module initialization remain separate
Stage-Two semantic/ABI work. Historical failed native routes were not rerun.
