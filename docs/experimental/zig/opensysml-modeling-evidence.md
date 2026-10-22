# SysML / OpenSysML Modeling Evidence and Qualification Limits

Read: 2026-10-20. Research HEAD
`b67da6262a973a0ae898002d5c7f5be2d8b5a90d`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
These are source/read identities, not installed or native-qualified profiles.
The [modeling design](opensysml-architecture-modeling.md) and
[unvalidated model](modernization-architecture.sysml) are proposals.

## Primary Tool and Standard Evidence

| ID | Primary source / inspected scope | Supported fact and limit |
| --- | --- | --- |
| SM01 | [OMG SysML 2.0 catalog](https://www.omg.org/spec/SysML/2.0/About-SysML); [language specification](https://www.omg.org/spec/SysML/2.0/Language/PDF), sections 7.12-13, 7.18, 7.21 | Ports/interfaces, states and requirements have language definitions. Requirements combine assumptions and required conditions. Modeling a condition does not prove an implementation satisfies it. Selected sections read, not a whole-spec conformance audit. |
| SM02 | [OpenSysML ecosystem](https://opensysml.org/) | Go REDK, Rust toolkit, OMG pilot and model store are separate projects. Choose a concrete implementation/version and supported subset; no single generic OpenSysML capability or qualified local installation is established. |
| SM03 | [OpenSysML README](https://raw.githubusercontent.com/Open-MBEE/OpenSysML/develop/README.md), Overview and runtime status | Go runtime offers instance/calculation/action/state execution and budgeted schedule exploration. A default run chooses a linearization. Its SMT solving is experimental. These are upstream documented facilities, not runs of Gambit models or observed local capabilities. |
| SM04 | [OpenSysML compliance ledger](https://raw.githubusercontent.com/Open-MBEE/OpenSysML/develop/docs/project/spec-compliance.md), Current Status; What Can't Be Claimed; schedule observations | Behavioral conformance is self-assessed; pilot differential cannot referee token-flow concurrency. Verification verdicts, variant selection and view rendering have tool-defined aspects. Budget-limited exploration remains incomplete; a found violation can still refute a model. No percentage or full conformance transferred. |
| SM05 | [Rust sysml-toolkit README](https://github.com/Open-MBEE/sysml-toolkit), Calculation/Static Boundaries and Known Limitations | Static checks, interchange and a decidable SMT fragment are documented. Behavioral execution is absent; unsupported/undecided expressions must stay explicit. A successful parse or round trip is not a behavioral witness. |
| SM06 | [OpenSysML architecture](https://raw.githubusercontent.com/Open-MBEE/OpenSysML/develop/docs/internals/architecture.md), layering and self-model paragraph | Tool architecture separates syntax, semantics, checks, execution, translation and views; it documents its own SysML self-model. This supports a modeling approach, not correctness of its execution semantics, interchange with another tool or our model. |

Rolling `develop` and GitHub pages are read-time documentation, not content-pinned
binary/library/solver cohorts. No installation/build/API/solver command was run.
Code and written-content licenses differ across projects; any future vendoring or
redistribution needs the actual selected project/library license inventory.

## Repository Correspondence Read This Turn

| ID | Direct file / reviewed scope | Consequence for our model |
| --- | --- | --- |
| SM07 | [research.ss](../../../evidence/scenarios/zig-native/research.ss):1-100; [current declarations](../../../evidence/scenarios/zig-native/research.view.json) | Claims/citations/dependencies/requirements/witnesses are distinct. Evidence-class matching and missing requirements matter. Keep model-to-claim mapping separate; model assertions cannot automatically become a matching-class witness. Engine and declaration files unchanged by this update, not evaluated. |
| SM08 | [gambit.h.in](../../../vendor/gambit/include/gambit.h.in):8059-8086; [mem.c](../../../vendor/gambit/lib/mem.c):6839-6863 | Saved-root macros store/reload/clear slots; inspected vendor mark_rc call is inside P0 block. Explicit publication, enumeration and current-vs-proposed ownership are needed; no new fault or root-domain implementation inferred. |
| SM09 | [_t-cpu.scm](../../../vendor/gambit/gsc/_t-cpu.scm):162-179; [full architecture](modernization-system-architecture.md):sections 2-7 | Native assembly is packaged using the C backend in inspected source. Direct native products, shared semantic producers and compiler-process/runtime-SDK separation are proposed replacement seams; obligations remain after C text disappears. |
| SM10 | [full evidence](modernization-system-evidence.md):MS01-MS10/MP01-MP12; [leverage matrix](modernization-leverage-matrix.md):LM01-LM14/FD01-FD09/AG01-AG07 | Preserve prior source/paper limits and fair C-full/Z-full comparison. These identifiers trace architecture and costs; they are not executed SysML nodes or newly satisfied gates. |

The partial guard model deliberately does not claim weak-memory refinement,
complete roots/FFI/continuation coverage or cost bounds. All five current Q-full
requirements remain unwitnessed by this update.

## Fetch and Evidence Boundaries

The old `opensysml.org/guide/02-first-model/` path returned 404; the old internals
path and several runtime-site paths could not be fetched. GitHub README links
identified the actual project documentation. The large GitHub compliance page
exposed file metadata only; its raw.githubusercontent.com source succeeded.
The OMG simple-vehicle download link returned document-not-found through the
web interface. The normative PDF and official pilot requirement/calculation
example text were readable; notation was reviewed from those, not parser-tested.

No availability failure is interpreted as a missing modeling capability. Public
docs contain differing rolling inventory counts; none is used as a coverage or
performance denominator. No upstream benchmark or verification claim is adopted.

The current research view has a pre-existing generated source/binding pair:
`research.view.source.json` and `research.view.binding.json`. Its bytes differ
from receipt 13's historical view hash. The materialized facts match the current
source declaration; the imported NJS driver now points to a retained snapshot
with the same `07a17564...` source digest. This update preserves that provenance
work and records current hashes rather than rewriting receipt 13. The binding's
`engineEvaluated: true` is another producer's metadata, not a model evaluation
performed here or a new result adopted by this study. No claim of semantic
identity to the unavailable historical view body follows from equal row counts.
