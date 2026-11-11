-- Formal design only. JSON decoding, binding resolution and C11 refinement remain trusted/open.
namespace ForceMaintenanceFidelity
inductive SourceInt where
 | literal : Int → SourceInt
 | field : Nat → SourceInt
 | add : SourceInt → SourceInt → SourceInt
 | unsupported : SourceInt
inductive AstInt where
 | literal : Int → AstInt
 | field : Nat → AstInt
 | add : AstInt → AstInt → AstInt
-- Resolved field indices model a successful typed binding witness, not a name lookup proof.
def extract : SourceInt → Option AstInt
 | .literal n => some (.literal n)
 | .field f => some (.field f)
 | .add a b => do return .add (← extract a) (← extract b)
 | .unsupported => none
def sourceEval (σ : Nat → Int) : SourceInt → Option Int
 | .literal n => some n
 | .field f => some (σ f)
 | .add a b => do return (← sourceEval σ a) + (← sourceEval σ b)
 | .unsupported => none
def astEval (σ : Nat → Int) : AstInt → Int
 | .literal n => n
 | .field f => σ f
 | .add a b => astEval σ a + astEval σ b
theorem extractionMeaning (e : SourceInt) (σ : Nat → Int) :
 (extract e).map (astEval σ) = sourceEval σ e := by
 induction e with
 | literal n => rfl
 | field f => rfl
 | unsupported => rfl
 | add a b ia ib =>
   simp only [extract, sourceEval]
   rw [← ia, ← ib]
   cases ha : extract a <;> cases hb : extract b <;>
     simp [Option.map, Option.bind, astEval]
theorem unsupportedRejected : extract .unsupported = none := rfl
theorem admittedMeaning (e : SourceInt) (a : AstInt) (σ : Nat → Int)
 (h : extract e = some a) : sourceEval σ e = some (astEval σ a) := by
 rw [← extractionMeaning e σ, h]; rfl
structure Debt where
 external : Bool
 maintenance : Bool
 roots : Nat
 reserved : Nat
 readers : Nat
 unknown : Bool
 deriving DecidableEq
def canRetire (d : Debt) : Prop :=
 d.external=false ∧ d.maintenance=false ∧ d.roots=0 ∧ d.reserved=0 ∧ d.readers=0 ∧ d.unknown=false
theorem reservationBlocks (d : Debt) (h : d.reserved > 0) : ¬ canRetire d := by
 intro c; have z := c.2.2.2.1; omega
theorem readerBlocks (d : Debt) (h : d.readers > 0) : ¬ canRetire d := by
 intro c; have z := c.2.2.2.2.1; omega
theorem unknownBlocks (d : Debt) (h : d.unknown=true) : ¬ canRetire d := by
 intro c; have z := c.2.2.2.2.2; simp_all
def transfer (d : Debt) : Debt := {d with reserved:=d.reserved-1, readers:=d.readers+1}
theorem reservationTransferConserves (d : Debt) (h : d.reserved>0) :
 (transfer d).reserved+(transfer d).readers = d.reserved+d.readers := by
 simp only [transfer]; omega
-- Result is detached from saved R1: restoring the caller must not overwrite the force result.
structure ReturnState where
 result : Int
 callerR1 : Int
 temp2 : Int
 currentR1 : Int
def saveResult (s : ReturnState) := {s with temp2:=s.result}
def restoreCaller (s : ReturnState) := {s with currentR1:=s.callerR1}
def consumeForce (s : ReturnState) := {s with currentR1:=s.temp2}
theorem forceRestoration (s : ReturnState) :
 (consumeForce (restoreCaller (saveResult s))).currentR1=s.result := rfl
-- A moving collection between save and consume needs an explicit rewrite/root protocol.
def moveResult (s : ReturnState) := {s with result:=s.result+1}
theorem staleTempCounterexample :
 (consumeForce (moveResult (saveResult ⟨1,9,0,0⟩))).currentR1 ≠
 (moveResult (saveResult ⟨1,9,0,0⟩)).result := by decide
end ForceMaintenanceFidelity
