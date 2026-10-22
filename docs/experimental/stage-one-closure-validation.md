# Stage-One Closure Audit Validation

## Scope And Identities

Local validation of the [closure audit](stage-one-closure-audit.md), not C/SCM
runtime changes, native correctness, source refinement or performance. The
native lane's source lock, Recipes, checkpoint, failures and runtime artifacts
were not modified or executed by this review.

| Input | SHA-256 |
| --- | --- |
| `docs/experimental/stage-one-closure-audit.md` | `ee2cdb2035bebd10aafc277325f670ac54e55a71895f479bfb57a0cdaa0b4b03` |
| `models/gambit/runtime_metadata_allocation.qnt` | `bdefd7fdf0d538a8704c922c1a07fb84cc855af06e4e9fe6363b7400f4bdf1af` |
| `models/gambit/ffi_gc_frame_protocol.qnt` | `1819e94cbd929e04db1e1d5bdc1ab15000cdc6083b5599eacc6cf2efc90ea5a3` |
| `models/gambit/lean/RuntimeEntryContracts.lean` | `fa23e8ba793ef6295ff25040ca1780de04ddc7903324137ce3044f23312b21a5` |
| `models/gambit/lean/controls/RuntimeEntryFalseClaims.lean` | `7763e2c581b68642f898903d083a869d3ec781a519e105815940671342f36001` |
| `evidence/scenarios/parallel-gc/runtime-entry.manifest.json` | `8770d803474bd8538a0b17afd2dbf18f48561ba4b45ad33cfa919f9547ad52ba` |

Both changed Quint files passed typechecking before TLC. Context inputs include
the versioned source lock/patch, pinned TTY/Geiser/reference source and unchanged
constructor/fixup/generation models. Generated C observations remain explicitly
unqualified as producers; no cache pathname became a source dependency.

## Model Results And Actual Counterexamples

The metadata model checked three **separate** profiles, not their combined
collector/allocator implementation. Its positive safety and weak-fair completion
passed over 316 distinct states (596 generated). All five expected controls
were observed, including the three original reservation/publication/rehash
controls and these two additions:

- Count-as-record: four-state trace ends with slots/count ready but `prm=false`,
  binding absent, a completed record observation and `badRecord=true`.
- Missing binding visibility: six-state trace ends with record initialized and
  binding present, but the required visibility edge absent and `badRecord=true`.

Both inspected traces have `badGc=false`. They distinguish the bad record
readiness inference from a slot-readiness failure; they do not reproduce a
particular native global/GC race. The visibility abstraction is a required
synchronization edge, not an axiomatic C11 memory-model proof.

The nested-root projection passed safety/completion over 22 distinct states
(28 generated). Four expected controls passed as controls: slot overwrite,
stale backup, caught-exit leak and stored-but-unmapped outer root. The new map
trace has three states: after relocation, the inner root becomes 12 while the
stored outer root stays 7 and is marked lost. A physical store is not proof
that the collector enumerates it. This does not establish a fault in the
inspected existing generated helper or qualify a future wrapper.

The unchanged original FFI projection was also checked at the final model
digest: all three old controls and positive safety passed. No native flags were
supplied. Other unchanged models were referenced, not rerun or admitted here.

Final new-projection receipts are accepted, context stable, without timeouts,
and retain `runtimeAdmitted=false`, `releaseAdmitted=false`, native `not-run`.
The existing verifier selected resources from host CPU/memory, rather than a
new hardcoded thread count. Per-check budgets were not widened; these model
durations are not runtime performance measurements.

## Lean And Existing Scheme Relations

Guarded Lean checked fourteen declared theorem/axiom inventories, with no
`sorryAx`; seven false claims were rejected as expected. The new Boolean
counterexample separates slot readiness from complete-record readiness. It
does not prove C ordering, generator correctness or native synchronization.

The existing Scheme component consumes the added caller/reader/publication
premises and partial model scopes. Session reuse returns the same answers;
source withdrawal exposes missing provenance and restoration recovers it.
Native obligations remain missing; `satisfies` remains empty. Python changes
are confined to the existing focused test, not an applicability engine.

Focused runtime-entry tests (three checks) and the unchanged parallel-GC
scenario check passed. The final facts also retain historical validations at
their original hashes; those are not relabeled as current-model admission.

## Receipts And Reproduction

Disposable raw receipts under `.cache/runtime-entry-models/`:

| Receipt | SHA-256 |
| --- | --- |
| `record-publication-scope/receipt.json` | `cce52961b534f67ca452b99806646c3fb6894580f3776555ca8f51683f65d76d` |
| `generated-root-map-coverage/receipt.json` | `ad2903dc04a3c4efb1bdf32393fa4242c1d5db0cdbebbfb99295b1ae13fa0bee` |

Successful guarded Lean observations under `.cache/runtime-entry-formal/run-0ij0bj0o/`:
`build.json` = `ced9a98073737559f9a618c44ffd83bb6e70755d77bcfcabca4a42c1a5528e5b`,
`axioms.json` = `f150b1645853c3ba2a93a43bb14f7395da3b4be3bceea4f159c5e005dd83ee46`,
`false-claims.json` = `382c7aac2b9ddd6a13cb70a7436f5c6c848d4029268be154fea6d8227c766f08`.
All exited without timeout and left quiescent process groups.

Use fresh output directories to reproduce from versioned inputs:

```sh
quint typecheck models/gambit/runtime_metadata_allocation.qnt
quint typecheck models/gambit/ffi_gc_frame_protocol.qnt
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case runtime_metadata_allocation --out .cache/runtime-entry-models/publication-recheck
.venv/bin/gambit-smp verify --manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json --case ffi_gc_frame_protocol --out .cache/runtime-entry-models/map-recheck
.venv/bin/gambit-smp check --case ffi_gc_frame_protocol --out .cache/runtime-entry-models/ffi-map-original-recheck
.venv/bin/python -m unittest discover -s tests -p test_runtime_entry_formal.py -v
.venv/bin/python -m unittest discover -s tests -p test_parallel_gc_evidence_scenario.py -v
```

## Revised Feasibility Boundary

The expanded census corrects the scope of the earlier narrower search: TTY has
a real internal C visitor, and Geiser has an allocating/global-creating raw-table
consumer outside the kernel fold. The reviewed kernel scan under `#if 0` is not
a live reader. No prior evidence was rewritten to imply it covered these paths.

Interning's permanent allocation is noncollecting, so preserving a leaf effect
envelope can avoid unnecessary new C root/service adapters. `fem_context.ps`
already exists for live fixup, but does not by itself establish startup readiness
or permission to enter collective service. This is a conditional lower-change
design option, not a verified new helper or a chosen lock algorithm.

For a complete first-stage shared-metadata claim, central reservation and whole
intern operations need every relevant reader, plus enabled global-record
publication/registry and fixup cell-address obligations. A symbol-only change is
not the complete package. Source-bound generated liveness, concrete C ordering,
native error/continuation/GC/TTY/raw-client behavior and original performance
gates remain open before adoption. General parallel loading, attachment and
generation replacement stay separate milestones. No native progress is claimed.
