import CacheReadyPublication
open CacheReadyPublicationAst
def badState : State := {initial with stage:=5,owned:=1,busy:=1,owner:=1,tls:=1,listed:=1,ack:=2,builder:=0,allocations:=1}
example : ¬ Safe badState := by simp [Safe,badState,initial]
example : Safe badState := by simp [Safe,badState,initial]
