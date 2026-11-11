import FrameCommit
import LazySplitAst
namespace FrameCommitBridge
def Coupled (n : FrameCommitAst.State) (p : LazySplitAst.State) : Prop :=
 (n.decision=2 → p.split=1) ∧ n.done=p.childDone
theorem bothForbidLocal (n : FrameCommitAst.State) (p : LazySplitAst.State)
 (hn : FrameCommitAst.Safe n) (hp : LazySplitAst.Safe p) (c : Coupled n p) (split : n.decision=2) :
 n.localGrants=0 ∧ ¬ LazySplitAst.runLocalParentGuard p := by
 constructor
 · exact FrameCommit.noLocalAfterSplit n hn split
 · have ps:=c.1 split
   unfold LazySplitAst.runLocalParentGuard
   intro g
   unfold LazySplitAst.Safe at hp
   grind
end FrameCommitBridge
