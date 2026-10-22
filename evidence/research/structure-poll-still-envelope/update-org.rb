p='dev/modeling/component-assurance.org';s=File.read(p)
s=s.sub('they own 90 needs, 248 direct prerequisites','they and [[file:../architecture/runtime/gc/models/sysml/structure-poll-still-envelope.sysml][the POLL/frame/still refinement]] own 96 needs, 272 direct prerequisites')
s=s.sub('The 90-need, 248-edge prerequisite view','The 96-need, 272-edge prerequisite view')
s+=<<~ORG

* RESEARCH Structure slow POLL, recursive frames and still allocation
:PROPERTIES:
:CUSTOM_ID: structure-poll-still-assurance
:STATUS: scoped-models-checked-source-and-effects-closure-open
:END:

[[file:../architecture/runtime/gc/structure-poll-still-envelope-design.org][The real continuation of the structure chain]] adds six needs and24 dependencies.
The selected graph is96 needs,272 edges,44 source routes and8 shared contracts.
The runtime ancestor cut is80 needs/249 edges; build/resource-exit remains56/123.
Their exact union is checked. Source routes and shared-contract metadata are
projected without qualification in a third request. Lossless paired receipt
transport avoids raising the unchanged ASCENT form limit; all identities,
scopes, statuses and conjunctive prerequisites remain independently checked.

#+NAME: structure-poll-still-closure
| Slice | Local evidence | Source / environment gap | Benefit and physical boundary |
|---+---+---+---|
| SP-H |18 QNT histories plus bounded positive simulation |254-frame batching, unknown-footprint and root-state source refinement | Abstract units and held upper envelope, not native peak evidence |
| SP-I |17 exact conditional Lean statements | Configured GVM/ABI, complete phase/capture/callback and physical identity premises | Frame stack8 vs heap7 already exists; no newly saved byte inferred |
| SP-POLL | Saved RETI -> stack_limit/GC -> installable interrupt -> internal return | Complete callback/exception/retry/capture budget and new binding | No finite whole-call cap from a alone |
| SP-FRAMES | Section selection, transfer post-check, captured frame and undo located | Complete actual descriptor and alias/reader closure | Pool/VM section assignment need not acquire/free backing |
| SP-STILL | Deferred/VM/GC, malloc, initialization, error/retry and sweep located | No safepoint ack until initialized; known root/result ownership and profile | charge a+6; conditional ordinary WS8 allocator request8a+63<=65599 |
| SP-PEAK | Phase maximum and transitive missing-evidence controls | Actual acquired/container sums across all participants and unknowns | Qg must omit actual acquisition; it cannot directly pay a separate still block |
| Current selected composition |36 local formal slices,34 inherited with unchanged subjects/scopes/digests |47 source-simulation plus13 platform/environment/order needs |0 complete/native components,0 retired runtime paths |

Native validation is scoped to the predecessor50 SysML files plus the new model.
A failed whole-DEV attempt found syntax errors in a concurrently edited,
unselected foundation-binding model; retained diagnostics forbid a whole-DEV
pass claim. Root runtime/model/patch bytes and the predecessor receipt remain
unchanged. Existing unrelated work was not repaired or reverted.
ORG
File.write(p,s)
p='dev/modeling/assurance-planner.org';s=File.read(p)
s=s.sub('--task rest-gc-resume-envelope trajectory clues < dev/modeling/ascent/component-assurance.request.scm','--task rest-gc-resume-envelope trajectory clues < evidence/research/rest-gc-resume-envelope/case-current.request.scm')
s=s.sub('--task rest-gc-resume-envelope trajectory clues < dev/modeling/ascent/component-assurance-build.request.scm','--task rest-gc-resume-envelope trajectory clues < evidence/research/rest-gc-resume-envelope/build-cut/case-current.request.scm')
s=s.sub('--task rest-gc-resume-envelope trajectory clues < dev/modeling/ascent/component-assurance-routes.request.scm','--task rest-gc-resume-envelope trajectory clues < evidence/research/rest-gc-resume-envelope/source-routes.request.scm')
s+=<<~ORG

** RESEARCH Structure slow-path envelope and receipt transport
[[file:component-assurance.org::#structure-poll-still-assurance][The selected frontier]] has96 needs/272 prerequisites/44 routes. The ancestor
inference cuts preserve the exact union. Shared contracts and source routes are
projection metadata in the third request; they never qualified a proof. Actual
DSL receiptPairFact expands each tuple to its independent receiptFact with exact
artifact/digest/method/check/scope/status. A form-bound failure is retained; the
engine limit and all native dependency edges are unchanged. Missing source or
transitive HR-BIND, wrong scope and stale digest still block upstream eligibility.

#+NAME: structure-poll-still-assurance-read
#+BEGIN_SRC sh :eval never
.venv/bin/gambit-smp --task structure-poll-still-envelope trajectory clues < dev/modeling/ascent/component-assurance.request.scm
.venv/bin/gambit-smp --task structure-poll-still-envelope trajectory clues < dev/modeling/ascent/component-assurance-build.request.scm
.venv/bin/gambit-smp --task structure-poll-still-envelope trajectory clues < dev/modeling/ascent/component-assurance-routes.request.scm
#+END_SRC
ORG
File.write(p,s)
{'dev/architecture/runtime/gc/index.org'=>"\n* Structure slow POLL, recursive frames and still allocation\n[[file:structure-poll-still-envelope-design.org][The next real source segment]] covers internal return, interrupt effects,
recursive stack/heap frames, section assignment and independent still backing.
[[file:structure-poll-still-envelope-matrix.org][The native matrix]] separates conditional bounds, existing reuse and real Qg credit.\n",
'dev/architecture/runtime/gc/models/quint/index.org'=>"\n* Structure POLL and still constructor custody\n[[file:../../structure-poll-still-envelope-design.org::#structure-refinement][SP-H]] binds [[file:../../../../../../models/gambit/structure_poll_still_envelope.qnt][the target history model]]:18 histories with bounded simulation.
Unknown outcomes charge potential held backing; initialization blocks collector
acknowledgement. Abstract units and a254-step batch are not source refinement.\n",
'dev/architecture/runtime/gc/models/lean/index.org'=>"\n* Structure frame, still and complete-phase premises\n[[file:../../structure-poll-still-envelope-design.org::#structure-refinement][SP-I]] binds [[file:../../../../../../models/gambit/lean/StructurePollStillEnvelope.lean][17 conditional arithmetic/ledger statements]]. Typed acquired bytes
are independent of pending/pool counters; every phase must fit below a matched
baseline maximum. Actual ABI, source steps and callback budgets remain open.\n",
'dev/refactoring/modern-c/runtime-blueprint.org'=>"\n* Structure slow-path modernization cut\n[[file:../../architecture/runtime/gc/structure-poll-still-envelope-design.org::#structure-migration][The POLL/frame/still replacement order]] adds PollEffectSpec, typed frame-growth
and noncollecting StillInitSpec to the Scheme-to-modern-C contract. Arbitrary
interrupts, exceptions and multi-shot captures remain language capabilities;
unknown effects refuse finite peak qualification, not execution. C owns actual
container/assignment/pin accounting, initialized-root publication and safe-point
acknowledgement. Unifying these removes hidden duplicated reasoning only after
all consumers migrate; no runtime path or existing reuse is newly claimed saved.\n"}.each{|p,t|File.open(p,'a'){|f|f.write(t)}}
