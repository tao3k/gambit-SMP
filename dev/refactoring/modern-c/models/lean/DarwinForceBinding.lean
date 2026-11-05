namespace DarwinForceBinding
-- The resolver input is a declared proof premise; raw JSON is outside this kernel model.
structure Ref where
 occurrence : Nat
 spelling : String
 slot : Nat
inductive Expr where
 | literal : Int → Expr
 | field : Ref → Expr
 | add : Expr → Expr → Expr
 | unsupported : Expr
inductive Ast where
 | literal : Int → Ast
 | field : Nat → Ast
 | add : Ast → Ast → Ast
def extract (resolve : Nat → Option Nat) (target : Nat) : Expr → Option Ast
 | .literal n => some (.literal n)
 | .field r => if resolve r.occurrence = some target then some (.field r.slot) else none
 | .add a b => do return .add (← extract resolve target a) (← extract resolve target b)
 | .unsupported => none
def evalSource (resolve : Nat → Option Nat) (ρ : Nat → Nat → Int) : Expr → Option Int
 | .literal n => some n
 | .field r => (resolve r.occurrence).map (fun d => ρ d r.slot)
 | .add a b => do return (← evalSource resolve ρ a)+(← evalSource resolve ρ b)
 | .unsupported => none
def evalAst (σ : Nat → Int) : Ast → Int
 | .literal n => n
 | .field f => σ f
 | .add a b => evalAst σ a+evalAst σ b
-- This theorem does not assume names determine identity.
theorem admittedMeaning (resolve : Nat → Option Nat) (target : Nat)
 (ρ : Nat → Nat → Int) (e : Expr) (a : Ast) (h : extract resolve target e=some a) :
 evalSource resolve ρ e=some (evalAst (ρ target) a) := by
 induction e generalizing a with
 | literal n => simp [extract] at h; cases h; rfl
 | unsupported => simp [extract] at h
 | field r =>
   simp only [extract] at h
   split at h
   next he => simp only [Option.some.injEq] at h; cases h; simp [evalSource,he,evalAst]
   next => simp at h
 | add l r il ir =>
   cases hl : extract resolve target l <;> cases hr : extract resolve target r <;>
     simp [extract,hl,hr] at h
   next al ar =>
     cases h
     simp [evalSource,il al hl,ir ar hr,evalAst]
theorem wrongIdentityRejected (resolve : Nat → Option Nat) (target : Nat) (r : Ref)
 (h : resolve r.occurrence ≠ some target) : extract resolve target (.field r)=none := by
 simp [extract,h]
theorem spellingIrrelevant (resolve : Nat → Option Nat) (target : Nat) (r : Ref) (n : String) :
 extract resolve target (.field {r with spelling:=n})=extract resolve target (.field r) := rfl
-- Same spelling is insufficient if the lookup resolves to the wrong declaration.
theorem sameSpellingCounterexample :
 extract (fun _ => some 8) 7 (.field ⟨172,"s",0⟩)=none := by decide
structure Debt where
 parent : Bool
 child : Nat
 initialized : Bool
 unknown : Bool
def live (d : Debt) : Nat := (if d.parent then 1 else 0)+(if d.child>0 then 1 else 0)
def reserve (d : Debt) : Debt := {d with child:=1,initialized:=false}
def dropParent (d : Debt) : Debt := {d with parent:=false}
def canFree (d : Debt) : Prop := d.parent=false ∧ d.child=0 ∧ d.unknown=false
theorem reserveBeforeDrop (d : Debt) : live (dropParent (reserve d))=1 := by simp [live,dropParent,reserve]
theorem childBlocks (d : Debt) (h : d.child>0) : ¬canFree d := by intro c; have z:=c.2.1; omega
theorem unknownBlocks (d : Debt) (h : d.unknown=true) : ¬canFree d := by intro c; simp_all [canFree]
def publish (d : Debt) : Debt := {d with child:=2}
def claim (d : Debt) : Debt := {d with child:=3}
theorem publishAcquire (d : Debt) (h : d.initialized=true) : (claim (publish d)).initialized=true := h
-- This proves payload-preservation of an abstract transition, not C11 synchronization.
theorem unpublishedCounterexample : (publish ⟨true,1,false,false⟩).initialized=false := rfl
end DarwinForceBinding
