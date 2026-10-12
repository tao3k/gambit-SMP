# Resize Result Distribution

## Pre-Code Review

This is a correctness repair prerequisite, not a speed candidate. Expected
performance benefit is unknown. Existing retirement models did not prove that
the winning non-root requester receives P0's failure. This model covers that
missing dimension; it does not repeat any denied native route.

## Source Facts

Frozen candidate027 `lib/setup.c` supplies the following facts:

- `OP_VM_RESIZE` at line 493 is non-combining.
- `___vm_resize_pstate` initializes local `err` to success at line 889.
- Only P0 performs new processor setup. On setup failure, P0 rolls back ready
  slots and returns the error at lines 958-967 after a barrier.
- Other processors wait at the barrier and, if retained, return their own local
  `err`; it is not assigned P0's setup error.
- `execute_sync_op` assigns each local call's result to its own `sop.arg[0]`.
- `execute_sync_op_loop` returns that local result to the winning processor
  (`winner_id == id`) at lines 1111-1119.
- `___current_vm_resize` has no P0-only admission guard and returns `sop.arg[0]`.

Thus merely returning a newly checked join error from P0 would not establish
requester-visible failure. Existing join errors are ignored, not already fixed.
This is source reachability, not a reproduced native failure or an explanation
of the historical compiler crash.

## Model And Paper Boundary

GHC GC section 3.5 and HotSpot GC section 3 require completion of admitted work
before terminal state/reuse. Here that principle motivates a result slot that
cannot be reused until consumers have acknowledged it. The papers do not define
Gambit resize results, epochs or any concrete implementation to copy.

The model has two winning requests and a fixed retained population of 2..4. Every
requester pair is checked with success and two distinguishable abstract error
values. Local execution, authoritative publication, result consumption and next
request admission are separate events. Four independent controls must fail:

- Non-root local success hides P0's error (source-inspired).
- A proposed shared-result read occurs before authoritative publication.
- The previous epoch's ready result is mistaken for the new result.
- A proposed shared result slot is reused before all replies complete.

The positive requires current-epoch publication and acknowledgments before reuse.
All result copies must be current; the winning requester's value must match P0.
It is an unimplemented abstract contract, not proof of C release/acquire or a
complete source barrier refinement. Weak fairness assumes admitted execution
eventually completes; it does not excuse a blocked native processor.

## Source Repair Gates

Do not add a bare VM-global error field. First determine where the source can
publish/receive without inserting a mismatched barrier and how next-round
convergence prevents overwrite. Audit interrupted and concurrent requests,
processor-count changes and a winning requester removed by shrink. P0's status
must also correctly represent ownership failures; these are separate retirement
and constructor contracts. Error encoding, quarantine teardown and epoch
wraparound remain open. No runtime code is changed by this model.

`start_processor_execution:814-842` enters `execute_sync_op_loop` with `OP_NOOP`
and `first_iter == 0` before running its Scheme thunk. Growth publishes the new
processor count before creating those threads (`setup.c:974-1008`). An added
result barrier must therefore account for new members' first operation round;
it cannot assume that only old retained members will participate. Creation
failure currently terminates through `___fatal_error`, not a recoverable local
return. This model does not change that source failure policy.

`pstate_retirement_generation` still records `resize_result_distribution` as a
source obligation. This bounded model does not automatically discharge it or
rewrite its prior hash-bound receipt. Native regression, full bootstrap and
Gerbil correctness/performance acceptance remain required after source repair.

## Verified Receipt

Campaign `resize-result-distribution-001` produced all four expected negative
counterexamples. Positive safety and temporal progress exhausted 25,092 distinct
states (60,057 generated, zero queued) in 25.564 seconds. Model/source/paper inputs
remained stable; workers were detected from the host. Portable hash-bound evidence
is in `evidence/model-results/resize-result-distribution/`. Native execution was
not run; runtime and release admission remain false.

After registering the receipt, `uv run --locked python -m unittest discover -s tests`
passed 234 framework tests in 54.373 seconds. This includes mocked native-runner
admission/denial tests; it is not an actual Gambit native suite or bootstrap run.
