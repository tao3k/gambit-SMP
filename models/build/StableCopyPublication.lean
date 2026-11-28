import Std.Tactic
namespace StableCopyPublication
structure State where
 locked : Bool
 sourcePin : Bool
 destPin : Bool
 lease : Bool
 a : Nat
 b : Nat
 generation : Nat
def canWrite (s : State) : Bool := !s.locked
theorem exclusiveBlocksWriter (s : State) (h : s.locked=true) : canWrite s=false := by simp [canWrite,h]
def ownedCopy (a b : Nat) : Nat × Nat := (a,b)
theorem copyEquality (a b expectedA expectedB : Nat) (ha : a=expectedA) (hb : b=expectedB) :
 ownedCopy a b=(expectedA,expectedB) := by simp [ownedCopy,ha,hb]
theorem tornCounterexample : (0,1)≠(0,0) ∧ (0,1)≠(1,1) := by decide
def releaseSource (s : State) : State := {s with locked:=false,sourcePin:=false}
theorem releasePreservesCopy (s : State) : (releaseSource s).a=s.a ∧ (releaseSource s).b=s.b ∧
 (releaseSource s).destPin=s.destPin ∧ (releaseSource s).lease=s.lease := by simp [releaseSource]
theorem generationMismatch (captured current : Nat) (h : captured≠current) : ¬current=captured := Ne.symm h
theorem noABA (generation advances : Nat) (h : 0<advances) : generation+advances≠generation := by omega
def mayPublish (tainted validated : Bool) := !tainted && validated
theorem taintBlocksPublication (validated : Bool) : mayPublish true validated=false := by simp [mayPublish]
theorem costPositive (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end StableCopyPublication
