namespace GambitSMP.StillReceiptAdmission
structure Ledger where
  liability : Nat
  credited : Nat
  consumed : Bool
  known : Bool
  permitsCredit : Bool
def total (s : Ledger) := s.liability+s.credited
inductive Step : Ledger → Ledger → Prop
 | settle (s : Ledger) (w : Nat) (h : w ≤ s.liability)
     (fresh : s.consumed=false) (known : s.known=true) (allowed : s.permitsCredit=true) :
     Step s {s with liability:=s.liability-w, credited:=s.credited+w, consumed:=true}
 | replay (s : Ledger) : Step s s
theorem stepConserves {a b : Ledger} (h : Step a b) : total a=total b := by
 cases h <;> simp [total] <;> omega
inductive Trace : Ledger → Ledger → Prop
 | nil (s : Ledger) : Trace s s
 | cons {a b c : Ledger} : Step a b → Trace b c → Trace a c
theorem traceConserves {a b : Ledger} (h : Trace a b) : total a=total b := by
 induction h with
 | nil => rfl
 | cons h _ ih => exact (stepConserves h).trans ih
theorem refundBound {a b : Ledger} (h : Trace a b) : b.credited ≤ a.liability+a.credited := by
 have e:=traceConserves h
 simp [total] at e
 omega
theorem duplicateNoCredit (a b : Ledger) (used : a.consumed=true) (h : Step a b) : b=a := by
 cases h with
 | settle w hw fresh known allowed => simp [used] at fresh
 | replay => rfl
theorem unknownNoCredit (a b : Ledger) (unknown : a.known=false) (h : Step a b) : b=a := by
 cases h with
 | settle w hw fresh known allowed => simp [unknown] at known
 | replay => rfl
theorem failedReleaseNoCredit (a b : Ledger) (denied : a.permitsCredit=false) (h : Step a b) : b=a := by
 cases h with
 | settle w hw fresh known allowed => simp [denied] at allowed
 | replay => rfl
structure Gate where
 captured : Nat
 current : Nat
 pending : Nat
 sweep : Bool
def admissible (g : Gate) := g.captured=g.current ∧ g.pending=0 ∧ g.sweep=false
theorem staleGateRejected (g : Gate) (stale : g.captured≠g.current) : ¬ admissible g := by
 simp [admissible,stale]
theorem busyGateRejected (g : Gate) (busy : 0<g.pending ∨ g.sweep=true) : ¬ admissible g := by
 intro h
 rcases h with ⟨_,hp,hs⟩
 rcases busy with hb|hb
 · omega
 · simp [hb] at hs
theorem releasedStillCharged (w : Nat) : total ⟨w,0,false,false,false⟩=w := by rfl
theorem metadataPeak (m rop n rblock d rgate v rview : Nat) :
 m*rop ≤ m*rop+n*rblock+d*rgate+v*rview := by omega
end GambitSMP.StillReceiptAdmission
