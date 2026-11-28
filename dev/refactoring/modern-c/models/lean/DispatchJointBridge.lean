import DispatchJointAst
import TclBorrowAst
import TclRefusalAst
namespace DispatchJointBridge
-- Conditional predicate embedding, not a full multi-model simulation.
def sourceInput (q : DispatchJointAst.State) : TclBorrowAst.State :=
 {TclBorrowAst.initial with scope:=q.borrow,borrower:=q.borrow,borrowCreated:=q.borrow,selected:=q.borrow}
theorem jointBorrowProvidesSourcePin (q : DispatchJointAst.State) (h : DispatchJointAst.Safe q) (b : q.borrow=1) :
 q.storage=1 ∧ TclBorrowAst.Safe (sourceInput q) := by
 constructor
 · unfold DispatchJointAst.Safe at h
   grind
 · simp [sourceInput,b,TclBorrowAst.Safe,TclBorrowAst.initial]
def nativeOutcome : TclRefusalAst.State := TclRefusalAst.beginEvalNext TclRefusalAst.initial
theorem refusalCanRecordNative (q : DispatchJointAst.State) (_r : q.refused=1) :
 TclRefusalAst.recordOuterRefusalGuard nativeOutcome := by
 simp [nativeOutcome,TclRefusalAst.beginEvalNext,TclRefusalAst.initial,TclRefusalAst.recordOuterRefusalGuard]
end DispatchJointBridge
