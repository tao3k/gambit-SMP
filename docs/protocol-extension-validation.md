# Executable Protocol Extensions

These three models extend, rather than rerun, the previously checked local
protocols. They express sufficient engineering contracts. Fault controls are
deliberate contract mutations, not assertions that current source permits every
schedule. No new runtime patch is admitted by these models alone.

The reviewed source is candidate 026 over revision
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Exact source and cached paper hashes
are pinned in `evidence/protocol-extensions.json`. The manifest also records
source symbols, predecessor models and excluded behavior. Local context paths
are repository-relative; another machine must supply matching cached inputs.

## Epoch And Work Bridge

`gc_epoch_work_bridge.qnt` replaces abstract per-worker scan completion with
private, queued, scanning and completed work. Scanning object 1 may discover
object 2, so a momentarily empty shared queue is not a completion certificate.
The same execution parks participants, completes roots, drains work, collects
acknowledgements, changes the population and enters a second GC epoch.

Both population growth (one to two) and shrinkage (two to one) are initial
states. Four controls violate root readiness, private-work accounting,
old-population closure and acknowledgement incarnation respectively.

Engineering consequences:

- Retain the old actual population throughout a nested resize GC. The requested
  target is not the participant count until the synchronous population commit.
- Decrement the active-worker count only after local producers and queued work
  are exhausted. A scanner that discovers work remains a producer.
- A final acknowledgement must certify this epoch's closure. New participants
  must join before their next epoch begins.

These are obligations on `___vm_resize_pstate`, `barrier_sync_op` and
`mark_reachable_from_marked`, not instructions to add epoch fields everywhere.
Existing barriers may establish incarnation isolation without explicit tags.

## Physical Scan Claim Transfer

`gc_scan_claim_transfer.qnt` separates two physical slots from the single
logical object they reference. Legitimate aliasing copies that object once;
it does not permit rereading an already relocated physical slot as from-space.
A copy-ready frontier, local scanned prefix, queue transfer and thief claim
are modeled separately across two address-reusing epochs.

Four controls retain a local claim during export, expose an incomplete copy,
rewind a rewritten slot and use a previous epoch's claim. The positive contract
hands over only the remaining scan extent and retires local ownership.

Important source distinction: `end_heap_chunk` already excludes a chunk
containing `scan_ptr` from the queue. Do not add a duplicate check or call that
guard missing. The model permits abstract suffix transfer to express ownership;
Gambit's complete-chunk FIFO must instead establish an equivalent full-extent
contract. Audit cursor resets and epoch boundaries against that mapping before
changing the implementation. No arbitrary to-space acceptance is authorized.

## Resource Reservation Across Reuse

`sync_retirement_drain.qnt` combines holder/waiter/late-signaler accounting
with processor-slot reincarnation. It adds a distinct captured-but-not-admitted
reference and an admitted-but-not-yet-locked reservation. Destroying an unused
mutex is still unsafe when an admitted caller is about to lock it.

Four controls allow admission after sealing, accept an old reference into a
new incarnation, omit pending reservations from the drain, and publish a
partially initialized second incarnation. Condition initialization failure
rolls back the successfully initialized mutex without reopening admission.

The source sends a condition signal after releasing `sync_mut`; observing the
message cannot certify that the sender has stopped using `sync_cv`. Likewise,
joining a retired processor does not by itself drain all foreign references.
The positive model assumes atomic admission/seal and generation validation;
the current source has not been shown to implement this exact contract.
Equivalent global quiescence can satisfy it. Do not install destructors until
that source proof and real lifecycle tests exist.

A concrete source-review schedule for a naive destructor is now explicit:
`barrier_sync_op` snapshots the old count in `n`, changes the VM count at the
root, then sends the winning operation to old children. A retiring child can
observe `sync_id0` through `SYNC_GET_MSG` and return into the shrink branch of
`___vm_resize_pstate` while the parent's `SYNC_SEND_MSG` is between publication
and its final signal. The child calls `___cleanup_pstate` before thread exit;
the root joins it later. Therefore putting destruction unconditionally in the
child cleanup path has no demonstrated ownership drain. Possible repairs must
instead prove sender completion before child teardown, or defer owned-resource
destruction to a coordinator after all incoming operations have drained. Moving
`signal` under the lock alone is insufficient because the child has a lock-free
message receive path. These are repair constraints, not native reproduction.

## Papers And Source Mapping

GHC sections 3.4-3.5 distinguish private scan/allocation work from published
blocks and keep possible producers in termination accounting. HotSpot section
3.3 similarly accounts for active workers while local/overflow work or stealing
can produce further traversal. These constrain the epoch/work model. Neither
paper proves Gambit's memory ordering or resource teardown.

