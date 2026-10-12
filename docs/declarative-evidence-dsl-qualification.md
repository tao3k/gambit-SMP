# Declarative Evidence DSL Qualification

## Interface

The Library owns expansion, hygiene, imports and inference. The downstream
application sends definitions through Python/C ABI and declares sources,
outputs, relations and upstream rules with `define-evidence`. It does not own
Scheme package imports or compilation. Source bindings authorize replacement;
result bindings name native relations without restricting execution or value
representation. The default explanation records dependencies and current rows,
not per-row proof, causal review, retry eligibility or host authorization.

`evidence/dsl/catalog.ss`, `review.ss` and `history.ss` are the actual main-path
declarations. `investigation.ss` also declares its real inventory, source
bindings, result bindings, missing-field rules, aggregation and lattice directly.
Its runtime operator handles use a necessary native Fragment bridge, not a
single-use Fragment wrapping the whole scenario. History expresses insertion, withdrawal, retention and input
changes directly. Catalog and review include reusable rule groups; single-use
declaration/result wrappers moved unchanged to
`tests/fixtures/evidence-dsl-previous`. The dependency Actor uses upstream
`ascent` rules and its reusable transitive macro rather than constructing rule
terms by hand. The Actor's admitted positive semantics remain narrower than
the ordinary session's negation, aggregation and lattice capabilities.

## Current Local Observations

Candidate `ascent-provider-067-declarative-003` was actually built by Library
`build.ss`: GNU GCC 16, O0, build exit zero in 113.337536 seconds under the
original 120-second cap. Package and API generation also exited successfully.
Its API receipt binds 132 build inputs and 1265 loading resources. The Library
SHA is `88b07e401eae0a244af71f9778ad6ab26e4aeddc411d9449b4b2c6b48469ad5b`.
The unchanged CFFI glue does not imply unchanged Library code.

- Corrected focused declaration controls: 9 tests, zero skips, 5.518488/15.
- Complete Library matrix: 206 tests, 37 fresh processes, zero skips,
  28.192181/120; complete identity checks before and after matched.
- Actual main paths, history and investigation/Actor scenario: 14 tests,
  zero skips, 11.100020/15.
- Consumer audit: all original 26 tests, zero skips, 8.468300/15 after module
  scheduling across independent processes; one shared deadline, no reset caps.

These observations have actual final exits, timeout flags and process-group
quiescence in local raw receipts. They do not qualify a portable wheel, cold
compiler build, locked dependency installation or completed remote source CI.

## Preserved Failures And Remaining Gates

The initial build lacked the maintenance build dependency. Declaration control
001 exposed an unquoted result alias; control 002 exposed a fixture replacing
sources before its required initial completed run. The corrected macro and
fixture have distinct receipts. Baseline build 001 timed out at 120 seconds.
Consumer audit 001 timed out at 15 seconds while its four audit modules were
serialized; audit 002 changed scheduling, retained all cases and retained the
original shared cap. No prior receipt was upgraded in place.

Matched local performance 001 and 002 checked identical DSL, all 2352 source
facts, answers, withdrawal/restoration, and the real Actor scenario against two
fresh builds. Their 132 build-input names match; only the loader and Actor
optimization files differ. Performance 002 completed all three alternating
pairs and the scenario in 57.487770/90, with no timeout or teardown failure.
Its cold queries did not establish an improvement: all three candidate first
queries were slower in that sample. The first additional scope in the warm
runtime fell from approximately 88 ms to 25 ms; later warm scopes were similar.
Neither this result nor Actor whole-scenario timings isolate individual native
expansion phases or establish a universal speedup.

Candidate 004 changes Library import-context reuse, retaining fresh module
namespaces and private aliases. Its actual build/package/API are terminal
success (114.891304/120 build). Its complete matrix is 206 tests/37 processes,
zero skips, 31.768357/120. The actual modified declarative investigation and
main/history paths passed 14 tests in 11.732448/15. All 26 consumer audit cases
passed in 8.543032/15 with three workers and cleanup scheduled immediately,
rather than behind other native initializations. The four-worker attempt's
15-second timeout is preserved, not rewritten. Phase diagnostics separately
observed full audit completion in 7.275453/15 and the zero-budget child closing
in 3.134880/15; they do not replace the complete audit receipt.

Matching performance 003 includes three alternating pairs, identical complete
2352 source facts, withdrawal/restoration, independent backend identities and
the real declarative Actor scenario. It passed in 64.109921/90 with all exits
and teardown checked. First queries were approximately 2.9 seconds for both
variants in two pairs, with a slower outlier; the Actor whole-scenario samples
also did not establish a stable speedup. Cold-start performance remains an
explicit open obligation, not a completed optimization claim. Complete current graph
generation/readback and exact-head source CI remain separate gates. A focused
or scenario pass is not whole-consumer closure; no overall completion is
claimed here.
