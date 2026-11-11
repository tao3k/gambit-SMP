# Arena Source Relations And Research Regression

## Result And Identity

Focused research regression: **12/12 tests passed in 29.372 seconds**, exit 0.
It used the existing direct unittest entry, real Scheme relation evaluation and
guarded Lean processes. It was not a managed native execution or an award of a
native checkpoint stage. The new formal composition separately passed 6/6
checks as recorded in `arena-validation.md`.

| Input | SHA-256 |
| --- | --- |
| `arena-facts.json` | `654aca918218f2940a468896acea69ef55f8e2dbdf9f0a7f7cd860d70cd848ca` |
| `arena-validation.md` | `aa76897860cc5384210f710e2996b628dfdd66d30b395d1c7c4bcee7aefe1fd9` |
| `arena.manifest.json` | `f86f261edbeda4f33e169bce20769f77adc9831cecae9972561eb3290186eee5` |
| `docs/saved-stack-arena-recipe.md` | `2f4eb6f8e6d5d488ccd3f0cbf02acfbb152c07f4a89dd512c06ac876dc9c4fea` |
| `models/gambit/saved_stack_arena_ownership.qnt` | `f460922d3e41fd850c39bcbc9f4ee994b69851edb866ca98500e5588c3b8fb74` |
| `models/gambit/lean/SavedStackArenaLifetime.lean` | `49f242f2471dbb698d08b41123a1bf3e0429aad6146b521d0b866bb57a397926` |
| `tests/test_saved_stack_arena_evidence.py` | `9eb1c544ea07c2bebde2bb4431e189193ff04102bf12beafb893c23460a1a497` |

The imported isolated stack model remained
`38dbe1b570efda86a261922781c3ee4de0ba9da379fbbd8d0697a177290c989c`.
The parent candidate facts/Recipe, earlier models, runtime patch, source lock,
native qualification and historical receipts were not rewritten.

## Preserved Launcher Noncompletion

The first workspace-supervised regression did not enter the test process. Its
startup was interrupted with exit 130 while `execution_scope -> collect ->
task_retention.collect -> referenced` was scanning retention references. The
research task record still named the preceding completed formal run; no new
test-stage receipt had been issued. The launcher was stopped, and a subsequent
process observation found no remaining process matching this research test
command. The separate native task was not stopped or resumed.

This is a retained framework-startup noncompletion, not a test pass, deadlock
classification or SMP runtime failure. No shared retention code, task state,
budget or watchdog was changed. The direct command below is an existing
research-test entry; it retains the same guarded proof checks but does not claim
the managed execution custody of the command that never started:

```sh
.venv/bin/python -m unittest tests.test_saved_stack_arena_evidence \
  tests.test_host_root_candidate_evidence tests.test_host_root_publication_evidence \
  tests.test_repair_redesign_evidence -v
```

## Source Graph And Scheme Outputs

The existing Scheme constructor consumes 23 source identities, producing two
scoped, source-lock-identified clues with factors and expandable references:

- `executor-slot-and-frame-backing` separates pstate retirement, VM arena and
  old-half incarnation. It records the observed no-arena-free cleanup and the
  old eager-copy guard's narrower scope.
- `moved-root-and-last-raw-consumer` records the thread-slot to break-link move,
  break/collector read sites, and the required complete alias/borrower census.

Both remain `source-composition-unbound` after the formal checks. Removing
the checks yields `model-check-unbound-or-stale`. Withdrawing each source
identity exposes an unbound premise without removing the two owed obligations
or composition requirements. Restoring inputs restores the original result.
All source hashes were checked before and after evaluation. `satisfies` and
`composition_binding` remain empty and every model scope is `partial`.

No new relation schema, CLI, production Python logic or Agent instruction was
added. The prior three candidate composition gaps remain in their unchanged
parent evidence. The new facts refine their interpretation; they do not convert
an old failure trace into a universal prohibition on a different, retained-
backing path. No Grok field trial is claimed by this relation regression.

The scanned-object link is also concrete, conditional on valid object headers,
field bounds and generated layout. Candidate `gambit.h.in:6485-6495` places
`THREAD_CONT` at structure field 23; :6520-6527 places `CURRENT_THREAD` at
processor field 14. The structure payload traversal in `mem.c:4595-4604`
includes those fields, followed by the continuation-specific frame scanner
(:4519-4523). Restore moves the raw frame to the break link, which the active
continuation scanner follows (:4322-4390). This supplies an actual consumer
path, not proof that all relevant thread/queue objects remain reachable after
processor deque removal or that their headers/maps cannot be corrupted.

## Remaining Source Refinement

1. Establish actual surviving roots and all aliases for every supported saved
   activation, including queues, sleeping threads and escaping continuations.
   A valid absence witness is allowed; missing enumeration is not absence.
2. Establish old-half non-overwrite and valid frame interpretation across
   overflow undo, allocator/custom-hook behavior, slot reuse, GC copying,
   forwarding publication and phase changes. Arena allocation alone does not
   prevent same-address corruption/reuse.
3. Close each real last consumer: break-link advancement is per frame; a
   collector scan and remote sync sender have different tails; native C
   catchers do not become valid because Scheme frame storage survives.

The current source suggests a lower-cost retained-arena route that preserves
Gambit's existing C/continuation design. It is not a measured speedup, a claim
of no memory-pressure tradeoff, or a completed repair for every supported path.
Mechanism-level independent carriers, changed attachment or root ABI remain
Experimental; none is selected here. No runtime changes or original native
tests were made, and this research does not change the owner's 9/12 count.
