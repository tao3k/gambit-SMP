# BTQ Field Provenance Diagnostic

## Question And Scope

The exact-image incident consumes a right-child word tagged 7, not STRUCTURE
tag 1. The source-corrected queue relocation model requires color, parent,
left/right and container fields to contain #f or queue/node structure references.
This diagnostic observes those Scheme field boundaries; it is not a repair,
source-refinement proof, native correctness pass or performance candidate.

The successor retains the previous 23-file source slice and changes only
`lib/_thread#.scm` in its active SMP branch. Fault reporting is compiled only
for Darwin/GNU (not Clang). Valid operations keep their original field access;
there is no normal-path logging, injected bad value, private loader, new lock,
SMP disablement or changed GC participation policy.

## Observations

The checks report to descriptor 2 through POSIX `dprintf`, then call standard C
`abort`. The phases are:

- 0: check the node's STRUCTURE tag before a field read.
- 1: check a field value immediately after its read.
- 2: check the node/value before the field store.

Fields are 4 (color), 5 (parent), 6 (left), 7 (right/minimum) and 17 (thread
container). A value may be #f or have STRUCTURE tag 1. Tag checks do not establish
address validity, allocation extent, concrete structure type or lifetime.

A store hit identifies an invalid value reaching a guarded Scheme store
boundary. A read hit without a store hit does not identify a GC writer: raw
writes, incomplete instrumentation, wrong layout/lifetime and compiler behavior
remain possible. Observation code changes generated control flow and timing;
no hit or non-recurrence is inconclusive, not a fix.

## Reproducible Inputs And Retained Failure

The current source lock is
`evidence/fixtures/darwin-btq-public-provenance/source.lock.json`; its complete
overlay restores the source slice from the pinned Gambit submodule. The recipe
reuses the existing full source worktree under a framework lease. The temporary
thin editing slice was renamed/reused, not cloned as another full source tree.

The first `darwin-btq-edge-provenance` build failed: expanded macros in `_io`
and `_repl` did not declare the runtime-private reporting functions initially
used by the diagnostic. That lock, patch and DENY receipt remain retained.
The public-API successor fixes the declarations at their source; compiler
warnings are not suppressed and the old receipt is not replaced with PASS.

Both recipes retain the same Bazel build profile and stage limits. All three
SMP/VM flags remain enabled, with host-selected build parallelism. Native
read/compile checks use the actual Gambit toolchain rather than the scanner
that cannot parse inherited embedded C. Only a completed source-bound producer
may be used for the subsequent unchanged upstream stress inventory.

## Actual Native Result

The public-API successor completed both bootstrap passes: 160.784 seconds in
the bootstrap step, 271.966 seconds for the entire source/configure/seed/review
run. The complete unchanged compiled stress attempted all four files:
terminate and interrupt passed, tfib failed with SIGSEGV, and interrupt2 reached
its original 300-second inactivity window. Native stage: 304.908 seconds;
whole recipe: 318.154 seconds. This remains DENY, not complete stress acceptance.
Neither the BTQ boundary probes nor the inherited FFI ABSENT probes fired.

The new incident is exact-image-bound but not child-PID-bound. It faults in the
kernel break handler's heap-frame return metadata decode, not the previous BTQ
right-child read. Original/debug kernel text and text relocations match; DWARF
maps object offset 0xea80 to generated `_kernel.c` line 12002. The preceding
instruction loads the frame's RA into x28; it contains `0xffffffffffffff00`.
The faulting instruction dereferences x28 + 7. Wrong frame identity/layout,
copy contents or lifetime remain possible; this does not identify a GC writer
or establish a common cause with the earlier failures.

The registered `captured-heap-return` Evidence view initially exposed the
missing heap-frame RA provenance requirement with two source anchors and no
model context. It now binds the captured-frame operation model and configured
coordinate checks, but both source gaps and the native DENY remain open.
Existing stack-frame/relock or queue-copy model PASS results do not close it.
Next work is real frame identity, descriptor and RA provenance, not an unchanged
diagnostic retry or another generic lock change.
