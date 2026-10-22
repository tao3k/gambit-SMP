p='dev/architecture/runtime/gc/rest-gc-resume-envelope-design.org'
s=File.read(p).sub('../../../org/setup.org','../../../modeling/org/setup.org');File.write(p,s)
p='dev/modeling/component-assurance.org';s=File.read(p)
s=s.sub('and eight shared contracts.','and eight shared contracts.')
s=s.sub('They own 84 needs, 226 direct prerequisites','Together with [[file:../architecture/runtime/gc/models/sysml/rest-gc-resume-envelope.sysml][the real rest/GC/resume envelope]], they own 90 needs, 248 direct prerequisites')
s=s.sub('The 84-need, 226-edge prerequisite view','The 90-need, 248-edge prerequisite view')
s+=<<~ORG

* RESEARCH Rest construction, framed GC and first resumed interval
:PROPERTIES:
:CUSTOM_ID: rest-resume-assurance
:STATUS: conditional-model-checked-source-and-physical-lifetime-open
:END:

[[file:../architecture/runtime/gc/rest-gc-resume-envelope-design.org][The selected real structure chain]] adds six GC-owned needs and 22 dependency
edges, connecting completion, VM binding, continuation, lifetime and whole-phase
peak claims. Native SysML owns 90 needs, 248 direct dependencies, 40 source
routes and eight shared contracts. ASCENT's runtime cut covers 74 needs/225
edges; the build/resource-exit cut remains 56/123. Their exact union is checked.
A third route-only projection includes all 90 needs/40 routes and qualifies none.

#+NAME: rest-resume-closure-matrix
| Slice | Local evidence | Still required | Benefit boundary |
|---+---+---+---|
| RG-H | 16 named QNT histories and bounded positive simulation | Exact C step/representation/entry and full-state simulation | B/completion and failure custody, not native capacity evidence |
| RG-I | 13 named conditional Lean arithmetic statements | Pointer/container provenance, whole-step induction, complete live-phase sum | Selected carrier <=24576 words; not a whole-GC bound |
| RG-COMPLETE | Real handler and pair/vector endpoints located | Preissued physically contiguous completion grant; legal caller census | Removes unjustified independent maxima, not global reserve subtraction |
| RG-RESUME | Existing structure entry, na=-1 and first POLL traced | Root/FrameSpec/current-binding and slow-path assurance | First heap span0, stack temporary2; later frame8 and allocation separate |
| RG-LIFETIME | Section/semispace/still release endpoints located | Complete last-alias/reader and captured-continuation closure | No physical refund at carrier detachment |
| RG-PEAK | All-phase conditional comparison, omitted-source controls | Matched actual backing acquisitions including fudge/still/failure | Qg positive only when it omits an actual acquisition and every phase stays lower |
| Whole selected graph | 34 distinct local formal slices, including 32 unchanged inherited slices | 43 source-simulation and 13 platform/environment/order needs | Zero fully admitted components or retired runtime paths |

All-scoped-pass scenarios are synthetic planner controls. Removing completion,
resume, lifetime, peak or transitive HR-BIND blocks upstream GC eligibility.
Wrong scope and stale digest do not qualify local checks. Neither partial
ancestor readiness nor existing files establishes source/native acceptance.
ORG
File.write(p,s)
p='dev/modeling/assurance-planner.org';s=File.read(p)
s=s.sub('--task guaranteed-tail-placement trajectory clues < dev/modeling/ascent/component-assurance.request.scm','--task guaranteed-tail-placement trajectory clues < evidence/research/guaranteed-tail-placement/case-current.request.scm')
s=s.sub('--task guaranteed-tail-placement trajectory clues < dev/modeling/ascent/component-assurance-build.request.scm','--task guaranteed-tail-placement trajectory clues < evidence/research/guaranteed-tail-placement/build-cut/case-current.request.scm')
s=s.sub('--task guaranteed-tail-placement trajectory clues < dev/modeling/ascent/component-assurance-routes.request.scm','--task guaranteed-tail-placement trajectory clues < evidence/research/guaranteed-tail-placement/source-routes.request.scm')
s+=<<~ORG

** RESEARCH Real rest-constructor completion and resume chain
[[file:component-assurance.org::#rest-resume-assurance][The current native frontier]] has 90 needs, 248 direct prerequisites and 40
source routes. Two ancestor-closed inference cuts and one qualification-free
source projection preserve the exact union without changing parser limits.
The task journal registers the native/model/DSL identity as a hypothesis only.

#+NAME: rest-resume-assurance-reads
#+BEGIN_SRC sh :eval never
.venv/bin/gambit-smp --task rest-gc-resume-envelope trajectory clues < dev/modeling/ascent/component-assurance.request.scm
.venv/bin/gambit-smp --task rest-gc-resume-envelope trajectory clues < dev/modeling/ascent/component-assurance-build.request.scm
.venv/bin/gambit-smp --task rest-gc-resume-envelope trajectory clues < dev/modeling/ascent/component-assurance-routes.request.scm
#+END_SRC
ORG
File.write(p,s)
{'dev/architecture/runtime/gc/index.org'=>"\n* Rest construction, framed GC and resumed execution\n[[file:rest-gc-resume-envelope-design.org][The real structure chain]] separates crossing guard, noncollecting completion,
first heap0/stack2 interval, later frame8 growth and actual physical release.
[[file:rest-gc-resume-envelope-matrix.org][The native-derived matrix]] reports conditional work and whole-round peak bounds.\n",
'dev/architecture/runtime/gc/models/quint/index.org'=>"\n* Rest completion and carrier lifetime\n[[file:../../rest-gc-resume-envelope-design.org::#rest-refinement][RG-H]] binds [[file:../../../../../../models/gambit/rest_gc_resume_envelope.qnt][the target history slice]]:16 histories, bounded positive simulation,
mutually exclusive acquisition and preserved counterexamples. p2/a5 and abstract
future demand4 are not the selected first heap0 span or a native GC simulation.\n",
'dev/architecture/runtime/gc/models/lean/index.org'=>"\n* Rest completion and physical-peak premises\n[[file:../../rest-gc-resume-envelope-design.org::#rest-refinement][RG-I]] binds [[file:../../../../../../models/gambit/lean/RestGcResumeEnvelope.lean][13 conditional statements]]: disjoint prefix/suffix accounting,
selected/generic constructor caps, first heap0, stack growth and phase credit.
Pointer provenance, source simulation and QNT induction remain separate.\n",
'dev/refactoring/modern-c/runtime-blueprint.org'=>"\n* Real rest constructor as a joint-capacity migration cut\n[[file:../../architecture/runtime/gc/rest-gc-resume-envelope-design.org][The structure/rest chain]] requires Scheme argument-shape/PointId/FrameSpec and
C-backed noncollecting completion before framed GC. Restore heap0 is separate
from stack2, repeated frame8 growth and the following small/still allocator.
Retire implicit global-reserve sufficiency and unconditional post-GC grants only
after every caller and actual backing consumer is migrated. Existing pair/vector
semantics, roots and continuation lifetimes remain authoritative until then.
This amplifies precise portable-C generation and safe GC placement; Zig adds no
established incremental semantic or peak benefit here.\n"}.each{|p,t|File.open(p,'a'){|f|f.write(t)}}
