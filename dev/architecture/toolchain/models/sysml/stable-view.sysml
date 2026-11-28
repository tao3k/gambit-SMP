package GambitStableView {
    private import ScalarValues::*;
    private import GambitToolchain::*;
    /* Qualification model only: no issuer or runtime implementation. */
    part def StableViewQualification {
        attribute issueRequested : Boolean;
        attribute writerSetClosed : Boolean;
        attribute ingressSerialized : Boolean;
        attribute readPinsProtected : Boolean;
        attribute rootsQualified : Boolean;
        attribute generationMatched : Boolean;
        attribute payloadEpochMatched : Boolean;
        attribute releaseRequested : Boolean;
        attribute pinsDrained : Boolean;
        attribute cleanupAcknowledged : Boolean;
        attribute rootHandoffAcknowledged : Boolean;
        attribute resumedBodyAllowed : Boolean;
        attribute freshEntryIssued : Boolean;
        attribute oldAcquisitionSettled : Boolean;
    }
    requirement def IssueLaw {
        subject witness : StableViewQualification;
        require constraint { not witness.issueRequested or
            (witness.writerSetClosed and witness.ingressSerialized and witness.readPinsProtected and
             witness.rootsQualified and witness.generationMatched and witness.payloadEpochMatched) }
    }
    requirement def ReleaseLaw {
        subject witness : StableViewQualification;
        require constraint { not witness.releaseRequested or
            (witness.pinsDrained and witness.cleanupAcknowledged and witness.rootHandoffAcknowledged) }
    }
    requirement def ResumeLaw {
        subject witness : StableViewQualification;
        require constraint { not witness.resumedBodyAllowed or
            (witness.freshEntryIssued and witness.oldAcquisitionSettled and witness.rootsQualified) }
    }

    part duty0 : GscFidelityObligation {
        attribute :>> fidelityId = "SV-SPEC";
        attribute :>> diagramLabel = "One acquisition owns roots and cleanup independently of read authority";
        attribute :>> dependsOn = "S-CUT";
        attribute :>> sourcePath = "dev/architecture/toolchain/models/sysml/stable-view.sysml";
        attribute :>> sourceRanges = "1-35";
        attribute :>> concreteBoundary = "Issue, release and resume requirements separate read permission from physical custody";
        attribute :>> encodingRule = "Use domain/VM, acquisition, issuer generation, entry, writer and payload epochs; no integer wrap admission";
        attribute :>> cleanControl = "Issuer ledger is mutable owned state outside continuation restoration; ROOT-HANDOFF remains shared";
        attribute :>> failureMapping = "A stale capability denies reads but never silently frees its roots or partially owned output";
        attribute :>> reflectionDuty = "Static requirements and ledger identities do not prove a native issuer or writer/GC refinement";
        attribute :>> benefitBoundary = "Share one request lifetime ledger; avoid a second parser, root registry or runtime state machine";
        attribute :>> leanSupport = "revokePreservesCustody; staleCleanupCannotClear";
        attribute :>> quintSupport = "readable; noReleasedRootWithPins";
        attribute :>> researchStatus = "conditional-contract";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty1 : GscFidelityObligation {
        attribute :>> fidelityId = "SV-ISSUE";
        attribute :>> diagramLabel = "Issue only after writer ingress, root coverage and acquisition settle";
        attribute :>> dependsOn = "SV-SPEC; S-ALIASES";
        attribute :>> sourcePath = "vendor/gambit/lib/_eval.scm";
        attribute :>> sourceRanges = "1396-1410;1437-1445;1489-1514";
        attribute :>> concreteBoundary = "Fresh compilation context and shallow alist do not supply immutable captured values";
        attribute :>> encodingRule = "Serialize all admitted writer ingress; bind complete alias/provider set; protect acquisition; then issue matching token";
        attribute :>> cleanControl = "Actual roots and live temporaries must be covered; ledger equality is not a freeze proof";
        attribute :>> failureMapping = "Unknown alias, nonzero RC coverage gap or racy acquisition refuses reuse";
        attribute :>> reflectionDuty = "issuedReceiptReadable assumes IssuableView; actual gates, source loads and atomic publication remain open";
        attribute :>> benefitBoundary = "Root/lease support is common modern C infrastructure; no language-specific saving";
        attribute :>> leanSupport = "issuedReceiptReadable";
        attribute :>> quintSupport = "issue; readable";
        attribute :>> researchStatus = "conditional-kernel";
        attribute :>> runtimeContractRefs = "ROOT-HANDOFF";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty2 : GscFidelityObligation {
        attribute :>> fidelityId = "SV-REVOKE";
        attribute :>> diagramLabel = "Revoke before draining; writers wait for pins rather than stale flags";
        attribute :>> dependsOn = "SV-ISSUE";
        attribute :>> sourcePath = "models/build/IncrementalBuild.lean";
        attribute :>> sourceRanges = "864-998";
        attribute :>> concreteBoundary = "Generation revocation invalidates token while retaining acquisition, roots and read pins";
        attribute :>> encodingRule = "Invalidation and source-memory reclamation are separate cuts; pins must drain before admitted store";
        attribute :>> cleanControl = "Same-owner callbacks must not wait on their own pin; end borrow before callback or refuse it";
        attribute :>> failureMapping = "An epoch retry cannot legalize a C data race or a raw FFI bypass";
        attribute :>> reflectionDuty = "Logical pin guards and identity proofs need actual memory-order/critical-section refinement";
        attribute :>> benefitBoundary = "Do not add duplicate global hashing or coarse invalidation to make revocation easy";
        attribute :>> leanSupport = "revokeRejectsOldReceipt; revokePreservesCustody; livePinBlocksWriter; returnPinKeepsCleanupDebt";
        attribute :>> quintSupport = "revoke; returnPin; payloadWrite";
        attribute :>> researchStatus = "conditional-kernel";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty3 : GscFidelityObligation {
        attribute :>> fidelityId = "SV-RESUME";
        attribute :>> diagramLabel = "Continuation restoration needs fresh entry authority and settled old custody";
        attribute :>> dependsOn = "SV-REVOKE";
        attribute :>> sourcePath = "vendor/gambit/lib/_thread.scm";
        attribute :>> sourceRanges = "4794-4817;4914-4988;5047-5080";
        attribute :>> concreteBoundary = "dynamic-wind after/before runs on extent changes; same-extent return fast path can skip winding";
        attribute :>> encodingRule = "Reentry creates fresh acquisition/entry/generation; old parameters, equal bytes or restored PC cannot revive token";
        attribute :>> cleanControl = "Settle old acquisition before native borrow resumes; register fresh roots and check before every resumed source read";
        attribute :>> failureMapping = "Before/after capture or exception can leave acquisition pending; same-extent mutation still needs read guard";
        attribute :>> reflectionDuty = "Existing CONTROL-ORIGIN and ROOT-HANDOFF are dependencies; full multi-shot/exception refinement remains open";
        attribute :>> benefitBoundary = "Keep Scheme winding semantics; introduce no C destructor-only continuation emulation";
        attribute :>> leanSupport = "freshEntryRejectsOldReceipt; freshEntryHasDistinctToken; sameExtentMutationRejects";
        attribute :>> quintSupport = "resume; rootGrant; readable";
        attribute :>> researchStatus = "conditional-kernel";
        attribute :>> runtimeContractRefs = "ROOT-HANDOFF; CONTROL-ORIGIN";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty4 : GscFidelityObligation {
        attribute :>> fidelityId = "SV-ALIASES";
        attribute :>> diagramLabel = "Dynamic writers and FFI enter by capability or refuse the managed profile";
        attribute :>> dependsOn = "SV-ISSUE";
        attribute :>> sourcePath = "vendor/gambit/include/gambit.h.in";
        attribute :>> sourceRanges = "5500-5514";
        attribute :>> concreteBoundary = "Native string store and generated Scheme mutation families bypass a script-line name census";
        attribute :>> encodingRule = "Bind writer-set epoch to generated mutators, context/table aliases and FFI provider identity; unsafe stores cannot self-attest";
        attribute :>> cleanControl = "Read-only provider, mediated write after borrow end, owned copy, or unqualified existing execution are distinct routes";
        attribute :>> failureMapping = "Unknown eval/native provider denies reusable credential without banning legal Scheme mutation";
        attribute :>> reflectionDuty = "unknownWriterRejectsRead is a ledger implication; actual provider closure and C race freedom remain open";
        attribute :>> benefitBoundary = "Generated modern C mutation/FFI contract can be shared with runtime work; Zig inherits it";
        attribute :>> leanSupport = "unknownWriterRejectsRead; livePinBlocksWriter";
        attribute :>> quintSupport = "unknownWriter; payloadWrite";
        attribute :>> researchStatus = "open-concrete-provider-closure";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty5 : GscFidelityObligation {
        attribute :>> fidelityId = "SV-CLEANUP";
        attribute :>> diagramLabel = "Cleanup ownership survives revocation, suspension and unknown close result";
        attribute :>> dependsOn = "SV-REVOKE; SV-RESUME";
        attribute :>> sourcePath = "vendor/gambit/gsc/_utils.scm";
        attribute :>> sourceRanges = "426-437;506-508";
        attribute :>> concreteBoundary = "Compiler continuation-abort and ordinary restoration differ from arbitrary exception cleanup";
        attribute :>> encodingRule = "Cleanup ticket binds acquisition rather than invalidated generation; track pending/ack/unknown; reject stale callback";
        attribute :>> cleanControl = "After hook initiates governed release; errors or cancellation retain custodian until physical acknowledgement";
        attribute :>> failureMapping = "No automatic free on stale read token; unknown close must not retry a reused fd or claim drain";
        attribute :>> reflectionDuty = "Ledger ack idempotence proves no native double-close/free or eventual completion; RETIRE-WINDOW stays unresolved";
        attribute :>> benefitBoundary = "One cleanup/outcome owner may replace global suffix bookkeeping only after all users migrate";
        attribute :>> leanSupport = "cleanupDebtBlocksDelivery; staleCleanupCannotClear; cleanupAckIdempotent";
        attribute :>> quintSupport = "cleanupAck; noReleasedRootWithPins";
        attribute :>> researchStatus = "conditional-ledger-physical-cleanup-open";
        attribute :>> runtimeContractRefs = "RETIRE-WINDOW";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty6 : GscFidelityObligation {
        attribute :>> fidelityId = "SV-ROUNDTRIP";
        attribute :>> diagramLabel = "Lease validity must cover actual string reads and exceptional ports";
        attribute :>> dependsOn = "SV-ISSUE; SV-CLEANUP; S-READ";
        attribute :>> sourcePath = "vendor/gambit/lib/_io.scm";
        attribute :>> sourceRanges = "11428-11505;13083-13160;13828-13837";
        attribute :>> concreteBoundary = "Writer scans length/characters; reader reconstructs through readtable and port; normal suffixes do not prove unwind cleanup";
        attribute :>> encodingRule = "Bind one admitted content view to record prefix, C suffix and all other linker inputs; source release follows owned transfer";
        attribute :>> cleanControl = "Guard resumes, allocation/GC reloads and callbacks; retain partial buffers/ports on exception until custody settles";
        attribute :>> failureMapping = "Failed lexical/read/close outcome remains failure or pending, never successful cache observation";
        attribute :>> reflectionDuty = "Actual character/port inverse, source-to-ledger simulation and full outcome/effect reflection remain open";
        attribute :>> benefitBoundary = "Reuse Scheme reader/writer and ghost wire; no compulsory extra serialization pass";
        attribute :>> leanSupport = "scriptFullObservationCongruence; cleanupDebtBlocksDelivery";
        attribute :>> quintSupport = "readable; fullLinkEquivalent";
        attribute :>> researchStatus = "open-actual-roundtrip-and-cleanup";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part duty7 : GscFidelityObligation {
        attribute :>> fidelityId = "SV-REFINE";
        attribute :>> diagramLabel = "Formal ledger preservation is not concrete read or continuation admission";
        attribute :>> dependsOn = "SV-ROUNDTRIP; SV-RESUME; S-REFLECT";
        attribute :>> sourcePath = "models/build/incremental_build.qnt";
        attribute :>> sourceRanges = "323-370";
        attribute :>> concreteBoundary = "Issue/revoke/pin/cleanup/resume actions specify a guarded lifecycle; unsafe providers remain excluded";
        attribute :>> encodingRule = "Prove each actual load, write, hook, error and handoff refines a legal step or explicit refused/pending outcome";
        attribute :>> cleanControl = "Old eight modules and runtime contracts retained; no source/FFI/C memory model proof synthesized";
        attribute :>> failureMapping = "Unknown acknowledgement, provider or multi-shot entry leaves qualification open";
        attribute :>> reflectionDuty = "Lean implications are checked; QNT is typechecked only; actual refinement and liveness remain open";
        attribute :>> benefitBoundary = "Conditional safety supports future work avoidance; no positive native speed claim";
        attribute :>> leanSupport = "issuedReceiptReadable; freshEntryRejectsOldReceipt; scriptPropertyReflection";
        attribute :>> quintSupport = "issue; failAcquire; revoke; returnPin; cleanupAck; resume; liveBorrowSafe";
        attribute :>> researchStatus = "conditional-kernel-concrete-refinement-open";
        attribute :>> runtimeContractRefs = "";
        attribute :>> obligationId = "BF-BUILD-CUT";
    }
    part def ViewTransition {
        attribute transitionId : String;
        attribute fromState : String;
        attribute toState : String;
        attribute guard : String;
        attribute effect : String;
        attribute failureCustody : String;
        attribute quintAction : String;
        attribute leanSupport : String;
    }
    part transition0 : ViewTransition {
        attribute :>> transitionId = "ISSUE";
        attribute :>> fromState = "Acquiring";
        attribute :>> toState = "Borrowed";
        attribute :>> guard = "sealed writer/alias/provider set; serialized ingress; qualified roots; no pending cleanup";
        attribute :>> effect = "Pin source read and bind generation/entry/acquisition/content identity";
        attribute :>> failureCustody = "Failure retains acquisition owner; no borrowed token";
        attribute :>> quintAction = "issue";
        attribute :>> leanSupport = "issuedReceiptReadable";
    }
    part transition1 : ViewTransition {
        attribute :>> transitionId = "REVOKE";
        attribute :>> fromState = "Borrowed";
        attribute :>> toState = "Draining";
        attribute :>> guard = "invalidate read permission before authorizing any conflicting write";
        attribute :>> effect = "Advance generation; keep pins, roots and acquisition cleanup owner";
        attribute :>> failureCustody = "Revocation is not source-memory reclamation";
        attribute :>> quintAction = "revoke";
        attribute :>> leanSupport = "revokeRejectsOldReceipt; revokePreservesCustody";
    }
    part transition2 : ViewTransition {
        attribute :>> transitionId = "RETURN-PIN";
        attribute :>> fromState = "Draining";
        attribute :>> toState = "Draining";
        attribute :>> guard = "one active read finishes; no further raw source read";
        attribute :>> effect = "Return one pin without clearing pending cleanup";
        attribute :>> failureCustody = "All remaining pins and cleanup debt stay owned";
        attribute :>> quintAction = "returnPin";
        attribute :>> leanSupport = "livePinBlocksWriter; returnPinKeepsCleanupDebt";
    }
    part transition3 : ViewTransition {
        attribute :>> transitionId = "CLEANUP-ACK";
        attribute :>> fromState = "Draining";
        attribute :>> toState = "Suspended";
        attribute :>> guard = "all pins returned and actual cleanup/root handoff acknowledged";
        attribute :>> effect = "Settle acquisition before root release and entry reuse";
        attribute :>> failureCustody = "Unknown/error completion remains Draining; stale acquisition cannot settle a newer one";
        attribute :>> quintAction = "cleanupAck";
        attribute :>> leanSupport = "cleanupDebtBlocksDelivery; staleCleanupCannotClear; cleanupAckIdempotent";
    }
    part transition4 : ViewTransition {
        attribute :>> transitionId = "RESUME";
        attribute :>> fromState = "Suspended";
        attribute :>> toState = "Acquiring";
        attribute :>> guard = "old acquisition settled; no live pins; Scheme control entry qualified";
        attribute :>> effect = "Fresh generation/entry/acquisition; fresh roots still required";
        attribute :>> failureCustody = "Before-hook failure retains pending owner; old token never revived";
        attribute :>> quintAction = "resume";
        attribute :>> leanSupport = "freshEntryRejectsOldReceipt; freshEntryHasDistinctToken";
    }
    part transition5 : ViewTransition {
        attribute :>> transitionId = "ROOT-GRANT";
        attribute :>> fromState = "Acquiring";
        attribute :>> toState = "Acquiring";
        attribute :>> guard = "actual ROOT-HANDOFF coverage established for this entry";
        attribute :>> effect = "Make source roots available; no implicit writer requalification";
        attribute :>> failureCustody = "Missing root/provider evidence denies issue";
        attribute :>> quintAction = "rootGrant";
        attribute :>> leanSupport = "issuedReceiptReadable";
    }
    part transition6 : ViewTransition {
        attribute :>> transitionId = "UNKNOWN-WRITER";
        attribute :>> fromState = "Acquiring; Borrowed; Suspended";
        attribute :>> toState = "Draining";
        attribute :>> guard = "new unqualified alias/eval/FFI capability reached before conflicting read/write";
        attribute :>> effect = "Revoke and invalidate writer-set authority; keep physical obligations";
        attribute :>> failureCustody = "Unmediated native bypass excludes the profile; legal Scheme execution remains available";
        attribute :>> quintAction = "unknownWriter";
        attribute :>> leanSupport = "unknownWriterRejectsRead";
    }
    part transition7 : ViewTransition {
        attribute :>> transitionId = "PAYLOAD-WRITE";
        attribute :>> fromState = "Acquiring; Draining; Suspended";
        attribute :>> toState = "same";
        attribute :>> guard = "no live read pin and no Borrowed phase; actual writer gate/ordering qualified";
        attribute :>> effect = "Advance content epoch; old read token cannot match";
        attribute :>> failureCustody = "Same-owner callback must first end borrow or refuse observation; no lock self-deadlock";
        attribute :>> quintAction = "payloadWrite";
        attribute :>> leanSupport = "sameExtentMutationRejects; livePinBlocksWriter";
    }
    part acquisitionFailure : ViewTransition {
        attribute :>> transitionId = "FAIL-ACQUIRE";
        attribute :>> fromState = "Acquiring";
        attribute :>> toState = "Draining";
        attribute :>> guard = "before-hook copy/root/provider acquisition fails or cancellation arrives before issue";
        attribute :>> effect = "Revoke generation and retain partial acquisition cleanup debt; do not assume body after-hook was installed";
        attribute :>> failureCustody = "Enclosing acquisition owner retains roots/buffers/resources until explicit cleanup acknowledgement";
        attribute :>> quintAction = "failAcquire";
        attribute :>> leanSupport = "revokePreservesCustody; cleanupDebtBlocksDelivery";
    }
}
