import CacheReadyPublication
open CacheReadyPublicationAst
def badState : State := {initial with stage:=6,owned:=1,busy:=1,tls:=1,listed:=1,ready:=1,ack:=1,allocations:=1}
example : ¬ Safe badState := by simp [Safe,badState,initial]
