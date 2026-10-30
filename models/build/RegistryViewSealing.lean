import Std.Tactic
namespace RegistryViewSealing
-- Current-provider names, not the initial call's spelling, select a named mode.
def provider (p mode : Nat) (safe : Bool) : Nat :=
 if p=0 ∧ safe=false then 1
 else if p=0 ∨ p=1 then (if mode=1 then (if p=0 then 2 else 3) else if mode=2 then (if p=0 then 4 else 5) else p)
 else if p=2 ∧ safe=false then 3 else if p=4 ∧ safe=false then 5 else p
theorem namedGenericStop : provider 0 1 false=1 ∧ provider 1 0 false=1 := by decide
theorem unsafeFirst (mode : Nat) : provider 0 mode false=1 := by simp [provider]
theorem fixUnsafe : provider 2 0 false=3 ∧ provider 2 0 true=2 := by decide
theorem terminalPreserved (rho : α → β) (inj : Function.Injective rho) (f : α → α) (g : β → β)
 (h : ∀ p, g (rho p)=rho (f p)) (p : α) : g (rho p)=rho p ↔ f p=p := by
 rw [h p]; exact ⟨fun e => inj e, congrArg rho⟩
def applies (q : α) (names : List α) : Prop := names=[] ∨ q ∈ names
instance [DecidableEq α] (q : α) (names : List α) : Decidable (applies q names) := by
 unfold applies; infer_instance
theorem namedMatch (rho : α → β) (inj : Function.Injective rho) (q : α) (names : List α) :
 applies (rho q) (names.map rho) ↔ applies q names := by
 have heq : ∀ a b, rho a=rho b ↔ a=b := fun a b => ⟨fun e => inj e, congrArg rho⟩
 simp [applies, List.mem_map, heq]
structure Policy (α : Type) where
 mode : Nat
 names : List α
def transport (rho : α → β) (d : Policy α) : Policy β := ⟨d.mode,d.names.map rho⟩
def lookup [DecidableEq α] (q : α) : List (Policy α) → Nat
 | [] => 0
 | d::rest => if applies q d.names then d.mode else lookup q rest
theorem orderedLookupTransport [DecidableEq α] [DecidableEq β] (rho : α → β)
 (inj : Function.Injective rho) (q : α) (ds : List (Policy α)) :
 lookup (rho q) (ds.map (transport rho))=lookup q ds := by
 induction ds with
 | nil => rfl
 | cons d rest ih =>
   simp only [List.map_cons, lookup, transport]
   simp only [namedMatch rho inj, ih]
structure LeaseState where
 admission : Bool
 retired : Bool
 roots : Bool
 holders : Nat
def retire (s : LeaseState) : LeaseState := {s with admission:=false, retired:=true}
theorem leaseRetire (s : LeaseState) : (retire s).admission=false ∧ (retire s).roots=s.roots ∧ (retire s).holders=s.holders := by simp [retire]
def mayBegin (arity admission stable : Bool) := arity && admission && stable
theorem arityReject (admission stable : Bool) : mayBegin false admission stable=false := by simp [mayBegin]
def publish (tainted complete stable : Bool) := !tainted && complete && stable
theorem taintReject (complete stable : Bool) : publish true complete stable=false := by simp [publish]
theorem costPositive (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end RegistryViewSealing
