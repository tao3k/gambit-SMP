# Evidence as a Scheme Module

`investigation.ss` is an ordinary Gerbil module. Its exported
`make-investigation` constructor returns an Evidence module containing a native
Program, explicit source/operator handles, and a separately owned explanation.
The Python boundary transports arguments, facts, identities and handles only.

The real consumer is `gambit-SMP/evidence/scenarios/investigation/entry.json`.
It uses the complete canonical failure inventory and original receipt-bound
observation fields, not invented fixture facts.

## Composition

```scheme
(import :gerbil-ascent/evidence/interface "dependency.ss")

(ascent
  (include (make-dependency-relations))
  (include (investigation-relations))
  (include operator)
  (bounds 4096 32768 32768))
```

`dependency.ss` exports a hygienic DSL macro and reusable relations. Fragment
remains a composition unit inside a module constructor, not the consumer's sole
entry. The native operator projects complete three-column contracts using
actual exported handles; native rules compute their recursive closure.

The scenario also uses negation for absent metadata, upstream
`gerbil-ascent-count` aggregates, and a max lattice. Source replacement withdraws
an actual receipt field and restores it in the same upstream session. This
checks deletion invalidation, not merely positive operator insertion.

The 041 historical run compiled these modules in the provider build. That was
not the final Library ownership contract. These files are now downstream-owned
DSL assets; consumers must only import the Python Library, with no `gerbil.pkg`
or Scheme compile workflow. Full module-source loading through that interface
is not yet implemented. Its trusted-code authorization gate is still open.

## Execution and Explanation

The explanation callback returns native Scheme objects with complete current
scenario source rows, declaration dependencies, source generation and a stated
proof gap. Native value graphs preserve those objects and opaque handles.
Execution does not depend on scalar JSON or per-row proof projection.

These are recorded observations and declared dependencies, not causal review,
retry eligibility, source refinement or host authorization. Arbitrary trusted
Scheme exports remain subject to host compilation and execution authorization.
Closing a module releases owned references; it does not magically close external
resources created by arbitrary Scheme code.

The actual 041 consumer run observed 37 inventory entries, 12 raw failures,
32 metadata gaps, 18 transitive dependencies and 3 recorded control references.
It exercised repeated queries, withdrawal/restoration, aggregate/lattice
invalidation, explanation ownership and session teardown. The separate complete
Catalog/review/history migration and history capacity obligation remain open.
