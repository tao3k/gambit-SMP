# Shared Regeneration Budget

## Rejected Budget Attribution

The 17-file migration metadata candidate timed out at its original 180-second
core limit. Its printed SCM-to-C commands omitted `p1`, but that does not imply
`GAMBOPT=p1` was ignored. That initial attribution was incorrect. In
`lib/main.c`, environment and command-line runtime options accumulate unless
an option source starts with a comma. The existing shared-budget documentation
already records the environment transport. A parent probe with exported
`GAMBOPT=p1` and directory-only command-line options printed one processor.

The new cumulative fixture changes only three additional build templates
relative to that candidate: `lib/makefile.in`, `gsi/makefile.in`, and
`gsc/makefile.in`. Every one of their eight `gsc-boot` generation/link commands
passes `-:$(GAMBOPT),...`. This duplicates an already effective environment
option under the current build plan. With an unset variable the leading comma
also changes option-source precedence, so this patch must not be promoted as
a general default-preserving build fix. The overlay is retained solely as the
exact identity of the measured component build, not an accepted optimization.

The existing host-auto planner owns the CPU policy; there is no evidence that
an extra command-line copy of its option improves that policy. Application
VM population and GC acceptance tests remain independently host-adaptive.

## Validation Scope

The isolated build starts from the unchanged parent's core snapshot, not the
partially rebuilt timed-out candidate. It regenerates effective makefiles,
checks that all boot recipes bind `GAMBOPT`, and retains the same 180-second
core cap. The compiler remains GNU GCC with all three SMP/multi-VM flags.
No Python framework or sealed provider implementation is modified.

Core completed in 113.098463 seconds with zero recursive build errors under
the original 180-second cap. This is not a matched speedup result: the previous
core timed out and the extra option is redundant. The build establishes linked
artifacts, not a fresh two-pass bootstrap. Migration regressions bind their
actual binary/source identity separately. Retirement drain, cancellation/root
composition, complete native suites and Gerbil acceptance remain open.

## Actual Migration Regressions

Source and artifact identity were checked before and after each process.
The processor population came from available host CPUs, not a fixture constant.
The completed 18-file build is the identity being tested, not the timed-out
17-file build and not the original parent binary.

- Unchanged canonical compiled migration: compile 2.027224 seconds, run
  0.501369 seconds, exit 0, exact completion marker and quiescent process group.
  All detected destination transitions completed with per-round forced GC.
- Concurrent worker migration and interrupts: compile 1.131484 seconds passed;
  run 0.534418 seconds, exit -11 (SIGSEGV), no completion marker. Group quiescent.

The combined regression receipt is DENY. No native correctness, speedup,
bootstrap or release admission follows. The signal is a new actual failure,
not proof of one particular queue, layout or GC cause. Preserve this input
identity and do not repeat the unchanged crash to seek a favorable schedule.
Native evidence is retained at
`evidence/source-results/fixtures/thread-migration-shared-regeneration-budget/migration-regressions.json`.
