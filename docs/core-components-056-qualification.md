# Fixed Component C ABI Qualification 056

Status: partial mechanical qualification, not full consumer closure.

## Implemented

The fixed `ascent_core_open` capture accepts either `sources`, or `components`
and `entry`. Component records contain exact source bytes, explicit exports and
dependency bindings. The adapter forwards to the existing
`EvidenceProgram::read_components`; it does not interpret ordinary procedures,
link scopes in Python, restore a Scheme VM, or silently fall back.

Python `Engine.core_components` transports those captures through the same
gerbil-scheme-rust owned ABI contract. The actual installed-wheel tests cover
trusted admission, hidden bindings, replacement/withdrawal, independent immutable
results and owner closure. Graph naming is retained; no Plan alias was added.

## Exact Local Identity

- Wheel SHA256: `296f309c9a50f7f1f22a564b214d3817be4fc01b6d7703af5b33e935e67e3375`.
- Extension SHA256: `3e61f563f6b40a992f0c1d01df46b768bcd9167e0bf32d320d28ccb5faf338e9`.
- Research seal: `.data/research-engine-core-components-056-001`.
- Engine ID: `fc91580718657c8b1f118f6ecbd09ba9221f1cb53b49dd3baf56636cd0d78f1c`.

The wheel is locally built, not a Git-published dependency identity.

## Actual Receipts

- Fixed C ABI: policy plus six integration tests, exit 0, 38.708429/120 seconds.
- Wheel build: exit 0, 10.821448/120 seconds.
- Installation: exit 0, 0.114562/15 seconds.
- Installed SDK/Scheme-denied controls: nine tests, exit 0, 0.604718/15 seconds.
- Clippy all targets with warnings denied: exit 0, 0.944865/120 seconds.
- Matched wheels: three alternating pairs, 480 workload observations, full
  answers/inputs and per-path source inventory matched; exit 0, 25.064135/90 seconds.

For the 16384-row compute case with typed rows and four workers, baseline pair
medians were 34.640/34.090/33.868 ms; candidate medians were
34.055/34.254/35.771 ms. This is not stable acceleration or performance closure.

## Still Blocking

The previous full run had one publication-identity failure and five semantic
errors. This component ABI addition does not fulfill arbitrary ordinary
component procedures, mutable closures, `Engine.dsl`, or `match/for` semantics.
Those no-VM algorithm exports are absent; the old generic module dispatcher
initializes Scheme runtime and is not an admissible replacement. A host method
alias or fixture-specific implementation would not satisfy the contract.

The previous graph is not current qualification for this wheel. No unchanged
known-failing route was rerun or promoted. Git direct-url metadata was not forged.
All original failures and budgets remain intact.

Raw receipts, including wrong-workspace and denied source-read attempts, are in
`evidence/library/core-components-056/raw`; SHA manifest records archived bytes.
