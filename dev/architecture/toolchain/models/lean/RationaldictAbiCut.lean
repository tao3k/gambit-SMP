import Std

-- Source-derived dependency paths, not a C parser or native layout proof.
namespace Gambit.RationaldictAbiCut
inductive Node where
 | moduleImage | moduleLayout | globalLayout | vmLayout | processorLayout
 | contextLayout | contextMemory | labelLayout | valueLayout | fieldAccess | hostBody
 deriving DecidableEq

def legacyEdge : Node → Node → Prop
 | .moduleImage, .moduleLayout => True
 | .moduleImage, .globalLayout => True
 | .moduleImage, .vmLayout => True
 | .moduleImage, .processorLayout => True
 | .globalLayout, .vmLayout => True
 | .vmLayout, .processorLayout => True
 | .vmLayout, .contextLayout => True
 | .contextLayout, .contextMemory => True
 | .moduleLayout, .labelLayout => True
 | .hostBody, .fieldAccess => True
 | .fieldAccess, .processorLayout => True
 | .fieldAccess, .contextLayout => True
 | .labelLayout, .valueLayout => True
 | _, _ => False
inductive Reach (edge : Node → Node → Prop) : Node → Node → Prop where
 | direct {a b} : edge a b → Reach edge a b
 | trans {a b c} : Reach edge a b → Reach edge b c → Reach edge a c

theorem sizeofReachesContext : Reach legacyEdge .moduleImage .contextLayout :=
 .trans (b:=.vmLayout) (.direct trivial) (.direct trivial)
theorem sizeofReachesMemory : Reach legacyEdge .moduleImage .contextMemory :=
 .trans sizeofReachesContext (.direct trivial)
theorem fieldAccessReachesContext : Reach legacyEdge .hostBody .contextLayout :=
 .trans (b:=.fieldAccess) (.direct trivial) (.direct trivial)

-- The new contract has TWO independent migration obligations; hiding one
-- surface cannot authorize dropping the other. No runtime implementation here.
structure Cut where
 moduleRegistrationReplaced : Bool
 stateAccessReplaced : Bool
 valueLabelProfileBound : Bool
 pasteAndBranchClosure : Bool
 declarationClosure : Bool
 setupAndEffectsRefined : Bool
 deriving DecidableEq

def Ready (c : Cut) : Prop := c.moduleRegistrationReplaced=true ∧
 c.stateAccessReplaced=true ∧ c.valueLabelProfileBound=true ∧
 c.pasteAndBranchClosure=true ∧ c.declarationClosure=true ∧ c.setupAndEffectsRefined=true

theorem readyRequiresRegistration (c : Cut) (ready : Ready c) : c.moduleRegistrationReplaced=true := ready.1
theorem readyRequiresState (c : Cut) (ready : Ready c) : c.stateAccessReplaced=true := ready.2.1
theorem accessOnlyNotReady (c : Cut) (old : c.moduleRegistrationReplaced=false) : ¬ Ready c := by
 intro ready
 have yes := readyRequiresRegistration c ready
 simp [old] at yes

def exposedEdge (c : Cut) (a b : Node) : Prop := legacyEdge a b ∧
 (a≠.moduleImage ∨ c.moduleRegistrationReplaced=false) ∧
 (a≠.fieldAccess ∨ c.stateAccessReplaced=false)
theorem fullCutRemovesRegistrationEdges (c : Cut) (ready : Ready c) (b : Node) :
 ¬ exposedEdge c .moduleImage b := by simp [exposedEdge,readyRequiresRegistration c ready]
theorem fullCutRemovesFieldEdges (c : Cut) (ready : Ready c) (b : Node) :
 ¬ exposedEdge c .fieldAccess b := by simp [exposedEdge,readyRequiresState c ready]

structure ValueLabelProfile where
 wordBits : Nat
 tagBits : Nat
 labelWords : Nat
 deriving DecidableEq
-- These are layout countermodels, not reports of actual compiled C offsets.
structure Layout where
 bytes : Nat
 registerOffset : Nat
 deriving DecidableEq
def left : Layout := ⟨64,8⟩
def right : Layout := ⟨64,16⟩
theorem equalSizeDoesNotBindOffset : left.bytes=right.bytes ∧ left.registerOffset≠right.registerOffset := by decide

def publicRead (readCell : Nat → Nat) (cell : Nat) := readCell cell
theorem readProjection (nativeCells : Nat → Nat) (publicCells : Nat → Nat)
 (refines : publicCells=nativeCells) (cell : Nat) : publicRead publicCells cell=nativeCells cell := by simp [publicRead,refines]
-- Lvalue operations include exactly one update, not an untyped repeated getter.
def writeCell (m : Nat → Nat) (cell value : Nat) := fun i => if i=cell then value else m i
theorem writeProjection (nativeCells publicCells : Nat → Nat) (refines : publicCells=nativeCells) (cell value : Nat) :
 writeCell publicCells cell value=writeCell nativeCells cell value := by rw [refines]

-- Exact arithmetic of the retained D855 MCP /12 diagnostic, NOT current POO.
theorem historicalTarget : (74671000 : Nat)=2*37335500 := by decide
theorem historicalIntervalDeficit : (636536000 : Nat)-12*37335500=188510000 := by decide
theorem scheduleOnlyCannotMeetTarget : (636536000 : Nat)>12*37335500 := by decide
theorem residualCriticalLowerBound : (53044667 : Nat)-37335500=15709167 := by decide
end Gambit.RationaldictAbiCut
