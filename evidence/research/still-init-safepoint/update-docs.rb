r='.cache/tasks/still-init-safepoint'
p='dev/architecture/runtime/gc/still-init-safepoint-design.org';s=File.read(p).sub('WB-SCAN-CUT','WB-SNAPSHOT').sub("The local QNT/Lean gate abstracts this through rootsReady; it does not prove\nremembered-set completeness. That source/refinement obligation remains open.","The local QNT has no remembered-set state; Lean's rootsReady is an assumed\npredicate, not a derivation of coverage. Neither proves remembered-set\ncompleteness. That source/refinement obligation remains open.");File.write(p,s)
p='dev/modeling/component-assurance.org';s=File.read(p).sub('they and [[file:../architecture/runtime/gc/models/sysml/structure-poll-still-envelope.sysml][the POLL/frame/still refinement]] own 96 needs, 272 direct prerequisites','they, [[file:../architecture/runtime/gc/models/sysml/structure-poll-still-envelope.sysml][the POLL/frame/still refinement]] and [[file:../architecture/runtime/gc/models/sysml/still-init-safepoint.sysml][the initialization/participation contracts]] own 100 needs, 288 direct prerequisites').sub('The 96-need, 272-edge prerequisite view','The 100-need, 288-edge prerequisite view')
s += <<~ORG

* RESEARCH Still initialization, request acknowledgement and root custody
:PROPERTIES:
:CUSTOM_ID: still-init-safepoint-assurance
:AUTHORITY: GambitStillInitSafepoint
:STATUS: local-kernels-checked-source-and-memory-refinement-open
:END:

[[file:../architecture/runtime/gc/still-init-safepoint-design.org][The selected source study]] traces allocation, sync-op/resize, heartbeat posting,
POLL delivery, marker/FFI and foreign cleanup. Request arrival is not participation;
completed fields are not result-root publication. A participant lease freezes
mutation until collection/withdrawal. Nested activation cleanup preserves parent
roots; unknown replies retain full storage and the original initializer owner.
Minor-GC admission additionally depends on WB-WRITERS/WB-SNAPSHOT coverage.

[[file:../architecture/runtime/gc/still-init-safepoint-matrix.org][The native-derived matrix]] binds SI-H (21 histories) and SI-I (13 exact conditional
statements). SI-GATE and SI-CUSTODY remain source obligations. The current exact
union is100 needs/288 edges/46 routes/eight shared contracts:38 local slices
(36 unchanged inherited),49 source gaps and13 platform gaps; zero complete/native
components. Two inference cuts and two qualification-free metadata cuts retain
that union. Fourteen ASCENT scenarios include omitted roots/source, stale digest,
wrong scope and paired-receipt controls. Passing mathematics is not native safety.
See [[file:../../evidence/research/still-init-safepoint/checks.json][the source-bound receipt]]. No old C runtime path is retired by this study.
ORG
File.write(p,s)
p='dev/modeling/assurance-planner.org';s=File.read(p)
%w[component-assurance component-assurance-build component-assurance-routes component-assurance-routes-tail].zip(%w[case-current build-cut/case-current source-routes source-routes-tail]).each do |shared,old|
 s=s.gsub("--task structure-poll-still-envelope trajectory clues < dev/modeling/ascent/#{shared}.request.scm", "--task structure-poll-still-envelope trajectory clues < evidence/research/structure-poll-still-envelope/#{old}.request.scm")
end
s += <<~ORG

