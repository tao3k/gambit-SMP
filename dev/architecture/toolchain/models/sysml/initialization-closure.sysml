package GerbilInitializationClosure {
 private import ScalarValues::*;
 part def Node { attribute key : String; attribute kind : String; attribute anchor : String; attribute rule : String; }
 part node0 : Node {
 attribute :>> key = "root";
 attribute :>> kind = "recipe";
 attribute :>> anchor = "expander/root.ss:168-184; expander/init.ss:8-15";
 attribute :>> rule = "Root/table construction; prelude and hook publication";
 }
 part node1 : Node {
 attribute :>> key = "foundation";
 attribute :>> kind = "composite";
 attribute :>> anchor = "base.ss:8-9; core.ss:8-30; runtime.ss:11-27";
 attribute :>> rule = "Core at displaced phases and runtime imports; no finite phase bound inferred";
 }
 part node2 : Node {
 attribute :>> key = "instance";
 attribute :>> kind = "owner";
 attribute :>> anchor = "expander/module.ss:93-116,131-208";
 attribute :>> rule = "Registry aliases and delayed evaluation preserve one selected instance";
 }
 part node3 : Node {
 attribute :>> key = "resolution";
 attribute :>> kind = "input";
 attribute :>> anchor = "expander/module.ss:358-397,414-452";
 attribute :>> rule = "Package ascent and ordered SSI/source search; negative existence inputs";
 }
 part node4 : Node {
 attribute :>> key = "sexpReader";
 attribute :>> kind = "session";
 attribute :>> anchor = "expander/module.ss:211-232; runtime/syntax.ss:255-276";
 attribute :>> rule = "Port, readtable, AST location and parse-error fallback";
 }
 part node5 : Node {
 attribute :>> key = "langReader";
 attribute :>> kind = "capability";
 attribute :>> anchor = "expander/module.ss:275-318";
 attribute :>> rule = "Resolve phase-1 reader export and evaluate procedure before invocation";
 }
 part node6 : Node {
 attribute :>> key = "readerBody";
 attribute :>> kind = "opaque";
 attribute :>> anchor = "std/text/parser/ebnf/lang.ss:5-18; lang-reader.ss:5-90";
 attribute :>> rule = "Concrete reader imports and executable parser helpers; arbitrary effects not excluded";
 }
 part node7 : Node {
 attribute :>> key = "phaseLoad";
 attribute :>> kind = "code";
 attribute :>> anchor = "compiler/compile.ss:1258-1276,1471-1484; compiler/driver.ss:707-750";
 attribute :>> rule = "SSI loads phase blocks; interface/code/initialization readiness differ";
 }
 part node8 : Node {
 attribute :>> key = "loader";
 attribute :>> kind = "owner";
 attribute :>> anchor = "runtime/loader.ss:11-16,32-110,112-143";
 attribute :>> rule = "Loading/error/success states, shared condition, reload and version selection";
 }
 part node9 : Node {
 attribute :>> key = "setup";
 attribute :>> kind = "native";
 attribute :>> anchor = "vendor/gambit/lib/_eval.scm:5413-5474; setup.c:2068-2095; os_dyn.c:255-277";
 attribute :>> rule = "Native loader and module setup are effectful; failure does not prove rollback";
 }
 part node10 : Node {
 attribute :>> key = "hooks";
 attribute :>> kind = "process";
 attribute :>> anchor = "runtime/init.ss:15-41; runtime/syntax.ss:287-310";
 attribute :>> rule = "Global compiler/readtable hooks and console ports require environment ownership";
 }
 part node11 : Node {
 attribute :>> key = "capture";
 attribute :>> kind = "open";
 attribute :>> anchor = "expander/core.ss:600-620,652-690; compiler/compile.ss:1150-1245";
 attribute :>> rule = "Reachable closure/capture graph, lazy writes and native aliases require admission";
 }
 part def Edge { attribute producer : Integer; attribute consumer : Integer; }
 part edge0 : Edge { attribute :>> producer = 0; attribute :>> consumer = 1; }
 part edge1 : Edge { attribute :>> producer = 0; attribute :>> consumer = 10; }
 part edge2 : Edge { attribute :>> producer = 1; attribute :>> consumer = 2; }
 part edge3 : Edge { attribute :>> producer = 1; attribute :>> consumer = 7; }
 part edge4 : Edge { attribute :>> producer = 2; attribute :>> consumer = 3; }
 part edge5 : Edge { attribute :>> producer = 2; attribute :>> consumer = 4; }
 part edge6 : Edge { attribute :>> producer = 2; attribute :>> consumer = 5; }
 part edge7 : Edge { attribute :>> producer = 2; attribute :>> consumer = 7; }
 part edge8 : Edge { attribute :>> producer = 2; attribute :>> consumer = 11; }
 part edge9 : Edge { attribute :>> producer = 4; attribute :>> consumer = 10; }
 part edge10 : Edge { attribute :>> producer = 5; attribute :>> consumer = 6; }
 part edge11 : Edge { attribute :>> producer = 5; attribute :>> consumer = 2; }
 part edge12 : Edge { attribute :>> producer = 6; attribute :>> consumer = 4; }
 part edge13 : Edge { attribute :>> producer = 6; attribute :>> consumer = 11; }
 part edge14 : Edge { attribute :>> producer = 7; attribute :>> consumer = 8; }
 part edge15 : Edge { attribute :>> producer = 8; attribute :>> consumer = 3; }
 part edge16 : Edge { attribute :>> producer = 8; attribute :>> consumer = 9; }
 part edge17 : Edge { attribute :>> producer = 9; attribute :>> consumer = 11; }
 part def Gate { attribute key : String; attribute rule : String; attribute qualified : Boolean; }
 part gate0 : Gate { attribute :>> key = "sourceCut"; attribute :>> rule = "Complete executable and reachable-state closure, including displaced phases, readers and captures"; attribute :>> qualified = false; }
 part gate1 : Gate { attribute :>> key = "capabilities"; attribute :>> rule = "Every eval/reader/native/FFI callback is mediated or explicitly refused"; attribute :>> qualified = false; }
 part gate2 : Gate { attribute :>> key = "stableInputs"; attribute :>> rule = "Positive and negative resolution facts, bytes, readtable, hooks and environment remain stable"; attribute :>> qualified = false; }
 part gate3 : Gate { attribute :>> key = "identity"; attribute :>> rule = "Canonical bindings, context aliases, marks and original module-instance scope are preserved"; attribute :>> qualified = false; }
 part gate4 : Gate { attribute :>> key = "initialized"; attribute :>> rule = "All required initialization has completed successfully; partial or unknown setup is not success"; attribute :>> qualified = false; }
 part gate5 : Gate { attribute :>> key = "writes"; attribute :>> rule = "Frozen cut has no reachable unowned writers; mutable provider state stays behind an owner"; attribute :>> qualified = false; }
 part gate6 : Gate { attribute :>> key = "lifetime"; attribute :>> rule = "Generation-bound publication and borrower pins prevent revoke/reclaim races"; attribute :>> qualified = false; }
 part gate7 : Gate { attribute :>> key = "nativePolicy"; attribute :>> rule = "Native addresses, constructors, globals and callbacks are admitted per process/VM domain"; attribute :>> qualified = false; }
 part def Benefit { attribute key : String; attribute removed : String; attribute mechanism : String; attribute added : String; }
 part benefit0 : Benefit {
 attribute :>> key = "foundation";
 attribute :>> removed = "Repeated isolated decoding/validation";
 attribute :>> mechanism = "Frozen recipe/image plus owned overlays";
 attribute :>> added = "Closure audit, publication and pin bookkeeping; existing batch reuse is baseline";
 }
 part benefit1 : Benefit {
 attribute :>> key = "reader";
 attribute :>> removed = "Repeated read/parse only for equivalent admitted observations";
 attribute :>> mechanism = "Cache read result with input and reader identities";
 attribute :>> added = "Mediated I/O, readtable/args/locations and failure evidence; opaque readers remain executable";
 }
 part benefit2 : Benefit {
 attribute :>> key = "native";
 attribute :>> removed = "Repeated lookup/phase load within an admitted domain";
 attribute :>> mechanism = "Keep code availability and instance readiness distinct";
 attribute :>> added = "OS/module setup and process globals cannot be copied as immutable bytes";
 }
 part benefit3 : Benefit {
 attribute :>> key = "stateful";
 attribute :>> removed = "False serialization outside provider access";
 attribute :>> mechanism = "Parallel independent consumer work around one effect owner";
 attribute :>> added = "Owner queue, continuation/dynamic-parameter handoff, reentry and dependency-order proof";
 }
 part benefit4 : Benefit {
 attribute :>> key = "reclamation";
 attribute :>> removed = "Redundant generation reconstruction";
 attribute :>> mechanism = "Reuse current qualified cut until inputs change";
 attribute :>> added = "Revocation closes new pins, drains old borrowers; unknown effects retain custody";
 }
 attribute observedClosure : Boolean = false;
 attribute gateCount : Integer = 8;
 attribute consumerCount : Integer = 2;
 part def FreezeWitness {
 attribute requested : Boolean; attribute sourceCut : Boolean; attribute capabilities : Boolean;
 attribute stableInputs : Boolean; attribute identity : Boolean; attribute initialized : Boolean;
 attribute writes : Boolean; attribute lifetime : Boolean; attribute nativePolicy : Boolean;
 }
 requirement def FreezeLaw {
 subject witness : FreezeWitness;
 require constraint { not witness.requested or
 (witness.sourceCut and witness.capabilities and witness.stableInputs and
 witness.identity and witness.initialized and witness.writes and witness.lifetime and witness.nativePolicy) }
 }
 part history : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "IC-H"; attribute :>> kind = "interleaving";
 attribute :>> subjectPath = "models/build/initialization_closure.qnt"; attribute :>> subjectScope = "initialization_closure:Test$"; attribute :>> premise = "Finite closure admission, unique instance, effect-order and revoke/drain controls; independent work is not arbitrary parallel macro execution";
 }
 part induction : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "IC-I"; attribute :>> kind = "induction";
 attribute :>> subjectPath = "models/build/InitializationClosure.lean"; attribute :>> subjectScope = "InitializationClosure:closureCoversWalk;readyRequiresSuccess;effectPreservesInstance;effectExtendsHistory;revokePreservesBorrowers;drainedReclaim;workThreshold"; attribute :>> premise = "Closed-cut path coverage and conditional algebraic obligations; source simulation and liveness not established";
 }
 part source : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "IC-S"; attribute :>> kind = "source-refinement";
 attribute :>> subjectPath = "dev/architecture/toolchain/initialization-closure-design.org"; attribute :>> subjectScope = "IC-S:initialization-source-simulation"; attribute :>> premise = "Full capture and capabilities census, recursive phase closure, loader aliases, reentry, failures and source-to-model simulation remain open";
 }
 part platform : GambitAssuranceRouting::ModelNeed {
 ref part :>> owner = GambitBuildAssurance::scheduler.component;
 attribute :>> obligationId = "IC-E"; attribute :>> kind = "environment-refinement";
 attribute :>> subjectPath = "dev/architecture/toolchain/initialization-closure-design.org"; attribute :>> subjectScope = "IC-E:freeze-publication-platform"; attribute :>> premise = "Modern-C release/acquire and root/pin lifetime, process hooks, native setup and owner invocation ABI remain unqualified";
 }
 part dependency0 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = history; }
 part dependency1 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = induction; }
 part dependency2 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = platform; }
 part dependency3 : GambitAssuranceRouting::NeedDependency { ref part :>> dependent = source; ref part :>> prerequisite = GerbilFoundationIdentity::source; }
}
