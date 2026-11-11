# CI historical evidence custody

The two `thread-completion-contract` historical failures are evidence, not
build caches. Their original failed runs cannot be recreated byte-for-byte on
a new host. A clean checkout must instead be able to revalidate the retained
failure observation, source identity, result and log hashes before ASCENT can
decide whether a new attempt is eligible. This is reproducibility of the
*review decision*, not a claim that the old runtime failure still occurs.

The eleven retained files have distinct roles:

| Files | Count | Reason to retain in Git |
| --- | ---: | --- |
| `observation.json` | 2 | Binds canonical failed receipt to the archived observation and exact field agreements. |
| `archive.json` | 2 | Declares the complete, hash-bound archive inventory and its non-admission status. |
| `receipt.json` | 2 | Records the original failed outcome, budget, scope and process observations. |
| `identity.json` | 2 | Binds the observation to the original compiler/source identity. |
| `bootstrap.log`, `gsi.log`, `processor-probe.log` | 3 | Supplies the exact logs required by the archive validator; the probe is part of the suite topology. |

`native_archive.validate` checks every member against the manifest, and
`native_review.historical_observation` compares typed fields against the
canonical failure. CI tests require these dependencies to be Git-tracked so a
dirty local cache cannot make a clean checkout appear complete. The archive
does not authorize a retry or admit native correctness by itself.

Transient runtimes, generated fixtures, repeated test products and process
logs not referenced by a retained evidence manifest stay under `.cache/`.
The retained eleven files contain no personal absolute path or detected
credential pattern; this content audit does not replace review before public
publication.

The `tfib-stress` CI recipe uses a per-stage, 1800-second *no-completed-work*
watchdog rather than a 300-second whole-run limit. The original interpreted
file emits no completed-file event while its single `(go 15 5000)` call is
running, so an inactivity timeout remains an incomplete observation, not a
deadlock finding. The unchanged stress workload and separate native
correctness gate remain in force.
