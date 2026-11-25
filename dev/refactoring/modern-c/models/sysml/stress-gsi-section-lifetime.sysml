package GambitStressGsiSectionLifetime {
 private import ScalarValues::*;
 ref part grant=GambitStressGsiRestoration::plan;
 ref part family=GambitModernCDeliveryPlan::a6;

 attribute open:Boolean=true;
 attribute logicalPredecessorSource:String="vendor/gambit/lib/_mem/allocation-limits.inc::___stack_limit; vendor/gambit/lib/_kernel.scm::break handler";
 attribute physicalReleaseSource:String="vendor/gambit/lib/_mem/allocation-limits.inc::___stack_overflow_undo_if_possible writes base[0] and issues a carrier free-list entry";
 attribute reuseConsumers:String="vendor/gambit/lib/_mem/allocation-limits.inc::___stack_limit and ___heap_limit pop the free list; heap-sections.inc supplies the VM fresh suffix and shared fallback";
 attribute epochCut:String="vendor/gambit/lib/_mem/collection-round.inc::weak drain, grant, move_continuation, restored, collective barrier";
 attribute admission:String="A logical predecessor can authorize frame recovery. Physical section reuse also needs exclusive interval ownership and drained readers across both stack and heap roles. Unknown ownership retains the old holder and makes the interval ineligible for allocation.";
 attribute falsifier:String="Show a real path out of shared fallback before epoch retirement while a live old heap interval remains. Current resize votes for GC when the fresh suffix is insufficient; pointer inequality is not a proof and actual same-round reachability remains open.";
 attribute boundary:String="Treat acquire, share, first-break publication, undo, both free-list consumers and epoch retirement as one replacement cut. Existing QNT owns transition histories and Lean owns the conditional interval facts.";
 attribute acceptance:String="The p2 frame controls support the coordinate refinement. The unchanged compiled p2 TFIB failure refutes sufficiency of the coordinate correction; the interpreted family remains open.";
}
