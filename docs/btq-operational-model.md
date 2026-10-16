# BTQ Operational Model

## Decision Before Implementation

| Question | Evidence-based decision |
| --- | --- |
| Is this the relevant path? | The existing binary/object/DWARF correspondence locates the compiled stress fault at deletion fixup's sibling child-color read. The model follows that generator, not a guessed Scheme call stack. |
| Was it already explored? | `btq_gc_transitive_edges.qnt` checks conditional root/edge/ownership obligations. It does not execute tree operations. This model replaces that gap with explicit mutations; the old conditional result is retained. |
| Is it worth modeling? | A structural counterexample can identify a specific missing/reordered write before another full bootstrap or stress run. A passing bounded model only narrows this search; it does not clear the native failure. |
| What benefit is expected? | Reduced diagnostic search and fewer unjustified native experiments. No runtime speedup or quantified research-time saving is claimed. |

## Source Operations

`models/gambit/btq_operations.qnt` translates the pinned `define-rbtree`
generator in `vendor/gambit/lib/_thread#.scm`. The current source overlay is
bound separately by the existing source lock; this is not a claim that the
entire overlay equals the submodule baseline.

| Source operation | Model operation | Representation |
| --- | --- | --- |
| `update-parent!`, lines 286-290 | `replace` | Update the actual parent's selected child, including the sentinel root slot. |
| `rotate!`, lines 292-302 | `rotate` | Move beta, set beta's parent even when beta is nil, reconnect the rotated root. |
| `def-insert!`, lines 325-426 | `insertBelow`, `beginInsert`, `insertFix` | Search by key, set container and nil children, update the minimum alias, recolor/rotate, blacken root, reset sentinel parent. |
| `def-remove!`, lines 427-566 | `beginRemove`, `removeFix`, `removeDone` | Clear removed links/container, transplant a child or successor, exchange the required color, repair the black deficit and reset sentinel parent. |
| Deletion `body`, lines 437-470 | `removeFix` | Both mirrored sides; red sibling rotation; far/near child reads; recolor propagation; near rotation and final common case. |

The sentinel is node `0`: its left field is the tree root and its right field
is the cached minimum. A removed `#f` link is `-1`, not nil. Sentinel minimum
updates follow insertion/removal branches; they are **not recomputed as a
repair** after each operation. The invariant independently computes the
minimum to check the source-directed update.

The safety predicate checks live child edges, parent/container consistency,
root reachability, full search ordering, root/nil colors, red-parent exclusion,
bounded black heights and the deletion sibling-color access. It does not assume
these properties after a mutation. They must follow from the transition.

## Bounds And Composition Boundary

- Four distinct nodes, all nondeterministic insertion/removal choices. The
  finite bound is a verification domain, not a configured CPU/worker limit.
- Distinct priorities and all-equal priorities are separate initial domains.
  The actual comparator at lines 1461-1466 is strict; ties insert on the right
  but rotations can place equal-priority nodes on either side. Mixed equality
  classes, floating-point exceptional values and changing priorities are not
  covered by these two domains.
- Two complete fill/drain rounds reuse the same cleared node slots. The second
  round does not reset fields or rebuild a fresh tree.
- Two possible lock owners represent competing callers. Queue ownership spans
  the fixup and is released afterward. Actual scheduler APIs obeying this lock
  discipline remain a separate source obligation; choosing an owner does not
  prove every native caller acquires the correct lock.
- Independent queue work may occur while this queue is owned. Weak fairness
  checks eventual drain and independent progress, not a performance bound.
- Each rotation/transplant block is atomic at this abstraction level. This is
  not a weak-memory proof or proof of every possible native safe point.
- Black color abstracts the source's sentinel-valued color reference to a
  Boolean. GC relocation, copying publication, physical slots, allocation
  generations, eager-field scan partition and thread wakeup/lock handoffs are
  **not yet operationally composed** here.
- There is one queue identity. Native `node->rbtree` recovery from a black
  node's color or a red node's parent's color is not independently executed.
  Corruption of those sentinel references therefore remains a required physical
  identity obligation, not something this tree result excludes.

Those last gaps must remain visible. In particular, this model cannot disprove
the previous native observation of a repeatedly scanned physical object. The
next collector component must execute forwarding, payload copying and field
rewrites; it must not merely assign "edges valid" at collection completion.

## Controls And Reproduction

The two negative initializers omit concrete writes: reconnecting a rotation to
its old parent, or transplanting a removed node's replacement. The ordinary
topology/balance invariant must reject both. These are sensitivity controls,
**not assertions that either omission exists in current Gambit**.

Run the checked-in `btq-operations.recipe.json` through the existing sealed
research framework, with a valid completed producer. The recipe reuses the
existing locked workspace and does not rebuild or create another source tree.
TLC concurrency is selected by the framework from the host, not by this model.
Retain failed receipts. Source/model admission remains false even when all
model checks pass.

The strengthened source-operation run explored **6,356 distinct states**
(19,404 generated, zero queued), with safety and weak-fair completion passing.
The missing-rotation-parent and missing-transplant controls both produced
invariant violations. The whole child framework run took 34.444 seconds;
individual check timings and exact receipt hashes are recorded in
`evidence/source-results/compiled-stress-failure/operations-model.json`.
The earlier ordered-path, single-round result (854 states) and distinct-only
two-round result (1,588 states) are superseded in scope, not rewritten. The earlier list/set type mismatch remains a failed
receipt; it never launched model checking or native tests.

The BTQ, concurrent-GC and evidence-view regression modules passed **16/16,
zero skips, 17.833 seconds**, using the receipt-bound compiled ASCENT ABI.
The initial test invocation without that ABI selection failed; substituting
the sealed Python package also failed because that older package lacks the
current view module. Neither was a semantic pass. The successful invocation
uses the current Python framework with an explicitly receipt-bound native
library, not the older sealed Python package on `PYTHONPATH`.

The native milestone remains **5/12**. The remaining gates are Stress GSI,
Stress GSC, registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness and
release performance. The compiled `tfib_stress.scm` SIGSEGV and interrupt stress
timeout remain failures; this component does not close either gate.
