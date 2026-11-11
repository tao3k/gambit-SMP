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
def preparedN : FrameCommitAst.State :=
 FrameCommitAst.prepareReturnNext (FrameCommitAst.validateCopyNext
  (FrameCommitAst.initializeCopyNext (FrameCommitAst.resolveCanonicalNext
   (FrameCommitAst.enterRuntimeNext (FrameCommitAst.allocateRootedCopyNext
    (FrameCommitAst.reserveSplitNext FrameCommitAst.initial))))))
def committedN : FrameCommitAst.State := FrameCommitAst.commitSplitNext preparedN
def queuedP : LazySplitAst.State :=
 LazySplitAst.publishReadyNext (LazySplitAst.initializeCopyNext
  (LazySplitAst.allocateCopyNext (LazySplitAst.claimSplitNext LazySplitAst.initial)))
-- Safe individual milestone states do not establish phase coupling.
theorem safePairsNeedPhaseRelation :
 FrameCommitAst.Safe committedN ∧ LazySplitAst.Safe queuedP ∧ ¬ Coupled committedN queuedP := by
 unfold FrameCommitAst.Safe LazySplitAst.Safe Coupled
 decide
end FrameCommitBridge
