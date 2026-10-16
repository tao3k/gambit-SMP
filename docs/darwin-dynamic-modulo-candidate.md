# Darwin Dynamic Modulo Candidate

## Evidence And Decision

The preceding complete default GSC campaign accepted 378/379 files. Its only
unfinished file was `_num.scm` at its unchanged 90-second inactivity window.
An independent default phase control completed Scheme-to-C in 4.742 seconds,
then independently timed out GNU C compilation after 90.008 seconds. This is
not a proven deadlock. Changed-option diagnostics compiled identical C in
76.623 seconds (three scheduling options disabled) and 80.512 seconds (only
modulo scheduling and loop rescheduling disabled), with original assertions
passing. These censored/sequential observations do not establish a stable
speedup ratio. See `compiled-scheduling-path-review.md`.

The candidate therefore disables only the latter two options, only in final
`FLAGS_DYN`, on Darwin with genuine GNU GCC and supported/enabled GCC options.
It does not change RTS/static/executable flags, instruction scheduling, ABI,
O1/RTS O3, SMP, multiple VMs or multiple threaded VMs. It is an unqualified
fixture patch, not an adopted release optimization.

## Model And Source Binding

QNT: `models/gambit/darwin_dynamic_modulo_scope.qnt`.
The finite matrix has 108 initial configurations and 216 distinct states,
with zero remaining queue. Four positive safety/progress checks and three
decoded counterexamples pass. Model evidence is published and registered in
the existing Datalog bundle registry; direct readback accepts seven checks.
The earlier syntax/type-conversion failures remain in the original run chain.

Portable model receipt SHA-256:
`d31732e041d455c68a860acc125e75171ef3c11bd50c998f678c4c3906b5d8b9`.
Source lock: `evidence/fixtures/darwin-dynamic-modulo-scope/source.lock.json`,
SHA-256 `316c87a64b5fd16f588141e2601fcce16f38ec88a4e7b7831baffe9467093c52`.
Patch: `patches/fixtures/darwin-dynamic-modulo-scope.patch`, SHA-256
`4ff967b00882132e861717852e5c87426b48e74dee99e1096f68d132a1b31b51`.
Focused tests reapply both 23-file snapshots from the pinned submodule,
verify all hashes and the one-insertion delta, and execute the actual shell
guard in 36 combinations. No retained second source tree was created.

## Current Qualification

The existing source workspace was changed under its exclusive framework lease;
old receipts were not rewritten. The exact new candidate passed complete
two-pass bootstrap: four phases each executed twice, bootstrap 127.135 seconds,
whole attempt 204.522 seconds. The observed host selected 12 make jobs from
available capacity, with the existing shared compiler-processor budget.
The actual generated driver retains original object flags and appends the
two negative modulo options only to its dynamic flags.

Completed producer: `evidence/research/current-source-full-bootstrap/dynamic-modulo-completed-producer.json`.
Outer bootstrap receipt SHA-256:
`849037859fe4f9e34423c941e1b0d5b9edc80582a406386d3ed9facf76b89f4c`.

The new complete GSC recipe contains 380 files, restoring the PR1038
`diagnostic/table_iteration_gc.scm` regression that had only been included in
the interpreted inventory. Its first attempt correctly rejected before native
execution because the inherited review intent still named the predecessor
driver hash. New separate review evidence binds the actual generated driver
`9209a529f443f78a87acf7b11d0ec1c3432ffd26f8decd26d64d60f074e99072`
and candidate scope proofs; neither old intent nor verifier was changed.

The reviewed complete attempt finished in 516.388848500 seconds, DENY:
379/380 files accepted; the only unfinished file was `_num.scm`, terminated
after 90.082458125 seconds of file-level silence. The added PR1038 GC fixture
was in an accepted group. The outer supervisor did not time out, and all
processes were reaped/quiescent. Outer receipt SHA-256:
`3ac4cadb8e4ccf181b4f9aad379bffabef2fcab10a9676402e9e50cdf1b80fe8`;
child receipt SHA-256:
`7eddc4e8af5b2875fba3bc7df0b1935b66b5d6ffe552742706c2746dd6e708d7`;
group observations SHA-256:
`b15bfde8fec786a7420ba9abba33afb02b53c5d15a6f09ac36bd588344debdbe`.
Run: `.data/fixtures/darwin-dynamic-modulo-reviewed-complete-compiled-run`.

