# Library Inventory Boundaries

The Python adapter caches inventory projections, not verification verdicts or
inference answers. A projection contains the original per-path mapping and build
metadata. It never replaces the complete source/resource inventory with one hash.

For a sealed request, the cache key includes the exact engine identity and caller
dependency declaration. The full no-follow seal inventory is hashed before and
after every request. Only paths present in that checked manifest can be projected.

For an installed wheel, the key includes loaded module origins, the complete
distribution entry list, all distribution metadata bytes, the dependency
declaration and publication lock. Each use checks canonical paths. Engine entry
and exit still hash every bound source, runtime resource and installed package
file. Changing bytes while restoring size or timestamps must still be rejected.
Callers receive copies and cannot mutate the cached projection.

The publication lock selects an explicit platform artifact. The Linux artifact's
producer is the recorded PR merge revision, not the dependency's historical source
revision. Its complete 186-file compiled source inventory was compared byte for
byte with the locked source inventory; that correspondence does not assert equal
producer revisions. The CI artifact ID and SHA-locked requirements file bind the
binary download. Missing platforms or artifacts fail closed: CI never compiles
ASCENT downstream or repairs it with SDK environment variables.

Raw profiles, failed runs, process observations and regression receipts belong in
the Git toplevel `.cache/`. Component success is not complete-framework, current
graph, native Gambit, performance or exact-head CI acceptance.
