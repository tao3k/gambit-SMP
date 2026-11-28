import SfunAdmissionAst
import SizeGuardAst
open SfunAdmissionAst
namespace SfunAdmissionBridge
-- Admission predicate only: no full root-value or C23 state simulation.
def entryDomain (q : State) : SizeGuardAst.State :=
 {SizeGuardAst.initial with closed:=1-q.domainOpen}
theorem refusalMatchesClosedParent (q : State) (g : refuseBeforeEntryGuard q) : ¬ SizeGuardAst.reserveSfunGuard (entryDomain q) := by
 simp only [refuseBeforeEntryGuard] at g
 simp [SizeGuardAst.reserveSfunGuard,entryDomain,SizeGuardAst.initial]
 omega
theorem admittedMatchesParent (q : State) (g : reserveGuardGuard q) : SizeGuardAst.reserveSfunGuard (entryDomain q) := by
 simp only [reserveGuardGuard] at g
 simp [SizeGuardAst.reserveSfunGuard,entryDomain,SizeGuardAst.initial]
 omega
theorem originDistinguishesSameCode : ∃ a b : State,
 a.code=b.code ∧ a.origin≠b.origin ∧ ¬ recoverGoodGuard a ∧ recoverGoodGuard b := by
 let a : State := {initial with phase:=6,origin:=1,code:=1,refused:=1}
 let b : State := {initial with phase:=5,origin:=2,code:=1}
 refine ⟨a,b,rfl,by decide,?_,?_⟩
 · simp [a,recoverGoodGuard,initial]
 · simp [b,recoverGoodGuard,initial]
end SfunAdmissionBridge
