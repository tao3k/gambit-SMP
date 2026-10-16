# Primitive Port Reporter Diagnostic

## Retained Failure

The global-cleanup successor complete interpreted grid remains **378/379**.
Its original `13-modules/prim_port.scm` failure reached the comparison
reporter and raised an unbound-variable error for `##failed-check`. The
upstream parent helper defines `##failed-test`, which prints the mismatch
and sets `##failed-test?` to true. The absent reporter hides the actual
behavior difference; it does not prove that the behavior is correct.

## Reproduction

Use the existing sealed research framework and GNU GCC with recipe
`smp-global-cleanup-prim-port-reporter-diagnostic`, defined in
`evidence/research/vm-registry-reader-lease/prim-port-reporter.recipe.json`.
It selects the immutable global-cleanup completed producer and its source
lock. It does not download or select a global installed runtime.

`models/gambit/native/prim_port_reporter.scm` is a new additional fixture,
not an upstream helper replacement. It includes the original helper,
defines the absent reporting function to call `##failed-test`, then includes
the unchanged original `prim_port.scm`. The framework checks original test
bytes after execution. The canonical failure inventory remains supplied;
the selected new fixture is not the original failed-file inventory and
cannot qualify that inventory by proxy.

Budgets remain 300 seconds for the recipe, 120 seconds for the suite step
and 20 seconds for the selected file. Concurrency is derived by the existing
framework from available capacity, not hardcoded to this machine.

## Observed Result

The diagnostic passed with exit zero and the exact `PASSED ALL 1 UNIT TESTS`
marker. No mismatch report appeared. It used 11 VM processors and one suite
worker on the observed 12-CPU host. The selected file ran in
**0.1353194999974221 seconds**; the enclosing sealed run took
**31.904840333998436 seconds** (whole observation 32.40617850000126 seconds).
Those measurements are not whole-suite or package performance results.

| Binding | SHA-256 |
| --- | --- |
| Fixture | `ce4f199604965c31d66f45cbf5a3b67f2096f3b8db07c818445da23d900eaba6` |
| Recipe | `161f15eeb7f7274197de926c52a7a11d598b65655dda8b943959a70036c30f54` |
| Sealed engine | `e2a93d5bb2ec260fa611c7e55289be9e7a124ffdeb077c5f88f37010f218c8e8` |
| Local outer receipt | `421e0fe993b80942ca7ae97c9be204802160a6f2840bb00a99e83880b98d951d` |
| Local suite step receipt | `c40701fd61936157818b7c38589883689ab568bad270cdbf7a5961bbfaa77bc6` |
| Local native stdout | `87c630701f620133686ed80feaf36e01d3b65a5dd18a327f6d8f2777bebef98c` |

The last three hashes identify local observations, not durable archived raw
receipts. Reproduction means rerunning the source-bound recipe; timing and
result are observations, not promised constants.

## Admission Boundary

This changed entry point did not reproduce the earlier behavior difference.
It is not an A/B result, a runtime fix, or a replacement for 379-file
acceptance. The original failure remains authoritative for that run. Do not
rerun the same diagnostic unchanged merely to collect another passing
schedule. Further investigation must bind a relevant context difference or
repair the reporter in an explicitly selected successor source fixture,
then retain real mismatch failures and qualify the complete original scope.

Two focused Python tests check the reporter delegation, exact fixture hash,
current-producer selection, canonical failure inventory and unchanged
budgets. They do not establish native correctness or SMP completion.
