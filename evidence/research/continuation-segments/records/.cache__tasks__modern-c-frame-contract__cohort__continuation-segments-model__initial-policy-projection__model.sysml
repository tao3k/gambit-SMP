/* Refinement of canonical control/roots/execution/foreign owners.
 * One obligation, one semantic key, one verification responsibility.
 * The LLM is the working environment, not another runtime/model service. */
package GambitContinuationSegments {
  private import ScalarValues::*;
  attribute sourceLock:String="evidence/research/continuation-segments/source.lock.json";
  attribute runtimeAdmitted:Boolean=false;
  attribute commitAdmitted:Boolean=false;
  part def Facet {
    ref part owner:GambitRuntimeComposition::BlueprintModule;
    attribute id:String; attribute contract:String; attribute anchors:String;
    attribute replacement:String; attribute retirement:String;
    attribute benefit:String; attribute cost:String; attribute refutation:String;
  }
  part capture:Facet {
    ref part :>> owner=GambitRuntimeComposition::blueprintModule5;
    attribute :>> id="capture";
    attribute :>> contract="CapturedControl identifies logical frame chain, current image revision, denv/wind identity, PointId and root custodian; stack-backed capture is legal before heap materialization";
    attribute :>> anchors="Gambit _kernel.scm:3153-3171; mem.c:4046-4206; Chez c/schsig.c:56-141 and c/alloc.c:866-882";
    attribute :>> replacement="Register the source slot before any collecting materializer; one descriptor drives stack/heap coordinates and captured-image updates";
    attribute :>> retirement="Independent handwritten frame-coordinate decoding and unregistered materialization inputs after every consumer migrates";
    attribute :>> benefit="Keep full multi-shot semantics while sharing eligible captured storage; avoid unnecessary eager whole-chain materialization";
    attribute :>> cost="Descriptor lifetime, rooted image handle and possible materialization/copy; no immutable-image assumption";
    attribute :>> refutation="Raw frame/continuation setters bypass revision/root discipline or a structural link is mistaken for an ordinary root";
  }
  part replay:Facet {
    ref part :>> owner=GambitRuntimeComposition::blueprintModule2;
    attribute :>> id="replay";
    attribute :>> contract="Per-invocation execution view and rooted transfer outlive collecting hooks; a valid issued view is refreshed after intervening image changes; Scheme heap identity is shared";
    attribute :>> anchors="Gambit _thread.scm:4992-5075; Chez c/schsig.c:86-141; Guile libguile/vm.c:1185-1268";
    attribute :>> replacement="Prepare/root view, run Scheme winding, revalidate image and native origin, then commit restoration under the current execution grant";
    attribute :>> retirement="C activation or old cached pointer as implicit replay authority; full continuation consumption as an optimization";
    attribute :>> benefit="Arbitrary repeated full continuation use; reusable restore path for future delimited segments; one-shot optimization remains optional and separately justified";
    attribute :>> cost="Per-shot restore work and rooted view retention; image changes can force refresh; no guarantee of zero copying";
    attribute :>> refutation="Matching version is accepted without authentic issuance/all-writer history, or replay rolls back shared heap effects";
  }
  part roots:Facet {
    ref part :>> owner=GambitRuntimeComposition::blueprintModule3;
    attribute :>> id="roots";
    attribute :>> contract="Root view covers captured and active frames, denv/winders, prompt tags, pending transfer/views, values and code metadata; scanner updates authoritative slots before reentry reload";
    attribute :>> anchors="Gambit mem.c:4459-4508; Chez s/mkgc.ss:209-269; Guile libguile/vm.c:713-772";
    attribute :>> replacement="FrameSpec-derived exact movable roots plus managed frame/denv/prompt stores and remembered writes; preserve source custody until destination registration";
    attribute :>> retirement="Repeated private interpretations of live slots and unchecked old-to-young stores only after complete writer inventory and adapters";
    attribute :>> benefit="Enable precise moving/generational collection and conditional mature-image scan skipping; root protocol is shared by backends";
    attribute :>> cost="Root publication/reload, metadata, barriers and remembered scans; retained roots and promotion reserve affect peak";
    attribute :>> refutation="Import Guile conservative BDW stack marking as precise moving-GC evidence or infer copying implies generations";
  }
  part winding:Facet {
    ref part :>> owner=GambitRuntimeComposition::blueprintModule5;
    attribute :>> id="winding";
    attribute :>> contract="Compare dynamic extent identity; exit inner-to-outer, enter outer-to-inner; identical extent runs no hooks; hooks may allocate, throw or capture/reenter";
    attribute :>> anchors="Gambit _thread.scm:4796-4821,4918-5018; Chez s/4.ss:349-397; Guile libguile/dynstack.c:322-442,446-505";
    attribute :>> replacement="Keep wind semantics and successor continuations in Scheme; generated C supplies rooted checkpoint/reentry adapters, not a second C winding algorithm";
    attribute :>> retirement="Ad hoc native cleanup treated as Scheme dynamic-wind; physical permit reuse solely because a logical extent is restored";
    attribute :>> benefit="Amplify existing Scheme nonlocal control without introducing semantic drift across GC, scheduler and FFI";
    attribute :>> cost="Required user hooks/effects remain; rooted transfers and fresh physical grants add work";
    attribute :>> refutation="Compare hook procedure equality instead of extent identity, replay hooks twice after a stale helper return, or refuse a legal Scheme hook continuation";
  }
  part promptBoundary:Facet {
    ref part :>> owner=GambitRuntimeComposition::blueprintModule5;
    attribute :>> id="prompt";
    attribute :>> contract="PromptSpec defines tag identity, delimiter cut, handler context, abort/composition and reinstatement policy separately from invocation multiplicity";
    attribute :>> anchors="Guile libguile/vm.c:1310-1345 and module/ice-9/control.scm:59-78; Sitaram PLDI 1993; Flatt/Yu/Findler/Felleisen ICFP 2007";
    attribute :>> replacement="Add prompt/partial-segment operations through the same FrameSpec/control/root ABI after full multi-shot baseline qualification";
    attribute :>> retirement="No existing call/cc or wind path retires merely because a library emulates shift/reset";
    attribute :>> benefit="Capture only an admitted semantic segment; support composable control/effects without downgrading full continuation capability";
    attribute :>> cost="Prompt lookup and handler/wind interaction; copied segment and dynamic metadata; escape-only can omit image only when no replay is exposed";
    attribute :>> refutation="Treat all prompt operators as shift/reset, apply an escape-only object as multi-shot, or silently change full call/cc extent";
  }
  part nativeBoundary:Facet {
    ref part :>> owner=GambitRuntimeComposition::blueprintModule6;
    attribute :>> id="foreign";
    attribute :>> contract="NativeOrigin identifies a still-live C activation; rooted Scheme frames cannot resurrect it; borrowers end before moving scan and cache reload precedes reentry";
    attribute :>> anchors="Gambit lib/c_intf.c and ___run callers; Guile libguile/continuations.c:186-213,345-376 and vm.c:1316-1325";
    attribute :>> replacement="Managed native activation/root/borrow adapters explicitly admit crossing, parking and return; nested calls obtain their own activation";
    attribute :>> retirement="Marker bit or restored Scheme frame alone as proof of live C origin after complete caller migration";
    attribute :>> benefit="Admitted blocked native calls surrender GC participation safely while roots and results remain owned";
    attribute :>> cost="Handles, origin checks, park/reload and retained resources; unknown native users can prevent selected reclamation";
    attribute :>> refutation="Import Guile thread/barrier restrictions verbatim or promise arbitrary C-stack migration without an origin proof";
  }
  part schema:Facet {
    ref part :>> owner=GambitRuntimeComposition::blueprintModule0;
    attribute :>> id="schema";
    attribute :>> contract="Scheme generates one FrameSpec/PointId/ControlSpec root and restore description; modern C realizes target layout, not Scheme policy";
    attribute :>> anchors="Gambit gsc/_t-c-1.scm; include/gambit.h.in:9275-9440; _kernel.scm frame consumers";
    attribute :>> replacement="Migrate emitter, decoder, collector, restorer, frame reflection and module metadata as one vertical slice";
    attribute :>> retirement="Duplicated C macro/primitive frame meaning after exact generated/native consumer equivalence and bootstrap";
    attribute :>> benefit="Gambit semantic information serves GC, native ABI, tooling and future LLVM/MLIR consumers; no second language is required";
    attribute :>> cost="Schema verification, metadata and affected-closure regeneration; LLVM services do not own Scheme semantics";
    attribute :>> refutation="Add another descriptor wrapper while old macro interpretations remain authoritative";
  }
  part def Obligation {
    attribute id:String; attribute semanticKey:String; attribute owner:String;
    attribute artifact:String; attribute declaration:String; attribute scope:String; attribute limitation:String;
  }
  part schedule:Obligation {
    attribute :>> id="CS-SCHEDULE"; attribute :>> semanticKey="control/transition-order-and-permit-lifetime"; attribute :>> owner="quint";
    attribute :>> artifact="dev/architecture/runtime/control/models/quint/continuation_segments.qnt"; attribute :>> declaration="safe";
    attribute :>> scope="finite schedules only: GC/root cuts, wind/reentry, stale permits and repeated availability";
    attribute :>> limitation="No payload coherence algebra, unbounded proof, complete Scheme observations or C memory-order proof";
  }
  part coherence:Obligation {
    attribute :>> id="CS-COHERENCE"; attribute :>> semanticKey="data/issued-view-coherence-under-versioned-history"; attribute :>> owner="lean";
    attribute :>> artifact="dev/architecture/runtime/control/models/lean/ContinuationSegments.lean"; attribute :>> declaration="issuedViewRemainsCoherent";
    attribute :>> scope="unbounded slot maps and finite writer histories under authentic issuance and version match";
    attribute :>> limitation="No scheduler, GC interleaving, winding or C proof; version equality alone is insufficient";
  }
  part bridge:Obligation {
    attribute :>> id="CS-BRIDGE"; attribute :>> semanticKey="refinement/ticket-interface-to-issued-view-premises"; attribute :>> owner="source";
    attribute :>> artifact="dev/architecture/runtime/control/models/sysml/continuation-segments.sysml"; attribute :>> declaration="ticketPayloadBridge";
    attribute :>> scope="QNT abstracts payload as a ticket; source adapter must issue a real coherent view and map mutation revocation to ImageHistory";
    attribute :>> limitation="OPEN; a shared field name or two successful tools does not establish this correspondence";
  }
  part writers:Obligation {
    attribute :>> id="CS-WRITERS"; attribute :>> semanticKey="source/all-frame-denv-root-writers"; attribute :>> owner="source";
    attribute :>> artifact="evidence/research/continuation-segments/source.lock.json"; attribute :>> declaration="writerInventory";
    attribute :>> scope="Actual frame/continuation/denv setters, GC repair, restoration, serializer and FFI stores obey publication and remembered-root policy";
    attribute :>> limitation="OPEN; selected real setters are identified, not every indirect/native writer closed";
  }
  part hookSemantics:Obligation {
    attribute :>> id="CS-HOOKS"; attribute :>> semanticKey="semantics/arbitrary-hook-capture-and-reinstatement"; attribute :>> owner="source";
    attribute :>> artifact="vendor/gambit/lib/_thread.scm"; attribute :>> declaration="##continuation-unwind-wind";
    attribute :>> scope="Preserve arbitrary Scheme hooks, returning/abandoned transfers and fresh physical authorization on reinstatement";
    attribute :>> limitation="OPEN; bounded takeover histories do not prove arbitrary hook-continuation restoration";
  }
  part promptSemantics:Obligation {
    attribute :>> id="CS-PROMPTS"; attribute :>> semanticKey="semantics/delimiter-composition-and-handler-context"; attribute :>> owner="source";
    attribute :>> artifact="evidence/research/continuation-segments/source.lock.json"; attribute :>> declaration="PromptSpec";
    attribute :>> scope="Specify actual operator family and its joint call/cc, dynamic-wind, dynamic binding and exception observations";
    attribute :>> limitation="OPEN; QNT only qualifies matching-tag/escape/borrow admission, not production prompt semantics";
  }
  part nativeAcceptance:Obligation {
    attribute :>> id="CS-NATIVE"; attribute :>> semanticKey="native/full-generated-control-root-ffi-regression"; attribute :>> owner="native";
    attribute :>> artifact="vendor/gambit/tests/frame-continuation-roots.scm"; attribute :>> declaration="full modern-C replacement acceptance";
    attribute :>> scope="Complete bootstrap and all affected control/root/FFI caller paths, exact Bazel profile and unchanged limits";
    attribute :>> limitation="OPEN; previous wide-root receipts are baseline evidence, not new prompt/alias/foreign qualification";
  }
  part frameRefinement:Obligation {
    attribute :>> id="CS-FRAMES"; attribute :>> semanticKey="source/generated-frame-coordinate-equivalence"; attribute :>> owner="source";
    attribute :>> artifact="vendor/gambit/include/gambit.h.in"; attribute :>> declaration="___decode_frame_descriptor";
    attribute :>> scope="Emitter, stack/heap materializer, scanner, ordinary/link partition, reflector, restorer and module metadata share FrameSpec";
    attribute :>> limitation="OPEN; source-address, layout and lifetime refinement required";
  }
  part def Use { ref part facet:Facet; ref part obligation:Obligation; }
  part use0:Use { ref part :>> facet=capture; ref part :>> obligation=schedule; }
  part use1:Use { ref part :>> facet=capture; ref part :>> obligation=writers; }
  part use2:Use { ref part :>> facet=capture; ref part :>> obligation=frameRefinement; }
  part use3:Use { ref part :>> facet=replay; ref part :>> obligation=schedule; }
  part use4:Use { ref part :>> facet=replay; ref part :>> obligation=coherence; }
  part use5:Use { ref part :>> facet=replay; ref part :>> obligation=bridge; }
  part use6:Use { ref part :>> facet=roots; ref part :>> obligation=schedule; }
  part use7:Use { ref part :>> facet=roots; ref part :>> obligation=writers; }
  part use8:Use { ref part :>> facet=winding; ref part :>> obligation=schedule; }
  part use9:Use { ref part :>> facet=winding; ref part :>> obligation=hookSemantics; }
  part use10:Use { ref part :>> facet=promptBoundary; ref part :>> obligation=schedule; }
  part use11:Use { ref part :>> facet=promptBoundary; ref part :>> obligation=promptSemantics; }
  part use12:Use { ref part :>> facet=nativeBoundary; ref part :>> obligation=schedule; }
  part use13:Use { ref part :>> facet=nativeBoundary; ref part :>> obligation=nativeAcceptance; }
  part use14:Use { ref part :>> facet=schema; ref part :>> obligation=frameRefinement; }
  part def Handoff { ref part producer:Facet; ref part consumer:Facet; attribute contract:String; }
  part edge0:Handoff { ref part :>> producer=schema; ref part :>> consumer=capture; attribute :>> contract="FrameSpec / PointId / stack-to-heap map"; }
  part edge1:Handoff { ref part :>> producer=capture; ref part :>> consumer=roots; attribute :>> contract="Registered captured image and denv/wind roots"; }
  part edge2:Handoff { ref part :>> producer=roots; ref part :>> consumer=replay; attribute :>> contract="Relocated authoritative slots and root reload"; }
  part edge3:Handoff { ref part :>> producer=replay; ref part :>> consumer=winding; attribute :>> contract="Rooted Scheme transfer; hooks may collect or reenter"; }
  part edge4:Handoff { ref part :>> producer=winding; ref part :>> consumer=replay; attribute :>> contract="Post-hook image refresh and current grant before commit"; }
  part edge5:Handoff { ref part :>> producer=promptBoundary; ref part :>> consumer=capture; attribute :>> contract="Explicit delimiter / tag / composition policy"; }
  part edge6:Handoff { ref part :>> producer=nativeBoundary; ref part :>> consumer=replay; attribute :>> contract="Live-origin admission; no native-stack resurrection"; }
}
