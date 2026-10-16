# Global Cleanup Native Checkpoint

The successor source is locked by
`evidence/fixtures/vm-global-cleanup-preflight/source.lock.json` and the cumulative
`patches/fixtures/vm-global-cleanup-preflight.patch`. It adds secondary-VM
precommit checks to the pending-join candidate. It does not change the frozen
resize-grace baseline or establish complete SMP acceptance.

## Completed Producer

The sealed `vm-global-cleanup-preflight-bazel-bootstrap` run passed in
311.672 seconds, within the original 600-second cap. Both bootstrap passes
completed; the parent was reaped and its process group was quiescent. The default
Bazel profile and all three SMP/multiple-VM/threaded-VM flags were retained.
Consumers use `global-cleanup-completed-producer.json`, not an older binary or a
new bootstrap. Runtime admission remains false.

The explicitly selected producer source root is
`.data/fixtures/vm-global-cleanup-preflight/bazel-bootstrap-run/run/bootstrap/source`;
its identity is the sibling `identity.json`, SHA-256
`21533fa63303a97bede3e819648d054123bd99b3486a09e5bde91dd86d94a136`.
The gsi/gsc/library hashes are respectively
`d3eb7ef7a3d7e2428602bbe62e855ca855c64043cc0c868f83d62f45f257b5d4`,
`d880cde9b08f321989f1a10b428ddd40cbe6b91cb592d4290bfb33b3140c2997`,
and `160787a7ab378aa4166858a7a64f1ab1ef23d9f8c03bd415102c51016db1edf6`.
These local artifact locators are validated through the committed producer
reference and source lock, not portable build prerequisites or a claim of latest
candidate selection across other tasks.

## Retained Native Failures

| Recipe | Observation | Boundary |
| --- | --- | --- |
| `smp-global-cleanup-registry-host-topology-grid` | DENY, executable timeout; compile 2.890 seconds, execution killed after 116.531 seconds | Unchanged topology, 300-second whole and 120-second step caps. No regression acceptance or retry on an unchanged premise. |
| `smp-pending-join-native-recovery` | DENY, executable exit 85 after 0.638 seconds; compile 1.718 seconds | Post-run VM count, pending ownership and injected-fault assertions did not all hold. The combined exit does not identify which predicate failed. |
| `smp-vm-scoped-pending-join-native-recovery` | DENY before execution, GCC rejected the stale C-lambda variable | Fixture arm-call error; retained, not runtime failure. |
| `smp-vm-owned-pending-join-native-recovery` | DENY, post-run `err=71 processors=1 injected=1 pending=1` | Fault and retention observed, but fixture incorrectly expected a Scheme exception rather than the returned encoded errno. |

The first fault fixture arms OS-thread-local state from Scheme. Scheme execution
can migrate, whereas the resize join executes on P0. This is a fixture ownership
gap to investigate, not evidence that the runtime recovery is correct. The
successor `vm_scoped_pending_join_recovery.scm` keys fault arming and counters to
the actual VM and prints the failing post-run values. Its recipe preserves the
same immutable producer and budgets, both QNT safety/negative controls, and the
earlier DENY records. A successful ordinary topology cannot substitute for this
fault test; neither can a model pass erase the topology timeout.

## Verified Fault Recovery

Source inspection confirms `___current_vm_resize` returns `sop.arg[0]`, exposed
as a Scheme object by `##current-vm-resize-raw`; it does not itself throw the
encoded join errno. The final `pending_join_errno_recovery.scm` fixture checks
the exact `___FIX(___ERRNO_ERR(EINVAL))` result, retaining every ownership check.

`smp-pending-join-errno-native-recovery` passed in 85.916 seconds within the
original 300-second whole cap. Native compilation took 2.302 seconds and
execution 0.507 seconds within the unchanged 120-second step cap, with no
stderr, timeout or nonzero exit. Host capacity was detected as 12: five concurrent
VMs each used two processors, reserving root and interrupt-reader capacity.
Each VM performed pinned forced-GC root checks, one injected resize join failure,
one injected owner-cleanup join failure, then a successful recovery/cleanup retry.
Global cleanup was rejected before `setup_state` changed from ready. Exact
per-VM injection counts prevent an ineffective interposition from passing.
The executable source hash is
`a8636647fb9007e23441352fb342efb7e939d406b4c43426c8a5dbf3da6bf8b3`.

Both QNT models' safety/negative-control/trajectory steps and the framework's
ASCENT exact-step verdict passed. This is a bounded POSIX fault observation, not
Windows qualification, natural OS error attribution, complete lifecycle fault
coverage or source-refinement proof. The topology timeout is still unresolved;
the candidate remains unadmitted, and the final acceptance count remains 2/12.

## Remaining Obligations

Resolve the native topology timeout from source/protocol evidence, verify actual
fault injection and retained recovery, then rerun the causally changed candidate
through complete interpreted/compiled inventories and the milestone obligations.
Root sticky cleanup failure, creation rollback and direct-user ownership remain
separate open requirements. No percentage gate is discharged by this checkpoint.
