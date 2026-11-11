import DispatchJointAst
open DispatchJointAst
def witness : State := {initial with scope:=1,selected:=1,phase:=2,pending:=1,lease:=1,rootAuth:=1,nativeAuth:=1,gcOpen:=0}
example : enterNativeGuard (initial) := by simp [enterNativeGuard,initial]
example : selectHandleGuard (enterNativeNext (initial)) := by simp [selectHandleGuard,initial,enterNativeNext]
example : reserveRootGuard (selectHandleNext (enterNativeNext (initial))) := by simp [reserveRootGuard,initial,enterNativeNext,selectHandleNext]
example : closeGcGuard (reserveRootNext (selectHandleNext (enterNativeNext (initial)))) := by simp [closeGcGuard,initial,enterNativeNext,selectHandleNext,reserveRootNext]
example : witness = closeGcNext (reserveRootNext (selectHandleNext (enterNativeNext (initial)))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : freezeRootsGuard witness := by simp [freezeRootsGuard,witness,initial]
example : ¬ (Safe (freezeRootsNext witness)) := by simp [Safe,freezeRootsNext,witness,initial]
example : Safe (freezeRootsNext witness) := by simp [Safe,freezeRootsNext,witness,initial]
