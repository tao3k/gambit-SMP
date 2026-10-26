package GerbilSessionClosure {
 private import ScalarValues::*;
 part def Support {
  attribute key : String; attribute number : Integer; attribute sourceAnchor : String;
  attribute kind : String; attribute work : String; attribute limit : String;
 }
 part support0 : Support {
 attribute :>> key = "for";
 attribute :>> number = 0;
 attribute :>> sourceAnchor = "iter/macros.ss:34-84";
 attribute :>> kind = "execute";
 attribute :>> work = "for syntax entry, for1 and dispatch setup";
 attribute :>> limit = "selected syntax and binding identity";
 }
 part support1 : Support {
 attribute :>> key = "binding";
 attribute :>> number = 1;
 attribute :>> sourceAnchor = "iter/macros.ss:10-32; core/contract.ss:1178-1211";
 attribute :>> kind = "execute";
 attribute :>> work = "binding-contract? calls signature-contract?; empty contract falls through to pattern check";
 attribute :>> limit = "selected simple-id path";
 }
 part support2 : Support {
 attribute :>> key = "pattern";
 attribute :>> number = 2;
 attribute :>> sourceAnchor = "core/match.ss:209-218,143-157";
 attribute :>> kind = "execute";
 attribute :>> work = "match-pattern? uses continuation and exception handler; identifier terminal selected here";
 attribute :>> limit = "custom pattern expander branch excluded only for audited identifier shape";
 }
 part support3 : Support {
 attribute :>> key = "lowering";
 attribute :>> number = 3;
 attribute :>> sourceAnchor = "iter/macros.ss:88-180";
 attribute :>> kind = "execute";
 attribute :>> work = "literal range specialized; conditional iterator and wg field select generic path";
 attribute :>> limit = "emitted syntax recursively expands";
 }
 part support4 : Support {
 attribute :>> key = "using";
 attribute :>> number = 4;
 attribute :>> sourceAnchor = "core/contract.ss:401-450,664-683";
 attribute :>> kind = "execute";
 attribute :>> work = "generic path emits using, resolves Iterator interface and constructs type environment";
 attribute :>> limit = "interface metadata lookup and mutable binding construction";
 }
 part support5 : Support {
 attribute :>> key = "foundation";
 attribute :>> number = 5;
 attribute :>> sourceAnchor = "expander/core.ss:44-64,567-620,846-857";
 attribute :>> kind = "opaque";
 attribute :>> work = "syntax primitives, root/prelude and transitive interface/mop macro initialization";
 attribute :>> limit = "full immutable foundation/import census remains unproved";
 }
 part support6 : Support {
 attribute :>> key = "optimizer";
 attribute :>> number = 6;
 attribute :>> sourceAnchor = "compiler/optimize.ss:22-48,119-162; optimize-base.ss:437-474";
 attribute :>> kind = "execute";
 attribute :>> work = "sticky optimizer tables, builtin/dep SSXI imports and type/class mutations";
 attribute :>> limit = "optimization enabled in selected default build profile";
 }
 part support7 : Support {
 attribute :>> key = "ssxiEval";
 attribute :>> number = 7;
 attribute :>> sourceAnchor = "compiler/optimize.ss:135-162; expander/module.ss:93-116";
 attribute :>> kind = "opaque";
 attribute :>> work = "selected SSXI module is imported with reload and eval enabled";
 attribute :>> limit = "arbitrary phase code and native/environment effects require mediation";
 }
 part support8 : Support {
 attribute :>> key = "moduleInit";
 attribute :>> number = 8;
 attribute :>> sourceAnchor = "expander/module.ss:139-181,839-875; compiler/driver.ss:707-747";
 attribute :>> kind = "opaque";
 attribute :>> work = "phase dependency evaluation, SSI loader calls and registry initialization";
 attribute :>> limit = "support program is reusable; mutable instantiated values and effects are fresh";
 }
 part support9 : Support {
 attribute :>> key = "iterRuntime";
 attribute :>> number = 9;
 attribute :>> sourceAnchor = "iter/macros.ss:173-180; iter/iterators.ss:9-22";
 attribute :>> kind = "emitted";
 attribute :>> work = "iter and iterator methods emitted in selected generic runtime loop";
 attribute :>> limit = "this call edge is not transformer execution; opaque initialization can still require runtime support";
 }
 part def SupportEdge { attribute producer : Integer; attribute consumer : Integer; attribute kind : String; }
 part edge0 : SupportEdge { attribute :>> producer = 0; attribute :>> consumer = 1; attribute :>> kind = "exec"; }
 part edge1 : SupportEdge { attribute :>> producer = 1; attribute :>> consumer = 2; attribute :>> kind = "exec"; }
 part edge2 : SupportEdge { attribute :>> producer = 0; attribute :>> consumer = 3; attribute :>> kind = "exec"; }
 part edge3 : SupportEdge { attribute :>> producer = 3; attribute :>> consumer = 4; attribute :>> kind = "exec"; }
 part edge4 : SupportEdge { attribute :>> producer = 1; attribute :>> consumer = 5; attribute :>> kind = "exec"; }
 part edge5 : SupportEdge { attribute :>> producer = 2; attribute :>> consumer = 5; attribute :>> kind = "exec"; }
 part edge6 : SupportEdge { attribute :>> producer = 4; attribute :>> consumer = 5; attribute :>> kind = "exec"; }
 part edge7 : SupportEdge { attribute :>> producer = 6; attribute :>> consumer = 7; attribute :>> kind = "exec"; }
 part edge8 : SupportEdge { attribute :>> producer = 8; attribute :>> consumer = 5; attribute :>> kind = "exec"; }
 part edge9 : SupportEdge { attribute :>> producer = 3; attribute :>> consumer = 9; attribute :>> kind = "emit"; }
    part def ReuseOpportunity {
        attribute key : String;
        attribute sourceAnchor : String;
        attribute candidate : String;
        attribute condition : String;
        attribute cost : String;
    }
    part opportunity0 : ReuseOpportunity {
        attribute :>> key = "bindingValidation";
        attribute :>> sourceAnchor = "iter/macros.ss:34-39,77-84; core/match.ss:209-218";
        attribute :>> candidate = "Selected for then for1 call for-binding? again; carry one validated binding descriptor within a single expansion";
        attribute :>> condition = "Same syntax/binding observations and exception behavior; no custom match-expander effects; no cross-session live-context cache";
        attribute :>> cost = "Descriptor construction and point/context validity; source equivalence remains open";
    }
    part opportunity1 : ReuseOpportunity {
        attribute :>> key = "builtinChecks";
        attribute :>> sourceAnchor = "compiler/optimize.ss:42-79";
        attribute :>> candidate = "Current cache avoids builtin reload but still checks the builtin list for each optimize invocation; use a versioned immutable builtin-set credential";
        attribute :>> condition = "Profile/compiler/input generation unchanged; builtin declarations deeply frozen; invalidation complete";
        attribute :>> cost = "Set credential and overlay validation; do not claim existing cached loads as removed";
    }
    part opportunity2 : ReuseOpportunity {
        attribute :>> key = "planning";
        attribute :>> sourceAnchor = "std/make.ss:238-290,299-343; compiler/optimize.ss:81-117";
        attribute :>> candidate = "Memoize immutable dependency/lookup/SSXI planning independently of file products";
        attribute :>> condition = "Complete import/absence/load-path and optimizer context projections; no hidden eval/native effects";
        attribute :>> cost = "Dependency index, snapshot validation and invalidation bookkeeping";
    }
    part opportunity3 : ReuseOpportunity {
        attribute :>> key = "phaseImage";
        attribute :>> sourceAnchor = "compiler/compile.ss:1150-1198; compiler/optimize.ss:22-35";
        attribute :>> candidate = "Retain program reuse while replacing shared live phase state with owned lifted constants and overlays";
        attribute :>> condition = "Immutable instructions plus binding reconstruction; freshness/alpha-equivalence and callback lifetime proved";
        attribute :>> cost = "Extra per-session initialization may exceed saved work; existing registry/sticky-cache reuse stays baseline";
    }

 attribute roots : String = "Set(0, 6, 8)";
 attribute observedCensus : Boolean = false;
 part def StateDomain { attribute key : String; attribute sourceAnchor : String; attribute stateText : String; attribute ownership : String; attribute benefit : String; }
 part domain0 : StateDomain {
 attribute :>> key = "contexts";
 attribute :>> sourceAnchor = "expander/module.ss:12-13,139-181,496-509; core.ss:567-620";
 attribute :>> stateText = "Registry, package cache, context binding tables and mark substitution";
 attribute :>> ownership = "Session-owned graph; no shallow aliases through imported contexts";
 attribute :>> benefit = "Decoded immutable programs may share; mutable registry/context construction remains";
 }
 part domain1 : StateDomain {
 attribute :>> key = "optimizer";
 attribute :>> sourceAnchor = "compiler/optimize.ss:22-35,119-162; optimize-base.ss:437-474";
 attribute :>> stateText = "Sticky optimizer-info type/classes/ssxi/methods and mutable class objects";
 attribute :>> ownership = "Fresh overlay or deeply frozen snapshot plus owned overlays";
 attribute :>> benefit = "Share validated optimizer declarations; copying only top-level hash tables is insufficient";
 }
 part domain2 : StateDomain {
 attribute :>> key = "loader";
 attribute :>> sourceAnchor = "runtime/loader.ss:14-30; std/make.ss:277-290";
 attribute :>> stateText = "Process load path, library lookup and missing-file choices";
 attribute :>> ownership = "Request-owned resolution snapshot; no temporary global-path mutation";
 attribute :>> benefit = "Memoize resolution under complete path/absence identity; runtime side effects remain";
 }
 part domain3 : StateDomain {
 attribute :>> key = "phaseState";
 attribute :>> sourceAnchor = "expander/module.ss:102-116,173-181,839-875; compiler/compile.ss:1150-1198";
 attribute :>> stateText = "Delayed eval, macro closures and lifted syntax-quote constants capturing current-expander-context";
 attribute :>> ownership = "Separate immutable program instructions from session-bound lifted constants, marks and binding relocation";
 attribute :>> benefit = "Program reuse requires an explicit instantiation plan; loaded phase module objects cannot be presumed context-independent";
 }
 part domain4 : StateDomain {
 attribute :>> key = "identity";
 attribute :>> sourceAnchor = "expander/core.ss:58-64,846-857";
 attribute :>> stateText = "gensym, lexical marks and identifier substitution";
 attribute :>> ownership = "Fresh session identity domain with alpha-equivalence and binding reconstruction proof";
 attribute :>> benefit = "Global supply may be coordinated; raw symbol equality is not a reuse criterion";
 }
 part domain5 : StateDomain {
 attribute :>> key = "outputs";
 attribute :>> sourceAnchor = "compiler/driver.ss:33-36,707-747";
 attribute :>> stateText = "Generated SSI, Scheme, phase and optimization paths";
 attribute :>> ownership = "Attempt-owned groups and unique logical target owner";
 attribute :>> benefit = "One publication manifest; current writes are not already transactional";
 }
 part domain6 : StateDomain {
 attribute :>> key = "executor";
 attribute :>> sourceAnchor = "compiler/base.ss:287-335; std/make.ss:348-359";
 attribute :>> stateText = "Global compile jobs, core counter and job mutex/condition";
 attribute :>> ownership = "One explicit shared executor authority; not copied per session";
 attribute :>> benefit = "Reuse or replace legacy pool after caller migration, not multiplicative worker counts";
 }
 part domain7 : StateDomain {
 attribute :>> key = "control";
 attribute :>> sourceAnchor = "core/match.ss:209-218; compiler/optimize.ss:136-162";
 attribute :>> stateText = "Exceptions, continuation escape, diagnostics and SSXI load failure";
 attribute :>> ownership = "Session handlers; effect ordering; retain custody until callbacks/borrowers stop";
 attribute :>> benefit = "Cannot cache suppressed load failures as an immutable successful result";
 }
 part history : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "GS-H"; attribute :>> kind = "interleaving"; attribute :>> subjectPath = "models/build/gerbil_session_closure.qnt"; attribute :>> subjectScope = "gerbil_session_closure:Test$"; attribute :>> premise = "Finite real heap-location alias and support-cut model; current-source census false; positive qualification is explicitly hypothetical";
 }
 part induction : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "GS-I"; attribute :>> kind = "induction"; attribute :>> subjectPath = "models/build/GerbilSessionClosure.lean"; attribute :>> subjectScope = "GerbilSessionClosure:writePreservesOther;writesCommute;noCrossOwnership;closedRequired;unknownRejects;sharingPositive"; attribute :>> premise = "Conditional heap-footprint noninterference and closure guards; no Scheme observational equivalence or full QNT simulation";
 }
 part source : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "GS-S"; attribute :>> kind = "source-refinement"; attribute :>> subjectPath = "models/build/GerbilSessionClosure.lean"; attribute :>> subjectScope = "GS-S:actual-session-source-simulation"; attribute :>> premise = "Deep alias census, executable initializer/SSXI closure, alpha-equivalent binding reconstruction, macro effects and complete output ownership remain open";
 }
 part platform : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "GS-E"; attribute :>> kind = "environment-refinement"; attribute :>> subjectPath = "dev/architecture/toolchain/gerbil-session-closure-design.org"; attribute :>> subjectScope = "GS-E:session-platform-refinement"; attribute :>> premise = "Process/VM isolation versus CPU parallelism, exception and native effect policy, Dune mutable-main snapshot pinning and actual overhead remain open";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = platform; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = GerbilPhaseReadiness::source; }
 attribute workRule : String = "Against duplicated isolated workers only: 2P+2I becomes P+2I+H, positive iff H<P. Current sticky batch may already share P and initialization, so credit no such saving without source evidence. Actual net work requires avoided work R to exceed added initialization, overlays, validation and IPC; parallel span reduction is separate.";
}

