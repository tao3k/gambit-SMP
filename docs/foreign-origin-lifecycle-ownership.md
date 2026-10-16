# Foreign-Origin Lifecycle Ownership

## Source Findings And Correction

The lease-admission candidate's global `___cleanup_checked` closes foreign
admission before destroying VM storage. Its multi-VM branch calls the internal
`cleanup_vmstate_locked` operation, consuming that ownership. Its single-VM
branch instead called public `___cleanup_vmstate`, which tries to close the
already closed gate and returns without destroying VM storage. The successor
uses the existing internal operation in that branch. The old source lock and
failed bootstrap receipts remain unchanged.

The pinned upstream `lib/os_base.c` implementation of `___fatal_error` calls
`___exit_process(___EXIT_CODE_SOFTWARE)` after reporting the error. The candidate's
legacy public `___cleanup` invokes it when checked cleanup rejects a busy VM.
Consequently, a native fixture cannot call legacy cleanup while a foreign
frame is live and then require normal return. The unexecuted
`foreign_origin_lease_roundtrip.scm` is retained as a source-rejected test
contract, not a claimed native failure. The historical actual timeout in
`callback_retirement_roundtrip.scm` remains unchanged.

`foreign_origin_frame_roundtrip.scm` is the replacement frame-only fixture:
it requires rejection of removed-origin retirement, intact topology and GC
roots, an actual return to the C parent and thread join, successful unrelated
retirement from retained P0, and successful retry after C return. It invokes
only the official FFI interface, with host-derived topology. It has not run
and does not qualify busy cleanup or the full GC/FFI gate. The candidate's
checked cleanup extension is source-audited, not treated as an upstream
official public interface authorized for native fault tests.

## Bound Model And Compiler Evidence

Source lock SHA-256:
`9edc6619ae08c52cb9f431d6c47bf5c7b759d3f55a8d3dacdddff5632aac74e2`.
Patch SHA-256:
`7d34074970ac4aae1345250b20094863d9a7002aa82ed0bb5941526cc2ca8852`.
The source revision remains `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.

`cleanup_endpoint_ownership.qnt` checks existing-admission consumption and
the checked-versus-legacy busy endpoint distinction. Two negative controls
expose gate reacquisition and an incorrect normal return from legacy fatal
cleanup. Five explicit trajectories and positive safety/no-stall checks passed
through native Quint/TLC and terminal ASCENT in 42.79284954200557 seconds.
Positive safety explored 16 generated / 12 distinct states, zero queued.
This is bounded protocol evidence, not arbitrary topology, fair liveness,
C memory-order refinement, physical destruction or fault acceptance.

The model run reads CURRENT/PASS. Its outer receipt SHA-256 is
`725f962f21c339f54f867fa1792ed041f66e7ee0766c97beb4ec6853d491d15f`;
child SHA-256 is
`3d54dc076d32d5bf4b68e471c9e5293ff6953062d1edcbaa56e2ed76ad0f4055`.

GNU GCC object checks also read CURRENT/PASS, 63.824394583993126 seconds
whole: setup 0.8067, c_intf 1.1891 and mem 0.9855 seconds. The pinned default
Bazel profile retains SMP, multiple VMs and multiple threaded VMs. An
additional setup object with `___SINGLE_VM` compiles the corrected branch in
1.0087 seconds; it is supplemental preprocessing coverage, not a runtime
configuration used to qualify SMP or replace the default profile.
Outer receipt SHA-256:
`a8e6566f920ab6161c8ea6c07ab3905a7d63bab3dc6c664d00b271d0eab841d1`;
child SHA-256:
`dd1767305adae1dcdd38bb29d786a20d14c2772a63880f92952608ed36ff9d9f`.
Both runs use engine
`d5e0bc206a9129ccf356e4b2699a1844ee9432599c05e933efe35178c6efa7a9`.

Reproduce with the declared `cleanup-endpoint-ownership-model` and
`foreign-origin-lifecycle-ownership-objects` recipes through the existing
sealed research framework. No private cleanup call, injection hook or custom
loader ran. These results do not admit a completed runtime or release.

## Remaining Integrated Gates

The accepted older producer remains 3/12; its passes are not transferred to
this successor. Fresh full bootstrap, official frame execution and complete
current-producer native/Gerbil/performance campaigns remain required. The
old bootstrap's two DENYs and cumulative expenditure remain bound, not reset
by the independent source/model/compiler audits. Original review timeout and
checked prefix-continuation integration remain framework dependencies.
