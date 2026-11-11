import DispatchJointAst
open DispatchJointAst
def witness : State := {initial with scope:=1,selected:=1,phase:=3,pending:=1,committed:=1,unknown:=1,borrow:=1,created:=1,rootAuth:=1,nativeAuth:=1}
example : enterNativeGuard (initial) := by simp [enterNativeGuard,initial]
example : selectHandleGuard (enterNativeNext (initial)) := by simp [selectHandleGuard,initial,enterNativeNext]
example : reserveRootGuard (selectHandleNext (enterNativeNext (initial))) := by simp [reserveRootGuard,initial,enterNativeNext,selectHandleNext]
example : commitJointGuard (reserveRootNext (selectHandleNext (enterNativeNext (initial)))) := by simp [commitJointGuard,initial,enterNativeNext,selectHandleNext,reserveRootNext]
example : loseReplyGuard (commitJointNext (reserveRootNext (selectHandleNext (enterNativeNext (initial))))) := by simp [loseReplyGuard,initial,enterNativeNext,selectHandleNext,reserveRootNext,commitJointNext]
example : witness = loseReplyNext (commitJointNext (reserveRootNext (selectHandleNext (enterNativeNext (initial))))) := by rfl
example : Safe witness := by simp [Safe,witness,initial]
example : deliverOutcomeGuard witness := by simp [deliverOutcomeGuard,witness,initial]
example : ¬ (Safe (deliverOutcomeNext witness)) := by simp [Safe,deliverOutcomeNext,witness,initial]
example : Safe (deliverOutcomeNext witness) := by simp [Safe,deliverOutcomeNext,witness,initial]
