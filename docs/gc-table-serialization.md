# Allocating Table Serialization Cursor

Runtime022 retains the effective #988/#1038 candidate repairs, but text
serialization still reaches `##explode-gc-hash-table` through `##wr-serialize`.
That helper reads a pair from live slots, allocates two cons cells and then
advances its physical slot index. Disabling ordinary interrupts does not make
allocation incapable of collecting. A GC rehash between visits can move an
already-seen key forward or an unseen key backward. This is the same cursor
ownership problem previously repaired in callback traversal, at a different
allocating caller. It is not an upstream PR defect attribution or Darwin-only
implementation claim; current native checks are macOS/GNU GCC only.

The `gc_table_serialization` QNT control covers three strongly rooted logical
keys and six rehash layouts. The old control produces a missed/duplicated-key
counterexample. The snapshot variant exhausts 37 distinct / 146 generated
states, with zero queue. Atomic typed capture after allocation is an assumption;
the source builder also requires the current `gc_table_iteration` proof and
checks the existing typed snapshot helper. Weak lifetime, union-find behavior,
concurrent table mutation, metadata semantics, C weak memory and full GC
liveness are not proved by this bounded model.

Native regression uses the unchanged upstream PR1038 text-roundtrip helper,
32 strongly rooted heap keys, 40 roundtrips and another processor requesting
64 GCs. It checks every decoded key and joins the collector worker. There is
no runtime shim, skipped assertion or injected primitive implementation.
This scheduling smoke does not guarantee every modeled interleaving.
Original runtime022 fails a decoded-key query in 2.642 seconds: the value is
`missing`, not the expected value. Source hashes are stable, and there is no
timeout. That failed configuration is retained and not rerun unchanged.

`gc-table-serialization-snapshot.patch` changes only the explode helper. It
captures a rooted vector with the existing typed-copy helper, enumerates that
vector and reads serialized size/flags/count/min-count/free from the same
capture. Slots 1 through 4 are documented in `_gambit#.scm`; size still uses
the same slot-count shift formula. The builder computes the exact expected
whole-file hash before applying the patch, rejects helper/cursor/metadata
drift, removes `_system.c` before regeneration and checks proof inputs again
after building. This lexical binding is not a semantic proof.

Runtime023 actual GNU GCC core rebuild passes in 29.894 seconds; all three
core artifact hashes change. The same regression passes interpreted execution
in 3.347 seconds and compilation/execution in 8.564 seconds, with unchanged
60-second whole-mode budgets, exit zero, exact completion markers and stable
source/proof identities. The original PR1038 helper tests are included too.
This closes one native residual locally, not all #1038 failures or bootstrap.
The subsequent full interpreted campaign passes 379/379 files in 240.252
seconds under the unchanged 300-second whole-mode budget: all 375 original
files plus PR1047, PR1037 and two PR1038 regression files. It uses the separately
model-bound interrupt-completion, start-join and per-read test repairs; original
assertions remain. Network tests run with local port binding permitted, not
skipped. Receipts record runner1 plus child11 on the detected 12-CPU host.
Complete compiled suites, two-pass bootstrap, Linux, Gerbil and performance
admission remain separate requirements.

The subsequent runtime023 `from-scratch` attempt is DENY at 600.010 seconds.
Generated C and new core binaries exist and no recursive compiler error is
reported, but the log stops during the first bootstrap's core recursion.
The retained `gsc-boot` hash still matches the seed. Upstream
`gsc/Makefile:bootstrap-post` promotes the newly built compiler only after
recursive core completion; that step and the second clean/core pass are not
observed. Artifact presence is therefore not a completed bootstrap, nor is
this budget denial evidence of a diagnosed GC or compiler crash. The denied
receipt is retained and this unchanged configuration is not retried.
