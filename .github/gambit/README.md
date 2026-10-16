# Gambit CI Through The Research Kernel

The CI-specific dispatcher and module registry have been removed. Workflow jobs
select data assets in `evidence/research/ci/*.recipe.json` and call the public
`gambit-smp research` interface. They do not select a Python handler, provide
arbitrary native argv, or make research/admission decisions.

## Data And Execution

- `three-flag-core.recipe.json`: locked materialization, O3 configuration with
  all three flags, pre-generated-C seed, one source-regenerated core and terminal
  Evidence DSL. This is **not full two-pass bootstrap**.
- Eight module Recipes: the same source lock, a checked imported generation,
  canonical failure inventory/review policy, official tests and terminal DSL.
- Unit/stress Recipes declare exact fixtures and distinct GSI/GSC steps using
  existing `gambit.suite`; both consume the same 300-second whole module budget.
- `gambit.upstream-tests` invokes the real upstream Make targets, including the
  actual `make check` rather than reimplementing its prerequisite/cleanup graph.
  Both execution modes and dependent Make operation scopes are reviewed before
  launch. Unstarted, DENY, timeout and unknown teardown never count as success.
- `execution.ss` infers missing steps from actual recorded outcomes. Its answers
  remain observations, not execution permission, runtime correctness or performance.
- Framework self-tests use the existing bounded process batch transport through
  its general observation CLI. `contracts.json` is test-request data, not a
  research producer or another CI execution kernel.

## Cross-Job Generation Contract

`research --export-runtime <completed-run> --step source-core --out <fresh.tar>`
requires an inspected successful sealed producer and exact successful dependency
closure. It transports the original receipts, stream/process logs, runtime
identity, full source/generated/binary paths/modes/internal links, source lock,
source inventory and engine/compiler provenance. Export time is charged against
the original 600-second build budget; expiry fails rather than resetting it.

`gambit.runtime-import` consumes a declared input descriptor
(`runtime-artifact-input.v1`), binds the actual incoming tar SHA, and checks the
complete archive inventory before extraction. Added, missing, changed, duplicate,
escaping and special-file entries fail closed. Consumer source bytes, source
lock, implementation/provider files and compiler/tool bytes must match. Only a
real source-core is published as `source-runtime`; seeds are never promoted.
The parent build budget/receipt remains unchanged. This is an independent test
campaign, not failed-build resumption; each native test still faces its own
canonical retry gate. The archive is a trusted-host observation, not a signature
or an authorization token. Portability is not admitted by packaging controls.

Build and native module whole budgets remain 600 and 300 seconds respectively.
Step ceilings do not reserve or restart these budgets: seed and source-core each
receive at most the remainder of the same 600-second deadline, and GSI/GSC share
the same 300-second deadline. Export is supervised by the sealed worker against
the original producer's monotonic deadline and boot identity, including idle time.
Missing or cross-boot clock provenance is rejected, not reconstructed from elapsed
durations. An archive does not create a fresh build budget.
Patch/framework transport controls retain one shared 15-second batch budget.
No automatic retry or continue-on-error is configured. All eight module jobs and
patch contracts are required by the final summary. Raw receipts/logs remain local
or Actions artifacts, never Git source.

## Current Evidence Boundary

The migration has not yet passed real hosted execution. The fixed ASCENT revision
`c8c3c8b4dc3bd5fa4c290dc258646915fdc1b69b` has no downloadable wheel artifact
in run 38886995055, and the current publication lock binds only macOS arm64.
The shared setup explicitly forbids building ASCENT from source downstream.
A published, source-bound Linux wheel and matching publication lock are required;
missing packaging is an environment/setup failure, not a test pass. Do not fix it
by injecting a Scheme SDK or weakening wheel/source validation.

The upstream wheel publication fix is committed at
`37d8538cbbae189be3316c2e32d30c5aac17bca4` (run 38908711765).
Its qualified-wheel upload is a prerequisite, not evidence of a completed run.
The downstream lock remains unchanged until an actual matching artifact and its
complete source identity have been checked; a source-build fallback is forbidden.

Historical runs remain historical:
- 38894861703 failed compiling `make_global` without a processor-state argument.
- 38897367565 built the minimal context patch but all eight native modules failed.
  TFIB retained exit -9, timeout true and group_quiescent false.
- 38899270572 built the same minimal source; threads, interrupt and terminate
  passed, TFIB and interrupt2 failed, and three official Make jobs were held
  without native launch. The whole run failed.
  Interrupt2's interpreted child exited with an uncaught exception (HI=70 LO=0);
  the compiled child terminated with SIGSEGV (HI=0 LO=139). Both suite parents
  exited 1 without timeout and with quiescent process groups. TFIB instead timed
  out and did not establish group quiescence. These are distinct native failures,
  not setup failures or evidence that all tests were launched successfully.

The new Recipes select the complete retained owner-limit source, not that minimal
slice. `candidate.json` retains the baseline failure and source-change hypothesis;
it does not prove a unique cause, typed retry eligibility or native success.
Historical Darwin/FD results cannot be credited to this GNU/Linux candidate.
`source.lock.json` in this directory remains a frozen historical source input;
its bytes and old receipts are not rewritten.

Three flags, graph validity and archive/control tests do not establish actual
multi-VM creation, roots, GC/FFI, rollback, teardown, Gerbil or matched performance.
Those require real same-candidate test receipts before overall closure.