** RESEARCH Still initialization and participation cuts
[[file:component-assurance.org::#still-init-safepoint-assurance][The current frontier]] has100 needs/288 prerequisites/46 routes. The runtime cut
contains84 needs/265 edges and the build/resource-exit cut56/123, with an exact
ancestor-closed union. Inference specialization elides exactly seven metadata-only
forms on empty inputs, preserving every qualification rule. Full source-route
projections retain all46 routes and eight contracts with zero proof receipts.
The unchanged DSL expands15 receipt pairs to30 independent runtime receipts;
wrong scope, stale artifact and shared nonpass status remain distinct controls.

#+NAME: still-init-safepoint-assurance-reads
#+BEGIN_SRC sh :eval never
.venv/bin/gambit-smp --task still-init-safepoint trajectory clues < dev/modeling/ascent/component-assurance.request.scm
.venv/bin/gambit-smp --task still-init-safepoint trajectory clues < dev/modeling/ascent/component-assurance-build.request.scm
.venv/bin/gambit-smp --task still-init-safepoint trajectory clues < dev/modeling/ascent/component-assurance-routes.request.scm
.venv/bin/gambit-smp --task still-init-safepoint trajectory clues < dev/modeling/ascent/component-assurance-routes-tail.request.scm
#+END_SRC
ORG
File.write(p,s)
adds={
'dev/architecture/runtime/gc/index.org'=><<~ORG,

* Still initialization and cooperative participation
[[file:still-init-safepoint-design.org][The initialization/request/root study]] separates request posting, body completion,
result-root publication and frozen participation. It traces real interrupt and
GC consumers, nested callback cleanup and unknown storage custody.
[[file:still-init-safepoint-matrix.org][The native-derived matrix]] states removable work, added root metadata and
whole-round peak conditions; no mandatory still allocation is eliminated.
ORG
'dev/architecture/runtime/gc/models/quint/index.org'=><<~ORG,

* Still initialization, frozen participation and nested roots
[[file:../../still-init-safepoint-design.org::#still-init-refinement][SI-H]] binds [[file:../../../../../../models/gambit/still_init_safepoint.qnt][the root target kernel]]:21 named histories and100 positive samples
of at most80 steps. One initializer, two activation roots and request numbers0..2
cover late ack, filled-but-unrooted entry, parent scratch loss, unknown storage
and unsafe mutation after participation. No remembered-set state, native pointer
proof, complete callback census or partial-result readback proof is inferred.
ORG
'dev/architecture/runtime/gc/models/lean/index.org'=><<~ORG,

* Still completion, root handoff and owner-token cleanup
[[file:../../still-init-safepoint-design.org::#still-init-refinement][SI-I]] binds [[file:../../../../../../models/gambit/lean/StillInitSafepoint.lean][13 exact conditional statements]] for initialized/rooted entry,
request freshness, own-token cleanup, unknown charge and phase-peak conditions.
Root readiness is a premise. Whole QNT induction, remembered coverage, source
steps, actual C happens-before and native layout remain separate obligations.
ORG
'dev/refactoring/modern-c/runtime-blueprint.org'=><<~ORG

* Still initialization as an explicit modern C runtime boundary
[[file:../../architecture/runtime/gc/still-init-safepoint-design.org][The root/init/participation design]] assigns semantic InitSpec and PointId to
Scheme, physical fill/root records and request-generation leases to modern C.
Refcount, interrupt masks and pending flags no longer substitute for scan-ready
publication. Nested callbacks retain parent activation roots; unknown service
results retain full backing and the original initializer. Mature-object
initialization joins remembered-set coverage before minor collection.
Retire fixed scratch and implicit no-GC intervals only after all constructor,
SAVE/RESTORE, callback, exception and native-exit consumers migrate. This enables
context/collector separation without weakening continuation or FFI semantics;
no Zig-specific additional benefit or native retirement is established here.
ORG
}
adds.each{|path,text|File.open(path,'a'){|f|f.write(text)}}
s=File.read('.cache/tasks/structure-poll-still-envelope/artifacts.txt').gsub('structure-poll-still-envelope','still-init-safepoint').gsub('structure_poll_still_envelope','still_init_safepoint').gsub('StructurePollStillEnvelope','StillInitSafepoint')
File.write("#{r}/artifacts.txt",s)
p="#{r}/verify-final.sh";s=File.read(p).gsub('"SP-H"','"SI-H"').gsub('"SP-I"','"SI-I"').gsub('==51','==52').gsub('==16','==14').gsub('==36','==38');File.write(p,s)
