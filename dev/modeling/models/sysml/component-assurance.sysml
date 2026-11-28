/* Cross-component assurance prerequisites are proof dependencies, not blocking
 * runtime waits. Contract arrows carry scoped rely/guarantee and failure custody. */
package GambitComponentAssurance {
    private import ScalarValues::*;
    part dependency0 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitBuildAssurance::scheduler.source;
        ref part :>> prerequisite = GambitBuildAssurance::planner.source;
    }
    part dependency1 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitBuildAssurance::publisher.source;
        ref part :>> prerequisite = GambitBuildAssurance::planner.source;
    }
    part dependency2 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitBuildAssurance::publisher.source;
        ref part :>> prerequisite = GambitBuildAssurance::scheduler.source;
    }
    part dependency3 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitBuildAssurance::publisher.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.source;
    }
    part dependency4 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitBuildAssurance::publisher.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::control.source;
    }
    part dependency5 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitBuildAssurance::publisher.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::release.source;
    }
    part dependency6 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitBuildAssurance::planner.source;
        ref part :>> prerequisite = GambitBuildAssurance::publisher.history;
    }
    part dependency7 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitBuildAssurance::planner.source;
        ref part :>> prerequisite = GambitBuildAssurance::publisher.induction;
    }
    part dependency8 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::work.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.source;
    }
    part dependency9 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::work.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::control.source;
    }
    part dependency10 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::work.source;
        ref part :>> prerequisite = GambitSynchronousPublication::need2;
    }
    part dependency11 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::control.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.source;
    }
    part dependency12 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::release.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::work.source;
    }
    part dependency13 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::release.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::control.source;
    }
    part dependency14 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitRuntimeAssurance::release.source;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.source;
    }
    part dependency15 : GambitAssuranceRouting::NeedDependency {
        ref part :>> dependent = GambitSynchronousPublication::need2;
        ref part :>> prerequisite = GambitRuntimeAssurance::roots.source;
    }
    part contract0 : GambitAssuranceRouting::SharedContract {
        ref part :>> producer = GambitAssuranceRelations::modelUse0;
        ref part :>> consumer = GambitAssuranceRelations::modelUse1;
        attribute :>> contractId = "INPUT-CUT";
        attribute :>> phaseScope = "build request/image identity";
        attribute :>> guarantee = "Complete mediated dynamic read/effect closure and stable producer image";
        attribute :>> rely = "Consumer uses the sealed image and admits all unknown capabilities";
        attribute :>> failureCustodian = "Planner retains incomplete cut; scheduler cannot issue reuse";
    }
    part contract1 : GambitAssuranceRouting::SharedContract {
        ref part :>> producer = GambitAssuranceRelations::modelUse2;
        ref part :>> consumer = GambitAssuranceRelations::modelUse0;
        attribute :>> contractId = "OUTPUT-GROUP";
        attribute :>> phaseScope = "build request/output group and source generation";
        attribute :>> guarantee = "All C/link metadata/diagnostic/effect observations reflect a successful complete producer group";
        attribute :>> rely = "Planner validates full consumer projections, not only file length/hash at endpoints";
        attribute :>> failureCustodian = "Publisher owns staged/partial results until accepted commit/discard";
    }
    part contract2 : GambitAssuranceRouting::SharedContract {
        ref part :>> producer = GambitAssuranceRelations::modelUse1;
        ref part :>> consumer = GambitAssuranceRelations::modelUse2;
        attribute :>> contractId = "CREDIT-RETURN";
        attribute :>> phaseScope = "one host budget with child ownership distinct from GC counts";
        attribute :>> guarantee = "Cancel request does not release a running job credit; physical completion returns it once";
        attribute :>> rely = "Publisher terminal acknowledgement distinguishes exit request from settled child effects";
        attribute :>> failureCustodian = "Scheduler retains credit for unknown child; publisher retains staged data";
    }
    part contract3 : GambitAssuranceRouting::SharedContract {
        ref part :>> producer = GambitAssuranceRelations::modelUse4;
        ref part :>> consumer = GambitAssuranceRelations::modelUse3;
        attribute :>> contractId = "ROOT-HANDOFF";
        attribute :>> phaseScope = "VM/processor/context/collection epoch";
        attribute :>> guarantee = "Final registered slots are frozen, acquired, scanned and relocated values reloaded";
        attribute :>> rely = "GC does not infer participation from RC record publication or callback entry";
        attribute :>> failureCustodian = "Root custodian retains slots and old backing until accepted scan/reentry";
    }
    part contract4 : GambitAssuranceRouting::SharedContract {
        ref part :>> producer = GambitAssuranceRelations::modelUse5;
        ref part :>> consumer = GambitAssuranceRelations::modelUse3;
        attribute :>> contractId = "CONTROL-ORIGIN";
        attribute :>> phaseScope = "captured origin/frame/collection identity";
        attribute :>> guarantee = "Every saved raw origin and precise frame root survives until traversal and lease drain";
        attribute :>> rely = "Current stack scan does not imply captured closure; GC honors FrameSpec coordinates";
        attribute :>> failureCustodian = "Control retains origin/backing on unknown traversal";
    }
    part contract5 : GambitAssuranceRouting::SharedContract {
        ref part :>> producer = GambitAssuranceRelations::modelUse4;
        ref part :>> consumer = GambitAssuranceRelations::modelUse5;
        attribute :>> contractId = "CALLBACK-BORROW";
        attribute :>> phaseScope = "entry depth and VM ownership";
        attribute :>> guarantee = "Nested callbacks preserve root protection and exception/continuation cleanup ownership";
        attribute :>> rely = "Control restores VM binding and reloads moved slots before user code";
        attribute :>> failureCustodian = "Entry custodian retains borrowed resources until exact exit acknowledgement";
    }
    part contract6 : GambitAssuranceRouting::SharedContract {
        ref part :>> producer = GambitAssuranceRelations::modelUse3;
        ref part :>> consumer = GambitAssuranceRelations::modelUse6;
        attribute :>> contractId = "RETIRE-FRONTIER";
        attribute :>> phaseScope = "phase/target-specific generation";
        attribute :>> guarantee = "Producer and descendant closure plus strong/weak/cleanup completion precede reclaim permission";
        attribute :>> rely = "Resource consumer additionally closes target ingress and drains actual non-GC users";
        attribute :>> failureCustodian = "GC owns unfinished tasks; release coordinator owns accepted destructor debt";
    }
    part contract7 : GambitAssuranceRouting::SharedContract {
        ref part :>> producer = GambitAssuranceRelations::modelUse6;
        ref part :>> consumer = GambitAssuranceRelations::modelUse2;
        attribute :>> contractId = "RESOURCE-DELIVERY";
        attribute :>> phaseScope = "compiler output handle/owner/request lifetime";
        attribute :>> guarantee = "Release completion is an owner-scoped acknowledgement rather than a call to free/close";
        attribute :>> rely = "Publisher cannot deliver success while handle cleanup or unknown I/O remains";
        attribute :>> failureCustodian = "Release owner retains unacknowledged handles; publisher retains result debt";
    }
    part def ResearchGraph {
        ref part component0 : GambitAssuranceRelations::ComponentModelUse = GambitAssuranceRelations::modelUse0;
        ref part component1 : GambitAssuranceRelations::ComponentModelUse = GambitAssuranceRelations::modelUse1;
        ref part component2 : GambitAssuranceRelations::ComponentModelUse = GambitAssuranceRelations::modelUse2;
        ref part component3 : GambitAssuranceRelations::ComponentModelUse = GambitAssuranceRelations::modelUse3;
        ref part component4 : GambitAssuranceRelations::ComponentModelUse = GambitAssuranceRelations::modelUse4;
        ref part component5 : GambitAssuranceRelations::ComponentModelUse = GambitAssuranceRelations::modelUse5;
        ref part component6 : GambitAssuranceRelations::ComponentModelUse = GambitAssuranceRelations::modelUse6;
        ref part synchronousPublication : GambitAssuranceRelations::ComponentModelUse = GambitSynchronousPublication::component;
        part planner : GambitAssuranceRouting::Planner;
        part qnt : GambitAssuranceRouting::QntChecker;
        part lean : GambitAssuranceRouting::LeanChecker;
        part frontier : GambitAssuranceRouting::OpenFrontier;
        connection routes0 connect component0 to planner;
        connection routes1 connect component1 to planner;
        connection routes2 connect component2 to planner;
        connection routes3 connect component3 to planner;
        connection routes4 connect component4 to planner;
        connection routes5 connect component5 to planner;
        connection routes6 connect component6 to planner;
        connection syncRoutes connect synchronousPublication to planner;
        connection selectsHistories connect planner to qnt;
        connection selectsInduction connect planner to lean;
        connection unmetWork connect planner to frontier;
        connection shared0 connect component0 to component1;
        connection shared1 connect component2 to component0;
        connection shared2 connect component1 to component2;
        connection shared3 connect component4 to component3;
        connection shared4 connect component5 to component3;
        connection shared5 connect component4 to component5;
        connection shared6 connect component3 to component6;
        connection shared7 connect component6 to component2;
    }
    part graph : ResearchGraph;
}

