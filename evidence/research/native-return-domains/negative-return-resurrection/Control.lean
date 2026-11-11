import NativeReturnAst
open NativeReturnAst
def witness : State := {initial with phase:=7,threadLive:=1,stackLive:=0,returnRight:=0,guard:=1,root:=1,shot:=2,ticket:=3,retained:=1,closed:=0,grace:=0}
example : Safe witness := by simp [Safe,witness,initial]
example : rejectStaleReturnGuard witness := by simp [rejectStaleReturnGuard,witness,initial]
example : ¬ (Safe (rejectStaleReturnNext witness)) := by simp [Safe,rejectStaleReturnNext,witness,initial]
example : Safe (rejectStaleReturnNext witness) := by simp [Safe,rejectStaleReturnNext,witness,initial]
