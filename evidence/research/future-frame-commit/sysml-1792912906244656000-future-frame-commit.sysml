package GambitFutureFrameCommit { private import ScalarValues::*;
part def SourceRow { attribute key:String; attribute path:String; attribute needle:String; attribute obligation:String; }
part source0:SourceRow { attribute :>> key="feeley-paper"; attribute :>> path="evidence/research/source-references/feeley-pvm/ad1f9ca247f0c97835bda99bd387ca735767ab68ed4338897ade618ad769d2f1.txt"; attribute :>> needle="2.7 Parallelism in PVM"; attribute :>> obligation="paper TASK/WORK/DONE and lazy materialization, not current runtime proof"; }
part source1:SourceRow { attribute :>> key="native-extent"; attribute :>> path="evidence/research/source-references/feeley-sfp/8bb2fae8ae4b54d3a86206596f90e9cf73da39846af0f39244a476074cf81ed4.txt"; attribute :>> needle="5       Pra"; attribute :>> obligation="historical native-stack proposal not an implemented source-split service"; }
part source2:SourceRow { attribute :>> key="future-generator"; attribute :>> path="vendor/gambit/gsc/_front.scm"; attribute :>> needle="(define (gen-fut node live reason)"; attribute :>> obligation="real compile-time future source producer"; }
part source3:SourceRow { attribute :>> key="future-save"; attribute :>> path="vendor/gambit/gsc/_front.scm"; attribute :>> needle="(save-regs-to-stk (live-regs live-after)"; attribute :>> obligation="save parent live registers before future"; }
part source4:SourceRow { attribute :>> key="future-cut"; attribute :>> path="vendor/gambit/gsc/_front.scm"; attribute :>> needle="1) ;; reserve space for a break frame"; attribute :>> obligation="frame alignment and break reservation precede task/return contexts"; }
part source5:SourceRow { attribute :>> key="task-context"; attribute :>> path="vendor/gambit/gsc/_front.scm"; attribute :>> needle="(make-context (- nb-slots frame-start)"; attribute :>> obligation="child task context and parent return context are already distinguished"; }
part source6:SourceRow { attribute :>> key="future-return"; attribute :>> path="vendor/gambit/gsc/_front.scm"; attribute :>> needle="(make-label-task-return"; attribute :>> obligation="result lives in proc-result before task-return label"; }
part source7:SourceRow { attribute :>> key="gvm-frame"; attribute :>> path="vendor/gambit/gsc/_gvm.scm"; attribute :>> needle="(define (make-frame size slots regs closed live)"; attribute :>> obligation="logical frame includes slots, registers, closed variables and liveness"; }
part source8:SourceRow { attribute :>> key="emit-entry"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(targ-emit (list \"TASK_PUSH\" 0))"; attribute :>> obligation="C emitter emits task hook"; }
part source9:SourceRow { attribute :>> key="emit-return"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(targ-emit (list \"TASK_POP\""; attribute :>> obligation="C emitter emits task completion hook"; }
part source10:SourceRow { attribute :>> key="emit-live-map"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(targ-build-gc-map"; attribute :>> obligation="native return metadata derives from semantic liveness"; }
part source11:SourceRow { attribute :>> key="emit-task-spec"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(targ-make-frame-spec 'task fs link gc-map)"; attribute :>> obligation="task FrameSpec exists in current working tree; not split ownership metadata"; }
part source12:SourceRow { attribute :>> key="physical-frame"; attribute :>> path="vendor/gambit/gsc/_t-c-3.scm"; attribute :>> needle="(define (targ-make-frame-spec kind fs link gc-map)"; attribute :>> obligation="current physical validation does not establish parent/child ownership or sealing aliases"; }
part source13:SourceRow { attribute :>> key="task-push-empty"; attribute :>> path="vendor/gambit/include/_gambit/module_generation.h.in"; attribute :>> needle="#define ___TASK_PUSH(i)"; attribute :>> obligation="empty source macro; no runtime split logic here"; }
part source14:SourceRow { attribute :>> key="task-pop-empty"; attribute :>> path="vendor/gambit/include/_gambit/module_generation.h.in"; attribute :>> needle="#define ___TASK_POP(n)"; attribute :>> obligation="empty source macro; no placeholder/result handoff here"; }
part source15:SourceRow { attribute :>> key="frame-decode"; attribute :>> path="vendor/gambit/include/_gambit/module_generation.h.in"; attribute :>> needle="___FRAME_INLINE ___frame_descriptor ___decode_frame_descriptor"; attribute :>> obligation="inline/out-of-line and internal-return coordinates can be reused"; }
part source16:SourceRow { attribute :>> key="root-cursor"; attribute :>> path="vendor/gambit/include/_gambit/module_generation.h.in"; attribute :>> needle="Borrowed, nonallocating scan state."; attribute :>> obligation="cursor may not cross safepoints or descriptor lifetime"; }
part source17:SourceRow { attribute :>> key="capture-macro"; attribute :>> path="vendor/gambit/include/_gambit/gvm_operations.h.in"; attribute :>> needle="#define ___CONTINUATION_CAPTURE"; attribute :>> obligation="capture records frame and dynamic environment; source storage can remain stack-backed"; }
part source18:SourceRow { attribute :>> key="graft-macro"; attribute :>> path="vendor/gambit/include/_gambit/gvm_operations.h.in"; attribute :>> needle="#define ___CONTINUATION_GRAFT_NO_WINDING"; attribute :>> obligation="restores frame/denv/cache; not a task publication or exclusive run receipt"; }
part source19:SourceRow { attribute :>> key="live-context-roots"; attribute :>> path="vendor/gambit/lib/_mem/root-origins.inc"; attribute :>> needle="mark_array (work, context->saved"; attribute :>> obligation="running register/saved roots are already enumerated"; }
part source20:SourceRow { attribute :>> key="context-stack"; attribute :>> path="vendor/gambit/lib/_mem/root-origins.inc"; attribute :>> needle="mark_continuation (work, context);"; attribute :>> obligation="context stack and RC sources belong to a concrete root origin"; }
part source21:SourceRow { attribute :>> key="captured-copy"; attribute :>> path="vendor/gambit/lib/_mem/continuation-roots.inc"; attribute :>> needle="grant = reserve_copy(work,alloc,words,0);"; attribute :>> obligation="copying captured frames is GC work, not a scheduler steal transaction"; }
part source22:SourceRow { attribute :>> key="captured-link"; attribute :>> path="vendor/gambit/lib/_mem/continuation-roots.inc"; attribute :>> needle="/* leave a forwarding pointer */"; attribute :>> obligation="forwarding and structural link rewrites must be reconciled with split reader authority"; }
part source23:SourceRow { attribute :>> key="captured-publish"; attribute :>> path="vendor/gambit/lib/_mem/continuation-roots.inc"; attribute :>> needle="publish_object_scan (work, copy_header);"; attribute :>> obligation="existing copy/scan publication is not reused without its own qualification"; }
part source24:SourceRow { attribute :>> key="frame-scan"; attribute :>> path="vendor/gambit/lib/_mem/continuation-roots.inc"; attribute :>> needle="___frame_ordinary_root_begin (frame)"; attribute :>> obligation="ordinary roots and structural link are distinct coordinates"; }
part source25:SourceRow { attribute :>> key="heap-frame-scan"; attribute :>> path="vendor/gambit/lib/_mem/object-scanning.inc"; attribute :>> needle="case ___sFRAME:"; attribute :>> obligation="heap frame consumer validates descriptor/payload size and traverses link"; }
part source26:SourceRow { attribute :>> key="steal-queued"; attribute :>> path="vendor/gambit/lib/_thread.scm"; attribute :>> needle="There are no runnable threads locally, so try to steal"; attribute :>> obligation="current steal path chooses existing runnable threads"; }
part source27:SourceRow { attribute :>> key="steal-pin"; attribute :>> path="vendor/gambit/lib/_thread.scm"; attribute :>> needle="(macro-thread-pinned stolen-thread)"; attribute :>> obligation="native/explicit pin prevents that thread migration"; }
part source28:SourceRow { attribute :>> key="otp-progress"; attribute :>> path="vendor/erlang-otp/erts/emulator/internal_doc/ThreadProgress.md"; attribute :>> needle="remove the possibility to look up"; attribute :>> obligation="retirement needs closed lookup and matching reader quiescence"; }
part source29:SourceRow { attribute :>> key="slot-order"; attribute :>> path="vendor/gambit/gsc/_front.scm"; attribute :>> needle="(list-ref slots (- nb-slots (stk-num opnd)))"; attribute :>> obligation="slots stored highest-to-lowest; stk(k) uses list index N-k"; }
part source30:SourceRow { attribute :>> key="save-return"; attribute :>> path="vendor/gambit/gsc/_front.scm"; attribute :>> needle="(define (save-opnd-to-reg opnd reg var live comment)"; attribute :>> obligation="preserve prior live register before installing task return label"; }
part source31:SourceRow { attribute :>> key="label-frame-reset"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(set! targ-proc-entry-frame targ-proc-exit-frame)"; attribute :>> obligation="label handling replaces previous linear instruction frame with label frame"; }
part source32:SourceRow { attribute :>> key="frame-pointer-height"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(define (targ-start-bb fs)"; attribute :>> obligation="task-return starts with current parent label height"; }
part source33:SourceRow { attribute :>> key="stk-emission"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(list \"STK\" (- (stk-num opnd) targ-proc-fp))"; attribute :>> obligation="C offset is k-h before runtime sign convention"; }
part source34:SourceRow { attribute :>> key="fp-adjust"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(list \"ADJFP\" (- fs fp))"; attribute :>> obligation="runtime adjustment preserves logical base fp+h"; }
part source35:SourceRow { attribute :>> key="flush-before-jump"; attribute :>> path="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> needle="(targ-update-fr targ-proc-entry-frame)"; attribute :>> obligation="floating-point/boxed representation readiness must match split point"; }
part source36:SourceRow { attribute :>> key="gcmask-writer"; attribute :>> path="vendor/gambit/gsc/_t-c-3.scm"; attribute :>> needle="(define (targ-build-gc-map slots live?)"; attribute :>> obligation="bit i indexes ascending variable list entry i"; }
part source37:SourceRow { attribute :>> key="frame-reserve"; attribute :>> path="vendor/gambit/gsc/_t-c-1.scm"; attribute :>> needle="(set! targ-frame-reserve 3)"; attribute :>> obligation="current source reserve and alignment, not all targets"; }
part source38:SourceRow { attribute :>> key="frame-align"; attribute :>> path="vendor/gambit/gsc/_t-c-1.scm"; attribute :>> needle="(set! targ-frame-alignment 4)"; attribute :>> obligation="current C alignment matches header macros"; }
part source39:SourceRow { attribute :>> key="runtime-stack"; attribute :>> path="vendor/gambit/include/_gambit/stack_operations.h.in"; attribute :>> needle="#define ___FP_STK(fp,fpo)fp[-(fpo)]"; attribute :>> obligation="word-address polarity; C pointer provenance not established by arithmetic"; }
part source40:SourceRow { attribute :>> key="runtime-frame-space"; attribute :>> path="vendor/gambit/include/_gambit/module_generation.h.in"; attribute :>> needle="#define ___FRAME_SPACE(n)"; attribute :>> obligation="normal scanner base accounts for reserve and alignment"; }
part source41:SourceRow { attribute :>> key="frame-gate-enter"; attribute :>> path="vendor/gambit/lib/_mem/copy-reservations.inc"; attribute :>> needle="___HIDDEN void acquire_frame_access"; attribute :>> obligation="current authority is collector-worker scoped"; }
part source42:SourceRow { attribute :>> key="frame-gate-cas"; attribute :>> path="vendor/gambit/lib/_mem/copy-reservations.inc"; attribute :>> needle="while (___COMPARE_AND_SWAP_WORD(&vms->gc_round.frame_gate,0,1) != 0)"; attribute :>> obligation="one global per-round frame access gate"; }
part source43:SourceRow { attribute :>> key="frame-gate-release"; attribute :>> path="vendor/gambit/lib/_mem/copy-reservations.inc"; attribute :>> needle="___FETCH_AND_CLEAR_WORD(&vms->gc_round.frame_gate);"; attribute :>> obligation="release backend does not itself authorize a scheduler grant"; }
part source44:SourceRow { attribute :>> key="frame-gate-reset"; attribute :>> path="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> needle="___vms->gc_round.frame_gate = 0;"; attribute :>> obligation="reset relies on all old-round users crossing barrier"; }
part source45:SourceRow { attribute :>> key="round-epoch"; attribute :>> path="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> needle="___vms->gc_round.epoch++;"; attribute :>> obligation="round identity alone is not a complete per-frame mutation revision"; }
part source46:SourceRow { attribute :>> key="frame-setter"; attribute :>> path="vendor/gambit/lib/_kernel.scm"; attribute :>> needle="___BODY_AS(___ARG1,___tFRAME)[fs-i+1] = ___ARG3;"; attribute :>> obligation="real reflective heap-frame writer has no frame-access call in this body"; }
part source47:SourceRow { attribute :>> key="frame-implode"; attribute :>> path="vendor/gambit/lib/_io.scm"; attribute :>> needle="(define-prim (##implode-frame re fields)"; attribute :>> obligation="actual frame-set caller fills new frames; unpublished constructor is distinct from concurrent semantic mutation"; }
part source48:SourceRow { attribute :>> key="cont-frame-setter"; attribute :>> path="vendor/gambit/include/_gambit/gvm_operations.h.in"; attribute :>> needle="#define ___CONTINUATIONFRAMESET(cont,val)"; attribute :>> obligation="continuation root/link setter is a plain store; does not join collector gate by itself"; }
part def ComponentRow { attribute componentId:String; attribute sharedContract:String; attribute role:String; }
part component0:ComponentRow { attribute :>> componentId="coordinates"; attribute :>> sharedContract="FrameCoordinates/CanonicalRoot/ReturnDecision/AccessGeneration"; attribute :>> role="Scheme slot partition, C address and GC coordinate interpretation"; }
part component1:ComponentRow { attribute :>> componentId="frame-access"; attribute :>> sharedContract="FrameCoordinates/CanonicalRoot/ReturnDecision/AccessGeneration"; attribute :>> role="shared writer/reader authority and canonical source resolution"; }
part component2:ComponentRow { attribute :>> componentId="copy-root"; attribute :>> sharedContract="FrameCoordinates/CanonicalRoot/ReturnDecision/AccessGeneration"; attribute :>> role="registered destination updated by GC and validated without recopy"; }
part component3:ComponentRow { attribute :>> componentId="return-decision"; attribute :>> sharedContract="FrameCoordinates/CanonicalRoot/ReturnDecision/AccessGeneration"; attribute :>> role="one irreversible LOCAL or SPLIT decision for one dispatch occurrence"; }
part component4:ComponentRow { attribute :>> componentId="collector"; attribute :>> sharedContract="FrameCoordinates/CanonicalRoot/ReturnDecision/AccessGeneration"; attribute :>> role="actual forwarding/link mutation and old-round reset census"; }
part component5:ComponentRow { attribute :>> componentId="composition"; attribute :>> sharedContract="FrameCoordinates/CanonicalRoot/ReturnDecision/AccessGeneration"; attribute :>> role="conditional relation to parent split/queue model; C23/native refinement open"; }
part def LearningRow { attribute key:String; attribute source:String; attribute mechanism:String; attribute fact:String; attribute mismatch:String; attribute candidate:String; attribute status:String; }
part learning0:LearningRow { attribute :>> key="source-cut"; attribute :>> source="future-generator"; attribute :>> mechanism="logical frame partition"; attribute :>> fact="child local j corresponds to original S+j; parent retains slots 1..S"; attribute :>> mismatch="padding/reserve are not all ordinary GC roots"; attribute :>> candidate="use one coordinate transform plus program-point liveness"; attribute :>> status="CURRENT-SOURCE/CONDITIONAL-ARITHMETIC"; }
part learning1:LearningRow { attribute :>> key="return-link"; attribute :>> source="save-return"; attribute :>> mechanism="old return preserved before task label"; attribute :>> fact="child R0 names task-return; original parent ret-var survives via save logic"; attribute :>> mismatch="task return address and parent structural link are different things"; attribute :>> candidate="bind both links and result home to return decision"; attribute :>> status="CURRENT-SOURCE"; }
part learning2:LearningRow { attribute :>> key="frame-gate"; attribute :>> source="frame-gate-enter"; attribute :>> mechanism="collector frame access domain"; attribute :>> fact="existing GC readers/writers serialize forwarding and link repair"; attribute :>> mismatch="not an admitted scheduler access API; reset assumes old GC roster"; attribute :>> candidate="extend authority/lifetime or exclude split from GC, with exact source resolution"; attribute :>> status="PROPOSED-GAMBIT-ADAPTATION"; }
part learning3:LearningRow { attribute :>> key="copy-root-update"; attribute :>> source="captured-link"; attribute :>> mechanism="moving pointer and structural-link repair"; attribute :>> fact="source root and forwarding links can move or change"; attribute :>> mismatch="old raw fp or prepared physical patch can become stale"; attribute :>> candidate="resolve canonical root after grant; revalidate current copy/patch generation"; attribute :>> status="PROPOSED-GAMBIT-ADAPTATION"; }
part learning4:LearningRow { attribute :>> key="paper-return"; attribute :>> source="feeley-paper"; attribute :>> mechanism="lazy child completion"; attribute :>> fact="paper provides task/work/done lazy parent materialization"; attribute :>> mismatch="does not prescribe C23 frame gate, commit CAS or failure recovery"; attribute :>> candidate="separate completion from irreversible return routing"; attribute :>> status="PRIMARY-PAPER/NEW-PROTOCOL"; }
part learning5:LearningRow { attribute :>> key="qualified-grace"; attribute :>> source="otp-progress"; attribute :>> mechanism="close lookup and wait for known-state readers"; attribute :>> fact="retirement/reset needs complete participating reader set"; attribute :>> mismatch="a Gambit scheduler checkpoint does not imply native/frame quiescence"; attribute :>> candidate="bind reset to all admitted frame roles"; attribute :>> status="PINNED-REFERENCE/CONDITIONAL"; }
part def IssuerRow { attribute key:String; attribute source:String; attribute existing:String; attribute candidate:String; attribute gap:String; }
part issuer0:IssuerRow { attribute :>> key="cut"; attribute :>> source="future-generator"; attribute :>> existing="gen-fut builds aligned parent and rebased child contexts"; attribute :>> candidate="Scheme semantic stage binds exact split point and live maps"; attribute :>> gap="future cut is not every running child safepoint"; }
part issuer1:IssuerRow { attribute :>> key="roots"; attribute :>> source="context-stack"; attribute :>> existing="GC has stack/register/saved/context roots and captured-frame scan"; attribute :>> candidate="same census includes private copy/result while task remains reserved"; attribute :>> gap="actual slot-update adapter open"; }
part issuer2:IssuerRow { attribute :>> key="access"; attribute :>> source="frame-gate-enter"; attribute :>> existing="collector worker receives frame access"; attribute :>> candidate="explicit runtime frame-access authority for split/return and GC"; attribute :>> gap="cannot fabricate collector_worker to call existing helper"; }
part issuer3:IssuerRow { attribute :>> key="source"; attribute :>> source="captured-link"; attribute :>> existing="GC writes forwarding and link cells"; attribute :>> candidate="canonical rooted source resolved within current generation/grant"; attribute :>> gap="no existing scheduler canonical-source resolver identified"; }
part issuer4:IssuerRow { attribute :>> key="decision"; attribute :>> source="emit-return"; attribute :>> existing="task-return emitter has task and ordinary fallback labels; hooks empty"; attribute :>> candidate="child closes OPEN to LOCAL or splitter commits RESERVED to SPLIT once"; attribute :>> gap="no C23 decision/patch implementation"; }
part issuer5:IssuerRow { attribute :>> key="reset"; attribute :>> source="frame-gate-reset"; attribute :>> existing="old-round barrier justifies frame_gate reset"; attribute :>> candidate="all-role admission close and drain before reuse"; attribute :>> gap="new scheduler users are not part of current reset proof"; }
part def ProfileRow { attribute key:String; attribute scope:String; attribute permission:String; attribute boundary:String; }
part profile0:ProfileRow { attribute :>> key="aligned-parent"; attribute :>> scope="current C R=3, A=4 parent task-return"; attribute :>> permission="normal scanner coordinate equals logical parent k under alignment"; attribute :>> boundary="child entry has no normal descriptor simply equal to child height minus reserve"; }
part profile1:ProfileRow { attribute :>> key="fixed-occurrence"; attribute :>> scope="one admitted normal future occurrence"; attribute :>> permission="one LOCAL/SPLIT dispatch grant; no source-value semantic mutation"; attribute :>> boundary="not an exactly-once law for arbitrary Scheme continuation effects"; }
part profile2:ProfileRow { attribute :>> key="rooted-copy"; attribute :>> scope="GC-safe initialized private copy registered in collector census"; attribute :>> permission="revalidate after relocation rather than recopy payload"; attribute :>> boundary="registration/root flags are premises until actual slots proved"; }
part profile3:ProfileRow { attribute :>> key="cross-role-access"; attribute :>> scope="proposed single shared frame-access lifetime domain"; attribute :>> permission="no GC forwarding during runtime access; accepted grants finish after admission closes"; attribute :>> boundary="existing GC-round helper is not this implemented domain"; }
part def PathRow { attribute key:String; attribute producer:String; attribute consumer:String; attribute classification:String; attribute missing:String; }
part path0:PathRow { attribute :>> key="parent-return-roots"; attribute :>> producer="future-generator"; attribute :>> consumer="frame-scan"; attribute :>> classification="S aligned, label frame reset, fs=S-3, gc bit i -> slot i+1"; attribute :>> missing="actual instantiated variable homes"; }
part path1:PathRow { attribute :>> key="child-runtime-roots"; attribute :>> producer="task-context"; attribute :>> consumer="live-context-roots"; attribute :>> classification="rebased child slots plus current regs/saved and internal-return maps"; attribute :>> missing="do not use parent normal formula at arbitrary child point"; }
part path2:PathRow { attribute :>> key="source-forwarding"; attribute :>> producer="frame-gate-enter"; attribute :>> consumer="captured-link"; attribute :>> classification="current GC access guards source read/copy/link updates"; attribute :>> missing="scheduler authority and canonical resolver"; }
part path3:PathRow { attribute :>> key="root-batch"; attribute :>> producer="frame-scan"; attribute :>> consumer="runtime-stack"; attribute :>> classification="mark_array forward run corresponds to reversed physical slot interval"; attribute :>> missing="allocated ranges and actual type/root maps"; }
part path4:PathRow { attribute :>> key="return-routing"; attribute :>> producer="emit-return"; attribute :>> consumer="task-pop-empty"; attribute :>> classification="task-return hook followed by ordinary return fallback label"; attribute :>> missing="irrevocable split/local decision and protected routing patch"; }
part def RouteRow { attribute component:String; attribute actionName:String; attribute lemma:String; attribute producerAnchor:String; attribute obligationId:String; }
part route0:RouteRow { attribute :>> component="return-decision"; attribute :>> actionName="future_frame_commit.reserveSplit"; attribute :>> lemma="FrameCommit.reserveSplitPreserves"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="return-safety"; }
part route1:RouteRow { attribute :>> component="return-decision"; attribute :>> actionName="future_frame_commit.childDone"; attribute :>> lemma="FrameCommit.childDonePreserves"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="return-safety"; }
part route2:RouteRow { attribute :>> component="return-decision"; attribute :>> actionName="future_frame_commit.closeLocal"; attribute :>> lemma="FrameCommit.closeLocalPreserves"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="return-safety"; }
part route3:RouteRow { attribute :>> component="copy-root"; attribute :>> actionName="future_frame_commit.allocateRootedCopy"; attribute :>> lemma="FrameCommit.allocateRootedCopyPreserves"; attribute :>> producerAnchor="context-stack"; attribute :>> obligationId="gc-snapshot"; }
part route4:RouteRow { attribute :>> component="frame-access"; attribute :>> actionName="future_frame_commit.enterRuntime"; attribute :>> lemma="FrameCommit.enterRuntimePreserves"; attribute :>> producerAnchor="frame-gate-enter"; attribute :>> obligationId="gc-snapshot"; }
part route5:RouteRow { attribute :>> component="frame-access"; attribute :>> actionName="future_frame_commit.resolveCanonical"; attribute :>> lemma="FrameCommit.resolveCanonicalPreserves"; attribute :>> producerAnchor="frame-gate-enter"; attribute :>> obligationId="gc-snapshot"; }
part route6:RouteRow { attribute :>> component="copy-root"; attribute :>> actionName="future_frame_commit.initializeCopy"; attribute :>> lemma="FrameCommit.initializeCopyPreserves"; attribute :>> producerAnchor="context-stack"; attribute :>> obligationId="gc-snapshot"; }
part route7:RouteRow { attribute :>> component="copy-root"; attribute :>> actionName="future_frame_commit.validateCopy"; attribute :>> lemma="FrameCommit.validateCopyPreserves"; attribute :>> producerAnchor="context-stack"; attribute :>> obligationId="gc-snapshot"; }
part route8:RouteRow { attribute :>> component="copy-root"; attribute :>> actionName="future_frame_commit.prepareReturn"; attribute :>> lemma="FrameCommit.prepareReturnPreserves"; attribute :>> producerAnchor="context-stack"; attribute :>> obligationId="gc-snapshot"; }
part route9:RouteRow { attribute :>> component="return-decision"; attribute :>> actionName="future_frame_commit.commitSplit"; attribute :>> lemma="FrameCommit.commitSplitPreserves"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="return-safety"; }
part route10:RouteRow { attribute :>> component="return-decision"; attribute :>> actionName="future_frame_commit.abortSplit"; attribute :>> lemma="FrameCommit.abortSplitPreserves"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="return-safety"; }
part route11:RouteRow { attribute :>> component="return-decision"; attribute :>> actionName="future_frame_commit.grantLocal"; attribute :>> lemma="FrameCommit.grantLocalPreserves"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="return-safety"; }
part route12:RouteRow { attribute :>> component="return-decision"; attribute :>> actionName="future_frame_commit.grantRemote"; attribute :>> lemma="FrameCommit.grantRemotePreserves"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="return-safety"; }
part route13:RouteRow { attribute :>> component="frame-access"; attribute :>> actionName="future_frame_commit.leaveRuntime"; attribute :>> lemma="FrameCommit.leaveRuntimePreserves"; attribute :>> producerAnchor="frame-gate-enter"; attribute :>> obligationId="gc-snapshot"; }
part route14:RouteRow { attribute :>> component="collector"; attribute :>> actionName="future_frame_commit.enterGc"; attribute :>> lemma="FrameCommit.enterGcPreserves"; attribute :>> producerAnchor="captured-link"; attribute :>> obligationId="gc-snapshot"; }
part route15:RouteRow { attribute :>> component="collector"; attribute :>> actionName="future_frame_commit.forwardNoCopy"; attribute :>> lemma="FrameCommit.forwardNoCopyPreserves"; attribute :>> producerAnchor="captured-link"; attribute :>> obligationId="gc-snapshot"; }
part route16:RouteRow { attribute :>> component="collector"; attribute :>> actionName="future_frame_commit.forwardWithCopy"; attribute :>> lemma="FrameCommit.forwardWithCopyPreserves"; attribute :>> producerAnchor="captured-link"; attribute :>> obligationId="gc-snapshot"; }
part route17:RouteRow { attribute :>> component="collector"; attribute :>> actionName="future_frame_commit.leaveGc"; attribute :>> lemma="FrameCommit.leaveGcPreserves"; attribute :>> producerAnchor="captured-link"; attribute :>> obligationId="gc-snapshot"; }
part route18:RouteRow { attribute :>> component="frame-access"; attribute :>> actionName="future_frame_commit.closeDomain"; attribute :>> lemma="FrameCommit.closeDomainPreserves"; attribute :>> producerAnchor="frame-gate-enter"; attribute :>> obligationId="gc-snapshot"; }
part route19:RouteRow { attribute :>> component="frame-access"; attribute :>> actionName="future_frame_commit.resetDomain"; attribute :>> lemma="FrameCommit.resetDomainPreserves"; attribute :>> producerAnchor="frame-gate-reset"; attribute :>> obligationId="gc-snapshot"; }
part route20:RouteRow { attribute :>> component="return-decision"; attribute :>> actionName="future_frame_commit.failedProbe"; attribute :>> lemma="FrameCommit.failedProbePreserves"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="return-safety"; }
part def CompositionRow { attribute key:String; attribute lemma:String; attribute source:String; attribute obligation:String; attribute boundary:String; }
part composition0:CompositionRow { attribute :>> key="word-mapping"; attribute :>> lemma="FutureCoordinates.parentScannerAddress"; attribute :>> source="stk-emission"; attribute :>> obligation="coordinate-laws"; attribute :>> boundary="aligned current C parent; not source-value or C pointer-provenance proof"; }
part composition1:CompositionRow { attribute :>> key="bitmap-example"; attribute :>> lemma="FutureCoordinates.workedRoots"; attribute :>> source="gcmask-writer"; attribute :>> obligation="coordinate-laws"; attribute :>> boundary="illustrative fs9 mask22 link2 yields ordinary roots2,5; not generated fixture"; }
part composition2:CompositionRow { attribute :>> key="forwarding"; attribute :>> lemma="FrameCommit.commitCurrent"; attribute :>> source="captured-link"; attribute :>> obligation="gc-snapshot"; attribute :>> boundary="atomic logical guard; actual source/root and C23 adapter open"; }
part composition3:CompositionRow { attribute :>> key="copy-once"; attribute :>> lemma="FrameCommit.noRecopyAfterGc"; attribute :>> source="context-stack"; attribute :>> obligation="copy-count"; attribute :>> boundary="GC updates registered private copy; no semantic source writes"; }
part composition4:CompositionRow { attribute :>> key="old-and-new"; attribute :>> lemma="FrameCommitBridge.bothForbidLocal"; attribute :>> source="emit-return"; attribute :>> obligation="parent-coupling"; attribute :>> boundary="legacy conditional bridge retained; new paired product establishes coupling inductively for the admitted normal prefix"; }
part def MemoryRow { attribute key:String; attribute order:String; attribute premise:String; attribute obligation:String; }
part memory0:MemoryRow { attribute :>> key="frame-access"; attribute :>> order="runtime/GC users share exclusion; resolve current canonical root only after grant"; attribute :>> premise="per-round gate reset cannot ignore old scheduler users"; attribute :>> obligation="role-census"; }
part memory1:MemoryRow { attribute :>> key="copy"; attribute :>> order="GC-safe destination root before initialization; protected read/initialize; current copy roots survive relocation"; attribute :>> premise="no allocations/callouts under a non-abandonable physical frame patch interval"; attribute :>> obligation="copy-update-adapter"; }
part memory2:MemoryRow { attribute :>> key="return"; attribute :>> order="RESERVED screens child from local fallback; patch links/root interpretation under access; release-publish SPLIT last"; attribute :>> premise="child closes OPEN via CAS, not check-then-return"; attribute :>> obligation="c23-memory"; }
part memory3:MemoryRow { attribute :>> key="dispatch"; attribute :>> order="acquire definitive LOCAL/SPLIT decision and fresh resolved frame, then issue one first-return grant"; attribute :>> premise="no Scheme user code executes while holding the frame gate"; attribute :>> obligation="c23-memory"; }
part memory4:MemoryRow { attribute :>> key="revalidation"; attribute :>> order="GC can occur after protected copy; reenter and refresh source/patch grant and revision"; attribute :>> premise="old physical pointer/patch may not be reused just because descriptor is unchanged"; attribute :>> obligation="canonical-resolver"; }
part memory5:MemoryRow { attribute :>> key="queue"; attribute :>> order="do not hold FIFO gate while waiting for frame access"; attribute :>> premise="return routing commit and queue activation are distinct; retain private root until actual queue handoff"; attribute :>> obligation="two-model-steps"; }
part def GainRow { attribute key:String; attribute benefit:String; attribute cost:String; attribute condition:String; attribute refutation:String; }
part gain0:GainRow { attribute :>> key="slot-contract"; attribute :>> benefit="one proven logical-to-C-to-GC coordinate convention"; attribute :>> cost="SplitSpec program-point/alias and boxed-value checks remain"; attribute :>> condition="same source/frame ABI and allocated ranges"; attribute :>> refutation="numeric disjointness does not exclude reflective/FFI aliases"; }
part gain1:GainRow { attribute :>> key="no-recopy"; attribute :>> benefit="one initialized copy across J GC relocation/revalidation cycles"; attribute :>> cost="J canonical revalidation/patch preparations plus GC scanning of copy"; attribute :>> condition="all copied pointer fields and links updated by GC; source semantic contents unchanged"; attribute :>> refutation="unregistered private field or source mutation requires rebuild/reject"; }
part gain2:GainRow { attribute :>> key="one-route"; attribute :>> benefit="exclude duplicate first local/remote parent dispatch"; attribute :>> cost="decision CAS, pending result root and routing patch"; attribute :>> condition="one dynamic admitted occurrence; no check-then-return"; attribute :>> refutation="not permission to memoize multishot Scheme suffixes"; }
part gain3:GainRow { attribute :>> key="shared-gate"; attribute :>> benefit="reference correctness design can reuse known exclusion discipline"; attribute :>> cost="global gate may serialize root-chain scanning and split copying"; attribute :>> condition="admit every role and reset only after drain"; attribute :>> refutation="processor identity does not prove disjoint shared captured tails"; }
part gain4:GainRow { attribute :>> key="finer-domains"; attribute :>> benefit="potentially reduce unrelated-frame contention"; attribute :>> cost="canonical identity, alias/overlap proof, lock order and more state"; attribute :>> condition="actual independence and lifecycle demonstrated"; attribute :>> refutation="stack coordinate partition alone is not a global ownership proof"; }
part gain5:GainRow { attribute :>> key="current-hooks"; attribute :>> benefit="makes a missing task routing responsibility explicit"; attribute :>> cost="all new parallel mechanics cost work compared with empty hooks"; attribute :>> condition="useful parallel work must overcome added overhead"; attribute :>> refutation="no current eager-allocation savings claimed"; }
part def ContractRow { attribute fromNode:String; attribute toNode:String; attribute custody:String; }
part contract0:ContractRow { attribute :>> fromNode="gen-fut parent/child contexts"; attribute :>> toNode="Coordinate contract"; attribute :>> custody="parent 1..S; child j maps S+j; return homes separate"; }
part contract1:ContractRow { attribute :>> fromNode="Coordinate contract"; attribute :>> toNode="C return FrameSpec"; attribute :>> custody="aligned parent fs=S-3; ordinary bits and structural link differ"; }
part contract2:ContractRow { attribute :>> fromNode="C return FrameSpec"; attribute :>> toNode="GC stack/heap scan"; attribute :>> custody="same addresses under stated descriptor/range premises"; }
part contract3:ContractRow { attribute :>> fromNode="Canonical frame root"; attribute :>> toNode="Protected frame access"; attribute :>> custody="resolve current stack/heap form after each grant"; }
part contract4:ContractRow { attribute :>> fromNode="GC forwarding"; attribute :>> toNode="Canonical frame root"; attribute :>> custody="repair roots and links; cached fp can be stale"; }
part contract5:ContractRow { attribute :>> fromNode="Protected frame access"; attribute :>> toNode="Private rooted copy"; attribute :>> custody="initialize once; collector updates registered fields"; }
part contract6:ContractRow { attribute :>> fromNode="Private rooted copy"; attribute :>> toNode="Return decision commit"; attribute :>> custody="fresh revision/generation/lease and prepared link patch"; }
part contract7:ContractRow { attribute :>> fromNode="Child completion"; attribute :>> toNode="Pending result root"; attribute :>> custody="does not authorize local fallback while RESERVED"; }
part contract8:ContractRow { attribute :>> fromNode="Return decision commit"; attribute :>> toNode="LOCAL dispatch grant"; attribute :>> custody="only definitive LOCAL; no SPLIT fallthrough"; }
part contract9:ContractRow { attribute :>> fromNode="Return decision commit"; attribute :>> toNode="SPLIT dispatch grant"; attribute :>> custody="only definitive SPLIT; parent roots held before queue activation"; }
part contract10:ContractRow { attribute :>> fromNode="Closed all-role admission"; attribute :>> toNode="Domain reset"; attribute :>> custody="all old holders gone before gate/generation reuse"; }
part contract11:ContractRow { attribute :>> fromNode="Return decision commit"; attribute :>> toNode="Parent split/queue model"; attribute :>> custody="paired logical commit preserves both actual-model Steps; activation gates dequeue; native linearization remains open"; }
part def NeedRow { attribute key:String; attribute status:String; attribute condition:String; }
part need0:NeedRow { attribute :>> key="coordinate-laws"; attribute :>> status="formal"; attribute :>> condition="word-index partition, aligned normal parent root mapping and worked bitmap proved under stated parameters"; }
part need1:NeedRow { attribute :>> key="return-safety"; attribute :>> status="formal"; attribute :>> condition="one first-return grant; SPLIT forbids local parent dispatch; child result remains rooted"; }
part need2:NeedRow { attribute :>> key="gc-snapshot"; attribute :>> status="formal"; attribute :>> condition="same access gate excludes forwarding during protected access; later forwarding requires fresh patch and grant"; }
part need3:NeedRow { attribute :>> key="copy-count"; attribute :>> status="formal"; attribute :>> condition="initialized registered copy can be revalidated across modeled GC without another initialization"; }
part need4:NeedRow { attribute :>> key="parent-coupling"; attribute :>> status="formal"; attribute :>> condition="legacy conditional lemma retained; product induction proves aligned commit and first-return routing without assuming Coupled"; }
part need5:NeedRow { attribute :>> key="physical-slot-refinement"; attribute :>> status="unresolved"; attribute :>> condition="actual GVM values, boxed registers, normal/internal roots and allocated pointer ranges refine coordinate functions"; }
part need6:NeedRow { attribute :>> key="canonical-resolver"; attribute :>> status="unresolved"; attribute :>> condition="a real rooted frame/marker handle resolves current stack or heap representation; raw cached fp excluded"; }
part need7:NeedRow { attribute :>> key="role-census"; attribute :>> status="unresolved"; attribute :>> condition="existing GC-only frame gate and reset admit every new frame reader/writer with correct lifetime"; }
part need8:NeedRow { attribute :>> key="all-writers"; attribute :>> status="unresolved"; attribute :>> condition="source parent immutable except qualified GC/link writers; reflection/FFI/continuation aliases excluded or mediated"; }
part need9:NeedRow { attribute :>> key="copy-update-adapter"; attribute :>> status="unresolved"; attribute :>> condition="GC scans and relocates every initialized private-copy field and structural link"; }
part need10:NeedRow { attribute :>> key="c23-memory"; attribute :>> status="unresolved"; attribute :>> condition="protected link patch plus release decision, acquire consumers and root publication refine C23"; }
part need11:NeedRow { attribute :>> key="two-model-steps"; attribute :>> status="formal"; attribute :>> condition="67-field product projects every 36-action step to actual FrameCommitAst and LazySplitAst Step or stutter; paired logical commit and activation gate preserve alignment through first return"; }
part need12:NeedRow { attribute :>> key="full-control-errors"; attribute :>> status="unresolved"; attribute :>> condition="exceptions/cancel/escaping child continuation and multishot dispatch identity remain outside normal fixed-occurrence model"; }
part need13:NeedRow { attribute :>> key="net-native-return"; attribute :>> status="unresolved"; attribute :>> condition="copy/revalidation benefit and global-gate contention require native qualification; no timing claim"; }
part composition5:CompositionRow { attribute :>> key="uncoupled-safe-pair"; attribute :>> lemma="FrameCommitBridge.safePairsNeedPhaseRelation"; attribute :>> source="emit-return"; attribute :>> obligation="parent-coupling"; attribute :>> boundary="safe individual milestone states do not imply Coupled; not a native or full-product execution counterexample"; }

part need14:NeedRow { attribute :>> key="product-native-cut"; attribute :>> status="unresolved"; attribute :>> condition="stable TaskId, inactive publication, atomic routing decision and non-abandonable bookkeeping must realize the paired logical cut; no native queue implementation or C23 weak-memory refinement exists"; }

part component6:ComponentRow { attribute :>> componentId="queue-activation"; attribute :>> sharedContract="FrameCoordinates/CanonicalRoot/ReturnDecision/AccessGeneration"; attribute :>> role="inactive rooted publication, definitive acceptance, matched split commit, activation and idempotent notification"; }

part source49:SourceRow { attribute :>> key="fifo-lock"; attribute :>> path="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> needle="___HIDDEN void lock_chunk_fifo"; attribute :>> obligation="local GC queue exclusion; not a future-task publication API"; }

part source50:SourceRow { attribute :>> key="chunk-claim"; attribute :>> path="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> needle="require_chunk_transition(work,node+1,1,2);"; attribute :>> obligation="claim responsibility before removing head"; }

part source51:SourceRow { attribute :>> key="chunk-ready"; attribute :>> path="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> needle="require_chunk_transition(work,alloc_heap_chunk_start,0,1);"; attribute :>> obligation="initialized chunk authority precedes queue link publication"; }

part source52:SourceRow { attribute :>> key="chunk-tail"; attribute :>> path="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> needle="heap_chunks_to_scan_tail = new_tail;"; attribute :>> obligation="tail visibility must follow payload/link publication"; }

part source53:SourceRow { attribute :>> key="chunk-notify"; attribute :>> path="vendor/gambit/lib/_mem/heap-sections.inc"; attribute :>> needle="___CONDVAR_SIGNAL(scan_termination_condvar);"; attribute :>> obligation="notification follows queue publication; not ownership transfer"; }

part def PairRow { attribute actionName:String; attribute nativeAction:String; attribute queueAction:String; attribute lemma:String; attribute boundary:String; }

part pair0:PairRow { attribute :>> actionName="future_frame_activation.reserve"; attribute :>> nativeAction="future_frame_commit.reserveSplit"; attribute :>> queueAction="lazy_future_split.claimSplit"; attribute :>> lemma="FrameActivation.reserveProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route21:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.reserve"; attribute :>> lemma="FrameActivation.reserveProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair1:PairRow { attribute :>> actionName="future_frame_activation.allocate"; attribute :>> nativeAction="future_frame_commit.allocateRootedCopy"; attribute :>> queueAction="lazy_future_split.allocateCopy"; attribute :>> lemma="FrameActivation.allocateProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route22:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.allocate"; attribute :>> lemma="FrameActivation.allocateProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair2:PairRow { attribute :>> actionName="future_frame_activation.enter"; attribute :>> nativeAction="future_frame_commit.enterRuntime"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.enterProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route23:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.enter"; attribute :>> lemma="FrameActivation.enterProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair3:PairRow { attribute :>> actionName="future_frame_activation.resolve"; attribute :>> nativeAction="future_frame_commit.resolveCanonical"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.resolveProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route24:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.resolve"; attribute :>> lemma="FrameActivation.resolveProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair4:PairRow { attribute :>> actionName="future_frame_activation.initialize"; attribute :>> nativeAction="future_frame_commit.initializeCopy"; attribute :>> queueAction="lazy_future_split.initializeCopy"; attribute :>> lemma="FrameActivation.initializeProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route25:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.initialize"; attribute :>> lemma="FrameActivation.initializeProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair5:PairRow { attribute :>> actionName="future_frame_activation.validate"; attribute :>> nativeAction="future_frame_commit.validateCopy"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.validateProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route26:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.validate"; attribute :>> lemma="FrameActivation.validateProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair6:PairRow { attribute :>> actionName="future_frame_activation.prepare"; attribute :>> nativeAction="future_frame_commit.prepareReturn"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.prepareProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route27:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.prepare"; attribute :>> lemma="FrameActivation.prepareProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair7:PairRow { attribute :>> actionName="future_frame_activation.sendPublication"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.sendPublicationProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route28:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.sendPublication"; attribute :>> lemma="FrameActivation.sendPublicationProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair8:PairRow { attribute :>> actionName="future_frame_activation.publicationUnknown"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.publicationUnknownProjects"; attribute :>> boundary="stable delivery identity; private source/copy roots retained; no rollback"; }

part route29:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.publicationUnknown"; attribute :>> lemma="FrameActivation.publicationUnknownProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair9:PairRow { attribute :>> actionName="future_frame_activation.acceptPublication"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.publishReady"; attribute :>> lemma="FrameActivation.acceptPublicationProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route30:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.acceptPublication"; attribute :>> lemma="FrameActivation.acceptPublicationProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair10:PairRow { attribute :>> actionName="future_frame_activation.rejectPublication"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.rejectPublicationProjects"; attribute :>> boundary="definitive absence and no late activation; timeout or lost response is not rejection"; }

part route31:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.rejectPublication"; attribute :>> lemma="FrameActivation.rejectPublicationProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair11:PairRow { attribute :>> actionName="future_frame_activation.commit"; attribute :>> nativeAction="future_frame_commit.commitSplit"; attribute :>> queueAction="lazy_future_split.commitSplit"; attribute :>> lemma="FrameActivation.commitProjects"; attribute :>> boundary="one shared logical commit changes both models; physical multi-store realization remains unresolved"; }

part route32:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.commit"; attribute :>> lemma="FrameActivation.commitProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair12:PairRow { attribute :>> actionName="future_frame_activation.activationFailed"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.activationFailedProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route33:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.activationFailed"; attribute :>> lemma="FrameActivation.activationFailedProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair13:PairRow { attribute :>> actionName="future_frame_activation.activate"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.activateProjects"; attribute :>> boundary="ledger grants execution after commit; physical wakeup is not the transfer cut"; }

part route34:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.activate"; attribute :>> lemma="FrameActivation.activateProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair14:PairRow { attribute :>> actionName="future_frame_activation.wakeFailed"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.wakeFailedProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route35:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.wakeFailed"; attribute :>> lemma="FrameActivation.wakeFailedProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair15:PairRow { attribute :>> actionName="future_frame_activation.dequeue"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.dequeueParent"; attribute :>> lemma="FrameActivation.dequeueProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route36:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.dequeue"; attribute :>> lemma="FrameActivation.dequeueProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair16:PairRow { attribute :>> actionName="future_frame_activation.restore"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.restoreParent"; attribute :>> lemma="FrameActivation.restoreProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route37:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.restore"; attribute :>> lemma="FrameActivation.restoreProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair17:PairRow { attribute :>> actionName="future_frame_activation.doneLocal"; attribute :>> nativeAction="future_frame_commit.childDone"; attribute :>> queueAction="lazy_future_split.localChildDone"; attribute :>> lemma="FrameActivation.doneLocalProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route38:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.doneLocal"; attribute :>> lemma="FrameActivation.doneLocalProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair18:PairRow { attribute :>> actionName="future_frame_activation.doneSplit"; attribute :>> nativeAction="future_frame_commit.childDone"; attribute :>> queueAction="lazy_future_split.childDoneInSplit"; attribute :>> lemma="FrameActivation.doneSplitProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route39:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.doneSplit"; attribute :>> lemma="FrameActivation.doneSplitProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair19:PairRow { attribute :>> actionName="future_frame_activation.closeLocal"; attribute :>> nativeAction="future_frame_commit.closeLocal"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.closeLocalProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route40:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.closeLocal"; attribute :>> lemma="FrameActivation.closeLocalProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair20:PairRow { attribute :>> actionName="future_frame_activation.abort"; attribute :>> nativeAction="future_frame_commit.abortSplit"; attribute :>> queueAction="lazy_future_split.abortPrivate"; attribute :>> lemma="FrameActivation.abortProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route41:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.abort"; attribute :>> lemma="FrameActivation.abortProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair21:PairRow { attribute :>> actionName="future_frame_activation.finishAborted"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.localAfterAbortDone"; attribute :>> lemma="FrameActivation.finishAbortedProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route42:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.finishAborted"; attribute :>> lemma="FrameActivation.finishAbortedProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair22:PairRow { attribute :>> actionName="future_frame_activation.publishResult"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.publishResult"; attribute :>> lemma="FrameActivation.publishResultProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route43:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.publishResult"; attribute :>> lemma="FrameActivation.publishResultProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair23:PairRow { attribute :>> actionName="future_frame_activation.runPrefix"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.runParentPrefix"; attribute :>> lemma="FrameActivation.runPrefixProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route44:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.runPrefix"; attribute :>> lemma="FrameActivation.runPrefixProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair24:PairRow { attribute :>> actionName="future_frame_activation.grantLocal"; attribute :>> nativeAction="future_frame_commit.grantLocal"; attribute :>> queueAction="lazy_future_split.runLocalParent"; attribute :>> lemma="FrameActivation.grantLocalProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route45:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.grantLocal"; attribute :>> lemma="FrameActivation.grantLocalProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair25:PairRow { attribute :>> actionName="future_frame_activation.grantRemote"; attribute :>> nativeAction="future_frame_commit.grantRemote"; attribute :>> queueAction="lazy_future_split.consumeSplitResult"; attribute :>> lemma="FrameActivation.grantRemoteProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route46:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.grantRemote"; attribute :>> lemma="FrameActivation.grantRemoteProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair26:PairRow { attribute :>> actionName="future_frame_activation.leave"; attribute :>> nativeAction="future_frame_commit.leaveRuntime"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.leaveProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route47:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.leave"; attribute :>> lemma="FrameActivation.leaveProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair27:PairRow { attribute :>> actionName="future_frame_activation.gcEnter"; attribute :>> nativeAction="future_frame_commit.enterGc"; attribute :>> queueAction="lazy_future_split.closeGc"; attribute :>> lemma="FrameActivation.gcEnterProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route48:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.gcEnter"; attribute :>> lemma="FrameActivation.gcEnterProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair28:PairRow { attribute :>> actionName="future_frame_activation.gcFreeze"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.freezeRoots"; attribute :>> lemma="FrameActivation.gcFreezeProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route49:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.gcFreeze"; attribute :>> lemma="FrameActivation.gcFreezeProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair29:PairRow { attribute :>> actionName="future_frame_activation.gcBegin"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.beginScan"; attribute :>> lemma="FrameActivation.gcBeginProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route50:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.gcBegin"; attribute :>> lemma="FrameActivation.gcBeginProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair30:PairRow { attribute :>> actionName="future_frame_activation.forwardNoCopy"; attribute :>> nativeAction="future_frame_commit.forwardNoCopy"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.forwardNoCopyProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route51:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.forwardNoCopy"; attribute :>> lemma="FrameActivation.forwardNoCopyProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair31:PairRow { attribute :>> actionName="future_frame_activation.forwardWithCopy"; attribute :>> nativeAction="future_frame_commit.forwardWithCopy"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.forwardWithCopyProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route52:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.forwardWithCopy"; attribute :>> lemma="FrameActivation.forwardWithCopyProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair32:PairRow { attribute :>> actionName="future_frame_activation.gcEnd"; attribute :>> nativeAction="stutter"; attribute :>> queueAction="lazy_future_split.endScan"; attribute :>> lemma="FrameActivation.gcEndProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route53:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.gcEnd"; attribute :>> lemma="FrameActivation.gcEndProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair33:PairRow { attribute :>> actionName="future_frame_activation.gcLeave"; attribute :>> nativeAction="future_frame_commit.leaveGc"; attribute :>> queueAction="lazy_future_split.resumeGc"; attribute :>> lemma="FrameActivation.gcLeaveProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route54:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.gcLeave"; attribute :>> lemma="FrameActivation.gcLeaveProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair34:PairRow { attribute :>> actionName="future_frame_activation.closeDomain"; attribute :>> nativeAction="future_frame_commit.closeDomain"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.closeDomainProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route55:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.closeDomain"; attribute :>> lemma="FrameActivation.closeDomainProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part pair35:PairRow { attribute :>> actionName="future_frame_activation.resetDomain"; attribute :>> nativeAction="future_frame_commit.resetDomain"; attribute :>> queueAction="stutter"; attribute :>> lemma="FrameActivation.resetDomainProjects"; attribute :>> boundary="one actual step or stutter in each projection; exact guard/update equations proved in Lean"; }

part route56:RouteRow { attribute :>> component="queue-activation"; attribute :>> actionName="future_frame_activation.resetDomain"; attribute :>> lemma="FrameActivation.resetDomainProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="two-model-steps"; }

part composition6:CompositionRow { attribute :>> key="paired-step"; attribute :>> lemma="FrameActivation.stepProjects"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="every admitted product step projects to both actual model Step relations; product restricts schedules and scope"; }

part composition7:CompositionRow { attribute :>> key="inductive-match"; attribute :>> lemma="FrameActivation.reachableSafe"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="initial matching plus actual step preservation; no Coupled assumption"; }

part composition8:CompositionRow { attribute :>> key="reachable-projections"; attribute :>> lemma="FrameActivation.reachableProjections"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="each reachable product prefix is reachable in both actual original models"; }

part composition9:CompositionRow { attribute :>> key="pending-activation"; attribute :>> lemma="FrameActivation.pendingActivationRooted"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="committed but inactive retains queue and copy root; no local fallback"; }

part composition10:CompositionRow { attribute :>> key="unknown-publication"; attribute :>> lemma="FrameActivation.publicationUnknownRooted"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="unknown publication retains source and private destination; no abort grant"; }

part composition11:CompositionRow { attribute :>> key="no-early-claim"; attribute :>> lemma="FrameActivation.noDequeueBeforeActivation"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="dequeue requires active ledger; physical queue must implement this strengthened guard"; }

part composition12:CompositionRow { attribute :>> key="one-first-return"; attribute :>> lemma="FrameActivation.firstGrantOnlyOnce"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="normal occurrence through first grant; multishot suffix semantics excluded"; }

part memory6:MemoryRow { attribute :>> key="prepared-publication"; attribute :>> order="root initialized copy before publishing inactive TaskId; acquire definitive acceptance before split commit"; attribute :>> premise="unknown response preserves both roots; definitive reject excludes all future activation"; attribute :>> obligation="product-native-cut"; }

part memory7:MemoryRow { attribute :>> key="activation-ledger"; attribute :>> order="release definitive SPLIT after protected patch; then release active ledger; acquire decision and active state before dequeue"; attribute :>> premise="GC participation does not require holding FIFO lock while waiting for frame access; notification is only a hint"; attribute :>> obligation="product-native-cut"; }

part memory8:MemoryRow { attribute :>> key="matched-cut"; attribute :>> order="one logical return decision simultaneously refines both split flags; other side may stutter"; attribute :>> premise="a shared stable record and non-abandonable publication bookkeeping must realize the logical atomic step"; attribute :>> obligation="product-native-cut"; }

part gain6:GainRow { attribute :>> key="activation-retries"; attribute :>> benefit="K lost wakeups/activation retries require zero extra parent initializations and zero new child runs"; attribute :>> cost="stable TaskId, root retention, active decision and K retries; no progress bound"; attribute :>> condition="initialized copy remains GC-updated and stable acceptance/activation can be reconciled"; attribute :>> refutation="permanent service failure can retain memory indefinitely; no liveness proof from safety induction"; }

part gain7:GainRow { attribute :>> key="stronger-gate"; attribute :>> benefit="excludes early dequeue and duplicate local parent after split"; attribute :>> cost="one matched logical routing cut plus one activation transition before first dequeue"; attribute :>> condition="native inactive-entry guard and first-return identity match product"; attribute :>> refutation="existing empty TASK hooks do not already supply these guards; not a measured speedup"; }

part composition13:CompositionRow { attribute :>> key="completion-commit"; attribute :>> lemma="FrameActivation.completionCommitGuards"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="both guards survive the opposite action; paired updates commute; physical done/reserve serialization remains open"; }

part composition14:CompositionRow { attribute :>> key="retry-stutter"; attribute :>> lemma="FrameActivation.wakeRetriesStutter"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="arbitrary finite wake retries leave both original records unchanged; no liveness or retention bound"; }

part composition15:CompositionRow { attribute :>> key="early-result"; attribute :>> lemma="FrameActivation.earlyResultRemainsRooted"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="completed result rooted in both projections across admitted normal-prefix steps"; }

part composition16:CompositionRow { attribute :>> key="gc-commit-exclusion"; attribute :>> lemma="FrameActivation.commitRequiresRuntime"; attribute :>> source="emit-return"; attribute :>> obligation="two-model-steps"; attribute :>> boundary="logical commit requires runtime grant and open GC admission; no literal existing frame-gate equivalence"; }

part memory9:MemoryRow { attribute :>> key="done-reserve-word"; attribute :>> order="serialize OPEN/reservation and completion-ready observations; preserve ready bits in routing CAS"; attribute :>> premise="a separate stale done load and later route CAS may not refine the atomic reserve guard"; attribute :>> obligation="product-native-cut"; }

part memory10:MemoryRow { attribute :>> key="inactive-root-alias"; attribute :>> order="inactive entries use stable rooted TaskId handles or registered updateable pointer slots"; attribute :>> premise="a private root update alone does not repair a stale raw queue alias during unknown acceptance"; attribute :>> obligation="copy-update-adapter"; }

part contract12:ContractRow { attribute :>> fromNode="Private rooted copy"; attribute :>> toNode="Publication in flight"; attribute :>> custody="same TaskId; source and copy retain custody while outcome unknown"; }

part contract13:ContractRow { attribute :>> fromNode="Publication in flight"; attribute :>> toNode="Accepted inactive entry"; attribute :>> custody="definitive acceptance; queue root added; no execution grant"; }

part contract14:ContractRow { attribute :>> fromNode="Publication in flight"; attribute :>> toNode="Confirmed private rollback"; attribute :>> custody="only definitive rejection permits LOCAL; source retained"; }

part contract15:ContractRow { attribute :>> fromNode="Accepted inactive entry"; attribute :>> toNode="Matched split commit"; attribute :>> custody="both actual models take commitSplit at one logical routing cut"; }

part contract16:ContractRow { attribute :>> fromNode="Matched split commit"; attribute :>> toNode="Pending activation"; attribute :>> custody="queue and copy stay rooted; SPLIT never falls through LOCAL"; }

part contract17:ContractRow { attribute :>> fromNode="Pending activation"; attribute :>> toNode="Active task ledger"; attribute :>> custody="activate same occurrence; retry failure preserves custody"; }

part contract18:ContractRow { attribute :>> fromNode="Active task ledger"; attribute :>> toNode="Worker restore context"; attribute :>> custody="acquire and single claim before queue-to-restore root handoff"; }

part contract19:ContractRow { attribute :>> fromNode="Active task ledger"; attribute :>> toNode="Notification retry"; attribute :>> custody="wake delivery is not ownership; duplicate/lost response does not restart parent"; }

part contract20:ContractRow { attribute :>> fromNode="GC forwarding"; attribute :>> toNode="Accepted inactive entry"; attribute :>> custody="stable rooted handle or all alias slots updated; actual adapter open"; }

part contract21:ContractRow { attribute :>> fromNode="Worker restore context"; attribute :>> toNode="First parent result grant"; attribute :>> custody="paired consume/grant once; result remains rooted"; }

part contract22:ContractRow { attribute :>> fromNode="Child completion"; attribute :>> toNode="Matched split commit"; attribute :>> custody="completion/commit commute under guards; result-ready bits must not be overwritten"; }

part gain8:GainRow { attribute :>> key="equal-correct-baseline"; attribute :>> benefit="retry/relocation does not force rematerialization in the proved model; not intrinsic superiority over equally correct modern C"; attribute :>> cost="CAS/activation, stable handle, root registration, reconciliation and contention"; attribute :>> condition="any claimed avoided-copy benefit is measured against a baseline that actually repeats that copy"; attribute :>> refutation="if the baseline already retains an updated rooted copy, additional avoided-copy benefit is zero; parallel useful work must pay for added protocol costs"; }

part component7:ComponentRow { attribute :>> componentId="control-word"; attribute :>> sharedContract="FrameCoordinates/CanonicalRoot/ReturnDecision/AccessGeneration"; attribute :>> role="one occurrence, combined route/completion word, observed-value CAS outcomes and cross-owner acquire witnesses"; }

part source54:SourceRow { attribute :>> key="ordered-native"; attribute :>> path="vendor/gambit/include/_gambit/activity_log.h.in"; attribute :>> needle="__atomic_compare_exchange_n(p,&(expected),v,0,__ATOMIC_ACQUIRE,__ATOMIC_RELAXED)"; attribute :>> obligation="current acquire-only success / relaxed failure; native updates expected; not proposed publisher"; }

part source55:SourceRow { attribute :>> key="ordered-legacy"; attribute :>> path="vendor/gambit/include/_gambit/activity_log.h.in"; attribute :>> needle="(___COMPARE_AND_SWAP_WORD(p,expected,v)==(expected))"; attribute :>> obligation="legacy Boolean wrapper does not assign observed value into expected"; }

part source56:SourceRow { attribute :>> key="observed-cas"; attribute :>> path="vendor/gambit/include/_gambit/activity_log.h.in"; attribute :>> needle="__sync_val_compare_and_swap(p,oldval,newval)"; attribute :>> obligation="old-value result must be normalized explicitly, not mistaken for C expected mutation"; }

part source57:SourceRow { attribute :>> key="ordered-storage"; attribute :>> path="vendor/gambit/include/_gambit/activity_log.h.in"; attribute :>> needle="Plain access is restricted to the no-thread backend or exclusive"; attribute :>> obligation="source storage boundary; not typed C23 qualification for new record"; }

part source58:SourceRow { attribute :>> key="c23-observations"; attribute :>> path="evidence/research/source-references/c23-control-word/observations.org"; attribute :>> needle="C23 CAS rules"; attribute :>> obligation="research observation note linked to inspected WG14 primary draft; not exact retained primary PDF bytes"; }

part need15:NeedRow { attribute :>> key="word-cas-steps"; attribute :>> status="formal"; attribute :>> condition="84-field CAS refinement projects every action to actual product Step or stutter and preserves shared-word encoding; one normal occurrence only"; }

part need16:NeedRow { attribute :>> key="word-handoff"; attribute :>> status="formal"; attribute :>> condition="role-local acquire witnesses preserved in model, not global permissions; HB graph composition conditional on externally established sequenced-before / synchronizes-with edges"; }

part need17:NeedRow { attribute :>> key="ordered-adapter"; attribute :>> status="unresolved"; attribute :>> condition="typed padding-free atomic storage and uniform success/observed outcome; native acquire-only wrapper and legacy expected mismatch cannot implement the publisher unchanged; lock-free/profile behavior unqualified"; }

part need18:NeedRow { attribute :>> key="control-reuse"; attribute :>> status="unresolved"; attribute :>> condition="stable task record lifetime, generation identity, no word reset during any access, cancellation/unwind and reuse ABA proof outside fixed occurrence"; }

part def WordRow { attribute actionName:String; attribute parentAction:String; attribute lemma:String; attribute source:String; attribute premise:String; }
part def LayoutRow { attribute value:String; attribute route:String; attribute ready:String; attribute meaning:String; }
part def WordEdgeRow { attribute fromNode:String; attribute toNode:String; attribute custody:String; }

part word0:WordRow { attribute :>> actionName="future_control_word.allocate"; attribute :>> parentAction="future_frame_activation.allocate"; attribute :>> lemma="ControlWord.allocateProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route57:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.allocate"; attribute :>> lemma="ControlWord.allocateProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word1:WordRow { attribute :>> actionName="future_control_word.enter"; attribute :>> parentAction="future_frame_activation.enter"; attribute :>> lemma="ControlWord.enterProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route58:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.enter"; attribute :>> lemma="ControlWord.enterProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word2:WordRow { attribute :>> actionName="future_control_word.resolve"; attribute :>> parentAction="future_frame_activation.resolve"; attribute :>> lemma="ControlWord.resolveProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route59:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.resolve"; attribute :>> lemma="ControlWord.resolveProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word3:WordRow { attribute :>> actionName="future_control_word.initialize"; attribute :>> parentAction="future_frame_activation.initialize"; attribute :>> lemma="ControlWord.initializeProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route60:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.initialize"; attribute :>> lemma="ControlWord.initializeProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word4:WordRow { attribute :>> actionName="future_control_word.validate"; attribute :>> parentAction="future_frame_activation.validate"; attribute :>> lemma="ControlWord.validateProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route61:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.validate"; attribute :>> lemma="ControlWord.validateProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word5:WordRow { attribute :>> actionName="future_control_word.prepare"; attribute :>> parentAction="future_frame_activation.prepare"; attribute :>> lemma="ControlWord.prepareProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route62:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.prepare"; attribute :>> lemma="ControlWord.prepareProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word6:WordRow { attribute :>> actionName="future_control_word.sendPublication"; attribute :>> parentAction="future_frame_activation.sendPublication"; attribute :>> lemma="ControlWord.sendPublicationProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route63:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.sendPublication"; attribute :>> lemma="ControlWord.sendPublicationProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word7:WordRow { attribute :>> actionName="future_control_word.publicationUnknown"; attribute :>> parentAction="future_frame_activation.publicationUnknown"; attribute :>> lemma="ControlWord.publicationUnknownProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route64:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.publicationUnknown"; attribute :>> lemma="ControlWord.publicationUnknownProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word8:WordRow { attribute :>> actionName="future_control_word.acceptPublication"; attribute :>> parentAction="future_frame_activation.acceptPublication"; attribute :>> lemma="ControlWord.acceptPublicationProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route65:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.acceptPublication"; attribute :>> lemma="ControlWord.acceptPublicationProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word9:WordRow { attribute :>> actionName="future_control_word.rejectPublication"; attribute :>> parentAction="future_frame_activation.rejectPublication"; attribute :>> lemma="ControlWord.rejectPublicationProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route66:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.rejectPublication"; attribute :>> lemma="ControlWord.rejectPublicationProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word10:WordRow { attribute :>> actionName="future_control_word.activationFailed"; attribute :>> parentAction="future_frame_activation.activationFailed"; attribute :>> lemma="ControlWord.activationFailedProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route67:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.activationFailed"; attribute :>> lemma="ControlWord.activationFailedProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word11:WordRow { attribute :>> actionName="future_control_word.wakeFailed"; attribute :>> parentAction="future_frame_activation.wakeFailed"; attribute :>> lemma="ControlWord.wakeFailedProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route68:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.wakeFailed"; attribute :>> lemma="ControlWord.wakeFailedProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word12:WordRow { attribute :>> actionName="future_control_word.restore"; attribute :>> parentAction="future_frame_activation.restore"; attribute :>> lemma="ControlWord.restoreProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route69:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.restore"; attribute :>> lemma="ControlWord.restoreProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word13:WordRow { attribute :>> actionName="future_control_word.finishAborted"; attribute :>> parentAction="future_frame_activation.finishAborted"; attribute :>> lemma="ControlWord.finishAbortedProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route70:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.finishAborted"; attribute :>> lemma="ControlWord.finishAbortedProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word14:WordRow { attribute :>> actionName="future_control_word.publishResult"; attribute :>> parentAction="future_frame_activation.publishResult"; attribute :>> lemma="ControlWord.publishResultProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route71:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.publishResult"; attribute :>> lemma="ControlWord.publishResultProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word15:WordRow { attribute :>> actionName="future_control_word.runPrefix"; attribute :>> parentAction="future_frame_activation.runPrefix"; attribute :>> lemma="ControlWord.runPrefixProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route72:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.runPrefix"; attribute :>> lemma="ControlWord.runPrefixProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word16:WordRow { attribute :>> actionName="future_control_word.grantLocal"; attribute :>> parentAction="future_frame_activation.grantLocal"; attribute :>> lemma="ControlWord.grantLocalProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route73:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.grantLocal"; attribute :>> lemma="ControlWord.grantLocalProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word17:WordRow { attribute :>> actionName="future_control_word.leave"; attribute :>> parentAction="future_frame_activation.leave"; attribute :>> lemma="ControlWord.leaveProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route74:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.leave"; attribute :>> lemma="ControlWord.leaveProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word18:WordRow { attribute :>> actionName="future_control_word.gcEnter"; attribute :>> parentAction="future_frame_activation.gcEnter"; attribute :>> lemma="ControlWord.gcEnterProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route75:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.gcEnter"; attribute :>> lemma="ControlWord.gcEnterProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word19:WordRow { attribute :>> actionName="future_control_word.gcFreeze"; attribute :>> parentAction="future_frame_activation.gcFreeze"; attribute :>> lemma="ControlWord.gcFreezeProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route76:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.gcFreeze"; attribute :>> lemma="ControlWord.gcFreezeProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word20:WordRow { attribute :>> actionName="future_control_word.gcBegin"; attribute :>> parentAction="future_frame_activation.gcBegin"; attribute :>> lemma="ControlWord.gcBeginProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route77:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.gcBegin"; attribute :>> lemma="ControlWord.gcBeginProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word21:WordRow { attribute :>> actionName="future_control_word.forwardNoCopy"; attribute :>> parentAction="future_frame_activation.forwardNoCopy"; attribute :>> lemma="ControlWord.forwardNoCopyProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route78:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.forwardNoCopy"; attribute :>> lemma="ControlWord.forwardNoCopyProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word22:WordRow { attribute :>> actionName="future_control_word.forwardWithCopy"; attribute :>> parentAction="future_frame_activation.forwardWithCopy"; attribute :>> lemma="ControlWord.forwardWithCopyProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route79:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.forwardWithCopy"; attribute :>> lemma="ControlWord.forwardWithCopyProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word23:WordRow { attribute :>> actionName="future_control_word.gcEnd"; attribute :>> parentAction="future_frame_activation.gcEnd"; attribute :>> lemma="ControlWord.gcEndProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route80:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.gcEnd"; attribute :>> lemma="ControlWord.gcEndProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word24:WordRow { attribute :>> actionName="future_control_word.gcLeave"; attribute :>> parentAction="future_frame_activation.gcLeave"; attribute :>> lemma="ControlWord.gcLeaveProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route81:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.gcLeave"; attribute :>> lemma="ControlWord.gcLeaveProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word25:WordRow { attribute :>> actionName="future_control_word.closeDomain"; attribute :>> parentAction="future_frame_activation.closeDomain"; attribute :>> lemma="ControlWord.closeDomainProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route82:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.closeDomain"; attribute :>> lemma="ControlWord.closeDomainProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word26:WordRow { attribute :>> actionName="future_control_word.resetDomain"; attribute :>> parentAction="future_frame_activation.resetDomain"; attribute :>> lemma="ControlWord.resetDomainProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route83:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.resetDomain"; attribute :>> lemma="ControlWord.resetDomainProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word27:WordRow { attribute :>> actionName="future_control_word.prepareResult"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.prepareResultProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route84:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.prepareResult"; attribute :>> lemma="ControlWord.prepareResultProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word28:WordRow { attribute :>> actionName="future_control_word.loadReserve"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.loadReserveProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route85:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.loadReserve"; attribute :>> lemma="ControlWord.loadReserveProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word29:WordRow { attribute :>> actionName="future_control_word.loadCommit"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.loadCommitProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route86:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.loadCommit"; attribute :>> lemma="ControlWord.loadCommitProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word30:WordRow { attribute :>> actionName="future_control_word.loadAbort"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.loadAbortProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route87:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.loadAbort"; attribute :>> lemma="ControlWord.loadAbortProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word31:WordRow { attribute :>> actionName="future_control_word.splitFailure"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.splitFailureProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route88:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.splitFailure"; attribute :>> lemma="ControlWord.splitFailureProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word32:WordRow { attribute :>> actionName="future_control_word.casReserve"; attribute :>> parentAction="future_frame_activation.reserve"; attribute :>> lemma="ControlWord.casReserveProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route89:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.casReserve"; attribute :>> lemma="ControlWord.casReserveProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word33:WordRow { attribute :>> actionName="future_control_word.casCommit"; attribute :>> parentAction="future_frame_activation.commit"; attribute :>> lemma="ControlWord.casCommitProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route90:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.casCommit"; attribute :>> lemma="ControlWord.casCommitProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word34:WordRow { attribute :>> actionName="future_control_word.casAbort"; attribute :>> parentAction="future_frame_activation.abort"; attribute :>> lemma="ControlWord.casAbortProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route91:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.casAbort"; attribute :>> lemma="ControlWord.casAbortProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word35:WordRow { attribute :>> actionName="future_control_word.loadChild"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.loadChildProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route92:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.loadChild"; attribute :>> lemma="ControlWord.loadChildProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word36:WordRow { attribute :>> actionName="future_control_word.loadLocal"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.loadLocalProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route93:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.loadLocal"; attribute :>> lemma="ControlWord.loadLocalProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word37:WordRow { attribute :>> actionName="future_control_word.childFailure"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.childFailureProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route94:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.childFailure"; attribute :>> lemma="ControlWord.childFailureProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word38:WordRow { attribute :>> actionName="future_control_word.casChildLocal"; attribute :>> parentAction="future_frame_activation.doneLocal"; attribute :>> lemma="ControlWord.casChildLocalProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route95:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.casChildLocal"; attribute :>> lemma="ControlWord.casChildLocalProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word39:WordRow { attribute :>> actionName="future_control_word.casChildSplit"; attribute :>> parentAction="future_frame_activation.doneSplit"; attribute :>> lemma="ControlWord.casChildSplitProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route96:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.casChildSplit"; attribute :>> lemma="ControlWord.casChildSplitProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word40:WordRow { attribute :>> actionName="future_control_word.casCloseLocal"; attribute :>> parentAction="future_frame_activation.closeLocal"; attribute :>> lemma="ControlWord.casCloseLocalProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route97:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.casCloseLocal"; attribute :>> lemma="ControlWord.casCloseLocalProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word41:WordRow { attribute :>> actionName="future_control_word.retirePreparedResult"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.retirePreparedResultProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route98:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.retirePreparedResult"; attribute :>> lemma="ControlWord.retirePreparedResultProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part word42:WordRow { attribute :>> actionName="future_control_word.acquireCommit"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.acquireCommitProjects"; attribute :>> source="c23-observations"; attribute :>> premise="qualifying acquire reads-from release or its release sequence; numeric value alone does not prove native HB"; }

part route99:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.acquireCommit"; attribute :>> lemma="ControlWord.acquireCommitProjects"; attribute :>> producerAnchor="c23-observations"; attribute :>> obligationId="word-cas-steps"; }

part word43:WordRow { attribute :>> actionName="future_control_word.casActivate"; attribute :>> parentAction="future_frame_activation.activate"; attribute :>> lemma="ControlWord.casActivateProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route100:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.casActivate"; attribute :>> lemma="ControlWord.casActivateProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word44:WordRow { attribute :>> actionName="future_control_word.acquireActive"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.acquireActiveProjects"; attribute :>> source="c23-observations"; attribute :>> premise="qualifying acquire reads-from release or its release sequence; numeric value alone does not prove native HB"; }

part route101:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.acquireActive"; attribute :>> lemma="ControlWord.acquireActiveProjects"; attribute :>> producerAnchor="c23-observations"; attribute :>> obligationId="word-cas-steps"; }

part word45:WordRow { attribute :>> actionName="future_control_word.casDequeue"; attribute :>> parentAction="future_frame_activation.dequeue"; attribute :>> lemma="ControlWord.casDequeueProjects"; attribute :>> source="ordered-native"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route102:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.casDequeue"; attribute :>> lemma="ControlWord.casDequeueProjects"; attribute :>> producerAnchor="ordered-native"; attribute :>> obligationId="word-cas-steps"; }

part word46:WordRow { attribute :>> actionName="future_control_word.acquireResult"; attribute :>> parentAction="stutter"; attribute :>> lemma="ControlWord.acquireResultProjects"; attribute :>> source="c23-observations"; attribute :>> premise="qualifying acquire reads-from release or its release sequence; numeric value alone does not prove native HB"; }

part route103:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.acquireResult"; attribute :>> lemma="ControlWord.acquireResultProjects"; attribute :>> producerAnchor="c23-observations"; attribute :>> obligationId="word-cas-steps"; }

part word47:WordRow { attribute :>> actionName="future_control_word.grantRemote"; attribute :>> parentAction="future_frame_activation.grantRemote"; attribute :>> lemma="ControlWord.grantRemoteProjects"; attribute :>> source="emit-return"; attribute :>> premise="fixed occurrence; successful CAS compares every word bit; failure only refreshes observation and clears intent"; }

part route104:RouteRow { attribute :>> component="control-word"; attribute :>> actionName="future_control_word.grantRemote"; attribute :>> lemma="ControlWord.grantRemoteProjects"; attribute :>> producerAnchor="emit-return"; attribute :>> obligationId="word-cas-steps"; }

part layout0:LayoutRow { attribute :>> value="0"; attribute :>> route="0"; attribute :>> ready="0"; attribute :>> meaning="OPEN / result pending"; }

part layout1:LayoutRow { attribute :>> value="1"; attribute :>> route="1"; attribute :>> ready="0"; attribute :>> meaning="RESERVED / result pending"; }

part layout2:LayoutRow { attribute :>> value="2"; attribute :>> route="2"; attribute :>> ready="0"; attribute :>> meaning="SPLIT / result pending"; }

part layout3:LayoutRow { attribute :>> value="3"; attribute :>> route="3"; attribute :>> ready="0"; attribute :>> meaning="LOCAL / result pending"; }

part layout4:LayoutRow { attribute :>> value="4"; attribute :>> route="0"; attribute :>> ready="1"; attribute :>> meaning="OPEN / result ready"; }

part layout5:LayoutRow { attribute :>> value="5"; attribute :>> route="1"; attribute :>> ready="1"; attribute :>> meaning="RESERVED / result ready"; }

part layout6:LayoutRow { attribute :>> value="6"; attribute :>> route="2"; attribute :>> ready="1"; attribute :>> meaning="SPLIT / result ready"; }

part layout7:LayoutRow { attribute :>> value="7"; attribute :>> route="3"; attribute :>> ready="1"; attribute :>> meaning="LOCAL / result ready"; }

part composition17:CompositionRow { attribute :>> key="word-refinement"; attribute :>> lemma="ControlWord.reachableParent"; attribute :>> source="ordered-native"; attribute :>> obligation="word-cas-steps"; attribute :>> boundary="every reachable CAS prefix projects to the actual paired product, hence both original models"; }

part composition18:CompositionRow { attribute :>> key="word-encoding"; attribute :>> lemma="ControlWord.encodingInjective"; attribute :>> source="ordered-native"; attribute :>> obligation="word-cas-steps"; attribute :>> boundary="two route bits plus one completion bit; mathematical Int encoding, not C storage proof"; }

part composition19:CompositionRow { attribute :>> key="stale-cas"; attribute :>> lemma="ControlWord.staleCommitMustFail"; attribute :>> source="ordered-native"; attribute :>> obligation="word-cas-steps"; attribute :>> boundary="completion racing with split invalidates whole-word expected; no stale desired overwrite"; }

part composition20:CompositionRow { attribute :>> key="failed-cas"; attribute :>> lemma="ControlWord.failureClearsIntent"; attribute :>> source="ordered-native"; attribute :>> obligation="word-cas-steps"; attribute :>> boundary="failure refreshes observed word and clears operation; native adapter must supply this uniformly"; }

part composition21:CompositionRow { attribute :>> key="preserved-ready"; attribute :>> lemma="ControlWord.commitPreservesDone"; attribute :>> source="ordered-native"; attribute :>> obligation="word-cas-steps"; attribute :>> boundary="successful commit changes routing while retaining current completion bit"; }

part composition22:CompositionRow { attribute :>> key="activation-witness"; attribute :>> lemma="ControlWord.crossOwnerActivation"; attribute :>> source="ordered-native"; attribute :>> obligation="word-handoff"; attribute :>> boundary="active implies commit acquired and carried; witness assumption is not a C23 execution proof"; }

part composition23:CompositionRow { attribute :>> key="handoff-graph"; attribute :>> lemma="ControlWord.releaseAcquireComposition"; attribute :>> source="ordered-native"; attribute :>> obligation="word-handoff"; attribute :>> boundary="conditional transitive HB graph with explicit external SW premises"; }

part composition24:CompositionRow { attribute :>> key="rmw-bound"; attribute :>> lemma="ControlWord.successfulRmwBound"; attribute :>> source="ordered-native"; attribute :>> obligation="word-cas-steps"; attribute :>> boundary="at most three state-changing protocol word CAS plus two activation/claim CAS; backend CAS loads, retries and root-registration excluded"; }

part memory11:MemoryRow { attribute :>> key="cas-outcome"; attribute :>> order="normalize success and observed value; recompute desired from observed after every failure"; attribute :>> premise="legacy wrapper does not mutate expected; weak failure may observe equality"; attribute :>> obligation="ordered-adapter"; }

part memory12:MemoryRow { attribute :>> key="cas-publisher"; attribute :>> order="reference success acq_rel / failure acquire; all route/result writes use RMW"; attribute :>> premise="all-acq_rel is conservative; narrower orders require separate proof; no whole-word plain stores"; attribute :>> obligation="ordered-adapter"; }

part memory13:MemoryRow { attribute :>> key="owner-relay"; attribute :>> order="commit release -> qualifying activator acquire -> active release -> qualifying worker acquire"; attribute :>> premise="child completion RMW can extend release sequence; numeric route equality alone is insufficient"; attribute :>> obligation="c23-memory"; }

part memory14:MemoryRow { attribute :>> key="result-carrier"; attribute :>> order="prepare result in existing rooted child context before completion release; retain until shared root delivery is confirmed"; attribute :>> premise="CAS failure never frees prepared result; registry and GC relocation adapter remain required"; attribute :>> obligation="copy-update-adapter"; }

part gain9:GainRow { attribute :>> key="bounded-success-cas"; attribute :>> benefit="normal fixed occurrence uses at most 3 state-changing route/completion CAS and 2 activation/claim CAS"; attribute :>> cost="unbounded weak/contention failures, acquire observations, roots, copy, registry and GC costs are additional"; attribute :>> condition="no cancellation/reuse; stable TaskId; same primitive semantics across adapters"; attribute :>> refutation="bound is not a latency/progress or lock-free guarantee; empty current task hooks cost less but provide no split service"; }

part wordEdge0:WordEdgeRow { attribute :>> fromNode="Task occurrence pin"; attribute :>> toNode="Route + ready word"; attribute :>> custody="no reuse while any owner/observer/root lives"; }

part wordEdge1:WordEdgeRow { attribute :>> fromNode="Reserve CAS"; attribute :>> toNode="Route + ready word"; attribute :>> custody="0 -> 1; whole expected word must match"; }

part wordEdge2:WordEdgeRow { attribute :>> fromNode="Prepared child root"; attribute :>> toNode="Child completion CAS"; attribute :>> custody="payload/root first; CAS merges +4, retains source carrier"; }

part wordEdge3:WordEdgeRow { attribute :>> fromNode="Child completion CAS"; attribute :>> toNode="Route + ready word"; attribute :>> custody="0/1/2/3 -> 4/5/6/7; old splitter expected must fail"; }

part wordEdge4:WordEdgeRow { attribute :>> fromNode="Split commit CAS"; attribute :>> toNode="Route + ready word"; attribute :>> custody="1 -> 2 or 5 -> 6; preserve ready bit"; }

part wordEdge5:WordEdgeRow { attribute :>> fromNode="Route + ready word"; attribute :>> toNode="Activator acquire"; attribute :>> custody="reads commit or qualifying completion RMW release sequence"; }

part wordEdge6:WordEdgeRow { attribute :>> fromNode="Activator acquire"; attribute :>> toNode="Active ledger release"; attribute :>> custody="carry commit visibility across owners"; }

part wordEdge7:WordEdgeRow { attribute :>> fromNode="Active ledger release"; attribute :>> toNode="Worker acquire and claim"; attribute :>> custody="inactive -> active -> claimed; notification is not permission"; }

part wordEdge8:WordEdgeRow { attribute :>> fromNode="CAS failure"; attribute :>> toNode="Reclassify and rebuild"; attribute :>> custody="refresh observed value; clear intent; no grant or root release"; }

part wordEdge9:WordEdgeRow { attribute :>> fromNode="GC root adapter"; attribute :>> toNode="Prepared child root"; attribute :>> custody="physical scan/update remains unresolved"; }
}