This does not meet complete GSC acceptance and the candidate is not adopted.
Its elapsed time is not a matched performance claim against the older
379-file campaign. Existing isolated changed-option passes must not be spliced
into this campaign to claim completeness. There is also a remaining watchdog
observability gap: compiler-observation records real Scheme/C/execution phase
completions, but the upstream suite adapter reports only completed files.
Any phase-aware suite extension must preserve actual commands/artifacts and
original assertion witnesses, original inactivity windows, exact inventory,
concurrency and failures; it must not fabricate progress or performance PASS.

Native qualification and performance remain open. Historical cumulative
milestone completion remains 3/12; this bootstrap requalification does not add
a gate or reset prior completion.

The same completed producer subsequently passed the complete interpreted/PR
inventory: 380/380 files, native suite execution 9.039662542 seconds, whole
attempt 57.073525125 seconds, three host-derived workers with three processors
per child. This requalifies the existing GSI and PR/GSI gates, not new gates.
Recipe: `evidence/research/current-source-full-bootstrap/dynamic-modulo-interpreted.recipe.json`.
Run: `.data/fixtures/darwin-dynamic-modulo-complete-interpreted-run`.
Outer receipt SHA-256:
`83d4f175417e3bbf87046d28449c4d30a96fa48468e18b2460f618b4e043c52c`;
child receipt SHA-256:
`e23d0fa83d151e4a321c519958ad0dcfe290b8ed913109691f276327ad6d5255`.
No compiled timeout is waived by this interpreted pass, and none of these
Gambit qualification times is an MCP package build/test measurement.

## Completed Original-Loader Qualification

The subsequent complete compiled attempt passed **380/380 files, 12/12 groups,
zero timeouts**. Native execution took 510.373226083 seconds; the full attempt
took 587.987150791 seconds. The host-derived allocation was three workers,
three processors per worker. This is correctness evidence, not a speedup.

Only the declared numerical file uses separate completed compiler phases.
Its Scheme generation, GNU C compilation and original GSI/assertion execution
took 22.484158667, 88.616999375 and 0.789129 seconds. Each retains the original
90-second inactivity window. Generated C SHA-256 is
`4d279ee53a1fe69f2e077ad16f01ca058ca6c6d2edacaead5054875e9ff3c29a`,
identical to the earlier original whole-run input. No workload, assertion,
compiler option or loader entry was replaced to obtain the pass.

Run: `.data/fixtures/original-loader-complete-compiled-run`.
Outer receipt SHA-256:
`45168fb4474b340c179e9b974811ae29f3784833f64cba7d612cf2c5eadf638a`.
Child receipt SHA-256:
`87fcb14dca60f8debeae3c10c7d5016686b0681f4c2726004d80a6223ae3c218`.

The current, quiescent sealed receipts were checked before projecting actual
file coverage. The original sealed engine then evaluated the generic coverage
rules plus the separate Scheme DSL PR requirements. It derived both
`complete-gsc` and `pr-regressions-gsc`, with no missing required fixture.
No invented observed-step alias or historical pass was inserted.
Receipt: `evidence/source-results/compiled-suite-coverage/receipt.json`.
The projection's first two integration attempts failed (passing a filesystem
path as an Engine object, then attempting sealed evaluation from editable
code). The successful path uses the existing sealed runner's `rules` entry;
neither identity check was bypassed. Neither failed integration ran native
Gambit tests again.

Run identifiers are opaque. Tests change numeric-looking and semantic suite
identifiers without changing qualification. Fixture paths and hashes live in
`pr-regression-requirements.ss`, separate from generic inference rules. That
versioned scope remains extendable and is not a claim to cover every SMP bug.
The cumulative milestone is now **5/12**, with seven native/performance gates
still open. Previous DENYs and their original elapsed times remain above.