GHC's copy-before-forward sequencing is not Gambit's forward-before-copy
implementation. The scan model therefore treats destination identity and
copy-ready extent separately rather than importing the paper's ordering.

Sources: [GHC parallel GC](https://simonmar.github.io/bib/papers/parallel-gc.pdf),
[HotSpot parallel GC](https://www.usenix.org/event/jvm01/full_papers/flood/flood.pdf).
The cached text/PDF files were reused, not downloaded again.

## Verification Contract

Run the shared adapter, optionally selecting one new case:

```sh
uv run --locked gambit-smp verify --out .data/protocol-check
```

The adapter reuses `check_gambit` admission/trace helpers and `framework`
execution/hash/CPU discovery. There is one data-driven adapter for all three
models, not three bespoke scripts. TLC workers follow available host CPUs;
the model's finite processor bound is separate from host parallel capacity.
The per-check bound remains 90 seconds. No native candidate runs.

Quint 0.33.0's TLC wrapper supplies `-deadlock`, disabling TLC's automatic
deadlock check. Consequently each positive check explicitly requests both
`safe` and temporal `progress`. The latter checks nonterminal action
availability and eventual terminal completion under weak fairness of changing
protocol steps. Terminal self-loops are permitted; nonterminal stuttering is
excluded only by the stated fairness assumption.

Full reachable-state exploration within these finite bounds does not prove
unbounded processors, arbitrary object graphs, C/ARM weak memory, POSIX error
behavior or wall-clock performance. Successful setup is assumed by the epoch
model; the lifecycle model explicitly includes one condition-init failure.
Model counterexamples guide source audit, not automatic source attribution.

## Configure Dimensions

`vm_configuration_contract.qnt` additionally explores all eight combinations
of the three build flags. These are configuration dimensions, not three
interchangeable names for SMP:

| Flag | Source contract | Model obligation |
| --- | --- | --- |
| `--enable-multiple-vms` | Separate global environments and heaps for VM instances. | VM-owned roots and participant sets must not become process-global merely because processor IDs coincide. |
| `--enable-multiple-threaded-vms` | Multiple OS threads per VM; without it `CONF_MAX_PROCESSORS` is 1. | Per-VM parking, work closure and resource ownership follow actual processor capacity. |
| `--enable-smp` | Selects the SMP Scheme scheduler through conditional expansion. | Turning it off is not permission to bypass GC coordination when threaded VMs remain enabled. |

`configure.ac` defines these independently; the model does not assume every
combination is natively buildable or fully qualified. Candidate 026's actual
`config.status` contains all three enabled flags. The outer shared CI build
script explicitly lists `multiple-vms` and `smp`; determining its effective
threaded-VM setting requires the nested configure result, not an inference from
the outer argument list alone. This audit does not change Bazel release flags.

The configuration model's collection body remains an explicit dependency on
the three protocol models, not a claim of a full cross-product proof including
all scheduler locks. Its three controls confuse scheduler selection with GC
quiescence, confuse VM count with processors per VM, or mix VM roots.

The same adapter checks it without rebuilding any runtime:

```sh
uv run --locked gambit-smp verify \
  --manifest evidence/configuration-model.json --out .data/configuration-check
```

The adapter now chooses an available loopback converter port per check, avoiding
another Working session's default port. `--resume-from` reuses only accepted,
same-model/source/initializer checks; failed verdicts cannot become passes by
renaming an attempt. Original denied infrastructure receipts remain available.

## Recorded Results

| Model | Distinct reachable states, positive protocol | Error controls | Positive result |
| --- | ---: | ---: | --- |
| `gc_epoch_work_bridge` | 245 | 4 | Safety and explicit temporal progress pass |
| `gc_scan_claim_transfer` | 32 | 4 | Safety and explicit temporal progress pass |
| `sync_retirement_drain` | 158 | 4 | Safety and explicit temporal progress pass |
| `vm_configuration_contract` | 180 | 3 | All eight initial configurations; safety and progress pass |

All four positive searches exhausted their queues. All 15 controls produced
the intended invariant counterexample, with typed traces retained. TLC used
12 workers selected from the available host CPUs, not a hardcoded worker count.
These state counts are model coverage, not speedup measurements.

Portable, log-digest-bound receipts and redacted logs are under
`evidence/model-results/protocol-extensions/` and
`evidence/model-results/configuration-model/`. The configuration campaign reused
its first accepted control after a converter-port conflict; no successful
control was rerun to repair that infrastructure failure. Earlier failed attempts
record a Quint initializer translation limitation, a sandboxed loopback bind
denial and the shared-port collision, not Gambit runtime failures.

Nine protocol-evidence tests and 14 existing research-audit tests pass. The
Datalog adapter distinguishes current bounded protocol receipts from the
remaining source-refinement and native-admission obligations. No Gambit native
test, bootstrap or package benchmark was executed in this round.
