import AtomicOwner
namespace AtomicOwner

structure AtomicOutcome where
 exchanged : Bool
 observed : Int
 deriving DecidableEq

-- These functions describe branch contracts, not compiled C wrappers.
def nativeNormalize (expectedBefore expectedAfter : Int) (ok : Bool) : AtomicOutcome :=
 {exchanged:=ok,observed:=if ok then expectedBefore else expectedAfter}
def legacyNormalize (expectedBefore rawOld : Int) : AtomicOutcome :=
 {exchanged:=decide (rawOld=expectedBefore),observed:=rawOld}
def weakContract (before : Int) (out : AtomicOutcome) : Prop :=
 out.exchanged=true → out.observed=before

theorem nativeFailureObserved (before after : Int) :
 (nativeNormalize before after false).observed=after := by rfl
theorem nativeSuccessObserved (before after : Int) :
 (nativeNormalize before after true).observed=before := by rfl
theorem legacyObservedIsRaw (before old : Int) :
 (legacyNormalize before old).observed=old := by rfl

theorem strongNormalizationsAgree (before old : Int) :
 nativeNormalize before old (decide (old=before))=legacyNormalize before old := by
 by_cases h : old=before
 · simp [nativeNormalize,legacyNormalize,h]
 · simp [nativeNormalize,legacyNormalize,h]

theorem legacyRefinesWeakContract (before old : Int) :
 weakContract before (legacyNormalize before old) := by
 simp [weakContract,legacyNormalize]

theorem equalWeakFailureIsAllowed : weakContract 1 {exchanged:=false,observed:=1} := by
 simp [weakContract]
theorem equalLegacyRawIsSuccess : (legacyNormalize 1 1).exchanged=true := by rfl

theorem failureDoesNotReleaseParent (q : AtomicOwnerAst.State) :
 (AtomicOwnerAst.splitNativeFailureNext q).n_sourceRoot=q.n_sourceRoot ∧
 (AtomicOwnerAst.splitNativeFailureNext q).n_destRoot=q.n_destRoot := by exact ⟨rfl,rfl⟩

theorem foreignWorkerViewCannotClaim (q : AtomicOwnerAst.State) (missing : q.w1View=0) :
 ¬ AtomicOwnerAst.claimW1Guard q := by simp [AtomicOwnerAst.claimW1Guard,missing]

theorem winnerPreventsOtherClaim (q : AtomicOwnerAst.State) (taken : q.activationWord=2) :
 ¬ AtomicOwnerAst.claimW1Guard q := by simp [AtomicOwnerAst.claimW1Guard,taken]
end AtomicOwner
