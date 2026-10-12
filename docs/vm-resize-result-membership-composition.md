# Resize Result and Membership Composition

## Protocol Closure

The previous result model uses a fixed retained population; the retirement model
does not carry the winning requester's reply through changed membership. The new
composition includes an extra surviving processor that can originate the request,
shrinks three processors to two, then grows back to three. The newly started
processor must consume the growth result before leaving startup or executing its
body. Join recovery precedes result publication and subsequent GC/reuse.

This matters in the actual source: `OP_VM_RESIZE` is noncombining, the winning
requester receives its local execution result, and `start_processor_execution`
enters the synchronization loop with `OP_NOOP`. Merely returning an error on P0
or adding a barrier for old processors does not close both obligations.

## Reproducible Source Projection

Authority is the pinned submodule plus
`evidence/fixtures/interrupt-prefix-owned-lifecycle/source.lock.json`, and the
canonical model sources, not a numbered cache.

The generic `gambit_smp.model_projection` framework uses Quint 0.33.0's resolved
IR, name-binding table and source map. It prefixes declarations and references
bound to those declarations, preserving record fields, literals, local parameters
and imported operator references. It does not textually replace every occurrence
of a name. Type names retain their required uppercase initial. Source-map offsets
are converted from UTF-16 units before editing Python strings.

The contract is `resize-result-membership-projection.json` in the Fixture. The
template is `models/gambit/components/vm_resize_result_membership_adapter.qnt.in`;
the output is `models/gambit/vm_resize_result_membership_composition.qnt`.
The generator, template, contract, canonical component and output are bound by
the model receipt. Regeneration is checked with:

```sh
.venv/bin/python -m gambit_smp.model_projection \
  evidence/fixtures/interrupt-prefix-owned-lifecycle/resize-result-membership-projection.json
```

This executes the existing retirement transitions, rather than introducing an
independent handwritten retirement implementation. The result module's state
was renamed from `s` to `reply` to avoid Quint effect-name collisions, and its
original four controls and complete positive check were rerun. The original
retirement source and receipt remain the active 138-state component evidence.

## Checked Results

The completed campaign took **19.511 seconds** with host-derived concurrency:
**2,128 distinct / 5,648 generated states, zero queued**, complete safety and
temporal progress. Three accepted exit-1 counterexamples show:

- A surviving nonzero requester receives local success instead of P0's status.
- The growth acknowledgement set remains the old two-processor membership.
- Result publication occurs after a failed join without retirement completion.

The portable receipt is
`evidence/model-results/fixtures/interrupt-prefix-owned-lifecycle/resize-result-membership-design-contract/receipt.json`.
The registry and Reflection reference this exact receipt.

Progress still assumes at most one join failure followed by successful recovery
and weak fairness. Returning the recovered first error is a proposed reporting
policy, not a behavior implemented by the current C source. The extra peer's
acknowledgement is modeled; its complete native GC/root/barrier behavior is not.

## Denied Construction Paths

Nested aliases, hidden state, same-name effects, empty instantiation syntax,
initializer conversion, nested-state initialization, exports and nested flattening
failed in the current Quint/TLC construction path. Their receipts, logs and source
snapshots are archived separately; none counts as an algorithm counterexample.
The source-projection path replaces those unsupported routes. A projection type
name error was also archived and corrected without changing transitions.

An intermediate accepted projection check preceded generator/template context
sealing. The archive-attempt interface correctly refused to reclassify an accepted
check as a failed attempt. The final campaign was rerun with the entire projection
chain bound, and only that final receipt is registered.

## Native Gate

No C runtime change is admitted by this result. The next repair must implement
result commit and startup participation over the actual synchronization operation
loop, and explicitly resolve permanent join failure and VM-wide admission/drain.
Then bind actual multi-processor tests, complete bootstrap and Gerbil acceptance
to one candidate. Finite model closure does not close those native requirements.

## Source Design Constraints for the Next Fixture

Keep `OP_VM_RESIZE` noncombining: its input contains the Scheme thunk, so changing
it to an arithmetic combining operation is not an error-distribution repair.
A separate status-commit operation could transport P0's result through the
existing `sop.arg[0]` publication channel, with neutral peer contributions.
Its priority, winning-operation arbitration and repeated-round identity still
require source refinement; this is a candidate design, not an implemented patch.

The startup processor currently offers `OP_NOOP`. It must observe and execute
the status commit before the later all-member acknowledgement permits that NOOP
to terminate its startup loop. A private barrier inserted only into the old
processors' call stack would not establish that participation. Reusing the
existing message payload channel also avoids silently assuming visibility of a
new unsynchronized VM-wide result field.

Result transport cannot authorize an unjoined slot. Before publishing a recovered
status, implement a source-grounded recovery/drain contract; specify permanent
failure separately. Do not reuse or destroy the retired slot, restore population
unilaterally, or report normal completion merely because the error was delivered.
