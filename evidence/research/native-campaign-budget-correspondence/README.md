# Whole Campaign Budget Correspondence

## Contract

Changing sequential/parallel scheduling can preserve a whole wall-clock budget
only when the bound original and current file selections are exactly equal and
unique, their modes match, causal review is complete, and every original budget
remains enforced. Atomic batch caps cannot become whole-campaign caps. No timing
improvement, native correctness or permission repair follows from correspondence.
Nested file limits are still enforced by the existing suite executor and its
scoped failure reviews; the model assumes that enforcement, rather than proving
the native timer implementation.

`models/gambit/native_campaign_budget_correspondence.qnt` models missing/extra
files, wrong mode, atomic-to-whole conversion, budget expansion, missing file
caps, missing review and spent-budget overflow. The bound controls recipe passed
under its original 90-second budget: 21.816 seconds child, 22.678 seconds whole,
exit zero, parent reaped and process group quiescent. TLC exhausted 772 distinct
states, 4,105 generated, zero queued; the bypass invariant failed as required.
These are finite conditional checks, not an unbounded SMP or GC proof.

## Linked Native Review

The complete SMP grid now requires positive and negative correspondence checks
before either native review. Python transports exact selection facts; native
Scheme DSL alone derives regime matching and conditional eligibility. Inventory
omission/duplication, atomic conversion, expanded budget or missing causal
premises remain rejected by transport/native controls.

The actual linked run on engine
`ff6dec93ad9b40fa6a1f704bb938e16124c21622d9e89ad864a74b657b33700f`
took 44.974 seconds including preparation under the original 300-second budget.
It rechecked the same completed bootstrap artifact, selected 375 files in each
mode, passed both correspondence controls and retained CURRENT / DENY.
The outer receipt SHA-256 is
`7d8cd5b1351f1dd02e4a1e209744a7c4ac58e2fca40973c7fdd53429dbb2c65b`.

Native ASCENT conditionally admitted four changed investigations:
`018-thread-interrupt`, `018-write-shared`, `018-table-search` and
`018-suite-budget`. Each binds its original denial, original candidate identity,
actual source/fixture byte difference, historical field roles and limited causal
reasoning. Prior local passes are supporting references, not current acceptance.
Interpreted missing premises decreased from 23 to seven. UDP permission and
prim-port reviews remain open; all ten compiled routes remain open. Neither full
native suite ran. This 44.974-second measurement is preflight, not build/test time.

The initial transport test correctly rejected Evidence changes within a reused
execution context. Independent cases corrected the fixture without clearing
bindings. The latest focused run discovered 101 tests: 67 executed successfully,
34 sealed-only tests skipped. Those skips do not qualify the complete sealed
framework domain or the SMP milestone. Full linked-runtime GC, independent
threaded VMs, Gerbil correctness and release performance remain required.
