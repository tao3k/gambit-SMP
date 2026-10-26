import ConverterUseAst
import SfunOwnerAst
namespace ConverterOwnerBridge
set_option maxRecDepth 10000
-- Local normal-cut adapter only; this does not simulate every transition or retirement.
def parentClosedAdmission (q : ConverterUseAst.State) : SfunOwnerAst.State :=
 { SfunOwnerAst.initial with stage:=(4), epoch:=(1), terminal:=(q.result - 1), active:=q.active, gate:=(0), valid:=q.valid, ref:=q.marker, effects:=q.effects, done:=q.settled, completed:=(1), borrowers:=q.inputRef, root:=q.roots, code:=q.code, captured:=q.captured, origin:=q.captured }
theorem normalCutInputs (q : ConverterUseAst.State) (h : ConverterUseAst.Safe q)
 (g : ConverterUseAst.signFinalUseGuard q) :
 (parentClosedAdmission q).active=0 ∧ (parentClosedAdmission q).borrowers=0 ∧
 (parentClosedAdmission q).terminal=1 ∧ (parentClosedAdmission q).ref=1 ∧
 (parentClosedAdmission q).root=1 ∧ (parentClosedAdmission q).code=1 := by
 dsimp only [parentClosedAdmission]
 grind [ConverterUseAst.Safe,ConverterUseAst.signFinalUseGuard]
theorem actualParentGuard (q : ConverterUseAst.State) (h : ConverterUseAst.Safe q)
 (g : ConverterUseAst.signFinalUseGuard q) :
 SfunOwnerAst.signLocalClosureGuard (parentClosedAdmission q) := by
 dsimp only [parentClosedAdmission,SfunOwnerAst.signLocalClosureGuard]
 grind [ConverterUseAst.Safe,ConverterUseAst.signFinalUseGuard]
theorem parentClosesSameUse (q : ConverterUseAst.State) (h : ConverterUseAst.Safe q)
 (g : ConverterUseAst.signFinalUseGuard q) :
 (SfunOwnerAst.signLocalClosureNext (parentClosedAdmission q)).closeOwner=1 ∧
 (SfunOwnerAst.signLocalClosureNext (parentClosedAdmission q)).closeEpoch=1 ∧
 (SfunOwnerAst.signLocalClosureNext (parentClosedAdmission q)).valid=0 := by
 exact ⟨rfl,rfl,rfl⟩
end ConverterOwnerBridge
