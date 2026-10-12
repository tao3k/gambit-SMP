# Recheck Visibility And Finite Completion

## Route Review

The existing `gc_recheck_visibility` model has five deterministic checks, not
exhaustive safety or progress evidence. Reuse its actual publication, predicate,
registration, M handoff and count restoration actions rather than clone them.
This is a new coverage obligation, not a retry of any failed native campaign.
Expected benefit is correctness discrimination; runtime speedup is unknown.

The current `sfun-owned-unwind` source lock already contains publisher Q unlock
before M signal, and descending queue recheck under M before count decrement.
It is incorrect to describe that source candidate as lacking this repair.
Historical source obligations retain their historical source identity.

## Executable Scope

`gc_recheck_visibility_completion.qnt` imports the original model unchanged.
The positive initializer covers both a new publication and a completed producer
M handoff. Predicate observation can miss a new publication before handoff;
the inherited action requires visibility after handoff. Completion requires
the waiter active and producer finished with notification. Aggregate weak
fairness is sufficient only for this finite, acyclic critical-section campaign;
it does not fix unbounded recursive-GC copier starvation.

Two independent controls expose assumptions previously only documented:

- Releasing M before wait registration permits notification before the waiter
  registers, leaving queued work and a sleeping waiter after the producer exits.
- Removing the producer from the count before its protected notification permits
  the waiter to declare zero-count termination while that work remains queued.

The model assumes successful primitives, stable population, one producer, one
waiter, one publication, valid resources and coherent ordered reads after M
handoff. Semantic roles are not a host CPU cap. It does not prove C race freedom,
payload scanning, multiple waiters, recursive discovery, phase closure, failure
rollback or full collector/VM lifetime composition. No runtime, performance or
release admission follows; native correctness and retained time gates remain open.
