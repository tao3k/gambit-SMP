# View source custody

The original `concurrent-gc/current.view.json` is retained unchanged as a
historical reference. Its source references point into a reused build workspace;
its configure.ac digest correctly rejects the subsequent Darwin source change.
Do not replace its expected digest with current workspace bytes.

`fdset-captured-032.view.json` binds copies of every original reference, with
unchanged SHA-256 values. The 23 locked candidate source files were reproduced
from revision 7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882 and the original overlay,
not copied from the changed workspace. The custody manifest records both the
original reference path and recovery path. Other references were copied only
after their original digests matched. This is historical reference custody,
not restoration of the complete runtime tree or native admission.

`darwin-source-032.view.json` independently binds the new source lock. It has no
observed flags, completed producer, native results or measurements. Consequently
the old fdset tests cannot satisfy its obligations. The registry exposes both
views rather than silently discarding history or merging candidate identities.

The registered `gc-transfer/fdset-observations-032.view.json` exposes the actual
Chez/Gambit comparison DSL relations in the main graph. Its five recorded runs
remain historical fdset observations, not results for the Darwin candidate.
Actual Library inference found six bounded shape classes, five repair
obligations, ten unproven boundaries and no missing source bindings. The new
candidate still needs its own source correspondence and matching tests.

The queue-endpoint baseline completed-runtime custody remains blocked by the
reused workspace. Its original standalone latency executable hash matches, but
this does not restore the complete source/toolchain/product identity. No direct
execution bypasses that gate, and no matched performance result is claimed.

Local receipts: `.data/view-custody-032-focused` (four real Library tests,
exit 0, 7.262/15 seconds; post-test summary printing failed and is retained),
`.data/gc-transfer-view-032` (actual DSL inference, exit 0, 2.239/15 seconds),
and `.data/view-custody-032-seal` (2512-file seal, exit 0, 4.726/15 seconds).
The seal captures framework identity, not a new Library build. These focused
observations do not establish full consumer, native lifecycle or performance
closure. Full graph validation remains an independent gate.
