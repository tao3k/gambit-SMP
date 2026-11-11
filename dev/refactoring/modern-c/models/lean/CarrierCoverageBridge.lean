import CarrierCoverage
import PersistentCensus
import SourceOwnerAst
namespace CarrierCoverageBridge
open CarrierCoverageAst
-- This bridges a parent precondition, not native trace refinement.
 theorem parentQualificationBoundary (p : SourceOwnerAst.State)
   (owner : p.owner = 2) (target : p.target0 = 1) (idle : p.gc = 0) :
   SourceOwnerAst.qualifyPersistentCoverageGuard p := by
   simp [SourceOwnerAst.qualifyPersistentCoverageGuard, owner, target, idle]
 theorem registeredClosingEnumerated (q : State) (h : Safe q)
   (frozen : q.gc = 1) (closing : q.d1 = 3) : q.snap1 = 1 := by
   simp_all [Safe]
 theorem cleanupRequiresBacking (q : State) (g : cleanupSourceGuard q) : q.backing1 = 1 := by
   simp_all [cleanupSourceGuard]
 theorem retirementRequiresIdle (q : State) (g : retireCarrierGuard q) : q.gc = 0 ∧ q.observe1 = 0 ∧ q.use1 = 0 := by
   simp_all [retireCarrierGuard]
theorem privateInitializationBlocksFreeze (q : State) (p : q.d1 = 1) (i : q.initialized1 = 1) : ¬ freezeSourceGuard q := by
   simp [freezeSourceGuard, p, i]
end CarrierCoverageBridge
