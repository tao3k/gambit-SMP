import FrameActivationMaps
namespace FrameActivation
open FrameActivationAst
theorem reserveAligned (q : State) (h : Safe q) (g : reserveGuard q) : Aligned (reserveNext q) := by
 dsimp only [Aligned,reserveNext]
 simp only [FrameActivationAst.Safe] at h
 simp only [reserveGuard] at g
 omega
theorem allocateAligned (q : State) (h : Safe q) (g : allocateGuard q) : Aligned (allocateNext q) := by
 dsimp only [Aligned,allocateNext]
 simp only [FrameActivationAst.Safe] at h
 simp only [allocateGuard] at g
 omega
theorem enterAligned (q : State) (h : Safe q) (g : enterGuard q) : Aligned (enterNext q) := by
 dsimp only [Aligned,enterNext]
 simp only [FrameActivationAst.Safe] at h
 simp only [enterGuard] at g
 omega
theorem resolveAligned (q : State) (h : Safe q) (g : resolveGuard q) : Aligned (resolveNext q) := by
 dsimp only [Aligned,resolveNext]
 simp only [FrameActivationAst.Safe] at h
 simp only [resolveGuard] at g
 omega
theorem initializeAligned (q : State) (h : Safe q) (g : initializeGuard q) : Aligned (initializeNext q) := by
 dsimp only [Aligned,initializeNext]
 simp only [FrameActivationAst.Safe] at h
 simp only [initializeGuard] at g
 omega
theorem validateAligned (q : State) (h : Safe q) (g : validateGuard q) : Aligned (validateNext q) := by
 dsimp only [Aligned,validateNext]
 simp only [FrameActivationAst.Safe] at h
 simp only [validateGuard] at g
 omega
end FrameActivation
