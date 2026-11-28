import TclBorrowAst
import TclRefusalAst
import SfunAdmissionAst
namespace TclBorrowBridge
-- This discharges an abstract source-pin premise, not the native issuer.
def admissionInput (q : TclBorrowAst.State) : SfunAdmissionAst.State :=
 {SfunAdmissionAst.initial with sourcePin:=q.borrower}
theorem activeBorrowProvidesAdmissionRoot (q : TclBorrowAst.State) (h : TclBorrowAst.Safe q) (b : q.borrower=1) :
 q.storage=1 ∧ SfunAdmissionAst.Safe (admissionInput q) := by
 constructor
 · unfold TclBorrowAst.Safe at h
   grind
 · simp [admissionInput,b,SfunAdmissionAst.Safe,SfunAdmissionAst.initial]
def refusalFrame : TclRefusalAst.State := TclRefusalAst.beginEvalNext TclRefusalAst.initial
theorem rejectedSourceCanRecord (q : TclBorrowAst.State) (_r : q.refused=1) : TclRefusalAst.recordOuterRefusalGuard refusalFrame := by
 simp [refusalFrame,TclRefusalAst.beginEvalNext,TclRefusalAst.initial,TclRefusalAst.recordOuterRefusalGuard]
theorem recordedSourceRefusalSurvivesCatch :
 (TclRefusalAst.catchOrResetResultNext (TclRefusalAst.publishOuterDiagnosticNext (TclRefusalAst.recordOuterRefusalNext refusalFrame))).eventSeen=1 := by rfl
end TclBorrowBridge
