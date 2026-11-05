import RuntimeTlsReady
open RuntimeTlsReadyAst
def badState : State := {initial with g:=3,locks:=1,tables:=1,genericKey:=1,allocKey:=1,cache:=4,fast:=1,fastEpoch:=1,observed:=1}
example : ¬ Safe badState := by simp [Safe,badState,initial]
example : Safe badState := by simp [Safe,badState,initial]
