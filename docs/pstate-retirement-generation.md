# Processor slot retirement generations

## Decision Before Runtime Changes

This is a correctness prerequisite, not a performance candidate. Expected speedup
is unknown; no build/test timing improvement is claimed. Existing retirement
models cover one successful shrink, not reuse after shrink/grow or join failure.
The new model extends that boundary rather than repeating a denied native route.

## Paper To Source To Model

GHC parallel GC section 3.5 and HotSpot parallel GC section 3 distinguish empty
work queues from completed work. They motivate retaining resources until admitted
users have completed. Neither paper proves Gambit's resize protocol or prescribes
the generation fields below. Generation/round identity is a proposed refinement,
not a claim about either paper's implementation.

In the frozen candidate027 source:

- `include/gambit.h.in:11960` embeds fixed `aligned_pstate` slots in a VM.
- `lib/setup.c:958` initializes additional slots during growth.
- `lib/setup.c:930-940` lets a retired worker clean up and exit.
- `lib/setup.c:984-988` joins retired workers and ignores the result.
- `lib/setup.c:4679` initializes sync mutex/condition resources.
- `lib/setup.c:4706` normal cleanup does not destroy those resources.

The source-inspired missing-destroy control therefore permits a subsequent grow
to initialize an already-live pair. Other controls are proposed bad repairs, not
assertions that existing source already contains generation records.

## Finite Contracts

Four independent controls must fail: initialization without prior release,
old-generation cleanup against a reused slot, previous-round closure reused for
the current shrink, and failed join treated as successful retirement.

The positive contract separates thread exit, join completion and old sender
completion. Reclamation needs a successful join, exact current-round closure and
matching pending/resource generation. It consumes the record before reuse.
Failed join reaches an explicit quarantined terminal state retaining ownership;
this is model error termination, not a successful runtime resize or native pass.

The finite witness is one slot and two retirements. Successful constructor setup
and single-round tree closure are delegated contracts recorded in Datalog. There
is no claim of arbitrary generations, arbitrary processor counts or actual C
memory ordering. No new runtime fields or cleanup hooks have been implemented.

## Remaining Source Gates

Before a runtime patch: refine actual pending-generation storage and round
identity; prove failed-grow rollback; specify quarantine/VM teardown ownership;
audit every caller's error distribution. `execute_sync_op_loop` returns the
winning requester's local result, so a P0-only error return is insufficient without
a distribution proof. Also audit `os_thread.c:___thread_join` mapping pthread's
returned error through errno; this is separate from ownership and remains open.

Only after these gates should source-unit checks, admitted native regressions,
complete bootstrap and Gerbil build/test be attempted. Model green does not
authorize retrying unchanged known failures or admit a runtime patch.

## Verified Receipt

Campaign `pstate-retirement-generation-001` found all four expected negative
counterexamples. Positive safety and temporal progress completed in 17.076 seconds:
59 distinct states, 94 generated, zero queued. Model/source/paper context remained
stable; workers were detected from the host. Portable hash-bound logs and traces
are in `evidence/model-results/pstate-retirement-generation/`. Native execution
was not run; runtime and release admission remain false.
