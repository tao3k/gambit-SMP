# Interrupt Prefix And Retained Slot Composition

## Source Order

The locked `sync-slot-retained-resources` Fixture calls
`setup_interrupts_pstate` for global VM0/P0 before `setup_os_and_mem` and before
cleanup is allowed through `setup_state`. `___setup_pstate` borrows this early
P0 prefix instead of constructing another mutex. Private VMs own their P0
prefix. `___cleanup` has a separate zero-processor global-prefix branch.

Consequently, a proposed interrupt ownership bitmap must not clear global
P0's borrowed flag during fresh VM initialization, nor release the borrowed
mutex as if it were a private processor failure. A global OS-setup failure
before cleanup admission needs its own owned-prefix release path. This is a
source-derived repair requirement, not a newly reproduced runtime failure.

The existing retirement-generation model already distinguishes failed joins
from successful retirement. This campaign did not repeat its old failure
route or treat corrected error identity as successful join/quarantine.

## Direct Composition

`interrupt_prefix_retained_composition.qnt` imports the existing
`sync_slot_retained_resources` model. The imported lock, publication, unlock,
signal, fast receive, child exit, reuse, admission seal and destruction actions
execute in the combined state. Interrupt P1 ownership remains live across
those exact old/new sync phases. This is stronger than an unexecuted
dependency edge; it is still not semantic C refinement or the complete GC.

The model covers borrowed global/private P0, private init failure, after-prefix
failure and early global OS failure, followed by distinct VM/global cleanup.
The active complete safety/progress check explores 208 distinct states, 340
generated and zero queued. Four controls have real exit-1 counterexamples:
erased borrowed ownership, P1 reinit, borrowed P0 destruction and forgotten
early global cleanup. The five-check campaign took 20.234 seconds with the
unchanged 90-second per-check budget and automatic control capacity.

The active manifest and portable receipt are:

- `evidence/fixtures/sync-slot-retained-resources/interrupt-prefix-design-contract.json`
- `evidence/model-results/fixtures/sync-slot-retained-resources/interrupt-prefix-early-global-contract/receipt.json`

The earlier 158-state composition omitted early global OS failure; its exact
receipt remains historical and is not the registered active bundle. Three
earlier DENYs were conversion errors: unsupported next-state field access,
an undeclared imported snapshot, and a local binding outside its lexical
scope. Their exact logs/models are archived separately. None is counted as
an accepted protocol counterexample. The imported model is explicitly hashed
and snapshotted; actions/invariants/progress were not dropped to obtain PASS.

## Remaining Conditions

Interrupt C ownership has not yet been repaired. Before implementation,
separate global ownership from fresh private VM metadata, retain live mutexes
through slot reuse, and close external interrupt admission before queue reset
or resource destruction. Preserve private failure rollback without destroying
borrowed global P0. Actual C/native caller checks must cover these branches.

Global/VM user drain and returning primitives are model premises. Every early
global setup stage, failed-join quarantine/result distribution, interrupt
payload semantics and foreign callback reentry remain unproved. The existing
five-stage pstate transaction is a contextual dependency, not imported as a
complete constructor proof here. No candidate C bytes were changed by this
composition campaign; full GC/bootstrap/Gerbil admission remains false.

## Reproduction

```sh
gambit-smp verify \
  --manifest evidence/fixtures/sync-slot-retained-resources/interrupt-prefix-design-contract.json \
  --out "$FRESH_MODEL_RUN" --timeout 90
```

Use a fresh output directory. The source context is the pinned submodule and
semantic Fixture overlay, never a numbered or disposable build-tree origin.
