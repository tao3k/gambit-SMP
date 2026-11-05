/* Authoritative producer census and necessary custody laws. Structural model only.
 * Counts are ghost accounting, not a requirement for per-object atomic counters. */
package GambitProducerCustody {
    private import ScalarValues::*;
    private import GambitCollectionCompletion::*;
    part def TicketBalance {
        part scope : PhaseScope;
        attribute issued : Integer;
        attribute unfinished : Integer;
        attribute settled : Integer;
        attribute totalDomainRepresented : Boolean;
        attribute exclusiveCustodian : Boolean;
        attribute balancePublished : Boolean;
    }
    requirement def TicketConservationLaw {
        subject ledger : TicketBalance;
        require constraint {
            not ledger.balancePublished or
            (ledger.issued >= 0 and ledger.unfinished >= 0 and ledger.settled >= 0 and
             ledger.issued == ledger.unfinished + ledger.settled and
             ledger.totalDomainRepresented and ledger.exclusiveCustodian)
        }
    }
    part def ChildHandoff {
        attribute requiredChild : Boolean;
        attribute parentReleased : Boolean;
        attribute childReservedBeforeRelease : Boolean;
        attribute samePhaseAndGeneration : Boolean;
        attribute targetAccepted : Boolean;
        attribute canonicalAlias : Boolean;
        attribute canonicalCustodianLive : Boolean;
        attribute unfinishedDebtRetained : Boolean;
        attribute knownPreEffectFailure : Boolean;
        attribute effectUnknown : Boolean;
        attribute sourceCustodianLive : Boolean;
        attribute transferCustodianLive : Boolean;
        attribute childSettled : Boolean;
    }
    requirement def ChildAcceptanceLaw {
        subject edge : ChildHandoff;
        require constraint {
            not edge.requiredChild or not edge.parentReleased or
            (edge.childReservedBeforeRelease and edge.samePhaseAndGeneration and
             (edge.targetAccepted or (edge.canonicalAlias and (edge.canonicalCustodianLive or edge.childSettled))) and
             (edge.childSettled or edge.unfinishedDebtRetained))
        }
    }
    requirement def FailedTransferCustodyLaw {
        subject edge : ChildHandoff;
        require constraint {
            (not edge.knownPreEffectFailure or not edge.requiredChild or edge.sourceCustodianLive) and
            (not edge.effectUnknown or edge.sourceCustodianLive or edge.transferCustodianLive)
        }
    }
    part def ShutdownCut {
        attribute newRootIssuersSealed : Boolean;
        attribute admittedDerivers : Integer;
        attribute unfinishedNativeTasks : Integer;
        attribute unresolvedTransfers : Integer;
        attribute payloadBorrowers : Integer;
        attribute lateDeliveryIngressSealed : Boolean;
        attribute allIssuerFamiliesCovered : Boolean;
        attribute servicesWithdrawn : Boolean;
    }
    requirement def ServiceWithdrawalLaw {
        subject shutdown : ShutdownCut;
        require constraint {
            not shutdown.servicesWithdrawn or
            (shutdown.newRootIssuersSealed and shutdown.lateDeliveryIngressSealed and
             shutdown.allIssuerFamiliesCovered and shutdown.admittedDerivers == 0 and
             shutdown.unfinishedNativeTasks == 0 and shutdown.unresolvedTransfers == 0 and
             shutdown.payloadBorrowers == 0)
        }
    }
    part def ProducerFamily {
        attribute familyId : String;
        attribute phase : String;
        attribute path : String;
        attribute ranges : String;
        attribute entryPath : String;
        attribute derivedWork : String;
        attribute closingCut : String;
        attribute coverageLimit : String;
    }
    part def CustodyEdge {
        attribute edgeId : String;
        attribute fromState : String;
        attribute toState : String;
        attribute commitRule : String;
        attribute failureCustody : String;
        attribute obligationId : String;
    }
    part def CensusScope {
        attribute path : String;
        attribute symbols : String;
        attribute boundary : String;
    }
    part producerFamilies {
        part StillSeeds : ProducerFamily {
            attribute :>> familyId = "StillSeeds";
            attribute :>> phase = "setup / strong";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "4210-4232;6775-6805";
            attribute :>> entryPath = "setup_still_objs_to_scan -> strong local scanning";
            attribute :>> derivedWork = "External still refcount is inspected during setup; resulting list remains local work";
            attribute :>> closingCut = "Owning processor remains enrolled until its list and descendants drain";
            attribute :>> coverageLimit = "Refcount writers and host participation still need ROOT-HANDOFF closure";
        }
        part VmRoots : ProducerFamily {
            attribute :>> familyId = "VmRoots";
            attribute :>> phase = "strong";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "3970-3987;6572-6590;6651-6664;6845-6849";
            attribute :>> entryPath = "processor 0 -> VM fields, symbol/keyword tables, RC payload roots";
            attribute :>> derivedWork = "Each root cell may start copying or still discovery";
            attribute :>> closingCut = "Root routines return to the still-counted processor before idle";
            attribute :>> coverageLimit = "P0 mark_rc is not proof that every processor RC registration is covered";
        }
        part GlobalRoots : ProducerFamily {
            attribute :>> familyId = "GlobalRoots";
            attribute :>> phase = "strong";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "6592-6647;6852-6852";
            attribute :>> entryPath = "mark_global_variables -> mark_array";
            attribute :>> derivedWork = "Partition depends on SINGLE_VM and processor id/count";
            attribute :>> closingCut = "All assigned globals scanned before local fixed point and idle";
            attribute :>> coverageLimit = "Global list mutation and exact participant snapshot remain premises";
        }
        part CurrentFrames : ProducerFamily {
            attribute :>> familyId = "CurrentFrames";
            attribute :>> phase = "strong / derived frames";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "3817-3965;4096-4146;6854-6854";
            attribute :>> entryPath = "mark_continuation and scan FRAME -> mark_frame / captured chain";
            attribute :>> derivedWork = "Descriptor-selected live slots and raw continuation origins are distinct";
            attribute :>> closingCut = "Current and copied frame producers retain processor custody through nested marking";
            attribute :>> coverageLimit = "Generated descriptor completeness and all frame/denv writers remain open";
        }
        part ProcessorRoots : ProducerFamily {
            attribute :>> familyId = "ProcessorRoots";
            attribute :>> phase = "strong";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "6509-6570;6856-6864";
            attribute :>> entryPath = "registers / saved / type cache / processor fields -> mark_array";
            attribute :>> derivedWork = "Each root range can derive movable or still work";
            attribute :>> closingCut = "Seed scan precedes mark_reachable_from_marked for this participant";
            attribute :>> coverageLimit = "Actual FFI saved values and safepoint publication must refine ROOT-HANDOFF";
        }
        part MovableCopy : ProducerFamily {
            attribute :>> familyId = "MovableCopy";
            attribute :>> phase = "strong / weak";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "3470-3663";
            attribute :>> entryPath = "mark_array -> copy, forwarding CAS, tail marking, still discovery";
            attribute :>> derivedWork = "Private alloc cursor, copied body and child traversal are not queue visibility";
            attribute :>> closingCut = "Winning copy obligation stays counted through initialization and scan custody; CAS loser aliases winner";
            attribute :>> coverageLimit = "Forwarding visibility is earlier than body copy; no new reader may infer initialized body from CAS alone";
        }
        part CapturedFrames : ProducerFamily {
            attribute :>> familyId = "CapturedFrames";
            attribute :>> phase = "strong / weak";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "3668-3814";
            attribute :>> entryPath = "mark_captured_continuation -> frame copies / mark_array / end_heap_chunk";
            attribute :>> derivedWork = "Raw origins and copied frame links retain their own storage users";
            attribute :>> closingCut = "MISC_MEM_LOCK and current producer lifetime cover construction; origin release needs CONTROL-ORIGIN";
            attribute :>> coverageLimit = "No independent worker frame-origin refinement is established";
        }
        part ObjectDispatch : ProducerFamily {
            attribute :>> familyId = "ObjectDispatch";
            attribute :>> phase = "strong / weak";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "3999-4207";
            attribute :>> entryPath = "scan / scan_and_advance -> fields, closures, continuation, weak metadata";
            attribute :>> derivedWork = "PAIR fast path is a macro producer; weak table and will metadata feed later phases";
            attribute :>> closingCut = "Scanner credit persists while nested mark calls create obligations";
            attribute :>> coverageLimit = "Source switch is finite; generated subtype/layout and conditional profiles still require admission";
        }
        part StillScan : ProducerFamily {
            attribute :>> familyId = "StillScan";
            attribute :>> phase = "strong / weak";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "4235-4249;6686-6690";
            attribute :>> entryPath = "scan_still_objs_to_scan -> scan";
            attribute :>> derivedWork = "List head is removed before recursive scan returns";
            attribute :>> closingCut = "Removed item becomes scanning custody rather than disappearing from the ledger";
            attribute :>> coverageLimit = "An empty still list alone cannot discharge the active scanner";
        }
        part ChunkPublication : ProducerFamily {
            attribute :>> familyId = "ChunkPublication";
            attribute :>> phase = "strong / weak";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "3249-3306;3547-3553;3616-3624;3744-3752;3794-3803";
            attribute :>> entryPath = "four end_heap_chunk call sites from object / captured-frame copying";
            attribute :>> derivedWork = "Marker + FIFO link + barriers + tail under chunk lock; current scan chunk may bypass FIFO";
            attribute :>> closingCut = "Publisher remains counted through ordered publication or private/local scan custody";
            attribute :>> coverageLimit = "Signal is notification, not durable task accounting; separate termination lock requires refinement";
        }
        part ChunkScanSteal : ProducerFamily {
            attribute :>> familyId = "ChunkScanSteal";
            attribute :>> phase = "strong / weak";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "4252-4381;6686-6772";
            attribute :>> entryPath = "local chunk / local FIFO / remote FIFO -> scan_complete_heap_chunk";
            attribute :>> derivedWork = "FIFO removal is followed by scan outside lock; scanning can derive more chunks";
            attribute :>> closingCut = "Queue custody transfers to a counted scanner before chunk can be forgotten";
            attribute :>> coverageLimit = "Current cursor, in-flight dequeue and last-idle observation must compose";
        }
        part WeakWills : ProducerFamily {
            attribute :>> familyId = "WeakWills";
            attribute :>> phase = "weak";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "5032-5108;6873-6909";
            attribute :>> entryPath = "process_wills -> mark_array -> weak graph traversal";
            attribute :>> derivedWork = "Wills and selected testators seed new work after strong drain";
            attribute :>> closingCut = "Distinct weak counter is enrolled before weak seeds; barrier separates phases";
            attribute :>> coverageLimit = "Next phase is legitimate work; never reopen strong receipt or equate executable will with executed action";
        }
        part WeakCleanup : ProducerFamily {
            attribute :>> familyId = "WeakCleanup";
            attribute :>> phase = "post weak drain";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "5364-5725;6223-6255;6912-6935";
            attribute :>> entryPath = "process_gc_hash_tables / move_continuation";
            attribute :>> derivedWork = "Weak table repair and live-stack movement retain metadata/backing users";
            attribute :>> closingCut = "Finish repair/movement before their target storage is resized or reused";
            attribute :>> coverageLimit = "No direct mark_array call in table cleanup span; not a theorem excluding indirect/generated effects";
        }
        part ForeignWrapper : ProducerFamily {
            attribute :>> familyId = "ForeignWrapper";
            attribute :>> phase = "cleanup / explicit release";
            attribute :>> path = "vendor/gambit/lib/c_intf.c";
            attribute :>> ranges = "1683-1713;5156-5223";
            attribute :>> entryPath = "release_foreign -> release_fn; POINTER_to_SCMOBJ installs callback";
            attribute :>> derivedWork = "Foreign fields are cleared before callback; payload identity must already survive elsewhere";
            attribute :>> closingCut = "Callback acceptance and payload custody must precede wrapper loss if release is deferred";
            attribute :>> coverageLimit = "Exported callback parameter is open-world; return error is not a retry receipt";
        }
        part GcAndTeardownRelease : ProducerFamily {
            attribute :>> familyId = "GcAndTeardownRelease";
            attribute :>> phase = "cleanup / teardown";
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> ranges = "4383-4452;4928-4966";
            attribute :>> entryPath = "free_unmarked_still_objs / free_still_objs -> release_foreign";
            attribute :>> derivedWork = "Both discard release status and free still wrapper; teardown also invokes cleanup_rc";
            attribute :>> closingCut = "Separate collection and teardown issuer cuts; preserve native tasks before RC and scanner services vanish";
            attribute :>> coverageLimit = "VM cleanup destroys scan mutex/condvar before P0 cleanup and carries other-processor TODO";
        }
        part NativeDeviceTls : ProducerFamily {
            attribute :>> familyId = "NativeDeviceTls";
            attribute :>> phase = "native resource disposal";
            attribute :>> path = "vendor/gambit/lib/os_io.c";
            attribute :>> ranges = "1603-1682;3948-4562;7100-7148;10120-11465";
            attribute :>> entryPath = "device_cleanup_from_ptr / release_rc_tls_context / release_event";
            attribute :>> derivedWork = "Device close can select/wait or fail after group removal; TLS frees SSL_CTX and RC storage";
            attribute :>> closingCut = "Owner-affine native work requires accepted ticket and stable payload independent of foreign wrapper";
            attribute :>> coverageLimit = "USE_PUMPS / WIN32 / TLS profiles differ; external SSL callbacks and other vtables remain open";
        }
        part ConversionFailure : ProducerFamily {
            attribute :>> familyId = "ConversionFailure";
            attribute :>> phase = "construction failure";
            attribute :>> path = "vendor/gambit/lib/c_intf.c";
            attribute :>> ranges = "5287-5383";
            attribute :>> entryPath = "STRUCT / UNION / TYPE converters -> release_fn on wrapper failure";
            attribute :>> derivedWork = "Cleanup can occur before a foreign wrapper is ever published";
            attribute :>> closingCut = "Constructor owns payload until callback custody is accepted or terminal disposition known";
            attribute :>> coverageLimit = "Generic POINTER conversion does not automatically free on failure; caller-specific ownership must be preserved";
        }
        part GeneratedForeign : ProducerFamily {
            attribute :>> familyId = "GeneratedForeign";
            attribute :>> phase = "explicit / generated / external";
            attribute :>> path = "vendor/gambit/gsc/_ptree2.scm";
            attribute :>> ranges = "2610-2660";
            attribute :>> entryPath = "FFI conversion selects default, generated or user release identifier";
            attribute :>> derivedWork = "Custom id or generated struct/type release function extends producer domain";
            attribute :>> closingCut = "Generated release descriptors and module admission must declare effects, owner and child issuers";
            attribute :>> coverageLimit = "Finite repository symbols do not close user C, dynamic modules, native vtables or callback recursion";
        }
    }
    part custodyEdges {
        part Seed : CustodyEdge {
            attribute :>> edgeId = "Seed";
            attribute :>> fromState = "RootOrStillSeed";
            attribute :>> toState = "PrivateChild";
            attribute :>> commitRule = "Root cell/list remains live and participant counted";
            attribute :>> failureCustody = "Allocation or scan failure retains original root and epoch custody";
            attribute :>> obligationId = "WC-PRODUCER-CLOSE";
        }
        part Reserve : CustodyEdge {
            attribute :>> edgeId = "Reserve";
            attribute :>> fromState = "PrivateChild";
            attribute :>> toState = "CopyInFlight";
            attribute :>> commitRule = "Register canonical child obligation before last parent right can disappear";
            attribute :>> failureCustody = "Known pre-effect failure rolls reservation back to the still-live source";
            attribute :>> obligationId = "WC-HANDOFF-ACCOUNT";
        }
        part Canonical : CustodyEdge {
            attribute :>> edgeId = "Canonical";
            attribute :>> fromState = "CopyInFlight";
            attribute :>> toState = "CanonicalChild";
            attribute :>> commitRule = "CAS winner owns body initialization and future scan; loser maps to that exact obligation";
            attribute :>> failureCustody = "Loser discards speculative bytes only; no invented winner completion";
            attribute :>> obligationId = "WC-CANONICAL-OWNER";
        }
        part Publish : CustodyEdge {
            attribute :>> edgeId = "Publish";
            attribute :>> fromState = "CanonicalChild";
            attribute :>> toState = "QueuedOrLocal";
            attribute :>> commitRule = "Initialize body and publish marker/link/cursor with required visibility before source release";
            attribute :>> failureCustody = "Unknown publication retains transfer ticket; do not enqueue a duplicate or free payload";
            attribute :>> obligationId = "WC-TRANSFER-REFINE";
        }
        part Dequeue : CustodyEdge {
            attribute :>> edgeId = "Dequeue";
            attribute :>> fromState = "QueuedOrLocal";
            attribute :>> toState = "ScanningParent";
            attribute :>> commitRule = "Remove FIFO/list item only with counted scanner custody; partial current chunk remains owned";
            attribute :>> failureCustody = "Interrupted/unknown dequeue retains transfer record and inhibits phase drain";
            attribute :>> obligationId = "WC-TRANSFER-REFINE";
        }
        part Derive : CustodyEdge {
            attribute :>> edgeId = "Derive";
            attribute :>> fromState = "ScanningParent";
            attribute :>> toState = "PrivateChild";
            attribute :>> commitRule = "Reserve and commit all required descendants before settling parent; canonical aliases reuse obligation";
            attribute :>> failureCustody = "Mandatory mark work cannot be canceled merely to reach zero";
            attribute :>> obligationId = "WC-HANDOFF-ACCOUNT";
        }
        part NativeDetach : CustodyEdge {
            attribute :>> edgeId = "NativeDetach";
            attribute :>> fromState = "ForeignWrapper";
            attribute :>> toState = "NativeCustodian";
            attribute :>> commitRule = "Prepare stable payload/roots and accept resource task before wrapper fields become unusable";
            attribute :>> failureCustody = "Rejected transfer keeps source payload or pre-enrolled failure custodian; unknown acceptance blocks reclaim";
            attribute :>> obligationId = "RW-FOREIGN-DELIVERY";
        }
        part NativeDerive : CustodyEdge {
            attribute :>> edgeId = "NativeDerive";
            attribute :>> fromState = "NativeCustodian";
            attribute :>> toState = "ChildNativeCustodian";
            attribute :>> commitRule = "Child issuer right moves or persists until descendants and callback reentry settle";
            attribute :>> failureCustody = "Shutdown closes new roots, not already-admitted child derivation; unresolved failure retains custody";
            attribute :>> obligationId = "RW-CLEANUP-PRODUCERS";
        }
    }
    part sourceCensus {
        part mem : CensusScope {
            attribute :>> path = "vendor/gambit/lib/mem.c";
            attribute :>> symbols = "mark_array;mark_captured_continuation;mark_frame;end_heap_chunk;setup_still_objs_to_scan;scan_still_objs_to_scan;scan_complete_heap_chunk;scan_movable_objs_to_scan;scan_and_advance;mark_reachable_from_marked;___release_foreign;free_still_objs";
            attribute :>> boundary = "All lexical call-like occurrences in this file; macro definitions classified separately; no preprocessing or callgraph proof";
        }
        part foreign : CensusScope {
            attribute :>> path = "vendor/gambit/lib/c_intf.c";
            attribute :>> symbols = "___release_foreign;___POINTER_to_SCMOBJ;release_fn";
            attribute :>> boundary = "All lexical call-like occurrences; indirect release_fn family remains open-world";
        }
        part devices : CensusScope {
            attribute :>> path = "vendor/gambit/lib/os_io.c";
            attribute :>> symbols = "___NONNULLPOINTER_to_SCMOBJ;___device_cleanup_from_ptr;___release_rc_tls_context;___release_event";
            attribute :>> boundary = "All lexical call-like occurrences plus callback identifier sites; preprocessor branches retained";
        }
    }
}
