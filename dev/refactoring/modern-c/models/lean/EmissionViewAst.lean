import Std
namespace EmissionViewAst
set_option maxRecDepth 10000
structure State where
 phase : Int
 generation : Int
 snapshot : Int
 pending : Int
 writers : Int
 cGen : Int
 mGen : Int
 frontCaptured : Bool
 lateCaptured : Bool
 aliasesClosed : Bool
 inputFrozen : Bool
 fragmentsOwned : Bool
 layoutDone : Bool
 escaped : Bool
 opaqueSeen : Bool
 nativeQualified : Bool
 verifierQualified : Bool
 cDone : Bool
 mDone : Bool
 coverage : Bool
 ioComplete : Bool
 receipt : Bool
 nativeReady : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.phase≥(0)) ∧ (q.phase≤(4)) ∧ (q.generation≥(1)) ∧ (q.snapshot≥(0)) ∧ (q.pending≥(0)) ∧ (q.pending≤(2)) ∧ (q.writers≥(0)) ∧ (q.writers≤(1)) ∧ (q.cGen≥(0)) ∧ (q.mGen≥(0)) ∧ (((q.phase=(2)) ∨ (q.phase=(3))) → ((((((((((q.frontCaptured=true) ∧ (q.lateCaptured=true)) ∧ (q.aliasesClosed=true)) ∧ (q.inputFrozen=true)) ∧ (q.fragmentsOwned=true)) ∧ (q.layoutDone=true)) ∧ (q.pending=(0))) ∧ (q.writers=(0))) ∧ (¬(q.escaped=true))) ∧ (q.snapshot=q.generation))) ∧ ((q.aliasesClosed=true) → ((q.phase≥(1)) ∧ (q.writers=(0)))) ∧ ((q.inputFrozen=true) → (q.aliasesClosed=true)) ∧ ((q.fragmentsOwned=true) → (q.aliasesClosed=true)) ∧ ((q.layoutDone=true) → (((((q.aliasesClosed=true) ∧ (q.inputFrozen=true)) ∧ (q.fragmentsOwned=true)) ∧ (q.pending=(0))) ∧ (q.writers=(0)))) ∧ ((q.cDone=true) → ((q.phase≥(2)) ∧ (q.cGen=q.snapshot))) ∧ ((q.mDone=true) → ((q.phase≥(2)) ∧ (q.mGen=q.snapshot))) ∧ ((q.coverage=true) → (((q.cDone=true) ∧ (q.mDone=true)) ∧ (q.verifierQualified=true))) ∧ ((q.ioComplete=true) → ((q.cDone=true) ∧ (q.mDone=true))) ∧ ((q.receipt=true) → (((((q.phase=(3)) ∧ (q.coverage=true)) ∧ (q.ioComplete=true)) ∧ (q.cGen=q.generation)) ∧ (q.mGen=q.generation))) ∧ ((q.phase=(3)) → (q.receipt=true)) ∧ ((q.nativeReady=true) → ((q.receipt=true) ∧ ((¬(q.opaqueSeen=true)) ∨ (q.nativeQualified=true)))))
