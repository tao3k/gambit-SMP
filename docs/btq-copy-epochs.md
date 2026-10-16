# BTQ Copy Epoch Composition

## Decision Before Execution

The native diagnostic still fails at a BTQ right-child color read. Existing
tree operations and scan-cursor models check separate protocols; neither
establishes that relocation preserves the logical identity of every tree edge.
This composition addresses that missing interaction, not an inferred crash cause.

The expected benefit is eliminating invalid protocol candidates before another
bootstrap/stress run. No runtime speedup is predicted or admitted by this model.
Unchanged native failures must not be retried merely because this model passes.

## Executable Projection

`models/gambit/btq_copy_epochs.qnt` imports the existing BTQ deletion actions.
It composes forwarding CAS, competing private reservations and loser rollback,
word-by-word payload copy, scan-task publication, rewritten roots and two
semispace epochs. Every stable collection boundary compares physical references
and fields against the logical tree, including each destination's node identity.

There are two logical nodes, two copy roles and six projected fields per object.
The roles bound model interleavings; they do not set native CPU parallelism.
The cell encoding `address * 32 + offset` is injective for the declared offsets
0, 4, 5, 6, 7 and 17 and remains disjoint from root cells 0 and 1.
Explicit mirror steps are projection bookkeeping: collection and tree actions
are disabled while a committed logical transition is being mirrored.

The five controls duplicate a scan task, publish before copying completes,
omit right-edge scanning, resume before pending work drains, or alias private
allocation arenas. Each must produce a decoded invariant counterexample.

## Boundaries And Remaining Requirements

Source audit found an additional limitation: the original physical projection
encodes colors as booleans and treats queue reference 9 as permanent. Actual
`define-rbtree` uses #f for red and the queue object for black; mutex/condvar
queues may move. The original result is retained as a conditional abstract
check, not source correspondence for color or movable queue references. The
`btq_queue_relocation.qnt` successor explicitly addresses this missing graph.

- Sequentially consistent finite protocol, not C/ARM memory-model refinement.
- Projected fields, not full thread layout or arbitrary object graphs.
- Scan leases are abstract tasks, not the collector's raw chunk FIFO.
- GC occurs at stable tree boundaries, not within transient tree mutations.
- No native fault causality, runtime repair or performance acceptance follows.
- Source correspondence still needs actual allocation generations, queue/scan
  ownership, publication order and mutator exclusion to be established.

The recipe uses the existing sealed research engine and current source-bound
producer. No new full source tree or unchanged native stress is required.
Earlier parse failures and the tuple-key counterexample decoding rejection are
retained; the rejection is not converted into a passing receipt.

## Checked Result

The integer-cell recipe completed in 54.632 seconds. The positive check generated
147,127 states, exhausted 22,961 distinct states with an empty queue, and passed
safety plus weak-fair completion. All five controls produced decoded invariant
counterexamples. The portable result is
`evidence/source-results/compiled-stress-failure/copy-epochs-model.json`.
The registered `btq-copy-epochs` Evidence view retains both source-refinement
requirements and the actual native DENY. Removing the model context must not
remove the native failure or alter those open source requirements.
