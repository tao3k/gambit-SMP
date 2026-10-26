/* Subordinate source premises of CS-BRIDGE / CS-WRITERS, not new proofs. */
package GambitFrameAliasContract {
  private import ScalarValues::*;
  ref part bridge=GambitContinuationSegments::bridge;
  ref part writers=GambitContinuationSegments::writers;
  ref part nativeAcceptance=GambitContinuationSegments::nativeAcceptance;
  attribute predecessor:String="evidence/research/control-refinement/validation.json";
  attribute profile:String="evidence/fixtures/gerbil-bazel-build-profile/profile.json";
  part def AdapterClause {
    ref part obligation:GambitContinuationSegments::Obligation;
    attribute id:String; attribute operation:String; attribute premise:String;
    attribute realization:String; attribute failure:String; attribute sourceGap:String;
  }
  part domainClause:AdapterClause {
    ref part :>> obligation=writers; attribute :>> id="alias-domain";
    attribute :>> operation="Capture, continuation-copy, shared-tail discovery and cross-context export";
    attribute :>> premise="A logical frame/segment domain survives address movement; overlapping captures share domains; wrapper identity does not identify the aliased payload";
    attribute :>> realization="Rooted domain records and nonreused incarnation, wrapper selection stamp, domain content/topology revisions and separate relocation epoch; register before aliases escape";
    attribute :>> failure="Unproved overlap, exhausted incarnation or unknown stack owner refuses optimized export and retains source custody";
    attribute :>> sourceGap="Current copy shares raw frame and denv fields but creates no canonical domain or managed alias publication";
  }
  part copyClause:AdapterClause {
    ref part :>> obligation=bridge; attribute :>> id="copy-root-issuance";
    attribute :>> operation="Copy wrapper and prepare the next restore fragment";
    attribute :>> premise="Authentic view issuance reads authoritative rooted head/denv and the admitted fragment under an access lease; allocation cannot lose the source";
    attribute :>> realization="Preallocate rooted metadata at a complete checkpoint, capture a consistent wrapper selection, preserve shared payload identities and give the new wrapper its own selection record";
    attribute :>> failure="Allocation or registration failure leaves original roots owned; no ACK or complete-view publication on unknown outcome";
    attribute :>> sourceGap="continuation-copy allocates a shallow wrapper and check-heap may collect; source adapters and issuance evidence are absent";
  }
  part storeClause:AdapterClause {
    ref part :>> obligation=writers; attribute :>> id="managed-frame-store";
    attribute :>> operation="frame-set!, continuation-set!, initialization stores and admitted frame reflection";
    attribute :>> premise="All readers/writers of a shared physical field obey C synchronization; a logical store invalidates every dependent view through its shared domain";
    attribute :>> realization="Reserve noncollecting remembered-log capacity before the short write lease; validate slot role via FrameSpec; perform store and revision publication under exclusion; release publishes to acquiring readers";
    attribute :>> failure="Log overflow or capacity failure releases lease before a safe collecting retry; root value retained; partial/unknown writes keep domain unresolved";
    attribute :>> sourceGap="Current setters perform plain C stores under local not-interrupts-enabled declarations, not interprocessor ownership enforcement";
  }
  part selectionClause:AdapterClause {
    ref part :>> obligation=writers; attribute :>> id="selection-and-topology";
    attribute :>> operation="continuation-frame-set!, denv-set!, next!, structural-link changes and scheduler save/restore";
    attribute :>> premise="Wrapper head/denv selection is a coherent pair; membership and ordering of dependent domains cannot change unnoticed";
    attribute :>> realization="Wrapper selection revision covers its head/denv; link-domain topology revisions cover shared tails; compare exact ordered domain/incarnation/revision lists, never an unchecked hash or sum";
    attribute :>> failure="Changed topology invalidates certificate and triggers rooted rediscovery; scheduler-owned slot consumption never consumes a general full continuation";
    attribute :>> sourceGap="next! mutates wrapper fields and sometimes stack RA; raw link/RA setters cannot be treated as ordinary payload stores";
  }
  part movingClause:AdapterClause {
    ref part :>> obligation=bridge; attribute :>> id="relocation-projection";
    attribute :>> operation="GC heapification, forwarding, root repair and post-GC reload";
    attribute :>> premise="Logical slot values use Scheme object identity; relocation changes physical coordinates without changing logical payload revisions";
    attribute :>> realization="Frozen context/domain access authorizes one structural updater; collector updates every authoritative root/handle; a fresh relocation epoch revokes raw address caches before resume";
    attribute :>> failure="Unsettled native borrow or missing frozen root view denies movement; matching logical revision never authorizes reuse of an old address";
    attribute :>> sourceGap="Collector frame access is VM-wide and distinct from raw mutator stores; stable identity and complete address reload correspondence remain unimplemented";
  }
  part certificateClause:AdapterClause {
    ref part :>> obligation=bridge; attribute :>> id="exact-dependency-certificate";
    attribute :>> operation="Validate a prepared fragment after writes, GC or winding";
    attribute :>> premise="Issuance is authentic and complete relevant writer histories are represented; equality includes domain membership, incarnation and revisions";
    attribute :>> realization="For one fixed certificate scope, use a ghost serial history to interpret Lean ImageHistory; physical dependency vectors are evidence for unchanged history, not a global VM counter";
    attribute :>> failure="Counter wrap/reuse, incomplete writers or changed scope expires certificate; reissue under new scope; finite Quint ticket IDs do not prove unbounded implementation traces";
    attribute :>> sourceGap="The existing Lean scalar version is an abstraction premise; no source refinement of a distributed revision vector exists yet";
  }
  part restoreClause:AdapterClause {
    ref part :>> obligation=bridge; attribute :>> id="lazy-fragment-commit";
    attribute :>> operation="Graft/return installation and each break-handler caller restoration";
    attribute :>> premise="Coherence is required at the actual fragment-consumption point; an invocation-wide frozen snapshot must not hide later legal writes to its unconsumed tail";
    attribute :>> realization="Retain rooted tail selection, pre-reserve bounded destination space, acquire short source read leases and current context grant, copy one admitted fragment into private execution storage, then release; revalidate next fragment when reached";
    attribute :>> failure="Insufficient contiguous reserve or stale certificate returns to complete rooted checkpoint before copy; partial initialization cannot be published as an executable frame";
    attribute :>> sourceGap="Current break handler restores a reached caller frame and rewrites links; no complete generated modern-C fragment adapter or whole-round capacity proof";
  }
  part hookClause:AdapterClause {
    ref part :>> obligation=bridge; attribute :>> id="scheme-hook-reentry";
    attribute :>> operation="Scheme wind hooks and multiple restoration of saved hook suffixes";
    attribute :>> premise="User hooks run without physical frame leases; restored Scheme suffixes acquire new physical permission; unchanged winding policy owns observable effects";
    attribute :>> realization="Keep logical transfer roots and selected Scheme continuation, release C leases before hook, then reread/reload current source fields and reissue only physical certificates; do not replay completed hooks merely because addresses changed";
    attribute :>> failure="Abandoned helper completion is stale while legal Scheme suffix remains reusable; native origin expiration refuses only the unsupported C return";
    attribute :>> sourceGap="Source winding computes a destination then invokes hooks; graft later reads actual continuation fields, so automatic semantic replanning is not justified";
  }
  part denvClause:AdapterClause {
    ref part :>> obligation=writers; attribute :>> id="denv-and-referents";
    attribute :>> operation="Denv/winder vector mutation, referenced Scheme objects and deserialized shells";
    attribute :>> premise="Denv identity is not deep immutability; referenced heap effects remain shared; derived cached fields need their own synchronization and dependency coverage";
    attribute :>> realization="Distinguish wrapper selection, shared record field changes, ordinary shared referents and private execution stores; initialization records remain scannable and non-executable until complete";
    attribute :>> failure="Unsupported alias/native writer removes optimized admission; conservative scanning alone cannot repair a C data race";
    attribute :>> sourceGap="Denv records are vectors, serializers fill shells and I/O rebuild writes separate frame objects; complete indirect writer coverage remains open";
  }
  part exportClause:AdapterClause {
    ref part :>> obligation=writers; attribute :>> id="cross-context-export";
    attribute :>> operation="Publish a stack-backed capture for another execution context or collector";
    attribute :>> premise="Local lazy capture may remain stack-backed; cross-context access requires a frozen owner view or a fully initialized managed shared representation before publication";
    attribute :>> realization="Use existing root-transfer custody boundary: register destination before source ACK, preserve native-origin identity, publish shared status before withdrawing private-owner privileges";
    attribute :>> failure="Unknown owner writes cannot be guessed stopped; no unrestricted foreign writer is isolated without a proven physical access bound";
    attribute :>> sourceGap="Same-VM cross-context export, writer withdrawal and destination registration do not yet form a complete implemented adapter";
  }
  part def SmpCriterion {
    ref part acceptance:GambitControlRefinement::NativeCase;
    attribute id:String; attribute necessary:String; attribute observation:String; attribute limitation:String;
  }
  part s0:SmpCriterion { ref part :>> acceptance=GambitControlRefinement::n4; attribute :>> id="same-vm-mutators"; attribute :>> necessary="Multiple mutators execute in the same VM without a VM-wide lock across Scheme work or hooks"; attribute :>> observation="Actual simultaneous active contexts with correct shared heap/control observations; processor population alone is insufficient"; attribute :>> limitation="Frame aliases cover only part of the shared heap memory model; existing Quint is a bounded single aggregate control model"; }
  part s1:SmpCriterion { ref part :>> acceptance=GambitControlRefinement::n4; attribute :>> id="independent-read-domains"; attribute :>> necessary="Read sharing and disjoint frame domains proceed independently; only overlapping writes/copiers serialize locally"; attribute :>> observation="Concurrent distinct-domain restoration and collection with contention/work counts; no global frame gate on the hot path"; attribute :>> limitation="A per-domain lock design alone proves neither fairness nor speedup"; }
  part s2:SmpCriterion { ref part :>> acceptance=GambitControlRefinement::n4; attribute :>> id="origin-task-worker"; attribute :>> necessary="Context owns roots, participant owns epoch authorization and worker owns claimed copying tasks independently of carrier ID"; attribute :>> observation="Worker count and root-origin count need not match; each claimed task updates the correct frozen roots and phase"; attribute :>> limitation="Current source still indexes participants/completion by carrier and checks synchronous binding"; }
  part s3:SmpCriterion { ref part :>> acceptance=GambitControlRefinement::n4; attribute :>> id="failure-scope"; attribute :>> necessary="Unknown outcomes retain exact roots/resources; isolation requires known writable intervals and physical stop or exclusion"; attribute :>> observation="Distinguish healthy other-VM GC from progress inside the affected VM; test known quarantine bounds and unresolved writes"; attribute :>> limitation="Current moving arena may remain blocked by unknown writes; alias records do not magically enable selective collection"; }
  part s4:SmpCriterion { ref part :>> acceptance=GambitControlRefinement::n6; attribute :>> id="gc-round-progress"; attribute :>> necessary="Frozen roots, publishing/private/Tail work, weak cleanup, termination and contiguous reserve form one admitted round"; attribute :>> observation="No unfinished task is hidden by carrier-idle counts; capacity failure retains source before flip under unchanged limits"; attribute :>> limitation="These GC/capacity obligations are dependencies, not proved by CS-BRIDGE/CS-WRITERS or the existing Lean law"; }
  part s5:SmpCriterion { ref part :>> acceptance=GambitControlRefinement::n6; attribute :>> id="measured-net-parallelism"; attribute :>> necessary="Parallel useful work exceeds access, root, barrier, dispatch and retention overhead for a stated workload"; attribute :>> observation="Same-source/profile single-versus-multicore work, latency, throughput and physical peak; include ordinary fast paths and failure histories"; attribute :>> limitation="No measured scaling result in this research; Scheme map ordering is preserved"; }
  part def Benefit { attribute id:String; attribute avoided:String; attribute added:String; attribute condition:String; }
  part b0:Benefit { attribute :>> id="lazy-multishot"; attribute :>> avoided="No repeated eager whole-chain snapshot by the new adapter; preserve existing reached-frame restoration"; attribute :>> added="Per-fragment grant, root reload and dependency validation; copy reached payload and perform required hooks"; attribute :>> condition="For r shots compare actual reached words sum(Rj), not r times an invented full-image baseline"; }
  part b1:Benefit { attribute :>> id="alias-invalidation"; attribute :>> avoided="No scan of all A wrapper aliases and no global historical identity table for each payload write"; attribute :>> added="O(1) revision work per touched admitted domain and O(d) validation per certificate with d dependencies"; attribute :>> condition="Canonical shared-tail domains and complete writers; multi-domain operations pay for every touched domain"; }
  part b2:Benefit { attribute :>> id="gc-relocation"; attribute :>> avoided="Address-only changes need not rebuild logically unchanged payload or rerun winding effects"; attribute :>> added="All authoritative root updates and physical address reload remain mandatory"; attribute :>> condition="Stable logical identity, frozen access and complete reload; pointer equality or matching logical revision alone is insufficient"; }
  part b3:Benefit { attribute :>> id="parallel-domain-work"; attribute :>> avoided="Unnecessary VM-wide serialization of independent frame copies/readers"; attribute :>> added="Domain metadata, local contention, task accounting and coordinator publication"; attribute :>> condition="For P workers and serial fraction s, ideal speedup is bounded by 1/(s+(1-s)/P) before extra overhead; neither s nor realized speedup measured"; }
  part b4:Benefit { attribute :>> id="metadata-and-peak"; attribute :>> avoided="Share eligible capture payload across wrappers and invocations rather than cloning all tails up front"; attribute :>> added="O(A+D+sum(dj)) wrapper/domain/live-certificate metadata plus rooted transfer, active copies and GC/native reserves"; attribute :>> condition="D is live canonical domains, not unbounded request history; retained unknown observers prevent unsafe domain reuse"; }
  part b5:Benefit { attribute :>> id="generational-path"; attribute :>> avoided="Eligible clean mature frame payload can eventually skip repeated minor traversal"; attribute :>> added="Remembered stores, overflow handling, scans and promotion/resume reserve"; attribute :>> condition="Zero claimed gain until all writers and generational runtime qualify; ordinary root visits and relocation are not eliminated"; }
  part def Witness { attribute id:String; attribute file:String; attribute firstLine:Integer; attribute lastLine:Integer; attribute finding:String; }
  part w0:Witness { attribute :>> id="shallow-copy"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> firstLine=3612; attribute :>> lastLine=3640; attribute :>> finding="Wrapper allocation shares frame/denv and checks heap afterwards"; }
  part w1:Witness { attribute :>> id="reflect-store"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> firstLine=3435; attribute :>> lastLine=3555; attribute :>> finding="Plain heap/stack stores use descriptor-derived coordinates"; }
  part w2:Witness { attribute :>> id="wrapper-select"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> firstLine=3153; attribute :>> lastLine=3170; attribute :>> finding="Frame materialization can collect; wrapper frame/denv setters are separate"; }
  part w3:Witness { attribute :>> id="traversal-update"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> firstLine=3640; attribute :>> lastLine=3725; attribute :>> finding="next! updates wrapper selection and stack RA; copied wrappers may share tails"; }
  part w4:Witness { attribute :>> id="lazy-consumer"; attribute :>> file="vendor/gambit/lib/_kernel.scm"; attribute :>> firstLine=1182; attribute :>> lastLine=1288; attribute :>> finding="Break handler copies one reached caller frame from stack or heap"; }
  part w5:Witness { attribute :>> id="graft-selection"; attribute :>> file="vendor/gambit/include/gambit.h.in"; attribute :>> firstLine=6659; attribute :>> lastLine=6671; attribute :>> finding="Graft reads actual continuation frame/denv and installs current thread caches"; }
  part w6:Witness { attribute :>> id="capture-source"; attribute :>> file="vendor/gambit/include/gambit.h.in"; attribute :>> firstLine=6594; attribute :>> lastLine=6611; attribute :>> finding="Capture can publish a stack-backed frame selection through a break frame"; }
  part w7:Witness { attribute :>> id="heapification"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=4046; attribute :>> lastLine=4197; attribute :>> finding="GC copies frame payload and repairs forwarding/structural roots"; }
  part w8:Witness { attribute :>> id="heap-frame-scan"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=4459; attribute :>> lastLine=4519; attribute :>> finding="Ordinary slots, link and return address have distinct scan roles"; }
  part w9:Witness { attribute :>> id="denv-records"; attribute :>> file="vendor/gambit/lib/_thread#.scm"; attribute :>> firstLine=742; attribute :>> lastLine=786; attribute :>> finding="Denv, environment and dynwind data use mutable vector records"; }
  part w10:Witness { attribute :>> id="deserialize-writer"; attribute :>> file="vendor/gambit/lib/_system.scm"; attribute :>> firstLine=4140; attribute :>> lastLine=4227; attribute :>> finding="Deserializer registers shells and fills continuation/frame values recursively"; }
  part w11:Witness { attribute :>> id="io-writer"; attribute :>> file="vendor/gambit/lib/_io.scm"; attribute :>> firstLine=11690; attribute :>> lastLine=11730; attribute :>> finding="Separate explode/implode path creates and fills frame objects"; }
  part w12:Witness { attribute :>> id="physical-frame-gate"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=3708; attribute :>> lastLine=3733; attribute :>> finding="Collector frame gate is VM-wide; raw reflective setters do not call it"; }
  part w13:Witness { attribute :>> id="frozen-root-origin"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=7282; attribute :>> lastLine=7305; attribute :>> finding="Worker scans the supplied frozen participant context, registers, startup marker and RC roots"; }
  part w14:Witness { attribute :>> id="carrier-index"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=7462; attribute :>> lastLine=7475; attribute :>> finding="Dispatch and strong completion still use carrier processor ID"; }
  part w15:Witness { attribute :>> id="synchronous-binding"; attribute :>> file="vendor/gambit/lib/mem.c"; attribute :>> firstLine=7570; attribute :>> lastLine=7598; attribute :>> finding="GC requires synchronous carrier/context binding and checks unknown-resize isolation"; }
  part w16:Witness { attribute :>> id="wind-and-current-selection"; attribute :>> file="vendor/gambit/lib/_thread.scm"; attribute :>> firstLine=5049; attribute :>> lastLine=5077; attribute :>> finding="Scheme computes destination winding and calls a suffix that invokes current continuation fields"; }
  part def EvidenceUse { ref part clause:AdapterClause; ref part witness:Witness; }
  part e0:EvidenceUse { ref part :>> clause=domainClause; ref part :>> witness=w0; }
  part e1:EvidenceUse { ref part :>> clause=copyClause; ref part :>> witness=w0; }
  part e2:EvidenceUse { ref part :>> clause=storeClause; ref part :>> witness=w1; }
  part e3:EvidenceUse { ref part :>> clause=selectionClause; ref part :>> witness=w2; }
  part e4:EvidenceUse { ref part :>> clause=copyClause; ref part :>> witness=w2; }
  part e5:EvidenceUse { ref part :>> clause=selectionClause; ref part :>> witness=w3; }
  part e6:EvidenceUse { ref part :>> clause=restoreClause; ref part :>> witness=w4; }
  part e7:EvidenceUse { ref part :>> clause=certificateClause; ref part :>> witness=w4; }
  part e8:EvidenceUse { ref part :>> clause=restoreClause; ref part :>> witness=w5; }
  part e9:EvidenceUse { ref part :>> clause=hookClause; ref part :>> witness=w5; }
  part e10:EvidenceUse { ref part :>> clause=selectionClause; ref part :>> witness=w5; }
  part e11:EvidenceUse { ref part :>> clause=exportClause; ref part :>> witness=w6; }
  part e12:EvidenceUse { ref part :>> clause=domainClause; ref part :>> witness=w6; }
  part e13:EvidenceUse { ref part :>> clause=movingClause; ref part :>> witness=w7; }
  part e14:EvidenceUse { ref part :>> clause=exportClause; ref part :>> witness=w7; }
  part e15:EvidenceUse { ref part :>> clause=movingClause; ref part :>> witness=w8; }
  part e16:EvidenceUse { ref part :>> clause=denvClause; ref part :>> witness=w9; }
  part e17:EvidenceUse { ref part :>> clause=denvClause; ref part :>> witness=w10; }
  part e18:EvidenceUse { ref part :>> clause=storeClause; ref part :>> witness=w10; }
  part e19:EvidenceUse { ref part :>> clause=denvClause; ref part :>> witness=w11; }
  part e20:EvidenceUse { ref part :>> clause=storeClause; ref part :>> witness=w11; }
  part e21:EvidenceUse { ref part :>> clause=storeClause; ref part :>> witness=w12; }
  part e22:EvidenceUse { ref part :>> clause=movingClause; ref part :>> witness=w13; }
  part e23:EvidenceUse { ref part :>> clause=exportClause; ref part :>> witness=w13; }
  part e24:EvidenceUse { ref part :>> clause=hookClause; ref part :>> witness=w16; }
  part def CriterionUse { ref part criterion:SmpCriterion; ref part witness:Witness; }
  part c0:CriterionUse { ref part :>> criterion=s0; ref part :>> witness=w12; }
  part c1:CriterionUse { ref part :>> criterion=s1; ref part :>> witness=w12; }
  part c2:CriterionUse { ref part :>> criterion=s2; ref part :>> witness=w13; }
  part c3:CriterionUse { ref part :>> criterion=s2; ref part :>> witness=w14; }
  part c4:CriterionUse { ref part :>> criterion=s2; ref part :>> witness=w15; }
  part c5:CriterionUse { ref part :>> criterion=s3; ref part :>> witness=w15; }
  part c6:CriterionUse { ref part :>> criterion=s4; ref part :>> witness=w7; }
  part c7:CriterionUse { ref part :>> criterion=s5; ref part :>> witness=w12; }
}
