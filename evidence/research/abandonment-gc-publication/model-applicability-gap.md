# Changed mechanism, unchanged model

## Observed reasoning gap

The agent started changing a cached C observer projection before establishing
that the proposed protocol was covered by the existing model. That draft was
not installed, built or executed. The current runtime retains the previously
recorded processor-only observer, not the unqualified inline draft.

This was not merely a missing instruction. The existing registered evidence
exposed finite model passes, instrumented native completions, and an unknown
owner. It did not expose the proposed mechanism's changed assumptions as
queryable relationships. `make-modeling-guidance` checked changed model bytes,
but unchanged model bytes could accompany a completely different proposal.
The agent therefore saw locally valid historical results without an explicit
applicability gap for the new proposal. That is a registration/inference gap,
not evidence that the runtime repair is ready.

The current native candidate remains source lock
`651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67` plus its
separately bound diagnostic overlay. Cumulative milestones remain 6/12.

## Actual abstraction boundary

The checked `ticket_observer_snapshot.qnt` models two writers, one reader,
unique writer tags, a source epoch, and a barrier's active lifetime. It does
not represent actual ticket ownership, a native stack-range association,
barrier operation election, compiler call-shape changes or timing cost.
`processor_interrupt_ticket.qnt` separately represents a conditional lock/
collective cycle. It does not establish those missing observer relationships.
Passing both separately is not a proof of their composition.

For the currently proposed inline observer, the unresolved correspondences are:

| Dimension | Checked abstraction | Proposed mechanism |
| --- | --- | --- |
| Slot version | Unique writer tags | Per-slot monotonic version |
| Owner identity | Coherent record only | Current ticket and live thread-stack overlap |
| Barrier operation | Entry/exit activity | Entry proposal, election stage, and selected operation |
| Observation effect | Not represented | No acquisition callback, OS call, allocation or global write counter |
| Record expiry | Epoch identity | Ticket advancement, generation, lifecycle and snapshot interval |

These rows are requirements to investigate, not an assertion that this observer
design is correct or the only useful design. Hash collisions, missing records,
unknown ownership, incomplete election and expired records must not become
positive claims. A model may establish metadata noninterference under declared
assumptions; it cannot establish that native timing or GCC register allocation
preserves a previously observed fault. That requires separate native evidence.

## Existing DSL contract

The existing modeling-guidance component now accepts source-bound proposals,
changed dimensions, model assumptions, and scope-review observations. A scope
review is current only when it matches model bytes, proposal bytes, assumption
bytes, their provenance, and the existing checked model revision.

Missing model declarations, missing dimensions and withdrawn reviews remain
applicability gaps. No aggregate "complete" result is inferred from an empty
gap list. A matching scope review is a recorded correspondence review, not a
proof, permission to edit, retry eligibility, or native qualification.

The same component projects each missing correspondence to the existing Clue
relations. Each requirement has its own witness identity, preventing factors
from separate gaps from being combined into an invented correspondence.
The shared registry, selector, Session, checkpoint and incremental slice remain
unchanged. Python does not compare assumptions or choose investigation steps.

Queries return changes, unsupported premises and their sources. They do not
emit a deterministic next step, prohibit alternatives, or make source edits
impossible. The model remains free to propose a different observer, another
discriminating experiment, or a source-level explanation; evidence support for
any resulting claim must be assessed against that claim's actual premises.

The new relation contract is exercised with real ASCENT evaluation, including
unchanged-model/new-mechanism, missing model/dimension, source withdrawal, and
independent model/proposal/assumption revisions. Formal composition and native
fault-preservation are still open, so no new native run or C change is admitted
on the strength of those relation tests.

## Executed framework checks

ASCENT's `packages/proofs/quint/ModelApplicability.qnt`, SHA-256
`a2cee154180657fd82c55ff0840475702461e0b00e428243a64173210244a7ba`,
is registered in its existing formal runner. The command is:

```sh
PYTHONPATH=workbench/src:python/src python3 -m ascent_workbench.formal quint ModelApplicability
```

The positive check and seven expected counterexamples passed: model-PASS
shortcut, stale proposal, stale model, stale assumptions, missing dimension,
forced next choice, and withdrawn provenance. This finite framework model
does not prove the native observer's soundness or the Agent's behavior.

The actual ASCENT-backed modeling, reasoning-method, Working and progressive
Clue regressions passed 62/62 in 141.453 seconds. A real proposal-anchored query
returned four independently traceable gaps in the first default-size window;
the fifth was deferred, retrieved through the same checkpoint, and not repeated
after acknowledgement. Execution authorization remained false and exploration
remained open. No larger display capacity, Python inference, or new CLI was used.

An initial projection used an unsupported Clue role and was rejected by the
Library. It was corrected to the existing attested observation contract, not
by weakening validation or adding another role. Each requirement is now its
own claim, so a large family cannot hide every premise behind one collapsed
record. Runtime code and the frozen C draft were not changed during this work.

These results close this local missing-applicability/slice regression, not the
whole architecture. An unregistered Agent intention cannot be inferred from
hidden reasoning. Proposed mechanisms and their factors must enter the existing
DSL exchange; the framework can then expose unsupported correspondence without
requiring a human to prescribe the investigation order. A real Grok correction
and complete SMP protocol composition remain separate acceptance work.
