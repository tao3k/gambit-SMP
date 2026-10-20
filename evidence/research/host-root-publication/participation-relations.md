# Source Handoff Relation Validation

The final source-bound regression passed **7/7 tests in 19.277 seconds**, exit
0, through the existing `workspace run` interface in campaign
`host-root-research`. There was no source copy, native build or native test.
The earlier seven-test run also passed in 7.375 seconds before JSON-only
formatting; its byte identity is not substituted for the final one.

## Inputs

| Input | SHA-256 |
| --- | --- |
| `participation-facts.json` | `c540ede31f0a8aea104330d58c1ce41ee25971b174b6412c2c65b9770c0f05bd` |
| `participation-validation.md` | `95c0b7d88321e368431849f3eee9e05d5763f7c9d76565f06cfadd3eec391662` |
| `participation.manifest.json` | `9ef169f5e75ac42387e407a1cfef2a59c9b5f733fda925bddbc4c3d306f93230` |
| `models/gambit/host_root_participation.qnt` | `e24c2ce90f6264d5bcba6d4c72da46ccc56c11405d6b1b7725fa6bd6b6b2730e` |
| `models/gambit/lean/HostRootParticipation.lean` | `e5ce61239be5d9012b899f22b1f4e744886a78e08c63035bf60451ab564f1193` |
| `tests/test_host_root_publication_evidence.py` | `61bfc398436af1f49f6bf470859c9263c9c4d0789fbeac278f2ef62e8856095c` |

The facts bind 26 primary/model/receipt sources. The test hashes all referenced
inputs before and after evaluation. No evaluator or production Python/Scheme
rules were added; the existing `parallel-gc-design-facts.v1` relations and
`make-parallel-gc-review` constructor were reused. Python remains the existing
test/host adapter. The Lean test helper was parameterized for the additional
proof rather than copied; both proof files and the older repair/redesign
relations passed in the same final regression.

## Exercised Boundaries

- Both transfer conditions have source-bound reference and Gambit sections.
  OCaml supplies the saved-state/ownership/domain-service chain; Chez supplies
  the collection-entry/generated-root interpretation chain.
- `final-root-state-handoff` remains `source-composition-unbound` after its
  QNT and Lean interface checks. No native candidate correspondence is supplied.
- `complete-supported-root-graph` also remains `source-composition-unbound`.
  Its unchanged census/lifetime abstraction and conditional proof are reused
  from their earlier exact-hash validation, not relabeled as a physical census.
- Withdrawing each of the 26 source identities exposes an unbound transfer
  premise. The same two obligations and composition requirements remain owed.
- Withdrawing the interface checks changes both gaps to
  `model-check-unbound-or-stale`, never to closed. Restoring the facts restores
  the original result; native obligations do not disappear on either path.
- `composition_link`, `composition_binding` and `satisfies` remain empty.
  Empty bindings express missing source refinement, not complete qualification.
  All model scopes remain `partial`.

The existing Experimental registration/carrier/epoch Recipe and its partial
models remain separate and unchanged. No new foreign-thread attachment,
backup-service mechanism, root ABI or TLS/locking design is selected here.

## Handoff And Remaining Work

The current implementation thread can use the source map to bind its exact
supported entry/configuration, physical root producers, execution handoff,
observer ordering, resumed generated state and per-record last consumers.
The bounded formal controls identify why these cannot be replaced by just
record registration, an interrupt request or a collector-done flag. They do
not prove that the active native failure has one of those causes.

Historical and current formal results, full-current graph review, native
correctness and performance remain distinct. This research adds no completion
to the other thread's reported 9/12 and does not reclassify its open gates.
