# Library Inventory Boundaries

The Python adapter caches inventory projections, not verification verdicts or
inference answers. A projection contains the original per-path mapping and build
metadata. It never replaces the complete source/resource inventory with one hash.

For a sealed request, the cache key includes the exact engine identity.
The full no-follow seal inventory is hashed before and
after every request. Only paths present in that checked manifest can be projected.

Action discovery deduplicates identical path arguments within one input pass, not
across passes. Its complete canonical path/SHA map is recomputed after inference;
any difference denies discovery and reports the changed paths. This is neither a
verification cache nor permission to omit a distinct source binding.

For an installed package, the key includes loaded module origins, the complete
distribution entry list and all distribution metadata bytes. Each use checks
canonical paths. Engine entry
and exit still hash every bound source, runtime resource and installed package
file. Changing bytes while restoring size or timestamps must still be rejected.
Callers receive copies and cannot mutate the cached projection.

Earlier publication-lock experiments compared Linux and macOS wheels, source
trees and build inventories. Their receipts remain historical evidence, not a
second active dependency manager. Current CI uses `uv sync --locked`; package
resolution belongs to `uv`, while the framework checks the installed package's
actual compiled inputs and resources. The old 186- and 187-input artifacts do
not qualify the current 188-input ASCENT package.

Trajectory attempt/explore is a required consumer capability, not an optional
test environment. The real restart/source-generation replay test runs without an
opt-in variable. The historical 5f9220b1 product did not implement the `attempt` event; its
recorded capability failure remains a failure. A source checkout containing the
implementation is not a published artifact. Before qualifying a replacement,
bind the complete per-path packaged source inventory, then run the mandatory replay and
complete consumer/current-graph validation against that same identity. Do not
translate new events into old event kinds or infer exploration results in Python.

Release builds and their build dependencies use optimization level 3. A build
watchdog observes real compiler output or measured process-group CPU advances;
120 seconds of inactivity is not a 120-second whole-build ceiling. This policy
does not change test or inference deadlines. Record build elapsed time separately
from tests, the exact source revision, wheel SHA, extension SHA and every source
path digest. Never pair an earlier wheel's passing results with a new revision.

The Library's optional parallel package verifier runs the same canonical-path,
regular-file, per-file SHA and exact missing/extra-entry checks in independent
branches. It publishes no partial result after a branch fails and caches no
verification verdict. The Python adapter resolves a resource once within a check,
but resolves it again on its next use; aliases and same-length byte changes must
still fail. Matched profiling must use identical manifest bytes and file contents,
alternate baseline/candidate order, retain negative results and keep compilation
separate from timed performance measurements. A faster verifier is not evidence
of faster complete research execution.

Raw profiles, failed runs, process observations and regression receipts belong in
the Git toplevel `.cache/`. Component success is not complete-framework, current
graph, native Gambit, performance or exact-head CI acceptance.
