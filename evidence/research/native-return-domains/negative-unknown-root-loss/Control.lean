import NativeReturnAst
open NativeReturnAst
def witness : State := {initial with phase:=4,threadLive:=1,stackLive:=1,returnRight:=1,guard:=1,root:=1,shot:=1,ticket:=2,retained:=1,closed:=0,grace:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : unknownExitGuard witness := by simp [unknownExitGuard,witness,initial]
example : ¬ (Safe (unknownExitNext witness)) := by simp [Safe,unknownExitNext,witness,initial]
example : Safe (unknownExitNext witness) := by simp [Safe,unknownExitNext,witness,initial]
