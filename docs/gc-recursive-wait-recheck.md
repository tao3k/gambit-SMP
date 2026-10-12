# Recursive GC Wait And Recheck

## Paper Protocol And Source Identity

This follow-up reads GHC sections 3.4-3.5, HotSpot section 3.3 and Boehm
section 2.3 against the pinned source and overlay. It is a mechanism study,
not a full source refinement, scheduling or runtime acceptance claim.
The three cached PDFs and extracted texts matched the paper lock and their
extraction receipts. No abstract-only reading or new download is counted.

GHC's pending-block protocol keeps scanners active while producing work. An
idle participant polls pending blocks while other participants remain active
and rejoins the population before resuming scanning. HotSpot's status-bit
protocol likewise retains local, stolen and overflow work in the termination
argument; its integer active-count alternative is described separately.
Neither paper supplies Gambit's condition-variable implementation or its
native scheduling guarantees.

The source identity is `evidence/runtime-source-029.lock.json`, revision
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, overlay digest
`2800148f8a3405f443d801efb19fa65ade07d6f5c8164002e65c12fdac8ce5ef`.
The audited `lib/mem.c` digest is
`df461034c6c2296b2e9fd07575fb9e5944110b9925a6fd8d3f2b7e2af2d0af1c`.
Numbers here identify historical source inputs, not the feature or its files.
The source is reproduced from the fixed submodule and versioned overlay;
the paper cache is replaceable and is not a runtime source dependency.

## Mechanism Correspondence

| Mechanism | Source location | Model boundary |
| --- | --- | --- |
| Publish after queue data and tail updates | `mem.c:3435-3459` | Publication readiness and signal-mutex acquisition remain distinct actions. |
| Repeated steal attempts | `mem.c:6913-6953` | The inherited first-occurrence probe compression is still an unproved abstraction of the 1000-cycle loop. |
| Descending queue recheck under M | `mem.c:6958-6977` | The new variant checks the greatest remaining queue index first. |
| Return on the first pending queue | `mem.c:6971-6974` | The new variant releases M and returns active without decrementing the population; it does not finish checking unrelated queues. |
| Idle registration and zero-count broadcast | `mem.c:6979-6990` | Original count and broadcast actions are retained, not established by queue emptiness alone. |
| Condition return and count restoration | `mem.c:6997-7010` | Repeated returns are permitted; restoration still occurs only for a nonzero population. |

The previous `gc_recursive_queue_wait` model chose an arbitrary remaining
queue and accumulated `found` until all queues were visited. That is not the
same lock-holding trace as the source's descending, first-match return.
This difference is not by itself a native failure. Old safety/rank receipts
remain bound to their old transition relation and do not transfer automatically.

`models/gambit/gc_recursive_wait_recheck.qnt` keeps the original state and
20 action branches. Its full transition relation replaces just the recheck
branch and the once-per-worker spurious-wake branch. `sourceWaitInit` selects
the combined policy. `aggregateProgress` is an unchecked obligation, not an
assertion that aggregate fairness suffices. This relation must be checked
directly; a focused subrelation's positive result cannot establish it.

## Memory And Resource Assumptions

Boehm section 2.3 explains why a spin flag or an ordinary load does not by
itself provide language-level synchronization. The source header's default
ticket-lock branch polls a volatile ticket after a fetch-add; it has no explicit
post-poll barrier. The existing steal path adds `___SHARED_MEMORY_BARRIER()`
after Q acquisition, whereas the new recheck path does not.

Inspection of the actual arm64 object shows that distinction: the steal wait
at offsets `0x1fa0-0x1fa8` is followed by `dmb ish` at `0x1fac`; the recheck
wait at `0x2020-0x2028` is followed by ordinary queue loads at
`0x2030-0x2034`, with no intervening acquire load or barrier. This is an
instruction observation, not a demonstrated stale-read failure.

