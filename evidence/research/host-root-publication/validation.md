# Host Root Publication And Lifetime Validation

## Exact Inputs And Command

| Input | SHA-256 |
| --- | --- |
| `models/gambit/host_root_publication_lifetime.qnt` | `e85a3ca15b6928ce4724110ccf6132b117c267ed195410fa4df57935895ffe92` |
| Imported `vm_list_c_memory_order.qnt` | `e90a4ed7d68935a37ec0bf8a45412f19b6fa3f6261f4d84a96cad6a9007d1075` |
| Imported `vm_list_reader_retirement.qnt` | `7bb56b5964657b7b7f7f41096c629a0882e00a89f6dbf9fffde5407cf27f5952` |
| `models/gambit/lean/HostRootPublicationLifetime.lean` | `3d593eb3a809e71d3d88723b7353798f53ede55ec83ae94d5de11a6134bbeb6c` |
| Imported `WorkAccounting.lean` | `7d6a00be12e01ad2283469df505f4e728468356db927c6df0c2b1eecfc113f0e` |
| `manifest.json` | `2c61bbcf8c2776c22d9c35c2577a3bc2a16d8d7eaa69873f965d118a000d8493` |

```sh
.venv/bin/gambit-smp verify \
  --manifest evidence/research/host-root-publication/manifest.json \
  --out .cache/host-root-publication/verify \
  --timeout 30 --tlc-liveness final \
  --tlc-jar .data/tools/apalache-0.62.1/lib/apalache.jar
```

The existing verifier completed in 66.984 s with `accepted=true`,
`contextStable=true`, `runtimeAdmitted=false` and native status `not-run`.
The manifest binds the pinned primary source files and model dependencies;
all inputs stayed unchanged. No other formal or native campaign was rerun.
The output directory is a receipt locator, not required source. For a new run,
use an unused receipt directory rather than overwrite it; the existing verifier
can reuse a matching receipt with `--resume-from`.

Host-auto resource selection observed twelve available processors, two control
jobs, six TLC workers per control and twelve for the serial positive check.
Those are observed scheduler choices, not configured CPU limits. Each check
kept the 30 s guard; no budget or watchdog was widened.

## QNT Results

| Initializer / property | Result | Seconds |
| --- | --- | --- |
| `initFixed` / `safe`, `completion` | Exhaustive finite safety and final-scheduled weak-fair progress: 16 distinct / 20 generated states, zero queued. | 13.659 |
| `initMissingRoot` / `rootCensusSafe` | Expected incomplete-census counterexample; initialized publication is not a complete declared root set. | 15.095 |
| `initReleaseOnly` / `publicationSafe` | Expected one-sided-publication counterexample from the imported visibility abstraction. | 15.019 |
| `initCollectorDoneAsHostDone` / `hostTailSafe` | Expected premature-cleanup counterexample while the host can still return. | 21.569 |
| `initFixed` / `noInactiveScan` | Expected witness: inactive host, scanned roots, live record. | 22.474 |
| `initFixed` / `noCompleteCleanup` | Expected witness: actual last host use followed by record reclamation. | 15.230 |

All six checks were accepted without timeout. The last two are counterexamples
to negated reachability predicates, not failed corrected protocols.

The decoded last-use counterexample has `h.phase=1`, `scanned=true`,
`lastUse=false`, both declared roots saved, and `L_s.reader=done`,
`writer=done`, `alive=false`, `invalidRead=false`. The independently instantiated
publication state has `acquiredInit=true`, `seenInit=true`, `reader=done`, no
mixed access and no payload race. Both imported protocols satisfy their own
invariants, yet the host lifetime condition fails. This is the precise extra
consumer missing from scanner-only discharge, not a reproduced native UAF.
The invariant detects dead backing storage before the host's actual read;
`badHostUse` is still false in that trace.

## Lean Results

The focused guarded command was:

```sh
.venv/bin/python -m unittest \
  tests.test_host_root_publication_evidence.HostRootPublicationEvidenceTests.test_guarded_lean_contracts -v
```

It passed in 4.246 s. The existing process observer ran Lean with 200000
heartbeats, recursion depth 512 and a 15 s process guard. It exited 0 without
timeout, with `group_quiescent=true`. Five declarations passed; printed axiom
sets contain only `propext`, `Quot.sound` or none, and no `sorryAx`.

The two general contracts quantify over arbitrary consumer and slot types;
they require caller-supplied complete host/scanner censuses, publication and
retention. The remaining declarations provide logical counterexamples and reuse
`WorkAccounting`'s root/mutation distinction. This is not a proof of actual C
memory ordering, a complete heap graph or a refinement of the entire QNT.

## Custody And Handoff Boundary

Raw TLC receipts, snapshots, compiled TLA/CFG and decoded counterexamples remain
under `host-root-publication/verify`; the first Lean receipt is
`host-root-publication/lean-52p1oxx7`. No failed native route or history was
removed. There was no failed check in this formal campaign.

The [Recipe](../../../docs/host-root-publication-recipe.md) maps OCaml's saved
inactive roots, mutex publication, successor owner and terminal admission, and
Chez's activation/root generator/collector/cleanup chain. The imported models
were not edited. General host registration and carrier/epoch redesign remain
in [Experimental](../../../docs/experimental/host-root-registration.md).

This bounded current-repair composition does not claim arbitrary host attachment,
actual candidate root completeness, physical relocation/reload, supported
nonlocal exits, allocation-failure recovery or native performance. No runtime,
source lock, native fixture, bootstrap, pressure test or other acceptance lane
changed. In particular, this result does not increment 9/12.

The host's phase 3 means its final access to this particular record, not a
universal end-of-C-call or OS-exit deadline. Some argument/root slots can be
released earlier once their actual successor/last use is established; unrelated
origin C-tail storage can need a later deadline. This model applies only to a
record the host still needs after the scanner finishes. It must not justify
blanket root retention or claim that all current RC callbacks have that access.
