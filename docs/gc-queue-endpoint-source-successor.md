# GC Queue Endpoint Source Successor

The source review enumerated five endpoint store sites: initial head/tail,
publisher tail, local pop head and remote pop head. All endpoint loads and
stores now use one local pair of access macros in GNU multi-threaded builds.
The unlocked hint uses relaxed atomic loads; payload links, pop and recheck
still retain their original locks and barriers. No field, ABI layout, global
lock, fixed processor limit or scanner serialization was added.

Single-threaded and non-GNU paths retain their original source behavior. The
new access-discipline model and qualification apply to the explicitly selected
GNU toolchain, not a claim about unsupported/non-GNU atomic semantics. This
is a correctness-contract repair, not a Darwin-only performance optimization
or a confirmed unique cause of the retained latency timeout.

The source exporter mechanically reapplied all 22 selected files from the
pinned submodule. Only `lib/mem.c` differs from the wake-budget predecessor.
Candidate mem.c SHA-256:
`38b69316dc682ac6771904a976af00547f9c628a78752e6448d3f1171be53dcd`.
Source lock SHA-256:
`02d2c5a9c679eb35c31b7f212851ac5ecfca827dd7994807db170f93fec75b5e`.
Overlay SHA-256:
`5adfd33e139d024b44fdabbd4f2deb4ef188d8ef0cf40ed81db092b94954daa5`.

GNU GCC 16.2.0 compiled the entire mem.c successor using the unchanged current
generated header and retained configuration. A separate endpoint diagnostic
passed lock-free static assertions; AArch64 assembly uses one `ldr` for load
and one `str` for store, without an atomic helper call or a new fence.
These are translation-unit/compiler diagnostics, not fresh linked acceptance
or an end-to-end performance measurement. Source-scope and changed-adapter
regressions passed 59 tests. Their overlay checks are lexical, not a C proof.

The bootstrap continuation retains the original 600-second qualification
budget and its predecessor's 218.226-second immutable DENY expenditure. It
requests 360 seconds from the remaining 381.774, through the existing canonical
ledger. Configure flags come from the same Bazel profile; make jobs use observed
host capacity. The existing workspace is reused, with no additional source copy.
Old producer and fixture passes cannot qualify this new mem.c. The cumulative
milestone stays 3/12 while current-source requalification is pending.

## Current Native Requalification

The first adoption was rejected before configure in 4.432 seconds because
generated cache files were not declared. The existing `seal_workspace_state`
API bound the complete current inventory to the new lock without qualifying
old executable bytes. A new immutable continuation reused that exact state;
the refusal and expenditure remain in the same canonical ledger.

The corrected six-stage bootstrap passed. All four phases ran twice,
`fullTwoPassBootstrapEstablished` is true, and make selected 12 jobs from host
capacity. The `from-scratch` command took 131.042 seconds, the entire bootstrap
stage 139.651 seconds, the child recipe 243.025 seconds and the complete outer
run 246.038 seconds. Configure itself took 53.461 seconds. The original 600
seconds remain unchanged: predecessor plus refusal plus new run charged
468.696 seconds, leaving about 131.304 seconds. No budget or refusal was reset.

`queue-endpoint-completed-producer.json` is a checked current-producer reference,
not an assumed reusable historical binary. Its outer receipt SHA-256 is
`f244e06d7ac9a7ad8b95dba8c6bb90d10bb8f355175575da8fd0bae1e723fd32`;
its child receipt SHA-256 is
`561b737e39557a49c9def3947b2106ce15a0af9b2c5b3d2f2e35e993e359a889`.

The full interpreted inventory then passed 380/380 standard and PR files in
65.385 outer seconds. The actual native suite stage took 12.875 seconds using
three workers and three processors per worker from the shared host plan.
The whole inventory, fixtures, assertions, known-failure manifest and case caps
were preserved. This requalifies the three already completed milestone gates
on the new source; it does not add a fourth gate.

## Complete Public Latency Grid

The original public VM/forced-GC workload then completed on the new producer
with all 4,002 samples across CPU-derived populations 2--5. Compilation took
2.167 seconds; execution 12.880 seconds; outer recipe 74.369 seconds. All 21
stages passed, no timeout occurred, and the process group was quiescent.
The original 300-second whole and 120-second native-step caps were unchanged.

| VM population | Samples | P55 ms | P99 ms |
| --- | ---: | ---: | ---: |
| 2 | 1,000 | 13.389 | 55.545 |
| 3 | 1,002 | 5.695 | 18.720 |
| 4 | 1,000 | 3.996 | 8.030 |
| 5 | 1,000 | 3.576 | 6.785 |

These are nearest-rank correlated trajectories, not confidence intervals or
release performance admission. One completed run does not establish stable
lifetime/fault coverage or uniquely explain the predecessor's 118-second
native timeout. That failure and its partial samples remain retained.
The earlier sampled diagnostic already completed in 18.836 native seconds,
so comparison to the timeout alone would overstate causal speedup.

Native raw latency SHA-256:
`1676124a0e3ccbfb3c2c85b68b9217672539bdcd21e9f485439806ec6085ad3c`.
Grid child receipt SHA-256:
`4b3c0938420c579306c2b97162dad462251915af3d3e4f70a9a4a2ecfe76e026`.
Full registry lifetime, lifecycle faults, GC/FFI, full GSC/stress, Gerbil and
release qualification remain open. Cumulative progress is still 3/12.

## Three Complete Grid Runs

Two additional unchanged full grids completed through the same current producer.
The original first-run 300-second ledger charged 74.369 seconds; the two-run
continuation charged 54.760 outer seconds, for 129.130 total, not a reset or
three separate expanded budgets. Source and producer validation were reused
within the existing framework, and prior finite checks were not rerun.

| Run | Native execution seconds | Complete latency samples |
| --- | ---: | ---: |
| First | 12.880 | 4,002 |
| Second | 12.631 | 4,002 |
| Third | 14.558 | 4,002 |

All three runs completed every CPU-derived population and original assertion.
The continuation's five stages passed, no timeout occurred, and its child
receipt SHA-256 is
`488174a0c27e5a42dcbb3e0fdce95822ac4e81e835ba9a7e2e5e567b50a133c0`.
The initial declaration lacked an explicit producer dependency for trial three
and was rejected before creating a run/reservation; the dependency was corrected
before execution. No native failure was reclassified.

Three successes strengthen current-producer stability evidence but do not prove
the unique cause of the old timeout, constructor failure rollback, every public
cleanup variant or complete GC/FFI. The full twelve-gate count remains 3/12.
