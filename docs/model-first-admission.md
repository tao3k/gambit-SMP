# Model-First Repair Admission

Runtime edits follow a checked protocol contract, not merely a plausible patch.
The papers explain design choices; pinned source determines implemented behavior.
Neither a paper nor a green abstract model proves the C implementation correct.

## Review Before Runtime Changes

| Question | Required evidence |
| --- | --- |
| Is this the correct route? | Source boundary, paper-derived obligation and a distinguishing counterexample. Do not attribute an injected fault to current C without source evidence. |
| Was it already explored? | Consult the recorded PR reports, native failure manifest and retry gate. An unchanged denied route does not run again. |
| Is it worth changing? | Identify a correctness violation or measured cost. Correctness repairs cannot be sold as an unmeasured speedup. |
| What benefit is expected? | State the repaired protocol obligation and acceptance test; numeric performance expectations require measurements. |

## Protocol Coverage And Open Composition

| Boundary | Existing QNT models | Required source gate |
| --- | --- | --- |
| Copy, forwarding, payload readiness and scan ownership | `gc_forward_publication`, `gc_work_closure`, `gc_scan_claim_transfer` | Map special readers, continuation frames and exclusive scan acquisition to actual locks/barriers. Forwarding identity alone is not permission to scan. |
| Private work, queue handoff, termination and collection epochs | `ticket_queue_handoff`, `gc_scan_termination`, `gc_epoch_work_bridge` | Every producer stays accounted for until it can no longer publish; bind strong/weak phase barriers and actual wait predicates. |
| GC entry, roots and processor membership | `gc_sync_membership`, `sync_tree_rounds`, `vm_configuration_contract` | Freeze participating population for each round; demonstrate parking/root readiness before collection and rendezvous before new Scheme execution. |
| Resource initialization, caller rollback, retirement and reuse | `pstate_setup_transaction`, `pstate_resize_composition`, `sync_resource_users`, `sync_retirement_drain` | Preserve borrowed resources, unwind only initialized owned resources, clean successful predecessors, seal admission and drain holders/waiters/late signalers before destruction or reuse. |
| Continuation chunk frontier | `continuation_chunk_publication` | Establish complete copied frames and unique scan ownership before changing publication granularity. Its current model checks a policy, not these missing premises. |

These are bounded contracts with explicit assumptions, not one proven whole-Gambit
composition. Contract edges must be checked against source; naming both models
does not establish their compatibility. POSIX/Win32 initialization semantics,
partial OS/memory failures, interrupt producers, slot reuse and global VM teardown
remain separate obligations of the setup model.

The continuation frontier review also needs link finality, not just copied frame
contents. A producer may retain a prior frame-link address and update it while
copying the next frame. A scanner's temporary link rewrite/restore could race
with that update unless actual source exclusion or phase scheduling prevents it.
This is an open source-schedule obligation, not an established native failure;
changing only the allocation-frontier guard is not admitted by the current model.

GHC ISMM 2008 sections 3.1-3.6 and HotSpot JVM 2001 sections 3.1-3.3 inform GC
readiness, ownership and termination. They do not specify Gambit's processor
constructor or its borrowed VM0 mutex. Those obligations come from `setup.c`.
See `paper-source-obligations.md` for the architectural differences.

## Setup Transaction Verification

`evidence/pstate-setup-protocol.json` binds the cached paper text, source files and
paper-to-source review by SHA-256. The shared verifier checks five independent
fault controls and the positive safety plus temporal progress property. Worker
capacity is obtained from the host by the shared framework, not fixed here.

The model treats each setup stage as atomic and allows one failure per run.
Progress assumes weak fairness; it does not prove OS calls return, scheduling
fairness in C, or memory ordering. A green result permits a source repair review,
not native or release admission.

The context-bound run `pstate-setup-model-003` completed all five negative controls
and positive safety plus temporal progress: 68 distinct positive states, 80
generated, no queued states. Positive verification took 19.765 seconds; the five
counterexample checks took 46.161, 41.997, 45.875, 31.751 and 21.048 seconds.
The shared framework selected 12 available processors from the current host.
The focused framework checks passed 36/36 in 0.813 seconds; these are not native
Gambit tests.

The portable summary is
`evidence/model-results/pstate-setup-transaction-context-bound.json`. Its log
names resolve in the original `.data/pstate-setup-model-003` run directory; this
summary alone is not a reusable log-complete model admission. The unchanged
checks were reused after adding source/composition metadata, then published with
portable logs and counterexamples to `evidence/model-results/pstate-setup-model/`.
The Datalog index checks those logs, model, source context and temporal completion
before marking this protocol checked. Drift leaves the obligation pending.
Both forms deliberately record `runtimeAdmitted: false` and `releaseAdmitted: false`.
That first publication is now explicitly invalidated for current admission:
the rollback action has been strengthened to derive actual release targets from
live and owned resource sets. Invalid destruction is computed from that action,
not assigned solely from the control selector. Its replacement campaign
`pstate-setup-model-005` passed all five negative controls and positive safety plus
temporal progress (68 distinct states, 80 generated, zero queued, 20.641 seconds
for the positive check). Portable proof material is now in
`evidence/model-results/pstate-setup-resource-derived/`; old logs remain historical,
not current proof. The index binds this replacement and the 109-state resize
composition separately, preserving their source-refinement gaps.

The next current proof replaces that atomic rollback with explicit sequential
resource releases. Memory setup failure reflects the actual helper's already
completed OS cleanup. Two additional controls detect double cleanup of that OS
resource and freeing OS while memory remains live. Seven negative controls and
positive safety plus temporal progress completed in `pstate-setup-model-006`:
91 distinct states, 103 generated, zero queued; positive check 35.802 seconds.
Current portable material is `evidence/model-results/pstate-setup-helper-owned/`.
The preceding resource-derived receipt is explicitly invalidated for current
admission and preserved as historical evidence.

GNU GCC 16.2.0 also compiled and ran the unchanged extracted OS/memory helper
functions against mocked primitive resource ownership. OS failure leaves no
resource; memory failure already frees OS; successful cleanup frees memory before
OS; a deliberately unconditional second cleanup performs two invalid releases.
Compilation took 1.435 seconds and the four-scenario observation 0.738 seconds.
The fixture and portable receipt/log are registered in the main case manifest.
This validates the helper boundary, not partial allocator internals, real OS
threads or the complete runtime repair. No separate Python runner was added.

After model review: audit actual callers and platform contracts, perform extracted
source checks, then changed-route atomic native tests, multi-VM/GC tests, complete
bootstrap and Gerbil build/test. Report exact counts, revisions and elapsed times.
Only correctness-qualified candidates enter performance acceptance.
