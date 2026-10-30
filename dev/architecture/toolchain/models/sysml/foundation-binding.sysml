package GerbilFoundationIdentity {
 private import ScalarValues::*;
 part def Region {
 attribute key : String; attribute ownership : String; attribute sourceAnchor : String; attribute labelText : String; attribute rule : String;
 }
 part region0 : Region {
 attribute :>> key = "rootImage";
 attribute :>> ownership = "image";
 attribute :>> sourceAnchor = "expander/root.ss:168-184; expander/init.ss:8-15";
 attribute :>> labelText = "Root expander/feature recipes";
 attribute :>> rule = "Share qualified immutable recipes and logical origins; existing live root table is not automatically frozen";
 }
 part region1 : Region {
 attribute :>> key = "definition";
 attribute :>> ownership = "canonical";
 attribute :>> sourceAnchor = "expander/core.ss:518-565; expander/top.ss:644-681";
 attribute :>> labelText = "Definition-context identity";
 attribute :>> rule = "One canonical identity per module generation, phase and nesting; never rebase quotes to consumer context";
 }
 part region2 : Region {
 attribute :>> key = "consumer";
 attribute :>> ownership = "session";
 attribute :>> sourceAnchor = "expander/core.ss:476-490; root.ss:176-182";
 attribute :>> labelText = "Use context and fresh expansion state";
 attribute :>> rule = "Private use contexts/marks; sharing canonical definitions does not share mutable consumer tables";
 }
 part region3 : Region {
 attribute :>> key = "liftedQuote";
 attribute :>> ownership = "split";
 attribute :>> sourceAnchor = "compiler/compile.ss:1150-1198,1219-1245; expander/stx.ss:20-24";
 attribute :>> labelText = "Lifted quote instruction versus initialized object";
 attribute :>> rule = "Share encoded context/mark references; instantiate or canonically intern quote objects using a memoized origin map, preserving context eq relations";
 }
 part region4 : Region {
 attribute :>> key = "marks";
 attribute :>> ownership = "split";
 attribute :>> sourceAnchor = "expander/core.ss:150-151,600-620,831-835; stx.ss:176-182";
 attribute :>> labelText = "Definition marks and use-site substitutions";
 attribute :>> rule = "Keep definition-mark origins stable; fresh use-site mark identities; ordered cancellation and repeated-reference aliases preserved; writes need actual ownership";
 }
 part region5 : Region {
 attribute :>> key = "phiLinks";
 attribute :>> ownership = "session";
 attribute :>> sourceAnchor = "expander/core.ss:652-690";
 attribute :>> labelText = "Lazy phase up/down materialization";
 attribute :>> rule = "Resolver reads can allocate and write links; precompute an admitted finite cut or redirect lazy cache writes to owned side state";
 }
 part region6 : Region {
 attribute :>> key = "moduleInstance";
 attribute :>> ownership = "effect-domain";
 attribute :>> sourceAnchor = "expander/module.ss:93-116,139-181; compiler/driver.ss:707-747";
 attribute :>> labelText = "Module initialization and captured phase state";
 attribute :>> rule = "Preserve existing once-per-instance scope; opaque/stateful providers have one serialized owner, not independent resets per consumer";
 }
 part region7 : Region {
 attribute :>> key = "loader";
 attribute :>> ownership = "effect-domain";
 attribute :>> sourceAnchor = "expander/module.ss:277-318; runtime/loader.ss:14-30; expander/init.ss:8-15";
 attribute :>> labelText = "Prelude, reader and loader hooks";
 attribute :>> rule = "Full reader/phase/native initialization closure unproved; separate code availability, initialization success and effect ownership";
 }
 part region8 : Region {
 attribute :>> key = "identityMap";
 attribute :>> ownership = "session";
 attribute :>> sourceAnchor = "compiler/compile.ss:1181-1245; expander/top.ss:644-681";
 attribute :>> labelText = "Binding/context/mark reconstruction map";
 attribute :>> rule = "Injective origin mapping, stable imported identities, consistent aliases and phase/generation separation; raw name equality is insufficient";
 }
 part region9 : Region {
 attribute :>> key = "diagnostics";
 attribute :>> ownership = "session";
 attribute :>> sourceAnchor = "expander/core.ss:154-168; core.ss:831-835";
 attribute :>> labelText = "Error context and mark trace";
 attribute :>> rule = "Retain required context/phase/error observations; source serializer already restores trace as false, not an arbitrary new erasure";
 }
 part def RegionEdge { attribute producer : Integer; attribute consumer : Integer; }
 part edge0 : RegionEdge { attribute :>> producer = 0; attribute :>> consumer = 1; }
 part edge1 : RegionEdge { attribute :>> producer = 1; attribute :>> consumer = 3; }
 part edge2 : RegionEdge { attribute :>> producer = 1; attribute :>> consumer = 4; }
 part edge3 : RegionEdge { attribute :>> producer = 2; attribute :>> consumer = 4; }
 part edge4 : RegionEdge { attribute :>> producer = 3; attribute :>> consumer = 8; }
 part edge5 : RegionEdge { attribute :>> producer = 4; attribute :>> consumer = 8; }
 part edge6 : RegionEdge { attribute :>> producer = 1; attribute :>> consumer = 5; }
 part edge7 : RegionEdge { attribute :>> producer = 6; attribute :>> consumer = 1; }
 part edge8 : RegionEdge { attribute :>> producer = 7; attribute :>> consumer = 6; }
 part edge9 : RegionEdge { attribute :>> producer = 4; attribute :>> consumer = 9; }
 part def ReconstructionWitness {
 attribute parallelRequested : Boolean;
 attribute completeFoundationCut : Boolean;
 attribute definitionIdentityPreserved : Boolean;
 attribute useMarksFresh : Boolean;
 attribute aliasesPreserved : Boolean;
 attribute phaseAndGenerationSeparated : Boolean;
 attribute moduleInstanceScopePreserved : Boolean;
 attribute noWritesToSharedGraph : Boolean;
 attribute effectDomainAdmitted : Boolean;
 }
 requirement def ParallelReconstructionLaw {
 subject witness : ReconstructionWitness;
 require constraint { not witness.parallelRequested or
 (witness.completeFoundationCut and witness.definitionIdentityPreserved and
 witness.useMarksFresh and witness.aliasesPreserved and
 witness.phaseAndGenerationSeparated and witness.moduleInstanceScopePreserved and
 witness.noWritesToSharedGraph and witness.effectDomainAdmitted) }
 }
 part def NetCase { attribute key : String; attribute baseline : String; attribute avoided : String; attribute added : String; }
 part net0 : NetCase {
 attribute :>> key = "quotePrograms";
 attribute :>> baseline = "Generator already lifts and memoizes quotes/marks within compilation; batch registry can reuse loaded modules";
 attribute :>> avoided = "Only repeated program decode/load across separately admitted requests can count as removed work";
 attribute :>> added = "Origin-map validation, initialized constants and binding reconstruction; R can be zero in current batch";
 }
 part net1 : NetCase {
 attribute :>> key = "phaseQueries";
 attribute :>> baseline = "Current lazy phase links are cached on live contexts";
 attribute :>> avoided = "Qualified finite phase images can prevent duplicate per-worker materialization relative to isolated workers";
 attribute :>> added = "Phase-cut validation, image publication and fallback overlays; no new saving credited when the current batch already shares the cache";
 }
 part net2 : NetCase {
 attribute :>> key = "useMarks";
 attribute :>> baseline = "Source allocates a fresh mark per user macro application";
 attribute :>> avoided = "No elimination of required fresh mark identities; optimize representation only under the same observable identity contract";
 attribute :>> added = "N admitted applications still need N fresh use identities; collapsing them changes cancellation/binding behavior";
 }
 part net3 : NetCase {
 attribute :>> key = "moduleInit";
 attribute :>> baseline = "Current module registry/delayed evaluation can initialize one instance for several consumers";
 attribute :>> avoided = "Keep the same module-instance effect scope; parallelize independent domains around it";
 attribute :>> added = "Stateful initialization cannot be erased or reset per consumer; serialized owner adds queue/drain bookkeeping";
 }
 part net4 : NetCase {
 attribute :>> key = "definitionLookup";
 attribute :>> baseline = "Current contexts and sticky optimizer state already share work";
 attribute :>> avoided = "Retain that reuse in an immutable image plus owned overlays while removing false serialization";
 attribute :>> added = "Reference completeness, deep freeze, canonical object lifetime and overlay costs; positive work requires independently established R greater than added costs";
 }

 attribute definitionContext : Integer = 0;
 attribute consumerContext : Integer = 1;
 attribute alternateContext : Integer = 2;
 attribute sourceFoundationClosed : Boolean = false;
 attribute workRule : String = "Current registry/sticky caches are the baseline. Count only avoided repeated plan/decode/validation work; subtract reconstruction maps, canonical identity bookkeeping, overlays, fresh initialization, effect-owner scheduling and pin/reclamation. Stateful module initialization is not removable work.";
 part history : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "FI-H"; attribute :>> kind = "interleaving";
 attribute :>> subjectPath = "models/build/foundation_binding_identity.qnt"; attribute :>> subjectScope = "foundation_binding_identity:Test$"; attribute :>> premise = "Finite definition/use binding, mark alias/cancellation, phase cache write and shared module-instance counter model; no actual source admission";
 }
 part induction : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "FI-I"; attribute :>> kind = "induction";
 attribute :>> subjectPath = "models/build/FoundationBindingIdentity.lean"; attribute :>> subjectScope = "FoundationBindingIdentity:mapToggle;bindingEqualityPreserved;transportedLookup;missingLookupPreserved;contextAliasPreserved;statefulResetChangesObservation;actualWorkPositive"; attribute :>> premise = "Conditional injective identity transport and lookup reflection, ordered mark cancellation and stateful reset counterexample; source resolver refinement open";
 }
 part source : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "FI-S"; attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "models/build/FoundationBindingIdentity.lean"; attribute :>> subjectScope = "FI-S:foundation-source-simulation"; attribute :>> premise = "Actual imported/alias resolver, phase displacement, deep capture ownership, context eq, module initialization effects and reflection APIs must refine the identity/owner contract";
 }
 part platform : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "FI-E"; attribute :>> kind = "environment-refinement";
 attribute :>> subjectPath = "dev/architecture/toolchain/foundation-binding-design.org"; attribute :>> subjectScope = "FI-E:foundation-platform-refinement"; attribute :>> premise = "Deep-frozen publication, lifetime, actual reader/native hooks and usable process/VM parallel configuration remain open; Dune learning snapshot is not a runtime input";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = platform; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = GerbilSessionClosure::source; }
}

