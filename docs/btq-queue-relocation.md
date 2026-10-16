# Movable BTQ Queue And Color References

## Source-Directed Correction

The active SMP `define-rbtree` implementation in `lib/_thread#.scm` defines
red as #f and black as the queue object (lines 254-274). Insertion writes the
queue into child links and container state (lines 377-424). Queue initialization
also writes self references (lines 587-606). Mutex construction initializes the
queue before returning the normally allocated Scheme structure (1630-1636).
These anchors are reproducible from the pinned source plus the candidate lock,
not from an independently numbered source directory.

The previous copy-epoch model's boolean colors/permanent queue omitted this
part of the real graph. Its conditional result is retained, but it does not
establish source-level color/reference correspondence. This is a model gap,
not proof that the native collector mishandles those references.

## Composed Protocol

`btq_queue_relocation.qnt` uses the existing logical BTQ operation module.
It adds queue object 0 to the two movable thread nodes. Black color and node
container references point to its current location; queue parent/self, root and
minimum fields are scanned and rewritten. Queue and thread identity are checked
after two semispace epochs and intervening deletion actions.

The queue projection has five fields and thread projections have six; the
queue does not invent a thread container field at offset 17. This is still a
projection, not complete mutex/condition-variable/thread layouts. Source stop
protocol, weak memory, transient mutator operations and arbitrary graphs remain
outside its proof boundary. Two copy roles bound the model, not native CPU use.

The first fine-grained run reached its original 60-second positive-check limit
without exhaustion. It is retained as DENY, never evidence of safety. The model
was then edited before all remaining controls had terminated, so that run's
overall source identity cannot serve as qualification evidence either. The next
run freezes its inputs through every step.

## Private Copy Reduction

For valid disjoint private destinations, other roles can redirect references
after CAS, but cannot scan the payload until its separate publication action.
Under the model's stable-source assumption, intermediate private field writes
are unobservable and commute with other disjoint copies. The successor groups
those writes while retaining CAS and publication as separate actions. Faulty
early publication and overlapping arenas keep their word-level interleavings.

This is a stated abstraction argument, not a general partial-order-reduction
theorem or C memory-model proof. It does not remove queue/color edges, weaken
stable-boundary identity checks, serialize the two roles, or raise the time cap.

Private-copy reduction alone also reached the unchanged positive limit; that
DENY remains retained. The next frozen model follows each object's ascending
projected field order, matching `scan` -> `mark_array` (candidate `mem.c`
4377-4378 and its advancing `start++` loop). Roots and different objects remain
independently eligible, including competing forwarding attempts. Idle workers'
obsolete job/origin/destination/copy counters are normalized after publication
or a lost CAS; only reservation cursors needed by future allocations remain.
No live operation reads the discarded private job values.

The source-ordered five-control run completed in 54.988 whole seconds; its
positive check exhausted 40,567 states (116,073 generated, zero queued) and
passed weak-fair completion. All original five controls produced decoded
counterexamples. A subsequent frozen recipe adds independent omitted-color and
omitted-container controls; those must be accepted as real counterexamples
before the expanded result is registered. Earlier partial/DENY runs remain
outside qualification.

The expanded frozen run passes in 72.356 whole seconds: 40,567 distinct states
exhausted (116,073 generated, zero queued), safety and weak-fair completion,
and seven decoded invariant-violation controls. The new omitted-color and
omitted-container controls find counterexamples after 3,520 and 3,190 distinct
states respectively. These are checker costs, not native build/test timings.
Portable result: `queue-relocation-model.json` in the compiled-stress-failure
Evidence directory. The current retry-review view uses this successor but still
denies unchanged stress because source repair/refinement evidence is absent.
