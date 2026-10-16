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
`recipes.tree_identity` (complete paths, modes and checked links),
`suite_primitives.selected_files` and `admitted_suite`; it has no independent
Bash timeout/exit parser or research verdict logic. Patch contracts use their
separate 15-second whole budget. Python transports the official make/runner
calls; candidate reasoning/admission remains in Evidence DSL and sealed kernel.

Modules cover the complete upstream `make check`, GC/C interface/dynamic load,
compiled execution, interpreted/compiled thread tests and all four explicit
upstream stress files. Stress is not part of the default unit-test inventory.

This workflow tests the exact **vendor gitlink baseline**, not an arbitrary
unreviewed patch or the current repair candidate. Patch/model regressions remain
in the Evidence framework CI. A patched runtime campaign must still pass the
existing sealed Recipe, complete failure inventory and typed retry review; do
not turn a workflow input into a gate bypass. New native fixtures should become
explicit modules consuming the same reviewed artifact, not separate hidden builds.

Three enabled flags do **not** establish independent multi-VM creation, roots,
rollback or teardown. Those candidate lifecycle gates, Gerbil, full bootstrap,
and matched performance acceptance remain separate. Green baseline CI cannot
be reported as the repair candidate's full native PASS.
