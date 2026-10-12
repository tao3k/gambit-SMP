# Source, Models And Native Evidence

## Classification

| Domain | Model examples | Cross-protocol boundary |
| --- | --- | --- |
| VM lifecycle and capacity | `heap_floor`, `heap_allocation_headroom`, `gc_postcopy_headroom`, `lazy_vm_startup` | Publication, processor initialization, copying assignment, GC admission and failure rollback |
| GC roots and relocation | `root_marker`, `gc_stack_lifecycle`, `gc_key_reference`, `gc_rc_roots` | Saved registers, stack frame ownership and forwarding |
| Synchronization | `sync_message_acquire`, `sync_wait_handshake`, `sync_tree_rounds`, `ticket_queue_handoff`, `sync_resource_retirement`, `sync_resource_users` | Weak visibility, queue ownership, condition wait, reusable barrier population, resource admission/drainage and partial initialization rollback |
| GC protocol composition | `gc_sync_membership`, `gc_work_closure` | Stop-the-world root admission, nested collection with old membership, startup rendezvous, unfinished local work and phase closure |
| Shared tables | `gc_rehash_protocol`, `rehash_lock_ownership`, `serial_number_transaction` | Predicate allocation, GC, resize publication and compound transactions |
| Process and pipe I/O | `pipe_wait`, `exec_gc_polling` | Blocking operations must retain GC participation; configuration failure and cleanup |

## Workflow

1. Read design publications and the exact pinned source. A historical paper
   explains intent; it does not establish current synchronization behavior.
2. Map public reports and PR changes onto explicit protocol obligations.
   Preserve source-head identity, partial success and residual failures.
3. Build bounded QNT protocols and composition models. Record assumptions,
   excluded failure paths, and safety versus progress properties.
4. Freeze actual checker counterexamples, including independent fault controls.
   Reject tool errors, stale digests and incomplete exhaustive queues.
5. Audit current source against the repair protocol. Lexical source guards
   reject known wrong edits but are not semantic refinement proofs.
6. Run atomic native cases with selected artifacts. A failure must update
   the model/source hypothesis before rerunning the same failed route.
7. Require source-generation-link closure, complete threaded self-bootstrap,
   full native suites and Gerbil package build/test correctness.
8. Only then consider formal patch promotion and the separate performance gates.

Runtime-edit admission requires an explicit paper/source obligation, an
inventory of prior coverage, independent fault controls and an exhausted
bounded positive check. Record unresolved composition and lifetime gaps
before choosing a source repair. A green local model with an excluded
source-reachable schedule does not satisfy this gate. See
[Synchronization Resource Retirement](sync-resource-retirement.md) for a
current model whose coverage gate is still open; do not promote its abstract
drain contract into runtime destruction calls yet.

QNT is the current formal-method lane; Lean is not required for this workflow.
Deepen bounded state exploration, independent fault controls and protocol
composition before introducing another proof system. Exhausted TLC queues
establish only the modeled properties within declared bounds and assumptions.
Source correspondence, native behavior and complete toolchain acceptance remain
separate obligations, not claims inferred from a green abstract model.

Installed Quint 0.33.0's `dist/src/tlc.js` invokes TLC with `-deadlock`, which
disables the automatic deadlock check. Existing invariant-only admissions
therefore do not attest deadlock freedom. New progress claims must explicitly
check nonterminal action availability and their temporal completion property,
with declared scheduling/fairness assumptions; do not upgrade old safety
receipts by inference.

Explicit unchanged-model progress overlays and source/context-bound protocol
extension checks now have separate Datalog predicates. Their negative
controls, complete temporal logs and exact generated/model source identities
are required independently of old safety admissions. See
[Explicit Model Progress](model-progress.md). The extension registry preserves
its temporal-capable verifier; it is not flattened into invariant-only cases.

## Python Framework Boundaries

`src/gambit_smp/framework.py` owns bounded process execution, process-group
termination, child identity, hashing and the clean GNU GCC environment.
It never decides whether a protocol or native test passed. Model checking,
source extraction, runtime identity and crash analysis remain separate
adapters with their own admission rules. Source-unit mocks are not native
correctness evidence. No per-candidate Python runner is required.

See [Python Verification Framework](python-framework.md) for layer ownership
and the local validation boundary.

Run the framework regression suite with:

```sh
uv run --locked python -m unittest discover -s tests -p 'test_*.py'
uv run --locked gambit-smp evidence --check
```

Generated binaries, logs and receipts belong under a fresh `--out` directory
in `.data/`, not beside tracked fixtures. Keep failed receipts and portable
counterexamples; do not reuse an output directory or silently widen a budget.

## ASCENT Evidence

`evidence/relations.json` is a deterministic fact export, not a second manually
maintained catalog. `evidence/catalog.ss` and `evidence/research-rules.ss` contain
inert typed ASCENT rules. The installed engine reads these sources; downstream
Python does not import, evaluate or compile Scheme and has no rule-parser fallback.
Queries expose missing model links, missing native adapters, shared obligations,
and transitive dependencies. Existing source manifests/report snapshots are
the input records; their digest changes make a stale export fail `--check`.

Markdown explains assumptions and scope. Datalog does not prove C memory
ordering or QNT invariants. A native adapter fact indicates only fixture
availability, not a passed native result. A frozen-negative fact indicates a
digest-bound trace, not an exhaustive positive check.

The concrete failed-file/mode retry rules are now connected to the upstream
suite entrypoint before native execution. See
[Failed Route Execution Gate](suite-retry-preflight.md) for the no-execution
negative control and remaining scope/review gaps. A changed artifact is a
review request, not an automatic native admission.

Paper-section facts and named model-contract edges now make the assumptions of
the two paper-guided compositions queryable. Contract dependencies have their
own cycle/identity checks, separate from PR dependencies. Missing native
adapters remain visible through the transitive contract closure. Paper facts
identify references, not publication authenticity, source refinement or model
proof. See `docs/gc-sync-membership.md` and `docs/gc-work-closure.md`.

Designated `modelReceipt` inputs are validated against current model bytes,
the complete required checks and initializers, finite-state-TLC evidence and
stable-source admission before exporting a `model_receipt` fact. This indexes
an existing recorded checker admission, not a fresh re-verification. Missing
designated receipts in contract dependencies are separate from missing native
adapters. Receipt facts neither attest current C behavior nor admit a release.

Queries accept acyclic PR dependencies only. Cycles are rejected before engine
execution after a local cyclic negative control stalled. This restriction is
explicit and tested; it is not a claim that arbitrary graph queries terminate.

## Design Sources

- [Feeley: Parallel VM for efficient Scheme compilation (1990)](https://doi.org/10.1145/91556.91606): historical compiler/VM design, not a specification of today's SMP GC.
- [Feeley: parallel GC announcement (2016)](https://mailman.iro.umontreal.ca/mailman3/hyperkitty/list/gambit-list%40iro.umontreal.ca/thread/HZQR57RT4NMFRAXODSXIMOVYJR4DSHJR/): describes a stop-the-world collector with parallel collection work; reported speedup was explicitly preliminary.
- [Feeley: SMP usage discussion (2017)](https://mailman.iro.umontreal.ca/mailman3/hyperkitty/list/gambit-list%40iro.umontreal.ca/thread/HJEMBKQTP5PXA4EUHA32LP5Q2QVSK7EF/): waiting processors participate in GC; audit actual wake/wait source before adopting a protocol abstraction.
- [gerbil-ascent](https://github.com/tao3k/gerbil-ascent): installed native rule reader and inference engine.

These references guide obligations; current source and reproducible receipts
remain authoritative. No claim of complete SMP correctness is made.
