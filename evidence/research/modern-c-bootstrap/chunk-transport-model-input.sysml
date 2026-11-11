package GambitCopyCustody {
  private import ScalarValues::*;
  attribute runtimeAdmitted:Boolean=false;
  attribute commitAdmitted:Boolean=false;
  attribute sourceLock:String="evidence/research/modern-c-bootstrap/scan-ownership-source.lock.json";
  part def Contract {
    attribute id:String; attribute cSource:String; attribute invariant:String;
    attribute quint:String; attribute lean:String; attribute open:String;
    attribute nativeMethod:String; attribute nativeArtifact:String; attribute nativeClass:String; attribute nativeScope:String;
  }
  part frozenCensus:Contract {
    attribute :>> id="COPY-FROZEN";
    attribute :>> nativeMethod="native-bootstrap"; attribute :>> nativeArtifact="evidence/research/modern-c-bootstrap/scan-ownership-bootstrap.recipe.json"; attribute :>> nativeClass="native-bootstrap"; attribute :>> nativeScope="51 generated products and full two-pass bootstrap; not a universal packing proof";
    attribute :>> cSource="mem.c setup_stack_heap_vmstate; ___garbage_collect_pstate";
    attribute :>> invariant="Every participant flushes fp/hp, freezes roots, then closes the old-set barrier before the source census or any parity flip. The census counts allocated words, not live words. Two initial destination intervals per participant are necessary, not sufficient.";
    attribute :>> quint="copy_custody.freeze; copy_custody.plan";
    attribute :>> lean="Gambit.CopyCustody.copyBoundNeedsUniqueSources";
    attribute :>> open="Per-worker contiguous capacity, captured-frame duplication, chunk markers/terminal fragments and full root ownership remain unproved. No added heap multiplier is credited.";
  }
  part copySource:Contract {
    attribute :>> id="COPY-SOURCE";
    attribute :>> nativeMethod="native-whole"; attribute :>> nativeArtifact="vendor/gambit/tests/frame-continuation-roots.scm"; attribute :>> nativeClass="native-whole"; attribute :>> nativeScope="p11 compiler and host-managed runtime, 80 roots, eleven GCs and multi-shot results, natural shutdown";
    attribute :>> cSource="mem.c require_fromspace_copy_source; change_object_scan_state; publish_object_scan; mark_array; mark_captured_continuation; scan";
    attribute :>> invariant="A MOVABLE forwarding attempt must refer to the frozen fromspace half. A tospace input is rejected before forwarding; failure coordinates are retained. CAS losers do not increment copied_words. A winning first field is Tail work and later scan skips it.";
    attribute :>> quint="copy_custody.forward; copy_custody.initializeCopy; copy_custody.publish; copy_custody.claim; copy_custody.observeDuplicate; copy_custody.completeTail; copy_custody.scan";
    attribute :>> lean="Gambit.CopyCustody.copyBoundNeedsUniqueSources; Gambit.CopyCustody.claimPreservesUniqueIdentities; Gambit.CopyCustody.duplicateTaskDoesNotCreateWriter";
    attribute :>> open="Destination objects now publish READY after initialization, claim OWNED before field repair and finish DONE. Repeated tasks acquire no second field-write authority; original owner and Tail debts must drain before termination. This is not yet a proof that chunk/root cells are uniquely scanned; C CAS/read memory order and forwarding-before-payload publication need refinement. Runtime guard costs logarithmic lookup per forwarding attempt.";
  }
  part abortDomain:Contract {
    attribute :>> id="ABORT-ISOLATION";
    attribute :>> nativeMethod="native-fault"; attribute :>> nativeArtifact="evidence/research/modern-c-bootstrap/scan-ownership-isolation-multi.scm"; attribute :>> nativeClass="native-fault-control"; attribute :>> nativeScope="three healthy members finish three collections while an unpublished native actor stays held and join is unknown; safety exit only";
    attribute :>> cSource="setup.c start_processor_execution; ___vm_resize_pstate; os_thread.c start_pthread_thread; mem.c ___isolate_aborted_resize";
    attribute :>> invariant="An immutable ABORT permit is independent of join. All contexts initialized, no unknown create, no RUN permit, no allocated movable/still/RC payload, and no activation marker allow heap claims to detach. Native record, gate and descriptors remain retained and cannot be reused. The retained request thunk is scanned by worker zero.";
    attribute :>> quint="copy_custody.abort; copy_custody.unknownJoin; copy_custody.isolate; copy_custody.collectHealthy";
    attribute :>> lean="Gambit.CopyCustody.isolationDoesNotRequireJoin; Gambit.CopyCustody.nativeReuseStillNeedsJoin";
    attribute :>> open="Published retiree, unknown create, raw native borrow, owner interruption or failed isolation remains retained and GC-inadmissible. This is not arbitrary owner-death recovery or a native handle reaper.";
  }
  part def Handoff { ref part producer:Contract; ref part consumer:Contract; attribute obligation:String; }
  part censusToCopy:Handoff { ref part :>> producer=frozenCensus; ref part :>> consumer=copySource;
    attribute :>> obligation="Source upper bound may become capacity evidence only after unique scanning and destination packing are proved."; }
  part abortToGC:Handoff { ref part :>> producer=abortDomain; ref part :>> consumer=frozenCensus;
    attribute :>> obligation="Old collective publishes abort_isolated before healthy GC; detached empty intervals may be reused, stable native identity must not be overwritten."; }  attribute physicalPackingClosed:Boolean=false;
  attribute capacityRule:String="Conditional: G=L-Amax-4-ceil(L/K)>0; heap sections <= W+floor(U/G); P >= N+2W+floor(U/G)+R+Q includes restoration and retained domains. U, Amax, source identity, packing and Tail/worker closure must be proved before issuing a pre-flip grant. No automatic heap growth from this formula is implemented.";
  part def Benefit { attribute id:String; attribute eliminated:String; attribute added:String; attribute bound:String; attribute gate:String; }
  part scanBenefit:Benefit {
    attribute :>> id="object-scan-authority";
    attribute :>> eliminated="Second ordinary field writer on duplicate chunk/frontier delivery; pair fast path bypassing authority";
    attribute :>> added="Per-destination READY/OWNED/DONE packed CAS state, initialization publication and first-field Tail exclusion";
    attribute :>> bound="Two bits per destination word: 16384 bytes per 1048576-byte section in the measured profile. O(M) trailer reset plus object state lookups/CAS. No speed or RSS claim.";
    attribute :>> gate="Native whole passes; packed CAS/C memory-order and arbitrary root/FFI refinement remain open";
  }
  part abortBenefit:Benefit {
    attribute :>> id="native-heap-custody-split";
    attribute :>> eliminated="Whole-VM GC refusal solely because a never-entered empty startup actor lacks a successful join";
    attribute :>> added="Empty-domain/immutable ABORT checks, retained native records and source root, fixed isolated receipt";
    attribute :>> bound="Unknown 3-to-5 growth detaches four empty section claims; three healthy members complete three GCs while one native actor remains held. No native handle or OS-stack refund is claimed.";
    attribute :>> gate="Known managed abort only; published retiree, unknown create, raw borrow and native reclamation remain excluded";
  }
  part capacityBenefit:Benefit {
    attribute :>> id="pre-copy-accounting";
    attribute :>> eliminated="Using a post-copy heap resize or aggregate logical free words as evidence of pre-copy capacity";
    attribute :>> added="Frozen source census, per-worker copy counts, explicit physical packing and restoration proof obligations";
    attribute :>> bound="No new Scheme root cells or configured heap increase. Current ABI delta from ownership predecessor is 1072 VM bytes plus 16384 bytes per section; overlapping fields must not be added twice.";
    attribute :>> gate="General U/Amax/packing and pre-flip all-or-retain allocator transaction are not implemented or admitted";
  }
}
