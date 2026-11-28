import Lean.Elab.Tactic.Omega

namespace GambitSMP.SynchronousPublication

-- Parametric target lemmas, not C source simulation or QNT-to-Lean refinement.
structure Debt where
  owner : Nat
  receipt : Bool
  notification : Bool
  callerResidual : Bool
  deriving DecidableEq

def Live (d : Debt) : Prop :=
  d.receipt = true ∨ d.notification = true ∨ d.callerResidual = true

def Covered (owners : List Nat) (debts : List Debt) : Prop :=
  ∀ d ∈ debts, Live d → d.owner ∈ owners

def ReceiptCovered (owners : List Nat) (debts : List Debt) : Prop :=
  ∀ d ∈ debts, d.receipt = true → d.owner ∈ owners

theorem zeroOwnersDischargesAllDebt (owners : List Nat) (debts : List Debt)
    (zero : owners.length = 0) (coverage : Covered owners debts) :
    ∀ d ∈ debts, ¬ Live d := by
  have empty : owners = [] := by
    cases owners with
    | nil => rfl
    | cons head tail => simp at zero
  intro d member live
  have owner := coverage d member live
  subst owners
  simp at owner

theorem completeCoverageImpliesReceiptCoverage (owners : List Nat) (debts : List Debt)
    (coverage : Covered owners debts) : ReceiptCovered owners debts := by
  intro d member receipt
  exact coverage d member (Or.inl receipt)

def lateNotification : Debt := ⟨0, false, true, false⟩

theorem receiptCoverageAloneInsufficient :
    ReceiptCovered [] [lateNotification] ∧ ¬ Covered [] [lateNotification] := by
  constructor
  · intro d member receipt
    simp only [List.mem_cons, List.not_mem_nil, or_false] at member
    subst d
    simp [lateNotification] at receipt
  · intro coverage
    have owner := coverage lateNotification (by simp) (by simp [Live, lateNotification])
    simp at owner

theorem coveredTransferPreservesClosure (owners : List Nat) (before after : List Debt)
    (coverage : Covered owners before)
    (transfer : ∀ d ∈ after, Live d → ∃ old ∈ before, Live old ∧ old.owner = d.owner) :
    Covered owners after := by
  intro d member live
  obtain ⟨old, oldMember, oldLive, sameOwner⟩ := transfer d member live
  simpa [sameOwner] using coverage old oldMember oldLive

structure Ledger where
  issued : Nat
  unfinished : Nat
  settled : Nat
  returned : Nat
  receipts : Nat
  deriving DecidableEq

def Balanced (l : Ledger) : Prop := l.issued = l.unfinished + l.settled + l.returned

def reserve (l : Ledger) : Ledger :=
  { l with issued := l.issued + 1, unfinished := l.unfinished + 1, receipts := l.receipts + 1 }

def settle (l : Ledger) : Ledger :=
  { l with unfinished := l.unfinished - 1, settled := l.settled + 1 }

def rejectKnown (l : Ledger) : Ledger :=
  { l with unfinished := l.unfinished - 1, returned := l.returned + 1 }

theorem reservePreserves (l : Ledger) (h : Balanced l) : Balanced (reserve l) := by
  simp only [Balanced, reserve] at *
  omega

theorem settlementPreserves (l : Ledger) (h : Balanced l) (positive : 0 < l.unfinished) :
    Balanced (settle l) := by
  simp only [Balanced, settle] at *
  omega

-- Source must additionally prove actual private custody restored before refund.
theorem knownReturnPreserves (l : Ledger) (h : Balanced l) (positive : 0 < l.unfinished) :
    Balanced (rejectKnown l) := by
  simp only [Balanced, rejectKnown] at *
  omega

theorem zeroUnfinishedDoesNotDischargeReceipt :
    ∃ l : Ledger, Balanced l ∧ l.unfinished = 0 ∧ l.receipts > 0 := by
  exact ⟨⟨1, 0, 1, 0, 1⟩, by rfl, rfl, by decide⟩

theorem explicitToContainedCost (b : Nat) : 5 * b = 3 * b + 2 * b := by omega

end GambitSMP.SynchronousPublication
