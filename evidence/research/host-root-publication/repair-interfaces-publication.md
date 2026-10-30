# Research Publication Audit

Base: SMP PR #1, `dcd91b2c6948f19c55da9046796012516c7f0207`.
The main research directory remains at its existing local HEAD and keeps its
shared staged/unstaged work. Publication uses an independent Git index based on
the PR head; no checkout, reset, shared-index rewrite or native execution occurs.

The publication includes the two consumer-interface models, conditional Lean
proof, exact accepted checker bundles, current-repair declarations and the
earlier host-root/root-closure research they depend on. The frozen mutex-return
patch and source lock are historical reconstruction evidence, not a new runtime
patch or a change to the implementation task's selected candidate. The manifest
and source-model dependencies are included instead of relying on ignored local
files. Failed partial publications are excluded.

Only the two new protocol bundle registrations and the current-repair view are
added to the PR's existing registries. Unrelated pending native registrations,
Zig research, task-process migration and other framework changes are excluded.
The sole Python change is exact compiled-artifact retention during model-check
reuse; no task lifecycle, native workflow or semantic inference is added.

The **exact independently assembled publication tree** passed all six tests in
`tests.test_repair_consumer_interfaces` in **13.077 seconds**. This includes the
real registered query and continuation, model/source mutation and restoration,
portable checker closures, guarded Lean and artifact-retention rejection tests.
The prior 51-test working-tree qualification remains a separate observation;
it is not relabeled as qualification of all pending framework changes on this
PR head.

The temporary validation tree used pinned vendor source references, the unchanged
installed ASCENT wheel with its distribution metadata, and the existing exact
Lean dependency cache. Setup failures were preserved as observations: missing
Git-root metadata, absent vendor references, and an installed wheel located
outside the tested root. No identity check was weakened. No runtime build,
native stress test or Grok session ran. Temporary publication material is not a
maintained second checkout or a new fixture.

Whitespace and personal-absolute-path checks passed for the selected publication
scope. The original shared index is preserved. This publication does not close
any of the four remaining native contracts or establish an end-to-end speedup.
