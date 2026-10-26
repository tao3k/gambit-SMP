import DispatchJointAst
open DispatchJointAst
def witness : State := {initial with nativeOpen:=0,others:=1}
example : enterOtherGuard (initial) := by simp [enterOtherGuard,initial]
example : deleteCommandGuard (enterOtherNext (initial)) := by simp [deleteCommandGuard,initial,enterOtherNext]
example : witness = deleteCommandNext (enterOtherNext (initial)) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : freeControlGuard witness := by simp [freeControlGuard,witness,initial]
example : ¬ (Safe (freeControlNext witness)) := by simp [Safe,freeControlNext,witness,initial]
example : Safe (freeControlNext witness) := by simp [Safe,freeControlNext,witness,initial]
