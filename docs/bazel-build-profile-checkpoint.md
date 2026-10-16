# Bazel Build Profile Checkpoint

## Default Qualification Configuration

The default SMP qualification recipe is now
`vm-registry-resize-grace-bazel-profile-bootstrap`. It consumes
`evidence/fixtures/gerbil-bazel-build-profile/profile.json`, not independently
maintained optimization levels. The typed data retains the exact current Bazel
`tools/ci/build_source_toolchain.sh` source bytes and their SHA-256:
`14f9adabe21a3eb490bdedb4418a68958df2960bf4e045f78a66babffc56a0cc`.
The origin worktree was modified; its recorded Git revision is context, not a
claim that the commit contains those bytes. The versioned byte snapshot is the
reproduction input. Updating the upstream profile requires a new bound snapshot
and qualification; it must not silently change old receipts.

The framework parses only the audited literal Darwin configure arrays as data;
it never executes the source script. Prefix, Gerbil revision and version-string
arguments are Gerbil-specific and are not forwarded to Gambit. The profile
supplies C O1, RTS `yes`, GCC options, inline jumps, dynamic clib, trusted C TCO,
single-host zero, empty march and `CFLAGS=-pipe`. Generated makefiles resolved
RTS `yes` to O3 under the selected GNU GCC. The profile snapshot lacks an
explicit multiple-threaded-VM option, so the separately recorded goal overlay
adds `--enable-multiple-threaded-vms`; SMP and multiple VMs already come from
the profile. No existing flag is removed or replaced.

O0, simple O1/O1 and RTS-only configurations remain explicitly diagnostic
recipes. They are not default release/profile qualification or interchangeable
producers. The original source lock, QNT controls, Scheme causal review,
machine-derived concurrency and bootstrap deadlines are retained.

## Actual Result

| Stage | Result |
| --- | --- |
| Configure | 32.609 seconds, exit zero, no timeout |
| Seed core | 84.583 seconds, exit zero, no timeout |
| From scratch | 223.599 seconds, both complete phase1-4 passes |
| Whole bootstrap | 408.068 seconds under the original 600-second cap |
| Sealed readback | CURRENT/PASS; root reaped, process group quiescent |

Engine: `03ebd972aaabc622edb2ab899f17ed2f6b336bc23ddaceb4c5249bc37a1918a3`.
Bootstrap identity:
`7dc39609792279599d149d5b8dce2d61f347c0e33add30646305c0484e2edb6d`.
Completed producer reference:
`evidence/research/vm-registry-reader-lease/bazel-profile-completed-producer.json`.
All three concurrency switches were observed in the actual configure argv.
This is bootstrap qualification, not complete native Grid, parallel GC, Gerbil
or performance admission. Existing O0 compiler-cost retry reviews are not
automatically transferable to this O1 dynamic-module profile.

## Retained Framework Failures

The first request used an executable script input and was rejected before
execution by the existing framework safety rule. The replacement is typed JSON
source data, not a renamed executable or a shell-evaluation bypass. The first
typed-data run ended DENY at 42.255 seconds before configure invocation because
the executor lacked its `source_path` import. That original run and traceback
remain retained. A focused executor regression now checks profile input binding,
actual configure arguments, CFLAGS and the unchanged 90-second child budget.
The corrected run above completed without relaxing either failure condition.

The RTS-only diagnostic completed CURRENT/PASS in 292.217 seconds; it is not
promoted as a faster baseline. No failed or partial full Grid has been rewritten
as passing based on these bootstrap results.
