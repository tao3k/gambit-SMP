import NativeReturnAst
open NativeReturnAst
def witness : State := {initial with phase:=6,threadLive:=1,stackLive:=0,returnRight:=0,guard:=0,root:=1,shot:=1,ticket:=2,retained:=1,closed:=0,grace:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : resumeSecondGuard witness := by simp [resumeSecondGuard,witness,initial]
example : ¬ (Safe (resumeSecondNext witness)) := by simp [Safe,resumeSecondNext,witness,initial]
example : Safe (resumeSecondNext witness) := by simp [Safe,resumeSecondNext,witness,initial]
