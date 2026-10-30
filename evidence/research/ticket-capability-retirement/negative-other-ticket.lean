import TicketCapabilityAst
namespace TicketIdentityAlgebra
structure Key where
 session : Nat
 domain : Nat
 generation : Nat
 serial : Nat
 deriving DecidableEq
structure Ticket where
 phase : Int
 payload : Nat
 outcome : Option Int
 deriving DecidableEq
abbrev Ledger := Key → Option Ticket
-- Completion is supplied by the trusted executor; source witness fidelity is external.
def finish (r : Option Ticket) (payload : Nat) (value : Int) : Option Ticket :=
 match r with
 | none => none
 | some t =>
   match t.outcome with
   | some _ => some t
   | none => if t.phase=2 ∧ t.payload=payload then
       some {t with phase:=3, outcome:=some value}
     else some t
def settle (ledger : Ledger) (key : Key) (payload : Nat) (value : Int) : Ledger :=
 fun q => finish (ledger key) payload value

theorem finishIdempotent (r : Option Ticket) (p : Nat) (v : Int) :
 finish (finish r p v) p v = finish r p v := by
 cases r with
 | none => rfl
 | some t =>
   cases h : t.outcome with
   | some x => simp [finish,h]
   | none =>
     by_cases g : t.phase=2 ∧ t.payload=p
     · simp [finish,h,g]
     · simp [finish,h,g]
theorem settleOther (ledger : Ledger) (key q : Key) (p : Nat) (v : Int)
 (different : q≠key) : settle ledger key p v q = ledger q := by
 simp [settle,different]
theorem settleIdempotent (ledger : Ledger) (key : Key) (p : Nat) (v : Int) :
 settle (settle ledger key p v) key p v = settle ledger key p v := by
 funext q
 by_cases h : q=key
 · subst q; simp [settle,finishIdempotent]
 · simp [settle,h]
theorem existingOutcomeRetained (ledger : Ledger) (key : Key) (p : Nat)
 (old new : Int) (t : Ticket) (found : ledger key=some t) (done : t.outcome=some old) :
 settle ledger key p new = ledger := by
 funext q
 by_cases h : q=key
 · subst q; simp [settle,found,finish,done]
 · simp [settle,h]
theorem differentGeneration (a b : Key) (g : a.generation≠b.generation) : a≠b := by
 intro h
 exact g (congrArg Key.generation h)
def dropHandle (handles : Key → Bool) (key : Key) : Key → Bool :=
 fun q => if q=key then false else handles q
theorem dropOther (handles : Key → Bool) (key q : Key) (h : q≠key) :
 dropHandle handles key q = handles q := by simp [dropHandle,h]
theorem dropIdempotent (handles : Key → Bool) (key : Key) :
 dropHandle (dropHandle handles key) key = dropHandle handles key := by
 funext q
 by_cases h : q=key <;> simp [dropHandle,h]
open TicketCapabilityAst
def view0 (q : State) : Option Ticket :=
 if q.t0phase=0 then none else
 some {phase:=q.t0phase,payload:=42,outcome:=if q.t0phase≥3 then some q.t0outcome else none}
def view1 (q : State) : Option Ticket :=
 if q.t1phase=0 then none else
 some {phase:=q.t1phase,payload:=42,outcome:=if q.t1phase≥3 then some q.t1outcome else none}
theorem commitProjection0 (q : State) (g : commit0Guard q) :
 view0 (commit0Next q)=finish (view0 q) 42 q.t0exit := by
 simp_all [view0,commit0Guard,commit0Next,finish]
theorem queryProjection0 (q : State) : view0 (query0Next q)=view0 q := by rfl
theorem commit0PreservesOtherIdentity (q : State) : view1 (commit0Next q)=view1 q := by rfl
end TicketIdentityAlgebra
