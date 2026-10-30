import DispatchJointAst
open DispatchJointAst
def witness : State := {initial with nativeOpen:=0,scope:=1,selected:=1,phase:=1,nativeAuth:=1}
example : enterNativeGuard (initial) := by simp [enterNativeGuard,initial]
example : selectHandleGuard (enterNativeNext (initial)) := by simp [selectHandleGuard,initial,enterNativeNext]
example : deleteCommandGuard (selectHandleNext (enterNativeNext (initial))) := by simp [deleteCommandGuard,initial,enterNativeNext,selectHandleNext]
example : witness = deleteCommandNext (selectHandleNext (enterNativeNext (initial))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : freeStorageGuard witness := by simp [freeStorageGuard,witness,initial]
example : ¬ (Safe (freeStorageNext witness)) := by simp [Safe,freeStorageNext,witness,initial]
example : Safe (freeStorageNext witness) := by simp [Safe,freeStorageNext,witness,initial]
