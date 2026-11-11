import RcStorageAst
namespace RcStorage
open RcStorageAst
theorem debugQuery (q : State) (h : Safe q) (g : queryCommitGuard q) : Safe (queryCommitNext q) := by
 simp only [Safe,queryCommitGuard,queryCommitNext] at *
 omega
end RcStorage
