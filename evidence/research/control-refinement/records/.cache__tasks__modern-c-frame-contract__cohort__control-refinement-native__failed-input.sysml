/* Source refinement and native acceptance refine existing obligations.
 * No additional Quint or Lean copy of those obligations is introduced. */
package GambitControlRefinement {
  private import ScalarValues::*;
  attribute target:String="full-control";
  attribute predecessor:String="evidence/research/continuation-segments/validation.json";
  attribute profile:String="evidence/fixtures/gerbil-bazel-build-profile/profile.json";
  part def Route {
    ref part obligation:GambitContinuationSegments::Obligation;
    attribute id:String; attribute method:String; attribute claim:String;
    attribute sourceClosure:String; attribute gap:String; attribute cut:String;
  }
  part bridge:Route {
    ref part :>> obligation=GambitContinuationSegments::bridge;
    attribute :>> id="bridge"; attribute :>> method="source";
    attribute :>> claim="A real issued RestoreView refines an opaque current ticket and Lean authentic issuance/history premises";
    attribute :>> sourceClosure="Construct an abstraction map for rooted slot identities, image ownership, mutation revision and commit; prove every admitted source transition preserves issuance, revocation and relocation correspondence";
    attribute :>> gap="No FrameStore/RestoreView implementation or complete source simulation exists; collector frame_gate does not exclude raw mutator setters";
    attribute :>> cut="Registered capture/materialization -> stable alias domain -> prepare -> Scheme hooks -> reload/revalidate -> exclusive restore commit";
  }
  part writers:Route {
    ref part :>> obligation=GambitContinuationSegments::writers;
    attribute :>> id="writers"; attribute :>> method="source";
    attribute :>> claim="All admitted writes preserve frame aliases, denv identity, root visibility and remembered edges";
    attribute :>> sourceClosure="Classify reflection, traversal, deserialization, I/O rebuild, thread save/restore, denv vectors, collector repair and native roots; each write has exactly one registered owner, exclusion and root/barrier adapter; unmanaged writes lose optimized admission";
    attribute :>> gap="Raw c-code and exported C macros defeat closed-world completeness; arbitrary vector aliases and unregistered native clients remain unqualified";
    attribute :>> cut="Shared physical frame identity owns revision; wrapper continuation identity alone cannot revoke all alias views; initialization and moving repair have explicit privileged modes";
  }
  part hooks:Route {
    ref part :>> obligation=GambitContinuationSegments::hookSemantics;
    attribute :>> id="hooks"; attribute :>> method="source";
    attribute :>> claim="Arbitrary Scheme hook capture, escape and repeated reinstatement retain dynamic-wind observations";
    attribute :>> sourceClosure="Relate old and new Scheme transfer continuations at user-call boundaries; preserve dynamic extent identity, denv, values, exception destination and order; fresh physical grant on each resumed suffix";
    attribute :>> gap="No source relation covers arbitrary saved hook continuations; a stale native helper must be refused without rejecting the legal Scheme continuation";
    attribute :>> cut="Factor the two Scheme semantic bodies through one common definition while retaining scheduler-specific accessors; rooted C crossing handles grants and reload only";
  }
  part prompts:Route {
    ref part :>> obligation=GambitContinuationSegments::promptSemantics;
    attribute :>> id="prompts"; attribute :>> method="source";
    attribute :>> claim="Full multi-shot baseline stays full; explicit partial-control extension has its own operator semantics";
    attribute :>> sourceClosure="For full-control prove no hidden delimiter truncates call/cc and no partial operation is advertised; for prompt-extension specify tag, cut, handler, composition, reinstatement and native-crossing observations separately";
    attribute :>> gap="PromptSpec is a design, not an implemented operator; Guile rewindability is evidence for a boundary, not Gambit semantic equivalence";
    attribute :>> cut="Reuse frame/root/transfer ABI; admit prompt-extension only after full-control and its own operator/foreign tests; do not weaken full-call semantics to close a gate";
  }
  part native:Route {
    ref part :>> obligation=GambitContinuationSegments::nativeAcceptance;
    attribute :>> id="native"; attribute :>> method="native";
    attribute :>> claim="Generated C, moving GC, multi-shot control and admitted native callers execute correctly under the exact profile";
    attribute :>> sourceClosure="Source review establishes where tests must exercise both ___run origins, generated SFUN/CFUN, catcher restoration, return-to-C and root consumers; source reading cannot close execution acceptance";
    attribute :>> gap="Existing fixture only exercises a synchronous C leaf; it does not test nested C-to-Scheme callbacks, hook capture, cross-context restore or dead-origin rejection";
    attribute :>> cut="One native acceptance owner consumes source/profile/case-bound receipts for the complete replacement; previous bootstrap and wide-root results remain baseline only";
  }
  part frames:Route {
    ref part :>> obligation=GambitContinuationSegments::frameRefinement;
    attribute :>> id="frames"; attribute :>> method="source";
    attribute :>> claim="Scheme frame encoding and every modern C consumer agree on live slots, structural links and metadata lifetime";
    attribute :>> sourceClosure="Derive stack coordinate FRAME_SPACE(fs)-i, heap coordinate fs-i+1 and gc bit i-1 from one FrameSpec; account for internal expanded size, task/normal kinds, link+1 exclusion, module lifetime and all materializers/restorers";
    attribute :>> gap="Shared decoder is partial progress; kernel copy/traversal and generated FFI still embed layout; descriptor input is trusted live metadata, not a validated arbitrary pointer";
    attribute :>> cut="Emitter -> ABI descriptors -> active/captured scanner -> kernel materialize/reflect/next/break -> FFI frame -> module metadata must migrate together";
  }
  part def Witness {
    ref part route:Route;
    attribute id:String; attribute file:String; attribute firstLine:Integer; attribute lastLine:Integer;
    attribute finding:String;
  }
  part w0:Witness { ref part :>> route=bridge; attribute :>> id="capture-gc"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> first=3153; attribute :>> last=3170; attribute :>> finding="Frame reification may GC; frame/denv setters are explicit primitives"; }
  part w1:Witness { ref part :>> route=bridge; attribute :>> id="alias-copy-next"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> first=3612; attribute :>> last=3725; attribute :>> finding="Continuation copy shares frame and denv; next! mutates wrapper and may write stack RA while traversing"; }
  part w2:Witness { ref part :>> route=bridge; attribute :>> id="collector-exclusion"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> first=3711; attribute :>> last=3733; attribute :>> finding="Frame gate serializes admitted collector operations; this is not proof that mutator setters use it"; }
  part w3:Witness { ref part :>> route=bridge; attribute :>> id="moving-root-origin"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> first=7282; attribute :>> last=7305; attribute :>> finding="Worker scans a frozen participant context including startup thunk, marker and RC data"; }
  part w4:Witness { ref part :>> route=writers; attribute :>> id="raw-frame-stores"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> first=3435; attribute :>> last=3555; attribute :>> finding="Heap and stack setters directly write their coordinate; wrapper revision alone misses shared-frame mutation"; }
  part w5:Witness { ref part :>> route=writers; attribute :>> id="deserialize-shells"; attribute :>> file="vendor/gambit/lib/_system.scm"; attribute :>> first=4140; attribute :>> last=4227; attribute :>> finding="Deserializer registers shells before recursive children and subsequently fills continuation/frame slots"; }
  part w6:Witness { ref part :>> route=writers; attribute :>> id="io-reconstruction"; attribute :>> file="vendor/gambit/lib/_io.scm"; attribute :>> first=11690; attribute :>> last=11730; attribute :>> finding="I/O explode/implode uses live maps and writes frames; separate path from deserialization"; }
  part w7:Witness { ref part :>> route=writers; attribute :>> id="scheduler-frame-stores"; attribute :>> file="vendor/gambit/include/gambit.h.in"; attribute :>> first=6310; attribute :>> last=6395; attribute :>> finding="THREAD_SAVE publishes stack-backed frames; THREAD_RESTORE consumes the thread continuation slot, distinct from full call/cc application"; }
  part w8:Witness { ref part :>> route=writers; attribute :>> id="denv-alias-vector"; attribute :>> file="vendor/gambit/lib/_thread#.scm"; attribute :>> first=742; attribute :>> last=786; attribute :>> finding="Dynamic environment and wind records are vectors with field macros; shared vector mutation requires adapter coverage"; }
  part w9:Witness { ref part :>> route=writers; attribute :>> id="native-rc-store"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> first=708; attribute :>> last=842; attribute :>> finding="RC register/unlink and data writes are explicit C APIs; set_data_rc carries no owner argument"; }
  part w10:Witness { ref part :>> route=hooks; attribute :>> id="smp-wind"; attribute :>> file="vendor/gambit/lib/_thread.scm"; attribute :>> first=4916; attribute :>> last=5077; attribute :>> finding="Graft-based Scheme continuations own hook suffixes; same-extent return bypasses hooks"; }
  part w11:Witness { ref part :>> route=hooks; attribute :>> id="non-smp-wind"; attribute :>> file="vendor/gambit/lib/_thread.scm"; attribute :>> first=8426; attribute :>> last=8587; attribute :>> finding="Non-SMP branch contains the corresponding winding body and same-extent shortcut"; }
  part w12:Witness { ref part :>> route=hooks; attribute :>> id="chez-wind"; attribute :>> file="vendor/chez/s/4.ss"; attribute :>> first=349; attribute :>> last=397; attribute :>> finding="Common winder tail uses identity; state updates surround hooks, not merely procedure equality"; }
  part w13:Witness { ref part :>> route=prompts; attribute :>> id="guile-partial"; attribute :>> file=".cache/tasks/modern-c-frame-contract/cohort/control-references/guile/libguile/vm.c"; attribute :>> first=1307; attribute :>> last=1346; attribute :>> finding="Partial capture finds a frame cut and checks saved native registers before declaring rewindability"; }
  part w14:Witness { ref part :>> route=prompts; attribute :>> id="guile-reinstate"; attribute :>> file=".cache/tasks/modern-c-frame-contract/cohort/control-references/guile/module/ice-9/control.scm"; attribute :>> first=59; attribute :>> last=84; attribute :>> finding="shift/reset wrappers explicitly reinstall prompts; partial image alone does not specify operator semantics"; }
  part w15:Witness { ref part :>> route=native; attribute :>> id="native-marker"; attribute :>> file="vendor/gambit/lib/c_intf.c"; attribute :>> first=6509; attribute :>> last=6576; attribute :>> finding="Rooted startup reload and legacy local wrapper differ; marker clear precedes still refcount decrement"; }
  part w16:Witness { ref part :>> route=native; attribute :>> id="call-run"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> first=3515; attribute :>> last=3695; attribute :>> finding="___call constructs a two-slot C-return frame; ___run catches errors and releases marker after the call path"; }
  part w17:Witness { ref part :>> route=native; attribute :>> id="run-worker-origin"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> first=766; attribute :>> last=802; attribute :>> finding="Processor execution enters ___run then reports error through collective synchronization"; }
  part w18:Witness { ref part :>> route=native; attribute :>> id="run-setup-origin"; attribute :>> file="vendor/gambit/lib/setup.c"; attribute :>> first=6814; attribute :>> last=6848; attribute :>> finding="Initial setup enters ___run with a thunk extracted from module descriptors"; }
  part w19:Witness { ref part :>> route=native; attribute :>> id="ffi-generator"; attribute :>> file="vendor/gambit/gsc/_ptree2.scm"; attribute :>> first=2930; attribute :>> last=3004; attribute :>> finding="FFI generation selects SFUN/CFUN conversion, cleanup and result macros; not located only in _t-c emitters"; }
  part w20:Witness { ref part :>> route=native; attribute :>> id="ffi-arg-emission"; attribute :>> file="vendor/gambit/gsc/_ptree2.scm"; attribute :>> first=3143; attribute :>> last=3185; attribute :>> finding="C-to-Scheme generator emits argument slot writes before SFUN call"; }
  part w21:Witness { ref part :>> route=native; attribute :>> id="catcher-and-sfun"; attribute :>> file="vendor/gambit/include/gambit.h.in"; attribute :>> first=10110; attribute :>> last=10200; attribute :>> finding="setjmp catcher restore and SFUN error/cleanup are macro paths requiring generated exit coverage"; }
  part w22:Witness { ref part :>> route=native; attribute :>> id="return-c-origin"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> first=1017; attribute :>> last=1071; attribute :>> finding="Return-to-C checks processor and invalidated marker before throwing to ___call"; }
  part w23:Witness { ref part :>> route=native; attribute :>> id="tcl-payload-delete"; attribute :>> file="vendor/gambit/examples/tcltk/tcltk.scm"; attribute :>> first=136; attribute :>> last=198; attribute :>> finding="Tcl callback reads ClientData payload and delete releases Scheme and RC ownership; pin-before-read is an extra adapter obligation"; }
  part w24:Witness { ref part :>> route=native; attribute :>> id="wide-map-baseline"; attribute :>> file="vendor/gambit/tests/frame-continuation-roots.scm"; attribute :>> first=1; attribute :>> last=94; attribute :>> finding="Real map retains 80 roots and resumes capture with 20/200; synchronous c-lambda leaf is not callback or cross-context coverage"; }
  part w25:Witness { ref part :>> route=frames; attribute :>> id="scheme-frame-spec"; attribute :>> file="vendor/gambit/gsc/_t-c-3.scm"; attribute :>> first=471; attribute :>> last=530; attribute :>> finding="Scheme constructs validated frame-spec and chunks root bits after semantic liveness"; }
  part w26:Witness { ref part :>> route=frames; attribute :>> id="return-kinds"; attribute :>> file="vendor/gambit/gsc/_t-c-2.scm"; attribute :>> first=275; attribute :>> last=291; attribute :>> finding="Normal/task/internal return paths construct the same frame-spec abstraction"; }
  part w27:Witness { ref part :>> route=frames; attribute :>> id="descriptor-emission"; attribute :>> file="vendor/gambit/gsc/_t-c-1.scm"; attribute :>> first=1940; attribute :>> last=2013; attribute :>> finding="Emitter chooses IFD/OFD and chunk representation from FrameSpec"; }
  part w28:Witness { ref part :>> route=frames; attribute :>> id="descriptor-consumer"; attribute :>> file="vendor/gambit/include/gambit.h.in"; attribute :>> first=9270; attribute :>> last=9417; attribute :>> finding="Trusted descriptor decoder and one-based root cursor exclude structural link for ordinary scanning"; }
  part w29:Witness { ref part :>> route=frames; attribute :>> id="captured-copy-link"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> first=4046; attribute :>> last=4207; attribute :>> finding="Copy reserves capacity, copies payload, repairs source/destination links, publishes scan then commits reservation"; }
  part w30:Witness { ref part :>> route=frames; attribute :>> id="heap-frame-scan"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> first=4459; attribute :>> last=4518; attribute :>> finding="Heap scan treats ordinary roots, structural link and RA separately under frame access"; }
  part w31:Witness { ref part :>> route=frames; attribute :>> id="break-restore"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> first=1182; attribute :>> last=1296; attribute :>> finding="Stack/heap caller restoration copies a reached frame and preserves break-link tail-call behavior"; }
  part w32:Witness { ref part :>> route=frames; attribute :>> id="map-source"; attribute :>> file="vendor/gambit/lib/gambit/list/list.scm"; attribute :>> first=818; attribute :>> last=870; attribute :>> finding="Higher-order result and recursive tail are live across non-tail calls; source map is sequential, not automatically parallel"; }
  part w33:Witness { ref part :>> route=frames; attribute :>> id="chez-stack-owner"; attribute :>> file="vendor/chez/s/mkgc.ss"; attribute :>> first=209; attribute :>> last=269; attribute :>> finding="Generated GC traces continuation fields and relies on single stack-segment ownership for remote sweeping"; }
  part def NativeCase {
    ref part obligation:GambitContinuationSegments::Obligation;
    attribute id:String; attribute target:String; attribute observation:String;
    attribute baseline:String; attribute missing:String;
  }
  part n0:NativeCase { ref part :>> obligation=GambitContinuationSegments::nativeAcceptance; attribute :>> id="bootstrap-map"; attribute :>> target="full-control"; attribute :>> observation="Exact-source complete bootstrap then real map, 80 roots, repeated restoration, GC and natural exit in p1/p11; unchanged heap/watchdog"; attribute :>> baseline="Historical exact-source scoped lanes exist"; attribute :>> missing="Requalify the complete new replacement source closure; do not substitute old binaries"; }
  part n1:NativeCase { ref part :>> obligation=GambitContinuationSegments::nativeAcceptance; attribute :>> id="alias-rebuild"; attribute :>> target="full-control"; attribute :>> observation="Two wrappers share frames; reflective write/next!/denv mutation, serializer and I/O roundtrip, GC between prepare and commit; correct values and relocation"; attribute :>> baseline="Real writers identified"; attribute :>> missing="Executable alias/rebuild regression and complete adapter implementation"; }
  part n2:NativeCase { ref part :>> obligation=GambitContinuationSegments::nativeAcceptance; attribute :>> id="hook-reentry"; attribute :>> target="full-control"; attribute :>> observation="Capture inside before/after, resume it repeatedly, nested wind, same extent, multiple values, allocation/GC and exception escape; compare Scheme event traces"; attribute :>> baseline="Current fixture records simple before/after only"; attribute :>> missing="Arbitrary hook suffix reentry/abandonment cases and independent expected observations"; }
  part n3:NativeCase { ref part :>> obligation=GambitContinuationSegments::nativeAcceptance; attribute :>> id="native-origins"; attribute :>> target="full-control"; attribute :>> observation="Both ___run origins plus generated SFUN/CFUN, marker allocation GC, nested callbacks, conversion errors, catcher restore, live/dead/wrong-origin return"; attribute :>> baseline="Leaf c-lambda call exists; managed startup roots are partial progress"; attribute :>> missing="Callback/borrow admission tests; Tcl bridge remains unqualified until pin/delete and cross-library cleanup are covered"; }
  part n4:NativeCase { ref part :>> obligation=GambitContinuationSegments::nativeAcceptance; attribute :>> id="context-worker"; attribute :>> target="full-control"; attribute :>> observation="Two execution contexts use independent views of shared capture under writer exclusion; worker scans frozen origin; resize/unknown join retains selected roots while healthy VM still GC progresses"; attribute :>> baseline="Participant context root scanner exists; carrier and worker remain coupled in places"; attribute :>> missing="Actual admitted migration, unique scan and unknown-join isolation under unchanged limits; no automatic parallel map"; }
  part n5:NativeCase { ref part :>> obligation=GambitContinuationSegments::nativeAcceptance; attribute :>> id="layout-lifetime"; attribute :>> target="full-control"; attribute :>> observation="Normal/task/internal, IFD/OFD word/sign-bit boundaries, stack/heap link sharing, code metadata lifetime and proper tail space across restore"; attribute :>> baseline="Wide root fixture crosses a map word boundary"; attribute :>> missing="All admitted target widths/configurations and module unload/lifetime regressions; unsupported combinations explicitly excluded"; }
  part n6:NativeCase { ref part :>> obligation=GambitContinuationSegments::nativeAcceptance; attribute :>> id="capacity-benefit"; attribute :>> target="full-control"; attribute :>> observation="Record capture/materialize/restored words, root visits, frame-gate contention, copy/CAS-loss refunds, retained unknown debt, whole-round peak; reserve failure preserves source before flip"; attribute :>> baseline="Per-copy reservation and scoped refund evidence exists"; attribute :>> missing="Joint pre-flip physical reserve and measured end-to-end net benefit, not only a new check or larger heap"; }
  part n7:NativeCase { ref part :>> obligation=GambitContinuationSegments::nativeAcceptance; attribute :>> id="prompt-operators"; attribute :>> target="prompt-extension"; attribute :>> observation="Explicit operator family: matching/missing tags, abort/composition, reinstatement, wind/denv/exceptions, multi-shot use and native boundary"; attribute :>> baseline="Pinned Guile source explains a concrete operator family"; attribute :>> missing="New Gambit operator implementation and source relation; not a requirement to change existing full call/cc"; }
  part def Gate { attribute id:String; attribute criterion:String; }
  part g0:Gate { attribute :>> id="tests"; attribute :>> requirement="All selected native cases pass for the same source/profile, plus unchanged applicable formal receipts"; }
  part g1:Gate { attribute :>> id="architecture"; attribute :>> requirement="Real retired owners and measured work/peak costs, not extra wrappers or moved patches"; }
  part g2:Gate { attribute :>> id="process"; attribute :>> requirement="Complete vertical replacement and explicit failure custody; no stranded caller/consumer"; }
  part g3:Gate { attribute :>> id="models"; attribute :>> requirement="Five source obligations refine their unique contracts; QNT and Lean remain distinct; no source audit is a proof"; }
  part g4:Gate { attribute :>> id="questions"; attribute :>> requirement="Full/multi-shot semantics, aliases, hook reinstatement, native origin, multicore sharing and extension boundary answered for the selected target"; }
}
