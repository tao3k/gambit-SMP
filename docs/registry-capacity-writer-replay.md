# Registry Capacity And Writer Replay

## Source-Guided Composition

The earlier single-slot `vm_registry_capacity_replay` model already covers
release replay and late publication. The selected vector-arity source already
implements both; another source patch for that historical failure is unjustified.

`registry_capacity_writer_replay.qnt` adds writer closure, reader drain,
resource replacement and reopening to the capacity protocol. Two slots abstract
counter saturation, not host CPUs. A rejected signal publishes a coalesced
mailbox bit. Reader leave schedules a flush; flush obtains a fresh lease,
delivers, releases without recursion and rechecks. A writer cannot reclaim
resources while a flush lease exists. No-mutation executions ensure that a
future writer cannot accidentally hide a missing release replay.

Source authority is `evidence/fixtures/vector-increment-arity-parity/source.lock.json`
and its declared patch, on the pinned Gambit submodule. Correspondence:

| Model action | Candidate `lib/setup.c` protocol |
| --- | --- |
| `record` | pending-bit publication and immediate `vm_registry_flush` |
| `leave` | atomic reader decrement and pending recheck |
| `check` | `vm_registry_enter` refuses closed or saturated admission |
| `deliver` | mailbox exchange and delivery under a fresh reader lease |
| `rawRelease` | flush's raw decrement followed by its loop recheck |
| `close` / `replace` | writer closes admission and drains readers before mutation |
| `reopen` | ordinary writer opens and explicitly replays pending signals |

## Actual Framework Result

Recipe `registry-capacity-writer-replay-model` completed all nine steps in
27.035406 seconds under its existing 300-second budget. Inspection returned
PASS/CURRENT. Safety and `noStall` each explored 86 distinct / 337 generated
states, with zero states left on the queue. Both unsafe-policy checks produced
the required counterexample; all three declared trajectories passed.

The framework uses the existing ASCENT provider and locked source materializer;
it does not configure, compile a seed or rebuild a runtime. The first two
prelaunch proposals were rejected for missing test inventory and missing locked
source ancestry. These are recipe-admission failures, not runtime failures.

Model SHA-256: `d59730876f3b913bb203d71788f0f02937aadda7ddd7acaa7fc035a18fee06ef`.
Recipe SHA-256: `91e01ef35df54dd8c7f6c1bcec0f9e2c45d877767827fbe01b0a84a0dbc14518`.
Outer receipt: `a05c3e990720fd25e16578ccd83f550d343811ff133d13cb3cc2f42b49061871`.
Child receipt: `8c4208fbb33ffd3b9a936f05e350b76fadfdd282117dcc8d180f5a44c9e79944`.
Engine: `c8f96875355bd06ecb1f346d659e8a574d49d8e829fcb19485989343e87f9ffe`.

## Remaining Requirements

This is finite protocol evidence, not C memory-order refinement, unbounded
liveness, signal callback safety or a measured native saturation test. The
model covers one already-rejected interrupt, not every direct-admission path.
It assumes each acquired lease eventually executes its release; `noStall`
checks enabled transitions, not fairness. Terminal shutdown, pending join
retention, concurrent private constructors and direct PSTATE owners still need
their separate composition and native evidence. No registry-lifetime or full
SMP gate is promoted by this result.
