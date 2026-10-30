# HostGraph Migration: C Responsibilities and Retirement Dependencies

Date: 2026-10-20. Architecture only. No implementation or performance/native
validation. Companion to the [generation contract](hostgraph-generation-contract.md)
and [source evidence](hostgraph-generation-evidence.md).

## 1. What Actually Moves

The unit of migration is an explicitly selected, rebuilt cohort: runtime,
kernel, libraries, foreign wrappers and modules used by that cohort. Do not
add a C0-to-new-runtime shim or an indefinite second semantic producer.
The old emitter may serve as a bounded migration reference until replacement
gates close. Keeping portable C output means maintaining the **new** C emitter;
it does not require continuing the old macro/module protocol in the new cohort.

| Existing responsibility / source | Retained Scheme/runtime authority | Zig destination | Required structural change |
| --- | --- | --- | --- |
| `_back.scm` target protocol; `_front.scm` entry context | Target negotiation, Scheme evaluation, GVM argument/result locations | Immutable resolved profile consumed by common planner | One profile authority; retain target feedback before frontend lowering (HG01-HG03) |
| `_gvm.scm` frame/live sets and slots-needed | Semantic liveness, closure dependencies, stack-frontier meaning | Validate and realize declared obligations | Do not port liveness into a second Zig analysis (HG03/HG05) |
| `_gvm.scm` purification/cloning | CFG semantics and anchor lineage | Validate frozen identities and membership | Add explicit exported-anchor reachability and transform rules, rather than relying on comments (HG04/HG05) |
| `_t-c-2.scm` call/jump/check/cache logic | Extract legal call/return/check placement, effect/budget and root-materialization plans | Instruction/cache/spill realization for C and LLVM | Split semantic completion from textual emission; late checks cannot remain hidden (HG06-HG09) |
| `_t-c-2.scm` return-frame construction | ret-var, root/protocol saved-state obligations and return kind | FrameLayout realization for both emitters | Separate semantic slots from alignment, map packing and descriptor bytes (HG08/HG10) |
| `_t-c-3.scm` maps/alignment and `_t-c-1.scm` descriptors | Profile definition and decoder obligations | One deterministic frame packer and descriptor emitter | Remove emitters' independent numbering/packing authority (HG10) |
| `_t-c-1.scm` C hosts/module rendering | Logical constants, module dependencies, setup/init meaning | New C/native host, resource, relocation and manifest emission | No whole `targ-dump` forwarding for selected products (D1-H R01) |
| `_kernel.scm` embedded control code | Handler semantics, environment, rest/key/force/foreign control behavior | Admitted typed operation/helper/control-region realizations | Extract control regions and symbolic role anchors; raw C strings are not semantic contracts (HG11) |
| `setup_kernel_handlers` numeric assignments | Runtime role definitions/required manifest and owner fields | Emit RoleBinding -> PointId -> materialized label records | Replace ordinal reconstruction with checked runtime binding (HG11/HG12) |
| `setup.c` module fixup/host query | Runtime publication, VM/global bindings, init effects and failure lifetime | Declarative fixup inputs and per-host point tables | Remove pc=0 metadata query and module-wide backend inference, preserve actual setup ordering (D1-H R03/R05/R09) |
| `_t-cpu.scm` C packaging | Native instruction semantics belonging to its producer | Direct native object + metadata/resource product | Remove `cpu.scm` C-backend dependency for native-selected output (D1-H R10) |
| Collector, VM scheduler, continuation machinery | Remain Gambit-owned under shared runtime contracts | Typed imports/layout declarations; native resource management only | No private Zig GC, collector replacement or use of native stack as Scheme continuation |

This is a refactor of the generated-C construction and runtime interface, not
a demand to rewrite all retained C helpers or GC algorithms in Zig. The gains
come from removing C as the only carrier of control/layout/module facts and
from deleting redundant generation paths. Zig is the chosen common subsystem
implementation; the semantic separation itself is an architectural decision,
not a property automatically granted by the language.

## 2. Ordered Replacement and Deletion Gates

All H rows below are **planned/open**. Source presence proves work exists to
replace; it is not a completed migration receipt. The predecessor column is a
dependency relation, not a sequence of implement-now instructions. E/A/SR gates
refer to [edge/module admission](d1h-edge-admission.md) and the
[shared-runtime gates](gvm-shared-runtime-contract.md).