M handoff may already order a publication whose publisher completed its M
signal section. A newly publishing scanner blocked on M must remain counted
and signal after the waiter releases M. Therefore an extra fence is not admitted
merely from this comparison: the model must distinguish these histories and
justify the required visibility using both lock order and producer lifetime.
The coherent queue read in the current model remains an explicit abstraction.

`gambit.h.in:10911-10924` returns Boolean results for POSIX mutex and condition
operations; `mem.c:4903-4904` ignores initialization results. The new wait model
does not cover failed initialization, lock failure, condition failure or resource
retirement. Successful primitive operations and valid resource lifetime are
assumptions, not conclusions imported from the two GC papers.

## Checks And Unclosed Evidence

### Predicate Visibility Versus Payload Consumption

`gc_recheck_visibility.qnt` distinguishes two publication histories. After a
producer's protected signal and unlock, a later successful M acquisition
supplies the modeled publication handoff. A producer still blocked behind the
waiter's M remains counted. Even if the predicate misses queued work, the waiter
registers before releasing M, then the producer acquires M and notifies it.
A visible predicate returns without relinquishing active-scanner ownership.

Thus the missing recheck-side acquire instruction alone does not demonstrate a
lost notification or stale payload consumption. Recheck does not dereference
payload; stealing under Q has an explicit barrier before scanning the chunk.
This does not establish C race freedom or compiler validity of queue accesses.
The model assumes successful POSIX operations, producer lifetime, one
publication and an ordered read after M handoff. Multiple waiters, repeated
publication, payload copying, phases, failure and fairness remain unmodeled.

The existing generic runner executes the new declarative recipe:

```sh
.venv/bin/python -m gambit_smp.recipes \
  --run gc-recheck-publication-visibility --out .data/recheck-visibility-fresh
```

The local run passed parse, type/effect checking and all five named controls
(0.315, 0.336 and 0.400 seconds respectively). The initial declaration applied a
zero-argument pure value as a function and failed type checking before controls
ran. The corrected declaration was retried with `--prior` and unchanged budgets.
This is tooling failure followed by local control success, not a native
counterexample or exhaustive proof. Durable model, recipe and pinned source
overlay are reproduction inputs; disposable run logs are not Git-persistent
acceptance evidence. No GC requirement is discharged by these controls.

`tests/fixtures/gc_wait_recheck.qnt` contains deterministic local checks for
early unlock with unchanged count, continued ownership after an empty queue,
descending-order and busy-queue guard rejection, and another condition return
after a previous wake. These control states are not a reachability proof.
Guard rejection tests are not solver `ENABLED` proofs. The declaration is
typechecked; exhaustive safety and temporal verification remain open.

The declarative research recipe is
`evidence/research/recursive-wait-recheck/mechanism.recipe.json`. It declares
typed capabilities, exact inputs, dependencies and budgets, not commands or a
prescribed Agent action sequence. The Agent
can select and interpret this experiment using the evidence graph. There is no
new feature-specific Python runner. Three rejected test-construction attempts
and their snapshots are retained; none is called a protocol counterexample.

The installed `gambit-smp recipes` entry point discovers this recipe from Evidence.
It binds the compiler-reported import closure and exact structured test inventory.
Local run receipts are rechecked with `recipes --read`; uncommitted local output
is not Git-persistent acceptance evidence. See [Evidence Recipes](evidence-recipes.md).

Unclosed evidence includes complete assignment feasibility, generator coverage,
the repeated-probe abstraction, M/publication visibility, per-worker and lock
fairness, and failed-primitive/resource-lifetime behavior. All source-bound GC,
multi-VM, bootstrap and Gerbil acceptance still requires the same actual
candidate, configuration and artifacts. No measured optimization follows from
this mechanism study.

Primary sources: [GHC parallel copying GC](https://simonmar.github.io/bib/papers/parallel-gc.pdf),
[HotSpot parallel GC](https://www.usenix.org/legacy/event/jvm01/full_papers/flood/flood.pdf),
[Boehm on benign races](https://hboehm.info/boehm-hotpar11.pdf).
The local test construction uses Quint's documented
[run and assertion operators](https://quint.sh/docs/builtin).
