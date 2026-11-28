package GambitSmpInterpreterTailDeopt {
 private import ScalarValues::*;
 ref part owner=GambitSmpDevComposition::interpreter;
 part def Transition {
   attribute id:String; attribute trigger:String; attribute authority:String;
   attribute contract:String; attribute refusal:String; attribute source:String;
   attribute qntAction:String;
 }
 part classify:Transition {
   attribute :>> id="classify"; attribute :>> trigger="A one-argument interpreted tail call is considered for reuse";
   attribute :>> authority="Existing interpreter compiler and active execution context";
   attribute :>> contract="Prove exact procedure identity, tail position, lexical writer and observer coverage; retain ordinary call when a handler, debugger, reflection or unknown path cannot be represented";
   attribute :>> refusal="Fallback preserves evaluation order, arity errors and original procedure dispatch";
   attribute :>> source="lib/_eval.scm: ##gen-app-aux, ##cprc-app1-red and ##cprc-prc-req1";
   attribute :>> qntAction="tailCall";
 }
 part compact:Transition {
   attribute :>> id="compact"; attribute :>> trigger="Enter an accepted compact activation";
   attribute :>> authority="Current execution context and collector root map";
   attribute :>> contract="Procedure, argument, lexical parent and deoptimization metadata remain visible to relocation and every required safe point";
   attribute :>> refusal="If any root or frame map is unknown, create the existing vector environment";
   attribute :>> source="lib/_eval#.scm: macro-code-run and macro-make-rte; compiler frame/stack maps";
   attribute :>> qntAction="collect";
 }
 part request:Transition {
   attribute :>> id="capture-request"; attribute :>> trigger="An asynchronous capture, debugger or escaping closure can observe the current lexical location";
   attribute :>> authority="Current activation until materialization commits";
   attribute :>> contract="Prevent a later tail-call overwrite while an observer request is pending; preserve actual lexical location and original control result";
   attribute :>> refusal="On unknown ordering, retain activation and fall back before delivering the observer";
   attribute :>> source="lib/_eval#.scm: macro-make-cprc and macro-step!; lib/_repl.scm: ##interp-continuation-rte";
   attribute :>> qntAction="requestCapture";
 }
 part begin:Transition {
   attribute :>> id="materialize-begin"; attribute :>> trigger="An observer requires stable heap representation";
   attribute :>> authority="Activation retains rooted compact fields throughout allocation";
   attribute :>> contract="Allocation or GC cannot lose or duplicate the values and identity needed for the stable lexical cell";
   attribute :>> refusal="Failure retains original roots and preserves the original exception/failure semantics";
   attribute :>> source="lib/_eval.scm: ##cprc-prc-req1 and ##check-heap-limit; GC root map";
   attribute :>> qntAction="beginMaterialization";
 }
 part commit:Transition {
   attribute :>> id="materialize-commit"; attribute :>> trigger="The stable lexical environment is fully initialized and rooted";
   attribute :>> authority="One environment identity shared by closure, continuation and reflection";
   attribute :>> contract="Publish the initialized cell before delivering capture, and redirect all later writes to that same identity";
   attribute :>> refusal="Partial or unknown initialization remains unpublished; no observer receives a partial vector";
   attribute :>> source="lib/_eval#.scm: macro-rte-ref, macro-rte-set! and macro-rte-up; lib/_repl.scm: ##for-each-rte-binding";
   attribute :>> qntAction="materialize";
 }
 part settle:Transition {
   attribute :>> id="capture-commit"; attribute :>> trigger="The observer receives the materialized frame";
   attribute :>> authority="Captured continuation or closure retains the stable location";
   attribute :>> contract="Repeated continuation resumes and closure writes see the same lexical location; later tail calls cannot overwrite it";
   attribute :>> refusal="Unknown observer ownership prevents reuse";
   attribute :>> source="lib/_repl.scm: ##interp-procedure-rte and ##interp-continuation-rte";
   attribute :>> qntAction="capture";
 }
 part bindingGuard:Transition {
   attribute :>> id="binding-guard"; attribute :>> trigger="A compact interpreter step is about to use a cached operator or binding";
   attribute :>> authority="Existing binding owner and current execution context";
   attribute :>> contract="The public binding and stable primitive identity must both be authoritative at the effect linearization point; evaluation order, numeric behavior and exceptions remain unchanged";
   attribute :>> refusal="A changed or unknown binding falls back at the current program point without replaying a committed effect";
   attribute :>> source="lib/_eval.scm: ##cprc-app1-red and ##cprc-app2-sub; lib/_kernel.scm: ##global-var-primitive-ref and ##global-var-primitive-set!";
   attribute :>> qntAction="fastEffect";
 }
 part laterPoll:Transition {
   attribute :>> id="later-poll-observation"; attribute :>> trigger="A later asynchronous interrupt exposes another interpreted activation at a numeric poll";
   attribute :>> authority="The captured continuation and debugger retain each observed lexical location independently";
   attribute :>> contract="After GC the original frame still exposes the same writable environment. Mutating that location cannot alter the later frame. Preserve identity before publishing the captured continuation.";
   attribute :>> refusal="Retain ordinary vectors when the poll path cannot root and detach each exposed location";
   attribute :>> source="lib/_repl.scm: ##interp-subproblem-continuation? and ##interp-continuation-rte read the rte slot from the real ##subproblem-apply2 frame";
   attribute :>> qntAction="inspectLaterPoll";
 }
 attribute modelPath:String="dev/refactoring/modern-c/models/quint/smp_interpreter_tail_deopt.qnt";
 attribute baselinePath:String="evidence/research/retained/modern-c/stress-gsi/dev-interpreter-identity-baseline.json";
 attribute numericCandidate:String="The public numeric procedure owns exact binary fixnum specialization after argument forcing. The interpreter still loads and invokes the actual operator and retains its normal continuation. Nonfixnum, overflow and variadic operations follow the existing path.";
 attribute numericResultRoute:String="The exact-two branch returns a proved boolean or successful fixnum after the existing poll. The fallback runs the original numeric kernel with its type and overflow result checks. Variadic folding retains its own checks.";
 attribute numericPoll:String="The C backend must retain a real poll and an exact internal-return frame before the specialized result becomes observable. Compare interrupted capture and resume to the ordinary numeric call on the same producer.";
 attribute numericControls:String="dev/refactoring/modern-c/models/quint/smp_interpreter_source_order.qnt";
 attribute numericNativeEvidence:String="Matched isolated GSI images share the retained archive and differ in the numeric module. Both observe the exact greater and subtraction poll labels during interpreted execution and resume across GC. Reduced ABBA timing isolates the numeric edge; unchanged allocation and original-family admission remain separate.";
 attribute costProjection:String="dev/refactoring/modern-c/models/quint/smp_tfib_cost_recurrence.qnt";
 attribute allocationUnits:String="An ordinary unary RTE writes four words in the selected 64-bit layout. The runtime reports movable occupation with a factor of two for semispace accounting. Compare the counted RTE contribution against that reporting unit, and keep physical payload, other allocations and live occupancy distinct.";
 attribute familyCriticalPath:String="p1 starts after all p2 shards finish. For the retained unspliced attempt, the p2 launch remainder and completed interrupt2 shard bound the optimistic p1 budget at about 102.61 seconds if those costs hold and the censored shard costs zero. The bound excludes teardown and p1 setup. A new producer requires a fresh whole-family observation.";
 attribute status:String="proposed protocol; no runtime implementation or source-refinement certificate";
 attribute admitted:Boolean=false;
}