def initial : State := {phase:=(0), generation:=(1), snapshot:=(0), pending:=(0), writers:=(0), cGen:=(0), mGen:=(0), frontCaptured:=false, lateCaptured:=false, aliasesClosed:=false, inputFrozen:=false, fragmentsOwned:=false, layoutDone:=false, escaped:=false, opaqueSeen:=false, nativeQualified:=false, verifierQualified:=false, cDone:=false, mDone:=false, coverage:=false, ioComplete:=false, receipt:=false, nativeReady:=false}
def captureFrontGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.frontCaptured=true)) ∧ (q.pending<(2))
def captureFrontNext (q : State) : State := {q with frontCaptured:=true, pending:=(q.pending+(1)), generation:=(q.generation+(1))}
def captureLateGuard (q : State) : Prop := (q.phase=(0)) ∧ (¬(q.lateCaptured=true)) ∧ (q.pending<(2))
def captureLateNext (q : State) : State := {q with lateCaptured:=true, pending:=(q.pending+(1)), generation:=(q.generation+(1))}
def discoverChildGuard (q : State) : Prop := (q.phase≤(1)) ∧ (q.pending>(0)) ∧ (q.pending<(2))
def discoverChildNext (q : State) : State := {q with pending:=(q.pending+(1)), generation:=(q.generation+(1))}
def drainOneGuard (q : State) : Prop := (q.phase≤(1)) ∧ (q.pending>(0))
def drainOneNext (q : State) : State := {q with pending:=(q.pending-(1)), generation:=(q.generation+(1))}
def reserveWriterGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.writers=(0))
def reserveWriterNext (q : State) : State := {q with writers:=(1)}
def writerPublishGuard (q : State) : Prop := (q.phase≤(1)) ∧ (q.writers=(1)) ∧ (q.pending<(2))
def writerPublishNext (q : State) : State := {q with pending:=(q.pending+(1)), generation:=(q.generation+(1))}
def writerDoneGuard (q : State) : Prop := (q.phase≤(1)) ∧ (q.writers=(1))
def writerDoneNext (q : State) : State := {q with writers:=(0)}
def unknownWriterGuard (q : State) : Prop := (q.phase≤(1)) ∧ (q.writers=(1))
def unknownWriterNext (q : State) : State := {q with phase:=(4)}
def escapeAliasGuard (q : State) : Prop := (q.phase≤(1)) ∧ (¬(q.aliasesClosed=true))
def escapeAliasNext (q : State) : State := {q with escaped:=true}
def beginCloseGuard (q : State) : Prop := (q.phase=(0)) ∧ (q.frontCaptured=true) ∧ (q.lateCaptured=true)
def beginCloseNext (q : State) : State := {q with phase:=(1)}
def closeAliasesGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.writers=(0)) ∧ (¬(q.escaped=true))
def closeAliasesNext (q : State) : State := {q with aliasesClosed:=true}
def freezeInputsGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.aliasesClosed=true) ∧ (¬(q.inputFrozen=true))
def freezeInputsNext (q : State) : State := {q with inputFrozen:=true, generation:=(q.generation+(1))}
def declareOpaqueGuard (q : State) : Prop := (q.phase≤(1)) ∧ (¬(q.fragmentsOwned=true))
def declareOpaqueNext (q : State) : State := {q with opaqueSeen:=true, generation:=(q.generation+(1))}
def copyFragmentsGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.aliasesClosed=true) ∧ (q.inputFrozen=true) ∧ (¬(q.fragmentsOwned=true))
def copyFragmentsNext (q : State) : State := {q with fragmentsOwned:=true, generation:=(q.generation+(1))}
def qualifyNativeGuard (q : State) : Prop := (q.phase=(1))
def qualifyNativeNext (q : State) : State := {q with nativeQualified:=true, generation:=(q.generation+(1)), layoutDone:=false}
def qualifyVerifierGuard (q : State) : Prop := (q.phase=(1))
def qualifyVerifierNext (q : State) : State := {q with verifierQualified:=true, generation:=(q.generation+(1)), layoutDone:=false}
def resolveLayoutGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.aliasesClosed=true) ∧ (q.inputFrozen=true) ∧ (q.fragmentsOwned=true) ∧ (q.pending=(0)) ∧ (q.writers=(0)) ∧ (¬(q.layoutDone=true))
def resolveLayoutNext (q : State) : State := {q with layoutDone:=true, generation:=(q.generation+(1))}
def lateLayoutWriteGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.layoutDone=true)
def lateLayoutWriteNext (q : State) : State := {q with layoutDone:=false, pending:=(1), generation:=(q.generation+(1))}
def freezeGuard (q : State) : Prop := (q.phase=(1)) ∧ (q.frontCaptured=true) ∧ (q.lateCaptured=true) ∧ (q.aliasesClosed=true) ∧ (q.inputFrozen=true) ∧ (q.fragmentsOwned=true) ∧ (q.layoutDone=true) ∧ (q.pending=(0)) ∧ (q.writers=(0)) ∧ (¬(q.escaped=true))
def freezeNext (q : State) : State := {q with phase:=(2), snapshot:=q.generation}
def emitCGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.cDone=true))
def emitCNext (q : State) : State := {q with cDone:=true, cGen:=q.snapshot}
def emitSpecGuard (q : State) : Prop := (q.phase=(2)) ∧ (¬(q.mDone=true))
def emitSpecNext (q : State) : State := {q with mDone:=true, mGen:=q.snapshot}
def verifyCoverageGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.cDone=true) ∧ (q.mDone=true) ∧ (q.verifierQualified=true)
def verifyCoverageNext (q : State) : State := {q with coverage:=true}
def closeOutputsGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.cDone=true) ∧ (q.mDone=true)
def closeOutputsNext (q : State) : State := {q with ioComplete:=true}
def issueGuard (q : State) : Prop := (q.phase=(2)) ∧ (q.coverage=true) ∧ (q.ioComplete=true) ∧ (q.cGen=q.generation) ∧ (q.mGen=q.generation)
def issueNext (q : State) : State := {q with phase:=(3), receipt:=true}
def nativePermitGuard (q : State) : Prop := (q.phase=(3)) ∧ (q.receipt=true) ∧ ((¬(q.opaqueSeen=true)) ∨ (q.nativeQualified=true))
def nativePermitNext (q : State) : State := {q with nativeReady:=true}
def rejectSnapshotGuard (q : State) : Prop := (q.phase=(2))
def rejectSnapshotNext (q : State) : State := {q with phase:=(4), generation:=(q.generation+(1))}
def unknownOutputGuard (q : State) : Prop := (q.phase=(2))
def unknownOutputNext (q : State) : State := {q with phase:=(4)}
def rejectLateWriterGuard (q : State) : Prop := (q.phase≥(1))
def rejectLateWriterNext (q : State) : State := {q with writers:=q.writers}
def Step (q r : State) : Prop := (captureFrontGuard q ∧ r=captureFrontNext q) ∨ (captureLateGuard q ∧ r=captureLateNext q) ∨ (discoverChildGuard q ∧ r=discoverChildNext q) ∨ (drainOneGuard q ∧ r=drainOneNext q) ∨ (reserveWriterGuard q ∧ r=reserveWriterNext q) ∨ (writerPublishGuard q ∧ r=writerPublishNext q) ∨ (writerDoneGuard q ∧ r=writerDoneNext q) ∨ (unknownWriterGuard q ∧ r=unknownWriterNext q) ∨ (escapeAliasGuard q ∧ r=escapeAliasNext q) ∨ (beginCloseGuard q ∧ r=beginCloseNext q) ∨ (closeAliasesGuard q ∧ r=closeAliasesNext q) ∨ (freezeInputsGuard q ∧ r=freezeInputsNext q) ∨ (declareOpaqueGuard q ∧ r=declareOpaqueNext q) ∨ (copyFragmentsGuard q ∧ r=copyFragmentsNext q) ∨ (qualifyNativeGuard q ∧ r=qualifyNativeNext q) ∨ (qualifyVerifierGuard q ∧ r=qualifyVerifierNext q) ∨ (resolveLayoutGuard q ∧ r=resolveLayoutNext q) ∨ (lateLayoutWriteGuard q ∧ r=lateLayoutWriteNext q) ∨ (freezeGuard q ∧ r=freezeNext q) ∨ (emitCGuard q ∧ r=emitCNext q) ∨ (emitSpecGuard q ∧ r=emitSpecNext q) ∨ (verifyCoverageGuard q ∧ r=verifyCoverageNext q) ∨ (closeOutputsGuard q ∧ r=closeOutputsNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (nativePermitGuard q ∧ r=nativePermitNext q) ∨ (rejectSnapshotGuard q ∧ r=rejectSnapshotNext q) ∨ (unknownOutputGuard q ∧ r=unknownOutputNext q) ∨ (rejectLateWriterGuard q ∧ r=rejectLateWriterNext q) ∨ r=q
end EmissionViewAst
