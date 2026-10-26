import RuntimeTlsReady
open RuntimeTlsReadyAst
def badState : State := {initial with g:=2,locks:=1,tables:=1,genericKey:=1}
example : ¬ Safe badState := by simp [Safe,badState,initial]
example : Safe badState := by simp [Safe,badState,initial]