| Step | Depends on | Replacement owner / concrete product | Old path that may retire in the selected cohort | Deletion gate and independent evidence |
| --- | --- | --- | --- | --- |
| H01: bind scope/profile | None | Scheme/config owner: exact cohort, profile, required role/operation/control-region census with source overlays | Duplicate implicit selection of target layout/call policy | One authoritative resolved profile; exact selected-domain denominator; no silent unknown input acceptance. M1-M12 config gates still apply |
| H02: explicit identity | H01 | Scheme: role declarations, AnchorIds, transform lineage, external roots | Comments/procedure names/label order as runtime-role identity | Every affected transform has a preservation rule and independent missing/duplicate/clone/merge controls; all required roles accounted for, not only the 15-row baseline census |
| H03: semantic completion | H01,H02 | Scheme: explicit calls/returns/checks, budget/materialize/reload operations, FrameSpecs | Semantic decisions executed only while generating C in `_t-c-2.scm` | Every admitted operation/exception/control edge has one semantic producer; no hidden checkpoint or codegen callback required downstream; root oracle independent of packer |
| H04: freeze/export | H03 | Scheme: versioned HostGraph closure, c-intf/runtime-control/init plans | C text/macros as sole transfer format for metadata/control facts | Graph closure, effect completeness, provenance and bounded amendment failure rules; unsupported opaque control rejected before code publication |
| H05: physical plan | H04 | Zig common planner: Host/PointLayouts and FrameLayouts with witnesses | Ad hoc C scanner label numbering and per-renderer packing in `_t-c-1/2/3.scm` | Independent decoder/coordinate/overflow checks, all RETN/RETT/RETI obligations, no competing layout owner; SR frame/root/capture gates remain open |
| H06: C product | H05 | Zig C emitter: C1 hosts, declarations, resources and metadata | Whole legacy C procedure/module renderer on the new managed C route | C1 required-tail/dispatch/root behavior separately admitted; E gates for C edges, no plain-return fallback; selected cohort never calls old whole dumper |
| H07: native product | H05 | Zig + MLIR/LLVM: N1 hosts and direct native product | `_t-cpu.scm` native-through-C packaging for native-selected output | Native edge admission plus mixed C1/N1 composition; no generated Scheme-host C or old dumper needed by native packaging; retained helper C is separately counted |
| H08: runtime bind/setup | H06,H07 | Runtime owner: per-host labels, checked runtime-role bindings, image/VM materialization | pc=0 host query, host-pointer identity, module-wide backend inference and handwritten runtime-role ordinals | E01-E12 and A01-A08 relevant closure; role signatures audited against every producer and consumer; code/maps rooted and failure-owned before publication |
| H09: close kernel/foreign domain | H03,H08 | Scheme/runtime/Zig owners jointly: all selected kernel control regions, FFI wrappers, reentry/escape and init paths | Selected embedded host-control macros and conversion wrappers that depend on old protocol | Actual caller census closes; conversions, errors, dynamic environment, callback roots and initialization order independently covered; no unclassified raw region forwarded |
| H10: delete old coupling | H06,H07,H08,H09 | Maintainers: remove selected legacy branches/call sites and regenerate cohort | Stable-ordinal workaround's dependency, old C host/module setup ABI and legacy packaging in the selected domain | Zero live callers after dependency analysis and qualification; clean rebuilt cohort; historical patches/failed receipts preserved; source disappearance alone is not behavioral evidence |

H08 integration can be developed with a smaller declared domain later, but its
retirement gate cannot be marked closed while H09 leaves users of the deleted
protocol. H10 removes a workaround only after its dependency has disappeared;
it must not delete unrelated complete-frame, stack-only check or masking fixes
from the same cumulative patch. No filename-level blanket patch deletion.

![Replacement dependency graph](hostgraph-retirement-order.svg)
[D2 source](hostgraph-retirement-order.d2).

The T01-T10 inventory in [D1-H](d1h-c-runtime-refactor.md) remains the broad
work inventory; H01-H10 refine its generator/identity/frame prerequisites.
These are not substitutes for configuration M1-M12 retirement: a new C emitter
still needs a qualified typed native request/toolchain route. Likewise, all
runtime publication/retirement changes must join the existing
[shared metadata owner](../shared-metadata-package.md).

## 3. Independent Acceptance Design

No acceptance workload is run now. Later evidence must separate producer
meaning, product encoding and runtime behavior, using matched identities.

