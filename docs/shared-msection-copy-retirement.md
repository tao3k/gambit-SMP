# Shared Msection Copy And Retirement

## Source Audit

Source identity is the pinned Gambit submodule plus
`evidence/fixtures/darwin-shared-successor-snapshot/source.lock.json` and its
versioned patch, not the cached source directory.

| Operation | Source mechanism | Remaining premise |
| --- | --- | --- |
| Stack section setup | `set_stack_msection` sets lower bound to `base + tospace_offset` and upper bound one half-section later. | Selected section and allocation generation are live. |
| Overflow transfer | `___stack_limit` reserves the first break frame, then copies `fp - prev_alloc_stack_ptr` words below it. | Decoded frame sizes and traversal stay in the old stack; transfer fits the new half-section. |
| GC stack relocation | `move_continuation` copies the contiguous range through the first break frame below the new stack pointer. | Old `fp`/break belong to the same valid range; the complete length fits the destination. |
| Frame forwarding | `mark_captured_continuation` stores forwarding state into decoded frame slots while holding `MISC_MEM_LOCK`. | Valid frame identity, descriptor/link coordinate and old-section generation; the lock alone does not establish them. |
| Retirement | `resize_heap` calls `adjust_msections` after phase barriers; contraction frees allocation-order tail sections. | Every surviving stack, heap, pool and captured-frame borrower is retained; address-order membership alone is insufficient. |

Ordinary stack writes in these operations should remain in `base[]`, not the
preceding index/position/prev/next header. That conclusion is conditional on the
range and lifetime premises, not a proof of the observed execution. The current
record has a damaged header but does not bind its first writer or last borrower.

The configured maximum-heap branch applies an upper cap after the assigned
section lower bound. It needs a separate retention audit; no evidence yet ties
that branch to the captured TFIB execution. It is not selected as a speculative
repair for this failure.

## Model Contract

`shared_msection_copy_retirement.qnt` checks copy bounds together with two
logical borrowers and phase retirement. Its abstract word coordinates are not
ABI sizes or hardcoded host concurrency. The positive control retains live
storage until both copies complete; the negative controls admit an escaped
frame range or retirement while a borrower still exists.

The unsafe controls are explicit missing-premise envelopes, not native
observations or source-reachable counterexamples. The earlier header-damage
model remains unchanged and source-bound. Passing this contract cannot retire
TFIB/interrupt2 failures, qualify a repair, or advance the 5/12 milestone.

## Decision Before Source Changes

The sealed framework run passes in 20.867 child / 22.402 whole outer seconds:
60 legal distinct states, zero queued; both negative controls produce expected
counterexamples. The loopback-prerequisite denial and initial Quint set-type
failure remain retained as failures. They are tooling failures, not native
runtime failures, and have not been rewritten as PASS.

- Relevant: these are the actual stack copy/forwarding and section-retirement
  paths preceding the observed shared-header use.
- Prior work: rejected pool-layout and saved-undo changes are not inherited;
  their failures remain History. No unchanged native retry is required here.
- Worth: identify the violated range/generation premise before selecting a
  runtime repair. A generic lock or another header layout does not satisfy it.
- Expected benefit: correctness and a narrower causal search, not a measured
  speedup. No runtime source change is justified by this finite model alone.
