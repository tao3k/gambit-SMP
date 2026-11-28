# Reproducible declarations and historical observations

## Repository boundary

Git maintains source, Scheme declarations, replay Recipes and validation
contracts. Runtime logs, execution receipts and their redacted derivatives are
Cache artifacts. Redaction protects paths; it does not make a historical run
reproducible. A raw SHA identifies bytes, not an available input or a successful
current qualification. The `native-archive` transport preserves originals,
verdicts and raw digest fields; its separate derivative manifest never grants
runtime admission. Do not copy that transport output into Git.

The original four missing references have these separate obligations:

| Observation | Maintained executable sources | Missing replay premises |
| --- | --- | --- |
| Root-signal comparison | `models/gambit/native/root_signal_retirement.scm`, `procedural_interrupt_retirement.scm`, root-signal cumulative patch | Complete baseline build identity and configured toolchain; external producer and real signal delivery; the historical checkpoint directory is not an input recipe |
| Constructor regression | `models/gambit/native/constructor_same_storage_emfile.scm` | Same repaired runtime, actual EMFILE fault, same-storage retry and forced-GC executions; a program hash alone does not establish these events |
| Runtime retirement | `models/gambit/native/runtime_join_quarantine.scm`, `terminal_registry_drain.scm`, runtime-retirement observation patch | Exact baseline and observed build identities, actual pending join/error and reader population; adversarial Darwin detach is not supported-program error reachability |
| Mechanism granularity | `tests/test_mechanism_granularity.py`, `test_retirement_repair_campaign.py`, `models/gambit/retirement_repair_campaign.qnt`, `models/gambit/lean/RetirementRepairCampaign.lean` | Regenerate the model/checker/Lean controls under their pinned tools and source closure; prior local process receipts are not replay inputs or native witnesses |

These are reproduction requirements, not a declaration that the historical
drivers already satisfy them. Their retained local observations are not rerun by
framework validation. The sources permit investigation and future replay; they
do not reproduce historical PIDs, durations, host paths or signal schedules.

## Currentness and history

The existing Scheme checkpoint rules already distinguish receipt assertions,
verified support, current bindings and material availability. Keep the historical
receipt identities as historical declarations, but withdraw their current
verification and binding when the only supporting bytes are local observations.
Native requirements then remain unclosed. Do not replace the raw receipt digest
with this document's digest and call the old run current. This document is only
the navigation and reproduction contract.

Formal model evidence and executable controls have their own scope. Neither
finite-state exploration nor a framework CI pass authenticates an unobserved C
execution. A clean checkout must load and query the declarations without
requiring private Cache content, and return the missing native qualification.
Session continuation must preserve that distinction; reading a contract does not
turn it into a runtime witness.

## Repair-quality and source handoff

Framework publication closure does not increase the native milestone count.
The remaining source obligations require the complete physical root graph,
every actual last consumer, and the C ordering from handler return through join
and handoff to reclamation. A new diagnostic, duplicate observation, smaller
abstract model or retained storage does not close those obligations.

Chez's retained/recycled carrier is conditional on its TC-mutex and collector
entry protocol. OCaml's ordinary backup-thread acknowledgement is not its forced
domain-cancellation path, and retained canceled-domain locks are not complete
cleanup or retry authority. Use the maintained source correspondence in
`handler-return-resource-order.md`; transfer the premises, not just an apparent
success marker. No runtime changes or native reruns are authorized by this
publication correction.