| Obligation | Independent source of expected result | Required failure controls / scope limit |
| --- | --- | --- |
| Runtime roles | Runtime required-role manifest + manually audited source anchors/incoming contracts | Delete/duplicate a binding; clone/split/merge an anchor; wrong frame/revision/role; no oracle using final C ordinals |
| Semantic frame roots | Scheme frame/live/closure dependencies plus protocol saved-state rules | Omit closure env, protocol-dead register root or return-link; compare packer output through independently derived runtime decoder |
| Check/transfer completeness | Original source semantics and explicit allocation/poll/masking/control law | Introduce hidden collecting helper or cross-mask poll; no blanket equivalence solely against old generated C if old path is under repair |
| Physical layout | Runtime decoder/profile equations and coordinate-domain checks | Inline/out-of-line boundary, internal saved-state expansion, padding, large/overflow values, wrong units; same generator is not its own oracle |
| C/native product | Independently inspected final edges and point/frame metadata; mixed-cycle behavior | Plain-return C fallback, wrong LLVM convention, non-tail bridge, stale local membership; reuse E01-E12 rather than declaring layout evidence sufficient |
| Module/FFI behavior | Existing setup/init/foreign control semantics and A01-A08 cases | Reentry, partial effects/error ownership, VM mismatch, stale generations, capture keeping image alive; no fabricated rollback semantics |
| Actual retirement | Call-site/dependency inventory for the declared cohort, final artifacts and build graph | Trace old whole dumper, old host query or packaging path intentionally reachable; count fallback as failure, not success |

An extraction may preserve a baseline defect. Therefore source correspondence
and old/new equality are controls, not the entire semantic oracle. Historical
patches contribute failure cases; current repaired native acceptance belongs
to its own source lock/receipts and is not established by this design.

## 4. Quantified Engineering Targets and Benefit Boundaries

These are acceptance measures, not measured improvements. Denominators are the
selected cohort's complete census. Uncounted operations/regions/consumers keep
coverage unresolved; the 15 handler assignments are not that denominator.

| Measure | Required target / accounting | What it demonstrates; what it does not |
| --- | --- | --- |
| Semantic producer count per admitted operation/frame/role law | 1 Scheme-owned authoritative definition | Removes drift-prone duplicated semantics; does not measure compile speed |
| Frame packer count per profile | 1 common Zig planner, independent read-only checker | Common C/native layout source; two uses of the packer are not independent evidence |
| Legacy whole-emitter invocations on new managed routes | 0 | Real C generation replacement, not a Zig build wrapper |
| Hidden collecting/control points created after freeze | 0 | Metadata closure; a legal amendment produces a new revision and is counted separately |
| Handwritten numeric runtime-role bindings | 0 in the admitted domain | Removes ordinal coupling; local physical dispatch ordinals remain legitimate |
| Forwarded opaque legacy host-control regions | 0 unclassified regions | Genuine kernel/control extraction; retained ordinary C helper bytes are separately reported |
| Native Scheme-host generated-C bytes / C parse work | 0 for native-selected hosts | Eliminates that host-C generation/preprocess/compile stage; retained runtime/helper C and native IR costs remain |
| New managed C route preprocessing | Measure generated bytes, include/macro footprint and parse time later | Zig does not automatically eliminate C frontend work on the C route |
| Metadata duplication / edit surface | Count authoritative producers, consumers and files touched for a new role/frame revision before and after | Engineering leverage from fewer coordinated definitions; new schemas/checkers/provider maintenance add costs |
| End-to-end cost | Graph analysis/export + layout + C/native compile + link + metadata + runtime transition/dispatch | Unknown until matched measurement; LLVM optimization/MLIR passes may increase compilation cost |

The [N01-N10 replacement measures](gvm-native-replacement-matrix.md) and
[Q01-Q18 benefit/cost ledger](zig-modernization-benefit-ledger.md) remain the
broader accounting. Report attributable work removed and new work added before
claiming a net benefit. Zig's no-GC allocation model does not remove Gambit root
obligations, parallel-GC synchronization or VM lifecycle costs. Exposing typed
runtime/control/layout contracts can make future native/runtime refactors
possible; it is not evidence of automatic multicore speedup.

If a supposedly migrated route still asks `_t-c-2.scm` to discover points/maps,
uses old numeric handler bindings, or invokes the whole old dumper, the
corresponding retirement row remains open even when the executable works.
That is the concrete distinction between a new wrapper and the selected C-layer
reconstruction.
