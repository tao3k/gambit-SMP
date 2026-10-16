# Historical Source Correspondence Input Repair

## Actual Defect And Repair

The source-unit receipt already records all reconstruction inputs, including
framework.py at SHA-256
`06a95515f6aca3cabd584cd6dedcc3378bacfe4c1f6870a26513aafc9e765d02`.
The selected historical archive omitted that input after the current framework
changed. The correspondence guard correctly rejected the incomplete binding.

The exact original framework.py is already versioned under
`evidence/source-results/fixtures/sfun-owned-unwind/historical-seed-inputs/`.
Its bytes also match the retained producer engine. No new producer run or
invented receipt field is needed to recover that historical input.

`sync-retirement-source-history/complete-input-archive.json` adds the missing
binding and reuses the other three original archived implementations. The
correspondence now selects this complete archive. The preceding archive,
original receipt and all original input SHA values remain unchanged.

Verification of all 123 recorded inputs finds no missing or drifted bytes.
The original source-unit receipt SHA remains
`a36b50b1fb050e643f77463236db0da720c49fa9445c0ae5e2269c3927c0a560`.

This is historical correspondence for the explicitly selected source lock,
not evidence that the newest SFUN source successor has been rebuilt or passed.
Current reconstruction code and historical producer code retain separate
bindings. Neither the source lock nor overlay may be replaced by history.

## Numeric Evidence Contract

The numeric test previously compared a historical adapter SHA against both its
archived source and the current compiler_cost.py. The second comparison wrongly
made a valid historical observation depend on future implementation edits.
It now checks the original adapter against its immutable archive manifest.

A separate test exercises the current witness predicate: one successful witness
is accepted; missing/duplicate witnesses, nonzero exit and timeout are rejected.
It does not rerun or readmit the historical native campaign. All five numeric
evidence tests pass (0.007 seconds).

## Real Inference Observations And Retained Failures

- Initial validation-domain invocation passed string IDs instead of unittest
  objects and failed before launch. The invocation was corrected, not the API.
- The closed model research engine cannot import the legacy correspondence
  consumer module. The 15-test validation selection was rejected before test
  execution (1.518 seconds); that run remains a failure, not 15 test verdicts.
- A direct consumer check using the older isolated ASCENT provider timed out
  at 58.009 seconds. Its narrowed source-only diagnostic also timed out at
  15.026 seconds. No runtime or algorithmic cause is inferred from those caps.
- An attempted editable-source sealed boundary was rejected by execution_origin
  (0.755 seconds). That guard remains unchanged.
- Against the current receipt-bound ASCENT candidate, the original real locked
  correspondence regression passes in 2.393 seconds, exit zero, no timeout,
  parent reaped and process group quiescent.
- The subsequent 20-test focused run outputs success for all 11 correspondence
  tests, then reaches its 15-second ceiling while running the full default vs
  managed audit comparison. Whole run: timeout, exit -9, 15.018539 seconds,
  parent reaped and process group quiescent. The remaining tests have no verdict
  from that run. It is not a focused-suite PASS.

The current provider identity for those observations is:

- library SHA-256: `e7d1636dd195461b4218b6c8e17f45f379157936603a232379db069cbe4ee2dc`
- build receipt SHA-256: `4fc9e9a42490b2a9f2bd3151ec825cf52dc0e9a3dcff947886d8eb1891ae54de`

Execution uses the existing framework executor and official receipt-bound API.
This document is a bounded observation record, not a new sealed whole-graph
qualification or a reproducible package location. No temporary provider path
becomes a repository dependency. No claim of a binding mismatch is made: the
inspected installed/sealed __init__ and operators files were byte-identical.

## Open Milestone

Cumulative SMP progress remains 3/12. Complete/PR GSC, GSI/GSC stress, registry
lifetime, lifecycle faults, GC/FFI, Gerbil correctness and release performance
remain open. The newest source still needs source-bound bootstrap and native
qualification. Original qualification consumption remains 468.695876834 / 600
seconds; no new bootstrap budget or full rebuild was started.
