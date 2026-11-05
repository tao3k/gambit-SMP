package GerbilModuleBuild {
    private import ScalarValues::*;
    /* Target architecture only. Existing proof duties stay open; these
     * references neither extend a checked scope nor issue a reuse receipt. */
    part def ModuleBuildBoundary {
        attribute boundaryId : String;
        attribute labelText : String;
        attribute sourceAnchor : String;
        attribute redesign : String;
        attribute gain : String;
        attribute addedCost : String;
        attribute openCondition : String;
        ref part sourceDuty : GambitAssuranceRouting::ModelNeed;
    }
    part planning : ModuleBuildBoundary {
        attribute :>> boundaryId = "planning";
        attribute :>> labelText = "Phase-aware input snapshot";
        attribute :>> sourceAnchor = "gerbil-gambit-bootstrap-audit/src/std/make.ss:246-290";
        attribute :>> redesign = "Replace timestamp-only reuse with producer-owned input and output projections; record include, macro execution and lookup observations";
        attribute :>> gain = "Zero eligible compile actions on an admitted no-change request; leaf invalidation follows actual consumers";
        attribute :>> addedCost = "Snapshot validation, content comparison, dependency index and capability mediation";
        attribute :>> openCondition = "Arbitrary macro/eval/native effects require mediation or denied reuse; timestamps are not semantic identity";
        ref part :>> sourceDuty = GambitBuildAssurance::planner.source;
    }
    part frontend : ModuleBuildBoundary {
        attribute :>> boundaryId = "frontend";
        attribute :>> labelText = "Isolated expansion and optimization";
        attribute :>> sourceAnchor = "gerbil-gambit-bootstrap-audit/src/std/make.ss:220-244; src/gerbil/compiler/driver.ss:119-136; src/gerbil/expander/module.ss:139-181";
        attribute :>> redesign = "Own mutable expander registry, lexical identity and optimizer state per admitted session; share immutable products only";
        attribute :>> gain = "Independent Scheme modules may expand concurrently without a single shared import critical section";
        attribute :>> addedCost = "Session construction or worker processes, immutable export encoding and fresh phase instantiation";
        attribute :>> openCondition = "Do not remove locks before shared-state and macro side-effect isolation is established";
        ref part :>> sourceDuty = GambitBuildAssurance::scheduler.source;
    }
    part readiness : ModuleBuildBoundary {
        attribute :>> boundaryId = "readiness";
        attribute :>> labelText = "Separate phase and runtime readiness";
        attribute :>> sourceAnchor = "gerbil-gambit-bootstrap-audit/src/std/make.ss:299-343; src/gerbil/compiler/driver.ss:621-641,707-747";
        attribute :>> redesign = "Replace one module completion with consumer-specific phase and runtime prerequisites, publishing coherent generated groups";
        attribute :>> gain = "A consumer can start before unrelated runtime compilation only when its phase closure is already executable";
        attribute :>> addedCost = "More completion states, phase dependency edges, output manifests and failure propagation";
        attribute :>> openCondition = "SSI can load runtime support; compiled transformer helpers and imported effects can still require native artifacts";
        ref part :>> sourceDuty = GambitBuildAssurance::publisher.source;
    }
    part execution : ModuleBuildBoundary {
        attribute :>> boundaryId = "execution";
        attribute :>> labelText = "One budget and physical completion";
        attribute :>> sourceAnchor = "gerbil-gambit-bootstrap-audit/src/std/make.ss:229-232,348-359; patches/gerbil-v19-darwin/0002-gerbil-streaming-compile-executor.patch";
        attribute :>> redesign = "Unify module, native and follow-up admission; delegate capacity when a parent waits; retain resources until physical termination";
        attribute :>> gain = "Bound nested concurrency and overlap generation with necessary native work";
        attribute :>> addedCost = "CPU and memory reservations, cancellation custody, attempt-owned outputs and drain tracking";
        attribute :>> openCondition = "Existing unit-credit QNT does not prove weighted nested fairness, process isolation or actual memory bounds";
        ref part :>> sourceDuty = GambitBuildAssurance::scheduler.source;
    }
    part def FlowEdge {
        ref part producer : ModuleBuildBoundary;
        ref part consumer : ModuleBuildBoundary;
    }
    part edge0 : FlowEdge {
        ref part :>> producer = planning;
        ref part :>> consumer = frontend;
    }
    part edge1 : FlowEdge {
        ref part :>> producer = frontend;
        ref part :>> consumer = readiness;
    }
    part edge2 : FlowEdge {
        ref part :>> producer = readiness;
        ref part :>> consumer = execution;
    }
}
