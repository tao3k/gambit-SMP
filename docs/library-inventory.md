# Library Inventory Boundaries

The Python adapter caches inventory projections, not verification verdicts or
inference answers. A projection contains the original per-path mapping and build
metadata. It never replaces the complete source/resource inventory with one hash.

For a sealed request, the cache key includes the exact engine identity.
The full no-follow seal inventory is hashed before and
after every request. Only paths present in that checked manifest can be projected.

For an installed package, the key includes loaded module origins, the complete
distribution entry list and all distribution metadata bytes. Each use checks canonical paths. Engine entry
and exit still hash every bound source, runtime resource and installed package
file. Changing bytes while restoring size or timestamps must still be rejected.
Callers receive copies and cannot mutate the cached projection.

`uv.lock` owns dependency resolution. The framework checks the installed
package's compiled inputs, resource hashes and RECORD, without maintaining a
second publication lock or constructing installer requirements. Earlier wheel
publication comparisons remain historical evidence, not an active install path.

Raw profiles, failed runs, process observations and regression receipts belong in
the Git toplevel `.cache/`. Component success is not complete-framework, current
graph, native Gambit, performance or exact-head CI acceptance.
