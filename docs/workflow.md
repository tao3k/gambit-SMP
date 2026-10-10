# Source, Models And Native Evidence

## Classification

| Domain | Model examples | Cross-protocol boundary |
| --- | --- | --- |
| VM lifecycle and capacity | `heap_floor`, `heap_allocation_headroom`, `lazy_vm_startup` | Publication, processor initialization, GC admission and failure rollback |
| GC roots and relocation | `root_marker`, `gc_stack_lifecycle`, `gc_key_reference`, `gc_rc_roots` | Saved registers, stack frame ownership and forwarding |
| Synchronization | `sync_message_acquire`, `sync_wait_handshake`, `sync_tree_rounds` | Weak visibility, condition wait and reusable barrier population |
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

## Why Datalog And Markdown Both Remain

`evidence/relations.json` is a deterministic fact export, not a second manually
maintained catalog. `evidence/rules.dl` is executable pyDatalog rule syntax.
Queries expose missing model links, missing native adapters, shared obligations,
and transitive dependencies. Existing source manifests/report snapshots are
the input records; their digest changes make a stale export fail `--check`.

Markdown explains assumptions and scope. Datalog does not prove C memory
ordering or QNT invariants. A native adapter fact indicates only fixture
availability, not a passed native result. A frozen-negative fact indicates a
digest-bound trace, not an exhaustive positive check.

Queries accept acyclic PR dependencies only. Cycles are rejected before engine
execution after a local cyclic negative control stalled. This restriction is
explicit and tested; it is not a claim that arbitrary graph queries terminate.

## Design Sources

- [Feeley: Parallel VM for efficient Scheme compilation (1990)](https://doi.org/10.1145/91556.91606): historical compiler/VM design, not a specification of today's SMP GC.
- [Feeley: parallel GC announcement (2016)](https://mailman.iro.umontreal.ca/mailman3/hyperkitty/list/gambit-list%40iro.umontreal.ca/thread/HZQR57RT4NMFRAXODSXIMOVYJR4DSHJR/): describes a stop-the-world collector with parallel collection work; reported speedup was explicitly preliminary.
- [Feeley: SMP usage discussion (2017)](https://mailman.iro.umontreal.ca/mailman3/hyperkitty/list/gambit-list%40iro.umontreal.ca/thread/HJEMBKQTP5PXA4EUHA32LP5Q2QVSK7EF/): waiting processors participate in GC; audit actual wake/wait source before adopting a protocol abstraction.
- [pyDatalog](https://github.com/pcarbonn/pyDatalog): existing query engine, not a custom handwritten Datalog evaluator.

These references guide obligations; current source and reproducible receipts
remain authoritative. No claim of complete SMP correctness is made.
