package GambitVMResizeQualification {
  private import ScalarValues::*;
  private import GambitVMResizeTransaction::*;
  attribute sourceLock:String = "evidence/research/modern-c-bootstrap/resize-ownership-source.lock.json";
  attribute profile:String = "evidence/fixtures/gerbil-bazel-build-profile/profile.json";
  attribute runtimeAdmitted:Boolean = false;
  part def Need {
    ref part component:Contract;
    attribute id:String; attribute method:String; attribute artifact:String;
    attribute scope:String; attribute evidenceClass:String; attribute check:String;
  }
  part transactionCheck:Need { ref part :>> component=grant;
    attribute :>> id="VQ-TRANSITION"; attribute :>> method="quint";
    attribute :>> artifact="dev/refactoring/modern-c/models/quint/vm_resize_transaction.qnt";
    attribute :>> scope="bounded transaction with three abstract members";
    attribute :>> evidenceClass="finite-model"; attribute :>> check="four histories; safety samples; five negative controls";
  }
  part arithmetic:Need { ref part :>> component=grant;
    attribute :>> id="VQ-ARITHMETIC"; attribute :>> method="lean";
    attribute :>> artifact="dev/refactoring/modern-c/models/lean/VMResizeTransaction.lean";
    attribute :>> scope="conditional natural-number and coverage laws";
    attribute :>> evidenceClass="conditional-proof"; attribute :>> check="twelve laws; no sorry; kernel axiom audit";
  }
  part routing:Need { ref part :>> component=publication;
    attribute :>> id="VQ-ROUTING"; attribute :>> method="ascent";
    attribute :>> artifact="dev/modeling/ascent/vm-resize-qualification.rules.scm";
    attribute :>> scope="exact source, profile, artifact, method, scope, class and check joins";
    attribute :>> evidenceClass="policy-control"; attribute :>> check="current blocked; stale source; wrong artifact; diagnostic promotion; missing law; failed native; synthetic complete";
  }
  part markerIdentity:Need { ref part :>> component=retirement;
    attribute :>> id="VQ-BODY"; attribute :>> method="native-focused";
    attribute :>> artifact="evidence/research/modern-c-bootstrap/resize-fixture.scm";
    attribute :>> scope="actual movable startup closure, GC, retire, reuse and GC";
    attribute :>> evidenceClass="native-caller"; attribute :>> check="two successful grow/retire cycles and natural shutdown";
  }
  part faultControl:Need { ref part :>> component=failure;
    attribute :>> id="VQ-FAULT"; attribute :>> method="native-fault";
    attribute :>> artifact="evidence/research/modern-c-bootstrap/resize-fault-calibration.c";
    attribute :>> scope="independent injection calibration plus allocation/create rollback and unknown join custody";
    attribute :>> evidenceClass="native-fault-control"; attribute :>> check="calibration exact counts; known failures refund; unknown join retains root/grant and refuses reuse; intentional safety exit is not natural shutdown";
  }
  part bootstrap:Need { ref part :>> component=census;
    attribute :>> id="VQ-BOOTSTRAP"; attribute :>> method="native-bootstrap";
    attribute :>> artifact="evidence/research/modern-c-bootstrap/resize-ownership-bootstrap.recipe.json";
    attribute :>> scope="exact Bazel O1/O3 profile, all generated products, full official two-pass bootstrap";
    attribute :>> evidenceClass="native-bootstrap"; attribute :>> check="all 51 products and each phase1..4 twice; original budgets; no old runtime linkage";
  }
  part hostPopulation:Need { ref part :>> component=roots;
    attribute :>> id="VQ-P11"; attribute :>> method="native-whole";
    attribute :>> artifact="vendor/gambit/tests/frame-continuation-roots.scm";
    attribute :>> scope="host-budget p11 compiled map multishot, 80 roots, 11 GCs and natural shutdown";
    attribute :>> evidenceClass="native-whole"; attribute :>> check="default heap; completed real native oracle; no debugger, p1 or larger-heap substitution";
  }
  part simulation:Need { ref part :>> component=publication;
    attribute :>> id="VQ-C-SIMULATION"; attribute :>> method="source-refinement";
    attribute :>> artifact="dev/refactoring/modern-c/models/sysml/vm-resize-refinement.sysml";
    attribute :>> scope="all nine C transition routes including memory order, raw borrowers and owner-stop premises";
    attribute :>> evidenceClass="source-simulation"; attribute :>> check="OPEN: structural routes and Nat laws do not establish C implementation refinement";
  }
  part def Question { attribute id:String; attribute source:String; attribute condition:String; attribute counterexample:String; }
  part uniqueCopy:Question {
    attribute :>> id="copy-once";
    attribute :>> source="mem.c mark_array/mark_captured_continuation/scan_complete_heap_chunk/setup_stack_heap_vmstate";
    attribute :>> condition="Before inferring a copy capacity bound, prove unique cell/chunk ownership, first-field Tail exclusion, complete frames and forwarding publication. Count real semispace intervals, worker terminal fragments and captured frame expansion before flipping.";
    attribute :>> counterexample="A source-word estimate can underestimate duplicate tospace copying; enough total free words need not give the requesting worker a contiguous interval. Later resize_heap cannot repair a failure inside strong copying.";
  }
  part bodyIdentity:Question {
    attribute :>> id="marker-body";
    attribute :>> source="mem.c ___can_retire_pstate; c_intf.c ___make_sfun_stack_marker_from_root; gambit.h object tags";
    attribute :>> condition="Identify the one owned entry marker by BODY0 identity. Reject any additional retained native marker, RC borrower or foreign effect before count commit.";
    attribute :>> counterexample="Rebuilding a generic subtyped tag for a specialized-tag vector falsely denies retirement; accepting all positive-refcount vectors would instead admit unrelated native borrowers.";
  }
  part quarantineIsolation:Question {
    attribute :>> id="quarantine-isolation";
    attribute :>> source="mem.c ___garbage_collect_pstate retained-phase guard; setup.c cleanup/setup";
    attribute :>> condition="A future isolated root/native custody domain must prove which writers can still touch quarantined objects before allowing healthy participants to collect. The current whole-VM refusal is a safety restriction, not that domain design.";
    attribute :>> counterexample="A join error can retain a native handle indefinitely. The current guard then refuses GC for the entire VM; a safety exit cannot demonstrate continued useful Scheme execution or independent collector liveness.";
  }
  part def Benefit { attribute id:String; attribute eliminated:String; attribute added:String; attribute bound:String; attribute gate:String; }
  part bGrant:Benefit { attribute :>> id="physical-grant"; attribute :>> eliminated="Per-child opportunistic section acquisition and publication before complete native creation"; attribute :>> added="Fixed slots, mutex/condition entry gate, precharged disjoint section pairs"; attribute :>> bound="Profile W=131072 words; growth 1 to 11 needs 20 pair sections; R=2 VM-free resume sections; 24 total in observed initial state. Capacity is not RSS."; attribute :>> gate="Native p11 and whole C ownership remain open"; }
  part bRoots:Benefit { attribute :>> id="rooted-entry"; attribute :>> eliminated="Raw thunk carried across allocating sync loop and marker creation"; attribute :>> added="Two Scheme root cells per context, registered cell reload and owner marker identity"; attribute :>> bound="16 bytes/context; fixed 64 slots add 1024 bytes/VM in this profile. An intended complete round visits 2N+1 added root cells, conditional on unique participant scans. Marker itself already existed; raw SFUN is unqualified."; attribute :>> gate="Focused native caller and all raw FFI writers are separate obligations"; }
  part bRetain:Benefit { attribute :>> id="unknown-custody"; attribute :>> eliminated="Ignored join result followed by resource/root reclamation; setup erasing retained ownership"; attribute :>> added="Retained root/grant/slot state and rejection of subsequent setup/reuse"; attribute :>> bound="Unknown join refunds zero sections. Current retained phase refuses whole-VM GC. Retention can last until process termination; isolated recovery/liveness is unproved."; attribute :>> gate="Calibrated injection, quarantine isolation and owner-stop/source refinement"; }
  part bCollect:Benefit { attribute :>> id="copy-frontier"; attribute :>> eliminated="No demonstrated elimination yet; fixed two-section-per-member startup floor is insufficient evidence for parallel copying"; attribute :>> added="Required future pre-copy capacity/unique-task contract; not implemented or credited"; attribute :>> bound="Debug observed exhausted 24/25 sections and unequal worker occupancy, plus separate invalid accesses. No speedup or measured peak reduction."; attribute :>> gate="copy-once source proof, actual intervals and native p11 acceptance"; }
}
