# Public VM Retirement Composition

## Decision And Scope

This is the public-interface part of the SMP qualification chain, not unrelated
History work or a performance claim. The parent source checks foreign frames
before public `___cleanup_vmstate`, but does not reject an active processor
cohort or retained failed joins before destroying synchronization and memory.
The private owned helper already checks those conditions. The public route is
required by the official-loader/FFI-only acceptance restriction.

The existing resource model assumed retired cohorts. This model checks that
assumption at the public entry, composing foreign admission, registry readers,
cohort membership, retained joins, OS release and memory reclamation. It does
not repeat known native timeout routes. Expected benefit is preventing unsafe
public teardown and establishing its admissible preconditions, not a measured
speedup. Healthy parallel GC, processor scheduling and foreign-call hot paths
are unchanged.

## Checked Model And Source Successor

`models/gambit/public_vm_retirement_composition.qnt` found both source-derived
negative controls: active cohort and pending join, each 13 distinct / 18
generated states. The proposed ownership guard passed safety and weak-fair
completion: 57 distinct / 101 generated states, queue zero. Rejected cleanup
retains storage; rejection is not successful teardown. Exclusive lifecycle
ownership, joined direct users and successful VM initialization remain premises.

The existing verification framework took 23.036 seconds. Individual checks
took 11.288, 11.447, 5.794 and 5.747 seconds, each below the unchanged
15-second cap. Concurrency was host-auto, not a model CPU constant.
The portable receipt, logs and counterexamples are in
`evidence/model-results/fixtures/public-cleanup-resource-ownership/retirement-composition/`.
The registered bundle binds the immutable parent source lock and patch.

The source successor rejects processor counts other than one and nonzero
pending joins before closing foreign admission or releasing resources. It
uses the existing public void API's fatal-error policy; this is not a new
recoverable error API or permission to silently free retained storage.
Pinned `lib/os_base.c:___fatal_error` invokes the configured reporter and then
exits the process. No extra lock or serialization is added to healthy execution.

Source lock: `evidence/fixtures/public-vm-retirement-composition/source.lock.json`
SHA-256 `4ea4de98d1f9ce4e0730fd85c567b1e8c2520d7d1ae003402217d2284c130571`.
Overlay: `patches/fixtures/public-vm-retirement-composition.patch`
SHA-256 `07814c673c45c2541d09bac7ce3e08bf54b99945eed5d9bd2f8bc6ccbb7527ef`.
The exporter reapplied all 22 selected files; source-lock validation and exact
candidate hashes passed. Only `lib/setup.c` changes from the resource-ownership
parent. The thin workspace was reused; no extra retained source tree was made.

The bundle fact loader admitted one checked model row, retained four open
obligations and bound 12 evidence inputs. This is not a full native ASCENT
graph evaluation. An expanded 48-test publication/source-audit/materialization
run finished in 6.276 seconds with seven source-audit errors. All seven fail
at the existing adapter's `_ascent_cffi` import. Further inspection corrected
the initial ABI-migration diagnosis: the installed binding still requires that
extension for its default API mode; `FFI().dlopen` is its separate explicitly
selected ABI mode. The missing default extension does not justify changing
the checked loader to ABI or assuming that API was removed. This is an API
artifact provision failure, not a Gambit cleanup regression. No import mock,
dependency repin or fallback was
introduced to report the expanded selection green. The failures remain open.
The publication/materialization-only selection passed 37/37 in 4.366 seconds;
it does not substitute for those seven failed source-audit cases.

## Remaining Native Requirements

The native successor is `models/gambit/native/public_vm_topology_grid.scm`.
Its SHA-256 is `43634b697790ea4642d576dac98a7fe67bf9c67b33473702c82d609aaa2019ad`;
the source successor lock and patch above are its required candidate identity,
not a claim that this fixture has already been executed on those bytes.
It exercises every host-derived topology from two children through
`floor((available CPUs - 2) / 2)`, distributes the remaining processor capacity
without fixed VM arrays, and keeps the previous grid's resize cycles, forced
GC, pinned workers, retained roots and thread joins. Global registry interrupts
continue until all child owners have completed teardown. Odd owners use public
VM cleanup directly; even owners first use public PSTATE cleanup. Before either
path, the returned VM must have one processor, no retained joins and no foreign
frame on P0. Both cleanup calls use the existing GSTATE public function table;
no research cleanup export, loader interposition or fault-injection hook is used.
Failure paths retain resources and fail the enclosing process rather than
setting accepted. The old private-helper fixture and its receipts are unchanged.

A retained Gambit reader read all ten forms successfully without evaluating the
fixture. This is a reader-only syntax diagnostic on an older producer, not C
compilation or current-source native qualification. There is no native PASS
receipt for this fixture. Full accepted execution remains downstream of a
qualified current-source producer and the existing causal review.
The public fixture, topology, endpoint ownership, publication and materialization
regression selection passed 49/49 in 3.910 seconds. These include static scope
tests, not actual C compilation, VM teardown or a substitute for native gates.

This source is not compiled, bootstrapped or accepted by native execution.
The model is not proof of the C implementation, hardware memory ordering or
whole GC. The new producer still needs bounded, source-bound qualification;
the public-only fixture route must then check normal retirement, rejection,
registry interruption and complete GC/FFI behavior. Do not run against an old
binary or privately exported cleanup helper to manufacture acceptance.

Cumulative milestone completion remains **3/12**. Complete GSC, PR/GSC,
stress GSI/GSC, registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness
and release performance remain open. Bootstrap/GSI/PR-GSI also need
requalification for this successor. Original budgets and failures are retained.
