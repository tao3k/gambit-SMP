import Std.Tactic
namespace DeclarationSpecializationContext
def walk [DecidableEq α] (next : α → α) : Nat → α → Option α
 | 0, _ => none
 | n+1, p => if next p=p then some p else walk next n (next p)
theorem walkTransport [DecidableEq α] [DecidableEq β] (rho : α → β) (inj : Function.Injective rho)
 (f : α → α) (g : β → β) (step : ∀ p, g (rho p)=rho (f p)) (n : Nat) (p : α) :
 Option.map rho (walk f n p)=walk g n (rho p) := by
 induction n generalizing p with
 | zero => rfl
 | succ n ih =>
   by_cases h : f p=p
   · have h' : g (rho p)=rho p := (step p).trans (congrArg rho h)
     simp [walk,h,h']
   · have h' : g (rho p)≠rho p := by intro e; exact h (inj ((step p).symm.trans e))
     rw [walk, if_neg h, walk, if_neg h', step p]
     exact ih (f p)
theorem fixedPointTransport (rho : α → β) (inj : Function.Injective rho) (f : α → α) (g : β → β)
 (step : ∀ p, g (rho p)=rho (f p)) (p : α) : g (rho p)=rho p ↔ f p=p := by
 rw [step p]
 exact ⟨fun e => inj e,congrArg rho⟩
theorem helperIdentity (rho : α → β) (inj : Function.Injective rho) (p h : α) : rho p=rho h ↔ p=h := ⟨fun e => inj e,congrArg rho⟩
structure Env where
 decl : List (Nat × Nat)
 bindings : Nat
def restore (env : Env) (saved : List (Nat × Nat)) : Env := {env with decl:=saved}
theorem restoreKeepsBinding (env : Env) (saved : List (Nat × Nat)) : (restore env saved).bindings=env.bindings := rfl
def lookup (name fallback : Nat) : List (Nat × Nat) → Nat
 | [] => fallback
 | (n,v)::rest => if n=name then v else lookup name fallback rest
theorem batchOrder : lookup 1 0 ([(1,1),(1,2)].foldl (fun acc d => d::acc) [])=2 := by decide
theorem headOverride (name value fallback : Nat) (rest : List (Nat × Nat)) : lookup name fallback ((name,value)::rest)=value := by simp [lookup]
theorem otherNameStable (n m v fallback : Nat) (rest : List (Nat × Nat)) (h : n≠m) : lookup m fallback ((n,v)::rest)=lookup m fallback rest := by simp [lookup,h]
theorem costPositive (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end DeclarationSpecializationContext
