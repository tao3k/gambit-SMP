import DispatchJointAst
open DispatchJointAst
def witness : State := {initial with nativeOpen:=0,gcOpen:=0,frozen:=1,scanning:=1,viewRoot:=1}
example : deleteCommandGuard (initial) := by simp [deleteCommandGuard,initial]
example : closeGcGuard (deleteCommandNext (initial)) := by simp [closeGcGuard,initial,deleteCommandNext]
example : freezeRootsGuard (closeGcNext (deleteCommandNext (initial))) := by simp [freezeRootsGuard,initial,deleteCommandNext,closeGcNext]
example : beginScanGuard (freezeRootsNext (closeGcNext (deleteCommandNext (initial)))) := by simp [beginScanGuard,initial,deleteCommandNext,closeGcNext,freezeRootsNext]
example : witness = beginScanNext (freezeRootsNext (closeGcNext (deleteCommandNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : removeRootGuard witness := by simp [removeRootGuard,witness,initial]
example : ¬ (Safe (removeRootNext witness)) := by simp [Safe,removeRootNext,witness,initial]
example : Safe (removeRootNext witness) := by simp [Safe,removeRootNext,witness,initial]
