import SfunAdmissionAst
open SfunAdmissionAst
def witness : State := {initial with phase:=6,sourcePin:=0,sourceDrops:=1,root:=1,guard:=1,guardCreates:=1,markerCreates:=1,markerDrops:=1,allocs:=1,bodyEntries:=1,origin:=5}
example : witness = releaseMarkerNext (finishSuccessNext (beginBodyNext (allocateMarkerNext (ackHandoffNext (reserveGuardNext (initial)))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : releaseMarkerGuard witness := by simp [releaseMarkerGuard,witness,initial]
example : ¬ (Safe (releaseMarkerNext witness)) := by simp [Safe,releaseMarkerNext,witness,initial]
example : Safe (releaseMarkerNext witness) := by simp [Safe,releaseMarkerNext,witness,initial]
