package GambitCopyCustody {
  private import ScalarValues::*;
  attribute runtimeAdmitted:Boolean=false;
  attribute commitAdmitted:Boolean=false;
  attribute sourceLock:String="evidence/research/modern-c-bootstrap/scan-ownership-source.lock.json";
  part def Contract {
    attribute id:String; attribute cSource:String; attribute invariant:String;
    attribute quint:String; attribute lean:String; attribute open:String;
  }
  part frozenCensus:Contract {
    attribute :>> id="COPY-FROZEN";
    attribute :>> cSource="mem.c setup_stack_heap_vmstate; ___garbage_collect_pstate";
    attribute :>> invariant="Every participant flushes fp/hp, freezes roots, then closes the old-set barrier before the source census or any parity flip. The census counts allocated words, not live words. Two initial destination intervals per participant are necessary, not sufficient.";
    attribute :>> quint="copy_custody.freeze; copy_custody.plan";
    attribute :>> lean="Gambit.CopyCustody.copyBoundNeedsUniqueSources";
    attribute :>> open="Per-worker contiguous capacity, captured-frame duplication, chunk markers/terminal fragments and full root ownership remain unproved. No added heap multiplier is credited.";
  }
  part copySource:Contract {
    attribute :>> id="COPY-SOURCE";
    attribute :>> cSource="mem.c require_fromspace_copy_source; change_object_scan_state; publish_object_scan; mark_array; mark_captured_continuation; scan";
    attribute :>> invariant="A MOVABLE forwarding attempt must refer to the frozen fromspace half. A tospace input is rejected before forwarding; failure coordinates are retained. CAS losers do not increment copied_words. A winning first field is Tail work and later scan skips it.";
    attribute :>> quint="copy_custody.forward; copy_custody.initializeCopy; copy_custody.publish; copy_custody.claim; copy_custody.observeDuplicate; copy_custody.completeTail; copy_custody.scan";
    attribute :>> lean="Gambit.CopyCustody.copyBoundNeedsUniqueSources";
    attribute :>> open="Destination objects now publish READY after initialization, claim OWNED before field repair and finish DONE. Repeated tasks acquire no second field-write authority; original owner and Tail debts must drain before termination. This is not yet a proof that chunk/root cells are uniquely scanned; C CAS/read memory order and forwarding-before-payload publication need refinement. Runtime guard costs logarithmic lookup per forwarding attempt.";
  }
  part abortDomain:Contract {
    attribute :>> id="ABORT-ISOLATION";
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
    attribute :>> obligation="Old collective publishes abort_isolated before healthy GC; detached empty intervals may be reused, stable native identity must not be overwritten."; }
}
