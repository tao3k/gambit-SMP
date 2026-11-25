/* Entry and shared schema. Responsibility packages own their declarations. */
package GambitSharedHeapSmp {

 private import ScalarValues::*;
 attribute projectionKind:String="flow-contract";
 attribute designId:String="shared-heap-smp";
 attribute verificationPolicy:String="GambitVerificationResponsibilities";
 attribute sourceRepository:String="vendor/gambit";
 attribute sourceBranch:String="modern-c";
 attribute senderCompletionOrg:String="dev/refactoring/modern-c/sender-completion-design.org";
 attribute completionFrameOrg:String="dev/refactoring/modern-c/completion-frame-contract.org";
 attribute completionSettlementOrg:String="dev/refactoring/modern-c/completion-retry-handoff.org";
 attribute completionRetryOrg:String="dev/refactoring/modern-c/completion-retry-handoff.org";
 attribute completionGeneratorOrg:String="dev/refactoring/modern-c/completion-generator-contract.org";
 attribute scope:String="Modern generated C shared-heap SMP and generational GC composition; DEV research only, no runtime/native acceptance.";
 attribute implementation:String="Scheme semantics and generators; C23 runtime consumers; no new Zig requirement, profile, executor or namespace.";
 attribute domainMeaning:String="VM heap/root/collection boundary differs from logical Actor, ExecutionContext, processor carrier and CollectorWorker. Cross-context references inside a VM remain allowed; cross-VM isolation is an explicit separate policy.";
 attribute foundationBoundary:String="Consume the existing 4/4 source-bound foundation evidence; do not reopen its denominator for generations or infer full runtime acceptance.";
 attribute independentBoundary:String="Recorded5/12 at canonical65a4a2e2 includes bootstrap, GSI, GSC, pr-gsi and pr-gsc; seven remain. The coordination review revalidated both model-bound PR receipts without rerunning native workloads. Preserve historical rejection as historical; no current dirty-successor, remote-CI or repair-line credit. Read accepted_smp_status before reporting a later count.";
 attribute repairBoundary:String="The user reports repair-line9/12; this study neither reruns nor promotes that source cohort. Repair counterexamples inform source questions, not modern-c passes.";
 attribute readinessQuestion:String="nativeAcceptance";
 attribute qntLocalHistories:Integer=17;
 attribute nativeAdmitted:Boolean=false;
 attribute progressDelta:Integer=0;
 attribute leanLibraryRepository:String="models/gambit/lean/.lake/packages/LeanPoo";
 attribute leanLibraryRelease:String="https://github.com/tao3k/lean-poo/releases/tag/v0.1.2";
 attribute leanLibraryRevision:String="b29ea0d9d2ffeed0c13b66794fc6d418fd5b0393";
 attribute leanLibraryModule:String="LeanPoo.Functional.Transformation";
 attribute leanLibrarySource:String="LeanPoo/Functional/Transformation.lean";
 attribute leanLibraryToolchain:String="leanprover/lean4:v4.34.0";
 attribute lastUserModel:String="models/gambit/retirement_last_consumers.qnt";
 attribute quarantineModel:String="models/gambit/runtime_retirement_quarantine.qnt";
 part def Component { attribute id:String; attribute label:String; attribute authority:String; attribute guarantee:String; attribute retirement:String; attribute source:String; attribute falsifier:String; attribute cost:String; }
 part def Question { attribute id:String; attribute semanticKey:String; attribute owner:String; attribute domain:String; attribute artifact:String; attribute symbols:String; attribute question:String; attribute boundary:String; }
 part def ImportedNeed { attribute id:String; attribute authority:String; attribute artifact:String; attribute premise:String; attribute boundary:String; }
 part def Dependency { ref part dependent:Question; ref part prerequisite:Question; }
 part def ExternalDependency { ref part dependent:Question; ref part prerequisite:ImportedNeed; }
 part def Flow { ref part producer:Component; ref part consumer:Component; attribute contract:String; }
 part def Use { ref part component:Component; ref part question:Question; }
 part def View { attribute kind:String; attribute path:String; attribute anchor:String; }
 attribute evidenceRule:String="Local formal outputs cannot close source/native questions. Every reused receipt must match source/hash/scope; unknown or missing evidence stays open. No duplicated Quint/Lean semantic key or inferred C correctness.";
 attribute costRule:String="Compare the same source/profile/workload, separate diagnostic counters from timing, retain original limits, and account CPU work, critical-path pause and physical peak separately. Unbounded arrival or retained user continuations preclude an unconditional constant-space/latency promise.";
 attribute requestServiceOrg:String="dev/refactoring/modern-c/request-service-reconstruction.org";
 attribute requestServiceD2:String="dev/refactoring/modern-c/diagrams/request-service-reconstruction.d2";
 attribute requestServiceSvg:String="dev/refactoring/modern-c/diagrams/request-service-reconstruction.svg";
 attribute mechanismResearch:String="dev/knowledge/systems/shared-heap-smp.org";
 attribute workContractModel:String="models/gambit/gc_work_contract.qnt";
 attribute workScheduleModel:String="models/gambit/gc_work_closure.qnt";
 attribute workDataModel:String="models/gambit/lean/WorkAccounting.lean";
 part def SupportFactor {
  attribute id:String; attribute owner:String; attribute domain:String;
  attribute authority:String; attribute artifact:String; attribute dependencies:String;
  attribute scope:String; attribute boundary:String;
  ref part component:Component; ref part requiredFor:Question;
 }

 part def Workstream { attribute id:String; attribute label:String; attribute authority:String; attribute unit:String; attribute 'entry':String; attribute 'exit':String; attribute excluded:String; attribute netBenefit:String; }
 part def ProgressAxis { attribute id:String; attribute authority:String; attribute reported:String; attribute meaning:String; attribute credit:String; }
 part def Assignment { ref part question:Question; ref part workstream:Workstream; }
 part def WorkDependency { ref part dependent:Workstream; ref part prerequisite:Workstream; }
 part def SourceSite { attribute id:String; attribute artifact:String; attribute anchor:String; attribute role:String; attribute observed:String; attribute required:String; attribute gap:String; ref part question:Question; }
 part def AdapterContract { attribute id:String; attribute inputs:String; attribute precondition:String; attribute authorization:String; attribute linearization:String; attribute postcondition:String; attribute recovery:String; attribute retirement:String; attribute stateModel:String; attribute dataModel:String; attribute acceptance:String; attribute rejection:String; attribute benefit:String; ref part question:Question; }
 part def AdapterClause { attribute id:String; attribute kind:String; attribute rule:String; attribute missing:String; attribute acceptance:String; ref part adapter:AdapterContract; ref part site:SourceSite; }
 part def InventoryScope { attribute 'id':String; attribute 'path':String; attribute 'suffixes':String; attribute 'exclude':String; attribute 'boundary':String; ref part adapter:AdapterContract; }
 part def AccessFamily { attribute 'id':String; attribute 'pattern':String; attribute 'role':String; attribute 'guard':String; attribute 'publication':String; attribute 'release':String; attribute 'knownCallers':String; attribute 'gap':String; attribute 'acceptance':String; ref part adapter:AdapterContract; ref part site:SourceSite; }
 part def SourceCase { attribute 'id':String; attribute 'precondition':String; attribute 'argument':String; attribute 'conclusion':String; attribute 'missing':String; attribute 'acceptance':String; attribute 'formalBoundary':String; attribute 'counterexample':String; ref part clause:AdapterClause; ref part entrySite:SourceSite; ref part exitSite:SourceSite; }
 part def CaseDependency { attribute 'condition':String; ref part dependent:SourceCase; ref part prerequisite:SourceCase; }
 part def HandoffProtocol { attribute 'id':String; attribute 'key':String; attribute 'joinRule':String; attribute 'scope':String; attribute 'valuePolicy':String; attribute 'unknownRule':String; attribute 'retirement':String; attribute 'acceptance':String; attribute 'nonGoals':String; ref part adapter:AdapterContract; }
 part def HandoffReceipt { attribute 'id':String; attribute 'kind':String; attribute 'identity':String; attribute 'condition':String; attribute 'outcomes':String; attribute 'permits':String; attribute 'forbids':String; attribute 'unknown':String; ref part protocol:HandoffProtocol; }
 part def HandoffPoint { attribute 'id':String; attribute 'caller':String; attribute 'precondition':String; attribute 'linearization':String; attribute 'missing':String; attribute 'unknown':String; attribute 'acceptance':String; ref part protocol:HandoffProtocol; ref part site:SourceSite; ref part clause:AdapterClause; }
 part def HandoffUse { attribute 'role':String; attribute 'purpose':String; attribute 'condition':String; ref part point:HandoffPoint; ref part receipt:HandoffReceipt; }

 part def ModelModule { attribute namespace:String; attribute source:String; attribute responsibility:String; }
 public import GambitSharedHeapSmpArchitecture::*;
 part module0:ModelModule { attribute :>> namespace="GambitSharedHeapSmpArchitecture"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/architecture.sysml"; attribute :>> responsibility="architecture"; }
 public import GambitSharedHeapSmpAssurance::*;
 part module1:ModelModule { attribute :>> namespace="GambitSharedHeapSmpAssurance"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/assurance.sysml"; attribute :>> responsibility="assurance"; }
 public import GambitSharedHeapSmpDelivery::*;
 part module2:ModelModule { attribute :>> namespace="GambitSharedHeapSmpDelivery"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/delivery.sysml"; attribute :>> responsibility="delivery"; }
 public import GambitSharedHeapSmpAdapters::*;
 part module3:ModelModule { attribute :>> namespace="GambitSharedHeapSmpAdapters"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/adapter-contracts.sysml"; attribute :>> responsibility="adapter-contracts"; }
 public import GambitSharedHeapSmpWriterInventory::*;
 part module4:ModelModule { attribute :>> namespace="GambitSharedHeapSmpWriterInventory"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/writer-inventory.sysml"; attribute :>> responsibility="writer-inventory"; }
 public import GambitSharedHeapSmpRootSources::*;
 part module5:ModelModule { attribute :>> namespace="GambitSharedHeapSmpRootSources"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/roots.sysml"; attribute :>> responsibility="source-sites/roots"; }
 public import GambitSharedHeapSmpCollectorSources::*;
 part module6:ModelModule { attribute :>> namespace="GambitSharedHeapSmpCollectorSources"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/collector.sysml"; attribute :>> responsibility="source-sites/collector"; }
 public import GambitSharedHeapSmpExecutionControlSources::*;
 part module7:ModelModule { attribute :>> namespace="GambitSharedHeapSmpExecutionControlSources"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/execution-and-control.sysml"; attribute :>> responsibility="source-sites/execution-and-control"; }
 public import GambitSharedHeapSmpForeignEntrySources::*;
 part module8:ModelModule { attribute :>> namespace="GambitSharedHeapSmpForeignEntrySources"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/foreign-entry.sysml"; attribute :>> responsibility="source-sites/foreign-entry"; }
 public import GambitSharedHeapSmpQualificationSources::*;
 part module9:ModelModule { attribute :>> namespace="GambitSharedHeapSmpQualificationSources"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/qualification.sysml"; attribute :>> responsibility="source-sites/qualification"; }
 public import GambitSharedHeapSmpCoordinationLifecycleSources::*;
 part module10:ModelModule { attribute :>> namespace="GambitSharedHeapSmpCoordinationLifecycleSources"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/coordination-and-lifecycle.sysml"; attribute :>> responsibility="source-sites/coordination-and-lifecycle"; }
 public import GambitSharedHeapSmpRootHandoffRefinement::*;
 part module11:ModelModule { attribute :>> namespace="GambitSharedHeapSmpRootHandoffRefinement"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/refinements/root-handoff.sysml"; attribute :>> responsibility="refinements/root-handoff"; }
 public import GambitSharedHeapSmpRefinementDependencies::*;
 part module12:ModelModule { attribute :>> namespace="GambitSharedHeapSmpRefinementDependencies"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/refinements/dependencies.sysml"; attribute :>> responsibility="refinements/dependencies"; }
 public import GambitSharedHeapSmpCollectorWorkRefinement::*;
 part module13:ModelModule { attribute :>> namespace="GambitSharedHeapSmpCollectorWorkRefinement"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/refinements/collector-work.sysml"; attribute :>> responsibility="refinements/collector-work"; }
 public import GambitSharedHeapSmpContinuationDomainRefinement::*;
 part module14:ModelModule { attribute :>> namespace="GambitSharedHeapSmpContinuationDomainRefinement"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/refinements/continuation-and-domain.sysml"; attribute :>> responsibility="refinements/continuation-and-domain"; }
 public import GambitSharedHeapSmpRegionBulkRefinement::*;
 part module15:ModelModule { attribute :>> namespace="GambitSharedHeapSmpRegionBulkRefinement"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/refinements/regions-and-bulk.sysml"; attribute :>> responsibility="refinements/regions-and-bulk"; }
 public import GambitSharedHeapSmpHandoffContracts::*;
 part module16:ModelModule { attribute :>> namespace="GambitSharedHeapSmpHandoffContracts"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/handoff/contracts.sysml"; attribute :>> responsibility="handoff/contracts"; }
 public import GambitSharedHeapSmpHandoffCallers::*;
 part module17:ModelModule { attribute :>> namespace="GambitSharedHeapSmpHandoffCallers"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/handoff/callers.sysml"; attribute :>> responsibility="handoff/callers"; }
 public import GambitSharedHeapSmpHandoffFacts::*;
 part module18:ModelModule { attribute :>> namespace="GambitSharedHeapSmpHandoffFacts"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/handoff/facts.sysml"; attribute :>> responsibility="handoff/facts"; }
 public import GambitSharedHeapSmpRequestServiceSources::*;
 part module19:ModelModule { attribute :>> namespace="GambitSharedHeapSmpRequestServiceSources"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/request-service.sysml"; attribute :>> responsibility="current request/wait/service/GC/exit conditional refinement"; }
 public import GambitSharedHeapSmpCompletionFrames::*;
 part module20:ModelModule { attribute :>> namespace="GambitSharedHeapSmpCompletionFrames"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/completion-frame.sysml"; attribute :>> responsibility="static resume structural frame/root/alias/exit refinement"; }
 public import GambitSharedHeapSmpCompletionGenerator::*;
 part module21:ModelModule { attribute :>> namespace="GambitSharedHeapSmpCompletionGenerator"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/completion-generator.sysml"; attribute :>> responsibility="GVM liveness/checkpoint/emission/consumer refinement"; }
 public import GambitSharedHeapSmpCompletionSettlement::*;
 part module22:ModelModule { attribute :>> namespace="GambitSharedHeapSmpCompletionSettlement"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/completion-settlement.sysml"; attribute :>> responsibility="same-wait root transfer/query/ACK and real-cut accounting"; }
 public import GambitSharedHeapSmpPr988Mechanisms::*;
 part module23:ModelModule { attribute :>> namespace="GambitSharedHeapSmpPr988Mechanisms"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/pr988-mechanisms.sysml"; attribute :>> responsibility="historical repair mechanism to current responsibility and acceptance refinement"; }
 public import GambitSharedHeapSmpWaitNativeAcceptance::*;
 public import GambitSharedHeapSmpEnvironmentQualification::*;
 part module25:ModelModule { attribute :>> namespace="GambitSharedHeapSmpEnvironmentQualification"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/environment-qualification.sysml"; attribute :>> responsibility="whole interpreter environment/root/exposure source refinement and stress admission"; }
 part module24:ModelModule { attribute :>> namespace="GambitSharedHeapSmpWaitNativeAcceptance"; attribute :>> source="dev/refactoring/modern-c/models/sysml/shared-heap-smp/source-sites/wait-native-acceptance.sysml"; attribute :>> responsibility="no-escape production wait, same-shot rearm/fallback and exit native acceptance source adapters"; }
}
