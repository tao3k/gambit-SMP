import DarwinForceBinding
namespace DerivationReceiptEnvironment
structure Flat where
 owner : Int
 active : Bool
 child : Int
 ledger : Int
 pubs : Int
 claims : Int
 receipt : Int
 uncertain : Bool
 closed : Bool
 freed : Bool
 deriving DecidableEq
inductive Phase where
 | live | derivingChild | finishing | done
 deriving DecidableEq
def phaseCode : Phase → Int
 | .live => 0 | .derivingChild => 1 | .finishing => 2 | .done => 3
structure State where
 phase : Phase
 child : Int
 ledger : Int
 pubs : Int
 claims : Int
 receipt : Int
 uncertain : Bool
 closed : Bool
 freed : Bool
 deriving DecidableEq
def alpha (s : State) : Flat :=
 ⟨phaseCode s.phase, s.phase==.derivingChild, s.child,s.ledger,s.pubs,s.claims,s.receipt,s.uncertain,s.closed,s.freed⟩
def qReserveGuard (q : Flat) : Prop := q.owner=1 ∧ q.active=true ∧ q.child=0 ∧ q.ledger<2
def qReserveNext (q : Flat) := {q with child:=1,ledger:=q.ledger+1}
def qPublishGuard (q : Flat) : Prop := q.owner=1 ∧ q.child=1
def qPublishNext (q : Flat) := {q with child:=2,receipt:=1,pubs:=q.pubs+1,uncertain:=true}
def qFinishGuard (q : Flat) : Prop := q.child=3 ∧ q.receipt=1 ∧ q.ledger>0
def qFinishNext (q : Flat) := {q with child:=4,receipt:=2,ledger:=q.ledger-1}
def reserve (s : State) := {s with child:=1,ledger:=s.ledger+1}
def publish (s : State) := {s with child:=2,receipt:=1,pubs:=s.pubs+1,uncertain:=true}
def finishChild (s : State) := {s with child:=4,receipt:=2,ledger:=s.ledger-1}
theorem reserveRefines (s : State) (h : s.phase=.derivingChild) (c : s.child=0) (n : s.ledger<2) :
 qReserveGuard (alpha s) ∧ alpha (reserve s)=qReserveNext (alpha s) := by
 simp [qReserveGuard,alpha,phaseCode,h,c,n,reserve,qReserveNext]
theorem publicationOwnsPendingDelivery (s : State) : (publish s).uncertain=true := rfl
theorem publishRefines (s : State) (h : s.phase=.derivingChild) (c : s.child=1) :
 qPublishGuard (alpha s) ∧ alpha (publish s)=qPublishNext (alpha s) := by
 simp [qPublishGuard,alpha,phaseCode,h,c,publish,qPublishNext]
theorem finishRefines (s : State) (c : s.child=3) (r : s.receipt=1) (n : s.ledger>0) :
 qFinishGuard (alpha s) ∧ alpha (finishChild s)=qFinishNext (alpha s) := by
 simp [qFinishGuard,alpha,c,r,n,finishChild,qFinishNext]
def canBeginFinish (s : State) : Prop := s.phase=.live
theorem derivingExcludesFinish (s : State) (h : s.phase=.derivingChild) : ¬canBeginFinish s := by
 simp [canBeginFinish,h]
theorem finishingExcludesDerive (s : State) (h : s.phase=.finishing) : s.phase≠.live := by simp [h]
def dropParent (s : State) := {s with phase:=.done,ledger:=s.ledger-1}
theorem reserveThenReleaseRetainsDebt (s : State) (h : s.ledger>0) :
 (dropParent (reserve s)).ledger>0 := by simp [dropParent,reserve]; omega
def replay (s : State) := s
theorem replayDoesNotPublish (s : State) : (replay s).pubs=s.pubs := rfl
def reconcile (s : State) := {s with uncertain:=false}
theorem reconcileDoesNotComplete (s : State) : (reconcile s).child=s.child ∧ (reconcile s).ledger=s.ledger := ⟨rfl,rfl⟩
def canRetire (s : State) : Prop := s.closed=true ∧ s.phase=.done ∧ s.ledger=0 ∧ s.uncertain=false
theorem unknownBlocksRetirement (s : State) (h : s.uncertain=true) : ¬canRetire s := by
 intro c; simp_all [canRetire]
-- A finite table is distinct from a caller-supplied function. First occurrence wins.
def buildEnv : List (Nat × Nat) → Nat → Option Nat
 | [], _ => none
 | (k,d)::rs, q => if q=k then some d else buildEnv rs q
def Matches (rows : List (Nat × Nat)) (env : Nat → Option Nat) : Prop :=
 ∀ p ∈ rows, env p.1=some p.2
def tableCheck (rows : List (Nat × Nat)) : Bool :=
 rows.all (fun p => buildEnv rows p.1 == some p.2)
theorem checkedEnvironment (rows : List (Nat × Nat)) (h : tableCheck rows=true) : Matches rows (buildEnv rows) := by
 simpa [tableCheck,Matches,List.all_eq_true] using h
theorem lookupFromWitness (rows : List (Nat × Nat)) (h : tableCheck rows=true)
 (k d : Nat) (m : (k,d)∈rows) : buildEnv rows k=some d := by
 exact checkedEnvironment rows h (k,d) m
theorem conflictingRowsRejected : tableCheck [(172,67),(172,8)]=false := by decide
theorem environmentExtractionMeaning (rows : List (Nat × Nat)) (target : Nat)
 (ρ : Nat → Nat → Int) (e : DarwinForceBinding.Expr) (a : DarwinForceBinding.Ast)
 (h : DarwinForceBinding.extract (buildEnv rows) target e=some a) :
 DarwinForceBinding.evalSource (buildEnv rows) ρ e=some (DarwinForceBinding.evalAst (ρ target) a) :=
 DarwinForceBinding.admittedMeaning (buildEnv rows) target ρ e a h
-- tableCheck consistency alone does not prove the rows came from authentic JSON.
end DerivationReceiptEnvironment
