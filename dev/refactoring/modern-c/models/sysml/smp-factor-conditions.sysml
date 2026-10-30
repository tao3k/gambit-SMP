/* Refines the existing eight pressure arguments; does not create a new layout.
 * Relevance to an observed failure is not universal causal attribution. */
package GambitSmpFactorConditions {
  private import ScalarValues::*;
  attribute gateLedger:String="docs/smp-twelve-gate-research-map.md";
  attribute priorEvidence:String="evidence/research/modern-c-bootstrap/architecture-causal-validation.json";
  part def Factor {
    ref part argument:GambitCausalArchitecture::Argument;
    attribute id:String; attribute scope:String; attribute mechanism:String;
    attribute sourceCondition:String; attribute nativeCondition:String;
    attribute workMetric:String; attribute memoryMetric:String; attribute boundary:String;
  }
  part f0:Factor {
    ref part :>> argument=GambitCausalArchitecture::exitCase; attribute :>> id="exit";
    attribute :>> scope="runtime lifecycle dependency";
    attribute :>> mechanism="Admission, heap participation and native lifetime are conflated; unknown result can cause unsafe reuse or unnecessarily broad GC veto";
    attribute :>> sourceCondition="Accepted callback/result and final native user have explicit custodian and disposition; withdrawal proves frozen/no-write root boundary separately from handle closure";
    attribute :>> nativeCondition="Inject known/unknown create/join and late callback outcomes; distinguish healthy other VM from progress inside affected VM; no heap access after certified withdrawal";
    attribute :>> workMetric="GC veto/wait time; accepted, retained and disposed outcomes; progress under fault";
    attribute :>> memoryMetric="Retained handles, roots and physical arenas per unresolved outcome; bound issuance on exhaustion";
    attribute :>> boundary="Alias certificates cannot stop an unknown writer; published native callers need stronger evidence than empty startup actors";
  }
  part f1:Factor {
    ref part :>> argument=GambitCausalArchitecture::work; attribute :>> id="work";
    attribute :>> scope="runtime work/phase dependency";
    attribute :>> mechanism="Carrier processor still selects participant roots/completion; idle counts cannot represent private frontier, Tail and future descendants";
    attribute :>> sourceCondition="Root origin, participant epoch and claimed work are separate; every producer/private cursor/publication descendant accounted for; completion is task-scoped";
    attribute :>> nativeCondition="Different worker/origin counts and worker handoff; late work and withdrawal never lose a root or complete a live phase";
    attribute :>> workMetric="Queued/private/in-flight/descendant work, steals, idle waits and useful scans per worker";
    attribute :>> memoryMetric="Task/cursor metadata and transfer-pending work retention at peak";
    attribute :>> boundary="Role structs alone do not remove synchronous binding; complete producer inventory, source root freeze and fairness remain required";
  }
  part f2:Factor {
    ref part :>> argument=GambitCausalArchitecture::copy; attribute :>> id="copy";
    attribute :>> scope="runtime scan/capacity dependency";
    attribute :>> mechanism="Duplicate scan delivery can become duplicate field writers; forwarding/readiness/Tail are confused, and per-copy reserve is mistaken for a whole-round physical plan";
    attribute :>> sourceCondition="One initializer and ordinary repair owner per destination; explicit Tail/link duties; injective contiguous intervals and resume reserve before flip; independent domains avoid global copy serialization";
    attribute :>> nativeCondition="Repeat delivery and CAS loss under pair/frame sharing; no duplicate repair; reserve failure preserves source; same-profile whole-round peak fits actual intervals";
    attribute :>> workMetric="Deliveries versus granted writers, copied/restored words, refunds and frame-domain contention";
    attribute :>> memoryMetric="Scan metadata, reserved/published intervals, private Tail debt and whole-round physical high-water";
    attribute :>> boundary="Recorded duplicate ordinary scan is a real conflict, not an explanation of every historical crash; current global frame gate and pre-flip planner remain open costs";
  }
  part f3:Factor {
    ref part :>> argument=GambitCausalArchitecture::ffi; attribute :>> id="ffi";
    attribute :>> scope="root/borrow prerequisite of workers";
    attribute :>> mechanism="Incoming values or resize payload can survive only in stale C locals; callback/marker allocation can precede real root registration";
    attribute :>> sourceCondition="Root before collecting conversion/marker, frozen borrow view, post-GC reload, native origin and every exceptional exit covered; destination registration precedes source ACK";
    attribute :>> nativeCondition="Both run origins, generated SFUN/CFUN, nested callbacks and nonzero processor roots under GC; late/unknown exits retain custody";
    attribute :>> workMetric="Root register/reload, park/reentry, scan visits and native participation waits";
    attribute :>> memoryMetric="Fixed control storage separately from retained Scheme graph/native payload; frozen borrowers at peak";
    attribute :>> boundary="A complete alias adapter cannot supply absent raw native access bounds or initialize marker roots retroactively";
  }
  part f4:Factor {
    ref part :>> argument=GambitCausalArchitecture::release; attribute :>> id="release";
    attribute :>> scope="GC progress and shutdown dependency";
    attribute :>> mechanism="Foreign destructor can require an owner callback while that owner waits for collector completion, producing a wait cycle";
    attribute :>> sourceCondition="Effects, affinity, rooted payload and pre-GC budget declared; eligible release work accepted and drained with descendants after required owner execution is permitted";
    attribute :>> nativeCondition="Real release producers, reentrant callbacks, cancellation and shutdown partial failures; neither GC completion nor owner callback is permanently blocked";
    attribute :>> workMetric="External blocking time on GC critical path, queue/drain work and unresolved release debt";
    attribute :>> memoryMetric="Deferred rooted payload, budget reserve and pending descendants";
    attribute :>> boundary="Queueing a destructor alone removes no cycle; unsupported effects remain explicit and no reclaimed PSTATE may be borrowed";
  }
  part f5:Factor {
    ref part :>> argument=GambitCausalArchitecture::frames; attribute :>> id="frames";
    attribute :>> scope="direct scope of current alias/control study";
    attribute :>> mechanism="Independent frame coordinates, untracked aliases and address caches make root repair/restoration disagree; a whole-invocation snapshot would alter lazy tail observations";
    attribute :>> sourceCondition="One FrameSpec, canonical shared domains, logical revision versus relocation epoch, authentic per-fragment consume and unchanged Scheme winding; all actual writers/consumers migrate";
    attribute :>> nativeCondition="Multi-shot map, later tail mutation, shared alias writes, GC relocation and concurrent admitted contexts with proper tail space and native-origin behavior";
    attribute :>> workMetric="Actual reached restore words, certificate validation, barriers, root reload and independent-domain overlap";
    attribute :>> memoryMetric="Shared captures counted once plus private active frames, live domain/certificate and metadata roots";
    attribute :>> boundary="CS-BRIDGE/CS-WRITERS remain open; their local premises do not close source frame/wind/native obligations or prove full SMP";
  }
  part f6:Factor {
    ref part :>> argument=GambitCausalArchitecture::profile; attribute :>> id="profile";
    attribute :>> scope="toolchain/development and evidence identity";
    attribute :>> mechanism="Generated headers/objects may have incompatible ancestry; build jobs and processor population are confused with simultaneous same-VM work";
    attribute :>> sourceCondition="Complete effective options and dynamic inputs bind generated/header/object/link closure; dependency invalidation and action scheduling have explicit ownership";
    attribute :>> nativeCondition="Exact-profile bootstrap and clean/no-op/leaf/macro controls; separate build concurrency from runtime mutation/GC acceptance";
    attribute :>> workMetric="Generation/preprocessing/compile/link actions and elapsed work; validation cost versus avoided work";
    attribute :>> memoryMetric="Build concurrency RSS and artifact retention separately from runtime heap peak";
    attribute :>> boundary="This is not itself a runtime race cause; cached bootstrap or parallel make is no evidence of SMP scaling";
  }
  part f7:Factor {
    ref part :>> argument=GambitCausalArchitecture::generation; attribute :>> id="generation";
    attribute :>> scope="cross-consumer semantic foundation";
    attribute :>> mechanism="Scheme semantic decisions are reconstructed in C macros, layouts and consumers; a new wrapper/backend can leave both old owners authoritative";
    attribute :>> sourceCondition="Scheme completes frame/module/effect/allocation semantics once; modern C consumes one generated ABI; migrate emitters, FFI, root scanners, restorer and module lifetime together";
    attribute :>> nativeCondition="All admitted frame kinds and target widths, module lifetime and generated/native observations match; no old semantic owner remains authoritative";
    attribute :>> workMetric="Independent interpretations retired, regenerated closure, descriptor access and semantic lowering work";
    attribute :>> memoryMetric="Descriptor/module lifetime and generated/native code footprint";
    attribute :>> boundary="Language/backend adoption supplies no automatic correctness or speed; preserves Gambit multi-shot, tail calls and portable C foundation";
  }
  part def Effect { ref part factor:Factor; ref part criterion:GambitFrameAliasContract::SmpCriterion; }
  part e0:Effect { ref part :>> factor=f0; ref part :>> criterion=GambitFrameAliasContract::s3; }
  part e1:Effect { ref part :>> factor=f1; ref part :>> criterion=GambitFrameAliasContract::s2; }
  part e2:Effect { ref part :>> factor=f1; ref part :>> criterion=GambitFrameAliasContract::s4; }
  part e3:Effect { ref part :>> factor=f2; ref part :>> criterion=GambitFrameAliasContract::s1; }
  part e4:Effect { ref part :>> factor=f2; ref part :>> criterion=GambitFrameAliasContract::s4; }
  part e5:Effect { ref part :>> factor=f3; ref part :>> criterion=GambitFrameAliasContract::s0; }
  part e6:Effect { ref part :>> factor=f3; ref part :>> criterion=GambitFrameAliasContract::s2; }
  part e7:Effect { ref part :>> factor=f3; ref part :>> criterion=GambitFrameAliasContract::s3; }
  part e8:Effect { ref part :>> factor=f4; ref part :>> criterion=GambitFrameAliasContract::s4; }
  part e9:Effect { ref part :>> factor=f5; ref part :>> criterion=GambitFrameAliasContract::s0; }
  part e10:Effect { ref part :>> factor=f5; ref part :>> criterion=GambitFrameAliasContract::s1; }
  part e11:Effect { ref part :>> factor=f6; ref part :>> criterion=GambitFrameAliasContract::s5; }
  part e12:Effect { ref part :>> factor=f7; ref part :>> criterion=GambitFrameAliasContract::s0; }
  part e13:Effect { ref part :>> factor=f7; ref part :>> criterion=GambitFrameAliasContract::s2; }
}
