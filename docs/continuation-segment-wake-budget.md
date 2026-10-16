# Continuation Segment Wake Budget

## Candidate Review Before Source Changes

The first private-segment successor retained the old single-chunk signal call
while publishing many chunks at once. If multiple peer collectors were already
waiting, that publication notified only one of them. Correct chunk conservation
does not prove preservation of parallel worker availability. This is a review
finding in our unqualified candidate, not a new upstream native failure report.

The refinement uses a saturating local count of eligible private chunks, bounded
by the current VM's processor count minus one. Under the unchanged wait-registration
mutex, segment publication issues that many notifications. Single-chunk ordinary
publication keeps its original single signal. No processor count is hardcoded,
no per-chunk allocation or PSTATE field is added, and no global broadcast or
queue-lock-over-copying path is introduced. GC cohort stability is a premise.

Notification is not OS scheduling. More notifications may help waiting workers
participate, but no performance improvement is claimed without measurement.
When fewer workers are sleeping, some notifications may have no recipient;
the original queue recheck and active-worker accounting remain necessary.

## Evidence

The finite model considers 2–4 processors and 1–5 eligible chunks. These are
proof bounds, not runtime host settings. The negative single-notification
control violates capacity at 54 distinct states. Saturating notifications pass
safety and no-stall, each with weak-fair progress, at 84 distinct states with
an empty exploration queue. The campaign took 11.167 seconds; checks took
3.782, 3.681 and 3.695 seconds under the original 15-second caps.

Portable evidence is in the append-only protocol manifest. The source exporter
reapplied all 22 locked files and checked every hash. Only `lib/mem.c` differs
from the private-segment parent; previous source locks and receipts are unchanged.
The reused thin source directory is still the only edited candidate tree.

| Artifact | SHA-256 |
| --- | --- |
| `evidence/fixtures/continuation-segment-wake-budget/source.lock.json` | `3f6f4a9c6714e8bd0d5d1c29d4ca21830e87959e73a65d87e0f25a00be8b2cdb` |
| `patches/fixtures/continuation-segment-wake-budget.patch` | `52234ec992414ebee30e2fd622cc5e6757af2321ddd3a24de67bd39c9387b9aa` |

GNU GCC syntax diagnostics passed with retained configuration dependencies.
That mixed-config check remains non-admitting. No current-source executable,
GSI/GSC workload, full bootstrap or release performance pass was produced.
The earlier public saved-stack regression remains prepared; its parent binding
does not automatically qualify this new source successor.

**Cumulative native completion remains 3/12, with current requalification open.**

## Current-Template Translation Unit Diagnostic

The reused candidate directory now has `include/gambit.h` rendered from its
own locked `gambit.h.in` by the retained bootstrap `config.status`. GNU GCC
16.2.0 compiled the entire successor `mem.c` to an object successfully in
0.460910209 seconds, with the current generated header first in the include
path. This is stronger than the prior old-layout syntax check, but still uses
retained configure substitutions/platform dependencies and is not a fresh
configured producer, linked executable, bootstrap or runtime qualification.

`compile-diagnostic.json` records source/compiler/header/configuration/object
hashes and the exact non-admitting scope. Generated header and object remain
disposable cache, not milestone authority. Their removal cannot reset 3/12.
`native-regression-contract.json` explicitly binds the existing public workload
to this successor without transferring any old native result.
