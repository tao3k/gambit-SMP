/* Maintained Org-linked copy. The original draft header below records historical
 * validation status; current strict-diagnostic status is in dev/research/validation.org.
 * No model behavior, solver, Gambit compiler or native test has been executed. */
/* DESIGN DRAFT, 2026-10-20: no parser/resolver/interpreter/solver run.
 * Proposed architecture, not Gambit implementation or an acceptance witness.
 * Ports specify exchanges, not byte layout, FFI ABI or memory lifetime.
 * Guard inputs and economics have no observed values or default successes.
 * See opensysml-architecture-modeling.md and opensysml-model-traceability.json.
 */
package GambitModernization {
    private import ScalarValues::*;

    item def SemanticProduct {
        attribute semanticIdentity : String;
        attribute route : String;
        attribute runtimeProfileIdentity : String;
        attribute sourceEvidenceIdentity : String;
    }
    item def NativeProduct {
        attribute objectIdentity : String;
        attribute rootFrameRoleMapIdentity : String;
        attribute runtimeProfileIdentity : String;
        attribute targetProviderIdentity : String;
        attribute diagnosticsIdentity : String;
    }
    port def CompileService {
        in item request : SemanticProduct;
        out item product : NativeProduct;
    }
    port def ProductDelivery {
        out item product : NativeProduct;
    }

    part def Frontend {
        doc /* SO01: binding, expansion, evaluation and ForeignPlan meanings. */
    }
    part def SemanticCompiler {
        doc /* SO02: high export or completed GVM; preserve semantic authority. */
        port high : ~CompileService;
        port gvm : ~CompileService;
    }
    part def RuntimeProtocol {
        doc /* SO03: Scheme values, roots, continuations, VM and control law. */
    }
    part def NativeWorker {
        doc /* SO04: separate compiler process, physical realization and custody.
             * No Scheme heap addresses or LLVM handles cross this service. */
        port high : CompileService;
        port gvm : CompileService;
    }
    part def MlirProvider {
        doc /* SO05: optional admitted high IR/lowering; domain legality required. */
    }
    part def LlvmProvider {
        doc /* SO06: target/code/object facilities, with qualified profile. */
    }
    part def RawCIsland {
        doc /* SO07: complete admitted raw-C nonlocal-control extents. */
    }
    part def RuntimeSdk {
        doc /* SO08: in-process implementation; no LLVM implementation dependency.
             * Module binding is not compiler-process execution. */
        port install : ~ProductDelivery;
    }
    part def ProductCustodian {
        doc /* Validate, retain and deliver owned product, not live heap pointers. */
        port deliver : ProductDelivery;
    }
    part def FullSystem {
        attribute nativeLanguage : String;
        part SO01_frontend : Frontend;
        part SO02_semantics : SemanticCompiler;
        part SO03_protocol : RuntimeProtocol;
        part SO04_worker : NativeWorker;
        part SO05_mlir : MlirProvider;
        part SO06_llvm : LlvmProvider;
        part SO07_rawC : RawCIsland;
        part SO08_sdk : RuntimeSdk;
        part productCustodian : ProductCustodian;
        interface SO02_semantics.high to SO04_worker.high;
        interface SO02_semantics.gvm to SO04_worker.gvm;
        interface productCustodian.deliver to SO08_sdk.install;
        /* Provider deployment, worker->custodian transfer, authority and product
         * validation are NOT encoded by these three interface connections. */
    }
    part def CFull :> FullSystem {
        attribute :>> nativeLanguage = "modern C with required provider support";
    }
    part def ZFull :> FullSystem {
        attribute :>> nativeLanguage = "Zig with required provider support";
    }
    /* Common types express intended capability parity, not evidence of it. */
    part cFull : CFull;
    part zFull : ZFull;

    package RuntimeContracts {
        item def BeginPark;
        item def PublicationAcknowledged;
        item def RequestReentry;
        item def ResumeGranted;
        item def BeginRetirement;
        item def RetentionNeeded;
        item def RetryRetirement;
        item def FinalUseAcknowledged;

        state def ContextLifecycle {
            doc /* CT projection: protocol inputs are unbound proof obligations.
                 * No publication actions, memory model or failure census yet. */
            in attribute parkReady : Boolean;
            in attribute resumeReady : Boolean;
            in attribute reclaimReady : Boolean;
            entry;
            then CT0_OwnedActive;
            state CT0_OwnedActive;
            state CT1_Publishing;
            state CT2_ParkedNative;
            state CT3_ReentryPending;
            state CT4_Retiring;
            state CT5_RetainedAfterFailure;
            state CT6_Reclaimed;

            transition beginPark first CT0_OwnedActive
                accept BeginPark then CT1_Publishing;
            transition park first CT1_Publishing
                accept PublicationAcknowledged if parkReady then CT2_ParkedNative;
            transition requestReentry first CT2_ParkedNative
                accept RequestReentry then CT3_ReentryPending;
            transition resume first CT3_ReentryPending
                accept ResumeGranted if resumeReady then CT0_OwnedActive;
            transition retireActive first CT0_OwnedActive
                accept BeginRetirement then CT4_Retiring;
            transition retireParked first CT2_ParkedNative
                accept BeginRetirement then CT4_Retiring;
            transition retainPublicationFailure first CT1_Publishing
                accept RetentionNeeded then CT5_RetainedAfterFailure;
            transition retainReentryFailure first CT3_ReentryPending
                accept RetentionNeeded then CT5_RetainedAfterFailure;
            transition retainRetirementFailure first CT4_Retiring
                accept RetentionNeeded then CT5_RetainedAfterFailure;
            transition retryRetirement first CT5_RetainedAfterFailure
                accept RetryRetirement then CT4_Retiring;
            transition reclaim first CT4_Retiring
                accept FinalUseAcknowledged if reclaimReady then CT6_Reclaimed;
        }

        requirement def ParkedRootLaw {
            doc /* MV02/MA02: necessary parked-context condition, not observed state. */
            attribute isParked : Boolean;
            attribute initializedPublication : Boolean;
            attribute scannerCustodianLive : Boolean;
            attribute noManagedMutation : Boolean;
            attribute membershipAcknowledged : Boolean;
            require constraint {
                not isParked or (initializedPublication and scannerCustodianLive
                    and noManagedMutation and membershipAcknowledged)
            }
        }
        requirement def ReentryLaw {
            attribute resumesScheme : Boolean;
            attribute vmAndOriginLive : Boolean;
            attribute exclusiveExecution : Boolean;
            attribute requestReconciled : Boolean;
            attribute relocatedValuesReloaded : Boolean;
            require constraint {
                not resumesScheme or (vmAndOriginLive and exclusiveExecution
                    and requestReconciled and relocatedValuesReloaded)
            }
        }
        requirement def ReclamationLaw {
            attribute isReclaimed : Boolean;
            attribute entryClosed : Boolean;
            attribute noExecutionUsers : Boolean;
            attribute noScannerUsers : Boolean;
            attribute noContinuationOrMapUsers : Boolean;
            attribute noNativeReturnUsers : Boolean;
            attribute noUnknownHostUsers : Boolean;
            require constraint {
                not isReclaimed or (entryClosed and noExecutionUsers
                    and noScannerUsers and noContinuationOrMapUsers
                    and noNativeReturnUsers and noUnknownHostUsers)
            }
        }
        /* Laws are not bound to guard inputs: that refinement is still open.
         * No instance has assertions of satisfaction or fabricated true values. */
    }

    package Economics {
        calc def NetLowerBound {
            doc /* One explicitly selected unit/horizon; no implicit pricing. */
            in benefitLower : Real;
            in replacementUpper : Real;
            in migrationUpper : Real;
            in maintenanceUpper : Real;
            in qualificationUpper : Real;
            return result : Real = benefitLower - replacementUpper
                - migrationUpper - maintenanceUpper - qualificationUpper;
        }
        requirement def PositiveNetBound {
            attribute scopeAndParityEstablished : Boolean;
            attribute benefitLower : Real;
            attribute replacementUpper : Real;
            attribute migrationUpper : Real;
            attribute maintenanceUpper : Real;
            attribute qualificationUpper : Real;
            require constraint { scopeAndParityEstablished }
            require constraint {
                benefitLower >= 0 and replacementUpper >= 0
                    and migrationUpper >= 0 and maintenanceUpper >= 0
                    and qualificationUpper >= 0
            }
            require constraint {
                benefitLower > replacementUpper + migrationUpper
                    + maintenanceUpper + qualificationUpper
            }
        }
        requirement totalModernization : PositiveNetBound {
            doc /* AG05: B0 -> full architecture; all values remain unbound. */
        }
        requirement zigIncrement : PositiveNetBound {
            doc /* AG06: C-full -> Z-full; common LLVM/GC gains excluded.
                 * replacementUpper here means marginal Zig support cost. */
        }
    }
}
