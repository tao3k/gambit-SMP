# Gambit CI modules

`gambit.yml` adapts the pinned upstream `.github/workflows/ci.yml` GNU build
and `tests/makefile.in` test entrypoints. It does not execute a local developer
build or the Working session's workspace. All three flags are enabled together.

One build artifact supplies every test job. Each job verifies its checkout SHA
and every regular source/generated/binary path before running. Logs, actual
exit status, timeout flag, process-group teardown, configure output, compiler and inventory
are Actions artifacts, not committed evidence. A failed module does not cancel
other modules; the summary requires all of them.

The initial CI process caps are 600 seconds for the build and 300 seconds for
each official test module; the outer job timeout includes checkout and artifact
transport. These are CI baseline contracts, not changes to any existing research
receipt, retry admission, or experiment budget. No automatic retry is configured.

`modules.json` declares the modules. The CI adapter reuses the framework's
`process_observation.capture` (whole deadline, reap and process-group probes),
`source_materialize.materialize` (revision/base/patch/candidate byte checks),
`gambit_build_primitives.build_seed_core` (shared build capacity, recursive
failure detection and complete core artifact inventory),
`native_capabilities.run_suite_groups` (one mode per invocation, isolated test
workspace, exact inventory, immutable fixture check and per-mode observations),
`recipes.tree_identity` (complete paths, modes and checked links),
`suite_primitives.selected_files` and `admitted_suite`; it has no independent
Bash timeout/exit parser or research verdict logic. Patch contracts use their
separate 15-second whole budget. Python transports the official make/runner
calls; candidate reasoning/admission remains in Evidence DSL and sealed kernel.

Modules cover the complete upstream `make check`, GC/C interface/dynamic load,
compiled execution, interpreted/compiled thread tests and all four explicit
upstream stress files. Stress is not part of the default unit-test inventory.
The runner's child interpreter/compiler processes receive the documented
`GAMBOPT=p2`, not just a processor option on their parent; receipts record it.
The transport parent uses the existing single-processor runner option; that
does not reduce the actual fixture/compilation children's `GAMBOPT=p2`.
GSI and GSC share one 300-second deadline; modes never receive separate caps.

Run 38897367565 completed its patched three-flag build, but **all eight native
modules failed**. The old combined `-gsi -gsc` invocation exceeded the upstream
file-count progress bar (104% / negative `make-string` length); it is replaced
by the existing per-mode suite executor, not by changing Gambit test sources.
Separate native failures remain: `make test5` reports an unscanned compiler
object; `make test7` terminates with SIGSEGV. Make-based jobs have explicit
hard-failing CI holds in the module catalog until source-causal review repairs
those failures. Holds launch no native process and cannot yield a green summary.
Do not remove them just because the CI transport changed or a local test passed.
The original TFIB run additionally recorded `exit=-9`, `timeout=true` and
`group_quiescent=false`; it is not a successful teardown. An executor exception
retains partial mode/plan records and explicitly marks later modes unstarted.
Sending SIGKILL alone never establishes process-group quiescence.

The original vendor-only run [38894861703](https://github.com/tao3k/gambit-SMP/actions/runs/38894861703)
failed with exit 2 (not timeout) in `setup.c:make_global`: `___GLOCELL` expands
through `___ps`, but that function has no processor-state argument. Stress jobs
did not run. Its logs/artifact and original baseline remain unchanged.

`source.lock.json` now declares a **minimal patched upstream CI candidate**, not
the Working repair candidate. The exact processor-context fix already present
in `patches/snapshots/candidate029-notification-source.patch` is reused without
its other changes. It passes the caller's context through ANSI and K&R forms,
and keeps single-VM expansion unchanged. `source_materialize` checks its pinned
base, complete overlay and resulting file SHA before building `.ci/gambit`.
Vendor and Working are never patched. Temporary real Git metadata supports the
official release-seed/bootstrap route; no dummy-compiler shortcut is introduced.
`aclocal`/`autoconf` resolve the installed pkg-config macro before configure.
Metadata is removed only from that disposable build after completion.

This is CI qualification, not a research retry/admission producer. No arbitrary
patch workflow input exists. All jobs bind the same lock, patch and artifact
identity. Research campaigns still require sealed Recipe/complete failures/typed
retry review; a CI result must not be imported as authorization or as the full
Working candidate's acceptance. New native fixtures must be explicit modules
consuming that campaign's reviewed artifact, not separate hidden builds.

Three enabled flags do **not** establish independent multi-VM creation, roots,
rollback or teardown. Those candidate lifecycle gates, Gerbil, full bootstrap,
and matched performance acceptance remain separate. Green baseline CI cannot
be reported as the repair candidate's full native PASS.
