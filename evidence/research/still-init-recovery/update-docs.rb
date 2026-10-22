r='.cache/tasks/still-init-recovery'
p='dev/modeling/component-assurance.org';s=File.read(p).sub('and [[file:../architecture/runtime/gc/models/sysml/still-init-safepoint.sysml][the initialization/participation contracts]] own 100 needs, 288 direct prerequisites','[[file:../architecture/runtime/gc/models/sysml/still-init-safepoint.sysml][the initialization/participation contracts]] and [[file:../architecture/runtime/gc/models/sysml/still-init-recovery.sysml][partial/result recovery]] own 106 needs, 314 direct prerequisites').sub('The 100-need, 288-edge prerequisite view','The 106-need, 314-edge prerequisite view')
s+=<<~ORG

* RESEARCH Partial initialization and undelivered-result recovery
:PROPERTIES:
:CUSTOM_ID: still-init-recovery-assurance
:AUTHORITY: GambitStillInitRecovery
:STATUS: target-kernels-checked-native-source-refinement-open
:END:

[[file:../architecture/runtime/gc/still-init-recovery-design.org][The actual constructor/FFI/caller study]] distinguishes reserved writes, committed
cursor, completed body without a result root, rooted completion and recipient
acceptance. Queries cannot initialize, advance directory I/O or invoke Scheme.
A frozen owner transfer preserves the exact cursor; unknown results preserve
full backing and responsibility. Raw output pointers are not atomic receipts.

[[file:../architecture/runtime/gc/still-init-recovery-matrix.org][The native-derived matrix]] binds IR-H (31 histories) and IR-I (16 exact conditional
statements, including a Progress Step/Trace kernel). IR-PROGRESS/ROOT/DELIVERY/ABORT
remain source obligations. The graph is106 needs/314 prerequisites/50 routes/eight
shared contracts:40 local slices (38 unchanged inherited),53 source gaps and13
platform gaps. Zero components have complete/native qualification. Atomic string
partial failure does not prove partial pointer-object scanning or retirement.
[[file:../../evidence/research/still-init-recovery/checks.json][The receipt]] retains negative controls and parser-bound failures separately.
ORG
File.write(p,s)
p='dev/modeling/assurance-planner.org';s=File.read(p)
%w[component-assurance component-assurance-build component-assurance-routes component-assurance-routes-tail].zip(%w[case-current build-cut/case-current source-routes source-routes-tail]).each{|shared,old|s=s.gsub("--task still-init-safepoint trajectory clues < dev/modeling/ascent/#{shared}.request.scm", "--task still-init-safepoint trajectory clues < evidence/research/still-init-safepoint/#{old}.request.scm")}
s+=<<~ORG

** RESEARCH Partial initialization and result admission
[[file:component-assurance.org::#still-init-recovery-assurance][The native frontier]] has106 needs/314 prerequisites/50 routes. Owner arbitration
and result admission depend on root, continuation and resource-exit contracts.
IR-ABORT brings all four resource-exit needs into the runtime ancestor closure;
the runtime cut has94 needs/297 edges/five complete owners, while build has56/123
and four complete owners. Their exact union remains eight unique components.

Receipt subject references reconstruct exact artifact/scope from native needFact
before the unchanged qualification rules. This transport requires globally unique
obligation identities and an independent inverse check of every resulting tuple.
Owner-batched edges carry five independent obligation/prerequisite pairs, never
merge conjunctive requirements. Inference cuts omit seven metadata-only and ten
unused legacy edge transport forms on empty inputs; full metadata projections
retain every source route/contract. Parser limits are unchanged. Initial byte
and form-bound failures are retained, not relabeled as model or native failures.

#+NAME: still-init-recovery-assurance-read
#+BEGIN_SRC sh :eval never
.venv/bin/gambit-smp --task still-init-recovery trajectory clues < dev/modeling/ascent/component-assurance.request.scm
.venv/bin/gambit-smp --task still-init-recovery trajectory clues < dev/modeling/ascent/component-assurance-build.request.scm
.venv/bin/gambit-smp --task still-init-recovery trajectory clues < dev/modeling/ascent/component-assurance-routes.request.scm
.venv/bin/gambit-smp --task still-init-recovery trajectory clues < dev/modeling/ascent/component-assurance-routes-tail.request.scm
#+END_SRC
ORG
File.write(p,s)
adds={
'dev/architecture/runtime/gc/index.org'=>"\n* Partial initializer and undelivered result recovery\n[[file:still-init-recovery-design.org][The progress/owner/result study]] traces actual pointer constructors, atomic string\npartial errors, directory I/O and generated FFI output/release scopes.\n[[file:still-init-recovery-matrix.org][The native matrix]] separates one-pass work, input snapshots, root overlap and\nunknown/dedup retention; unsafe retry is not a legitimate performance baseline.\n",
'dev/architecture/runtime/gc/models/quint/index.org'=>"\n* Partial progress and result admission\n[[file:../../still-init-recovery-design.org::#still-recovery-proof][IR-H]] binds [[file:../../../../../../models/gambit/still_init_recovery.qnt][31 target histories]] and100 sampled traces of at most100 transitions.\nReserved/physical/committed progress, frozen transfer, lost replies, cancellation,\nreceiver admission and unknown storage are abstract. Stale transport, decoder\nstate, GC layout, many actors, receipt retirement and liveness remain open.\n",
'dev/architecture/runtime/gc/models/lean/index.org'=>"\n* Progress preservation and idempotent admission\n[[file:../../still-init-recovery-design.org::#still-recovery-proof][IR-I]] binds [[file:../../../../../../models/gambit/lean/StillInitRecovery.lean][16 named conditional statements]]. Progress Step/Trace preservation\nis explicit; unique owner relies on a linearized owner record. Admission\nidempotence and root overlap do not prove the entire QNT model, C atomicity,\nnative buffer stability, external-effect exactly-once or crash recovery.\n",
'dev/refactoring/modern-c/runtime-blueprint.org'=>"\n* Recoverable initialization and result ownership\n[[file:../../architecture/runtime/gc/still-init-recovery-design.org][The partial/result design]] gives modern C an operation record, generation-bound\ninitializer and atomic recipient-root/receipt boundary. Scheme supplies typed\nInitSpec, cursor and invocation identity; multi-shot continuation calls remain\ndistinct semantic invocations. Readback never replays constructors or native I/O.\nA synchronous fast path can keep one final cut. Per-field atomics, a copied input\nimage or a second runtime are not implicit requirements. Root/input/dedup\nlifetimes and source memory order must close before old ownership paths retire.\n"}
adds.each{|p,t|File.open(p,'a'){|f|f.write(t)}}
s=File.read('.cache/tasks/still-init-safepoint/artifacts.txt').gsub('still-init-safepoint','still-init-recovery').gsub('still_init_safepoint','still_init_recovery').gsub('StillInitSafepoint','StillInitRecovery');File.write("#{r}/artifacts.txt",s)
