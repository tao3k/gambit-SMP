# Shared Build CPU Budget

## Source Finding

Pinned `vendor/gambit/lib/main.c` initializes multi-threaded runtime parallelism
to 50% of detected CPUs. The lib/gsc make recipes pass directory runtime options
but no processor option. Therefore `make -jN core` alone does not establish a
shared CPU budget: concurrent Scheme compilers can each start another population.
This is a scheduling observation, not attribution of a historical GC failure.

## Build Policy

The generic build primitives detect available process CPUs and give that budget
to the recursive make jobserver. Compiler populations are computed from the same
budget. With one job per available CPU, each compiler gets one processor through
the command-line make variable `GAMBOPT=p1`, exported to recipe children. No
leading comma is used, so directory runtime options remain accumulated.

This selects per-process build topology; it does not disable SMP, multiple VMs
or multiple threaded VMs in the generated runtime. Single-module regeneration
continues to use the full host population explicitly. Native SMP/GC acceptance
must use its independently recorded multi-processor topology; a one-processor
compiler build is not that acceptance.

Tests cover odd/even/single CPU budgets, invalid capacities, actual make variable
export and command/receipt binding. The original engine and receipts are retained;
the new scheduling implementation is sealed separately. Physical memory pressure
and concurrent external processes are not measured by this CPU-only policy.

## Native Observation

The shared-budget source-core command was `make -j12 GAMBOPT=p1 core`, with 12
selected from this host, not a recipe constant. It completed all generated C
and linked artifacts in 137.850 seconds; there were no missing sources or build
errors. The complete campaign remains DENY (229.937 seconds): the newly sealed
Python evidence implementation requires ASCENT `open-sources`, absent from the
selected API build. This is distinct from a compiler failure. The old matched
engine/API source-core campaign remains PASS at 117.701 seconds for its make
stage; these samples do not establish a performance improvement.

Do not repeat the unchanged denied campaign or rebuild its successful core just
to diagnose the API mismatch. Repair and qualify the evidence provider pairing
first; preserve the original DENY and exact engine identities.
